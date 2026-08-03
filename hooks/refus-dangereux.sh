#!/bin/bash
# Garde-fou global des commandes d'agents.
# Bloque les commandes shell catastrophiques avant que les agents ne les exécutent.
# Liste de refus : ~/.agents/hooks/motifs-dangereux.txt (une regex ERE par ligne).
#
# Utilisé par :
#   Claude Code  ~/.claude/settings.json  PreToolUse (matcher Bash)
#   Codex        ~/.codex/hooks.json      PreToolUse (matcher Bash)
#   Cursor       ~/.cursor/hooks.json     beforeShellExecution (argument : cursor)
#
# stdin  : JSON du hook. Claude/Codex mettent la commande dans .tool_input.command,
#          Grok dans .toolInput.command, Cursor dans .command.
# Bloque : mode par défaut -> exit 2 + raison sur stderr (contrat Claude/Codex).
#          mode « cursor »  -> JSON {"permission":"deny",...} sur stdout, exit 0.
# Autorise: mode par défaut -> exit 0, silencieux. Mode cursor -> {"permission":"allow"}.
#
# PROPRIÉTÉ À PRÉSERVER : cette garde ne s'ouvre jamais en silence. Sans `jq` elle
# bascule sur python3, et si aucun analyseur JSON n'est disponible elle le signale
# explicitement (variable DENY_GUARD_WARN_FILE) au lieu de laisser croire que la
# protection est active. Une garde muette est pire que pas de garde du tout.

set -uo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
MOTIFS="${DENY_GUARD_PATTERNS:-$HOME/.agents/hooks/motifs-dangereux.txt}"
MODE="${1:-exitcode}"
WARN_FILE="${DENY_GUARD_WARN_FILE:-$HOME/.agents/hooks/.garde-inactive}"

autoriser() {
  [ "$MODE" = "cursor" ] && printf '{"permission":"allow"}\n'
  exit 0
}

# Extrait la commande du JSON du hook. jq d'abord, python3 en secours.
extraire_commande() {
  local entree="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$entree" |
      jq -r '.tool_input.command // .toolInput.command // .command // empty' 2>/dev/null
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$entree" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if not isinstance(d, dict):
    sys.exit(0)
ti = d.get("tool_input") or d.get("toolInput") or {}
cmd = (ti.get("command") if isinstance(ti, dict) else None) or d.get("command") or ""
sys.stdout.write(cmd if isinstance(cmd, str) else "")
' 2>/dev/null
    return 0
  fi
  # Aucun analyseur JSON : on trace le trou de couverture, une seule fois.
  printf 'garde inactive (ni jq ni python3) depuis %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" \
    >"$WARN_FILE" 2>/dev/null || true
  echo "AVERTISSEMENT : garde-fou inactif — ni jq ni python3 sur le PATH. Installez-en un." >&2
  return 1
}

[ -f "$MOTIFS" ] || {
  echo "AVERTISSEMENT : garde-fou inactif — fichier de motifs introuvable : $MOTIFS" >&2
  autoriser
}

ENTREE=$(cat)
CMD=$(extraire_commande "$ENTREE") || autoriser
[ -z "$CMD" ] && autoriser

# Une garde active efface la trace d'inactivité laissée par un run précédent.
[ -f "$WARN_FILE" ] && rm -f "$WARN_FILE" 2>/dev/null

while IFS= read -r motif; do
  case "$motif" in ''|\#*) continue ;; esac
  if printf '%s\n' "$CMD" | grep -qE -- "$motif" 2>/dev/null; then
    RAISON="Commande bloquée par le garde-fou global ($MOTIFS). Motif déclenché : $motif. Ne relancez pas cette commande et ne cherchez pas à contourner la garde ; expliquez le blocage à l'utilisateur."
    if [ "$MODE" = "cursor" ]; then
      if command -v jq >/dev/null 2>&1; then
        jq -cn --arg r "$RAISON" '{
          permission: "deny",
          user_message: "Le garde-fou a bloqué une commande dangereuse.",
          agent_message: $r
        }'
      else
        printf '{"permission":"deny","user_message":"Le garde-fou a bloque une commande dangereuse.","agent_message":"Commande bloquee par le garde-fou global. Ne relancez pas cette commande."}\n'
      fi
      exit 0
    fi
    echo "$RAISON" >&2
    exit 2
  fi
done < "$MOTIFS"

autoriser

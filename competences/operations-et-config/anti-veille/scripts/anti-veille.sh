#!/bin/bash
# Anti-veille — enveloppe fiable autour de caffeinate (macOS).
# Crée un agent de lancement utilisateur à usage unique, avec les seuls outils intégrés.
#
# `start` remplace la session active par défaut, conformément au SKILL.md : l'utilisateur
# qui demande une nouvelle durée a déjà exprimé son intention. --no-replace fait échouer
# la commande à la place, quand on veut inspecter la session en cours avant de la remplacer.

set -euo pipefail

ETIQUETTE="${ANTI_VEILLE_LABEL:-local.anti-veille}"
DOMAINE="gui/$(/usr/bin/id -u)"
SERVICE="${DOMAINE}/${ETIQUETTE}"
DOSSIER_ETAT="${HOME}/Library/Caches/${ETIQUETTE}"
PLIST="${DOSSIER_ETAT}/job.plist"
ETAT="${DOSSIER_ETAT}/etat"
VERROU="${DOSSIER_ETAT}/verrou"

usage() {
  cat <<'FIN'
Usage :
  anti-veille.sh start SECONDES [--no-replace] [OPTIONS...]
  anti-veille.sh start-pid PID   [--no-replace] [OPTIONS...]
  anti-veille.sh verify
  anti-veille.sh status
  anti-veille.sh stop

OPTIONS par défaut : -d -i
Options autorisées : -d -i -m -s -u
FIN
}

mourir() { echo "ERREUR=$*" >&2; exit 1; }

liberer_verrou() { /bin/rmdir "$VERROU" >/dev/null 2>&1 || true; }

prendre_verrou() {
  local maintenant modifie
  /bin/mkdir -p "$DOSSIER_ETAT"
  /bin/chmod 700 "$DOSSIER_ETAT"
  if ! /bin/mkdir "$VERROU" 2>/dev/null; then
    maintenant=$(/bin/date +%s)
    modifie=$(/usr/bin/stat -f %m "$VERROU" 2>/dev/null || echo "$maintenant")
    # un verrou de plus de 30 s est considéré comme abandonné par un shell tué
    if [[ "$modifie" =~ ^[0-9]+$ ]] && (( maintenant - modifie > 30 )); then
      /bin/rmdir "$VERROU" 2>/dev/null || mourir "une autre opération anti-veille est en cours"
      /bin/mkdir "$VERROU" 2>/dev/null || mourir "une autre opération anti-veille est en cours"
    else
      mourir "une autre opération anti-veille est en cours"
    fi
  fi
  trap liberer_verrou EXIT
  trap 'exit 130' HUP INT TERM
}

service_charge() { /bin/launchctl print "$SERVICE" >/dev/null 2>&1; }

pid_service() {
  /bin/launchctl print "$SERVICE" 2>/dev/null |
    /usr/bin/awk '$1 == "pid" && $2 == "=" { print $3; exit }'
}

est_caffeinate() {
  local pid="${1:-}" commande
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  commande=$(/bin/ps -p "$pid" -o command= 2>/dev/null || true)
  [[ "$commande" == /usr/bin/caffeinate* ]]
}

valeur_etat() {
  local cle="$1"
  [[ -f "$ETAT" ]] || return 1
  /usr/bin/awk -F= -v cle="$cle" '$1 == cle { sub(/^[^=]*=/, ""); print; exit }' "$ETAT"
}

formater_epoch() { /bin/date -r "$1" '+%Y-%m-%d %H:%M:%S %Z'; }

valider_options() {
  local opt
  for opt in "$@"; do
    case "$opt" in
      -d|-i|-m|-s|-u) ;;
      *) mourir "option caffeinate non prise en charge : $opt" ;;
    esac
  done
}

decharger_job() {
  if service_charge; then
    /bin/launchctl bootout "$SERVICE" >/dev/null ||
      mourir "impossible de retirer l'agent de lancement existant ${ETIQUETTE}"
  fi
}

ecrire_plist() {
  local temp argument
  temp=$(/usr/bin/mktemp "${DOSSIER_ETAT}/job.plist.XXXXXX")
  {
    cat <<FIN
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${ETIQUETTE}</string>
  <key>ProgramArguments</key>
  <array>
FIN
    for argument in "$@"; do
      printf '    <string>%s</string>\n' "$argument"
    done
    cat <<'FIN'
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <false/>
</dict>
</plist>
FIN
  } >"$temp"
  /bin/chmod 600 "$temp"
  /bin/mv "$temp" "$PLIST"
}

ecrire_etat() {
  local mode="$1" cible="$2" options="$3" pid="$4" debut="$5" expiration="$6" temp
  temp=$(/usr/bin/mktemp "${DOSSIER_ETAT}/etat.XXXXXX")
  {
    printf 'MODE=%s\n' "$mode"
    printf 'CIBLE=%s\n' "$cible"
    printf 'OPTIONS=%s\n' "$options"
    printf 'PID=%s\n' "$pid"
    printf 'DEBUT_EPOCH=%s\n' "$debut"
    printf 'EXPIRATION_EPOCH=%s\n' "$expiration"
  } >"$temp"
  /bin/chmod 600 "$temp"
  /bin/mv "$temp" "$ETAT"
}

verifier_actif() {
  local pid commande assertions
  pid=$(pid_service || true)
  est_caffeinate "$pid" || return 1
  commande=$(/bin/ps -p "$pid" -o command=)
  assertions=$(/usr/bin/pmset -g assertions 2>/dev/null || true)
  /usr/bin/grep -Fq "pid ${pid}(caffeinate)" <<<"$assertions" || return 1

  printf 'STATUT=actif\n'
  printf 'ETIQUETTE=%s\n' "$ETIQUETTE"
  printf 'PID=%s\n' "$pid"
  printf 'COMMANDE=%s\n' "$commande"
  printf 'ASSERTIONS=actives\n'

  if [[ -f "$ETAT" ]]; then
    printf 'MODE=%s\n' "$(valeur_etat MODE)"
    printf 'OPTIONS=%s\n' "$(valeur_etat OPTIONS)"
    if [[ "$(valeur_etat MODE)" == "minuteur" ]]; then
      printf 'EXPIRE_LE=%s\n' "$(formater_epoch "$(valeur_etat EXPIRATION_EPOCH)")"
    else
      printf 'JUSQU_AU_PID=%s\n' "$(valeur_etat CIBLE)"
    fi
  fi
}

demarrer_job() {
  local mode="$1" cible="$2" remplacer="$3"
  shift 3
  local options=("$@")
  local arguments=(/usr/bin/caffeinate)
  local texte_options pid_existant pid debut expiration=0 tentative

  if [[ ${#options[@]} -eq 0 ]]; then options=(-d -i); fi
  valider_options "${options[@]}"
  prendre_verrou

  pid_existant=$(pid_service || true)
  if est_caffeinate "$pid_existant"; then
    if [[ "$remplacer" != "oui" ]]; then
      mourir "anti-veille tourne déjà (PID ${pid_existant}) ; --no-replace demandé"
    fi
    echo "REMPLACEMENT=session active PID ${pid_existant} arrêtée" >&2
  fi

  decharger_job
  /bin/mkdir -p "$DOSSIER_ETAT"
  /bin/chmod 700 "$DOSSIER_ETAT"
  /bin/rm -f "$PLIST" "$ETAT"

  arguments+=("${options[@]}")
  if [[ "$mode" == "minuteur" ]]; then
    arguments+=(-t "$cible")
  else
    arguments+=(-w "$cible")
  fi

  ecrire_plist "${arguments[@]}"
  debut=$(/bin/date +%s)
  [[ "$mode" == "minuteur" ]] && expiration=$((debut + cible))

  if ! /bin/launchctl bootstrap "$DOMAINE" "$PLIST"; then
    /bin/rm -f "$PLIST"
    mourir "launchctl n'a pas pu démarrer l'agent de lancement à usage unique"
  fi

  pid=""
  for tentative in 1 2 3 4 5; do
    pid=$(pid_service || true)
    est_caffeinate "$pid" && break
    /bin/sleep 0.2
  done

  if ! est_caffeinate "$pid"; then
    decharger_job
    /bin/rm -f "$PLIST" "$ETAT"
    mourir "caffeinate n'a pas survécu au lancement"
  fi

  texte_options="${options[*]}"
  ecrire_etat "$mode" "$cible" "$texte_options" "$pid" "$debut" "$expiration"

  verifier_actif || {
    decharger_job
    /bin/rm -f "$PLIST" "$ETAT"
    mourir "caffeinate a démarré sans assertion d'alimentation visible"
  }
}

statut_job() {
  local maintenant mode expiration pid
  if verifier_actif; then return 0; fi

  pid=$(pid_service || true)
  if [[ -f "$ETAT" ]]; then
    mode=$(valeur_etat MODE)
    if [[ "$mode" == "minuteur" ]]; then
      maintenant=$(/bin/date +%s)
      expiration=$(valeur_etat EXPIRATION_EPOCH)
      if [[ "$expiration" =~ ^[0-9]+$ ]] && (( maintenant >= expiration )); then
        printf 'STATUT=expire\n'
        printf 'EXPIRE_LE=%s\n' "$(formater_epoch "$expiration")"
        return 0
      fi
    fi
    printf 'STATUT=echec\n'
    printf 'PID_ATTENDU=%s\n' "$(valeur_etat PID)"
    printf 'PID_OBSERVE=%s\n' "${pid:-aucun}"
    return 1
  fi

  if service_charge; then
    printf 'STATUT=inactif\n'
    printf 'ETIQUETTE=%s\n' "$ETIQUETTE"
  else
    printf 'STATUT=arrete\n'
  fi
}

arreter_job() {
  prendre_verrou
  decharger_job
  /bin/rm -f "$PLIST" "$ETAT"
  printf 'STATUT=arrete\n'
  printf 'ETIQUETTE=%s\n' "$ETIQUETTE"
}

# Extrait --no-replace de la liste d'arguments et renvoie le reste.
REMPLACER="oui"
ARGS=()
for a in "$@"; do
  if [[ "$a" == "--no-replace" ]]; then REMPLACER="non"; else ARGS+=("$a"); fi
done
set -- ${ARGS[@]+"${ARGS[@]}"}

commande="${1:-}"
case "$commande" in
  start)
    duree="${2:-}"
    [[ "$duree" =~ ^[0-9]+$ ]] || mourir "la durée doit être un entier d'au moins 5 secondes"
    duree=$((10#$duree))
    (( duree >= 5 )) || mourir "la durée doit être un entier d'au moins 5 secondes"
    shift 2
    demarrer_job minuteur "$duree" "$REMPLACER" "$@"
    ;;
  start-pid)
    pid_cible="${2:-}"
    [[ "$pid_cible" =~ ^[0-9]+$ ]] || mourir "le PID doit être un entier positif"
    pid_cible=$((10#$pid_cible))
    (( pid_cible >= 1 )) || mourir "le PID doit être un entier positif"
    kill -0 "$pid_cible" 2>/dev/null || mourir "le PID cible ${pid_cible} ne tourne pas"
    shift 2
    demarrer_job pid "$pid_cible" "$REMPLACER" "$@"
    ;;
  verify)
    verifier_actif || mourir "anti-veille n'est pas actif avec des assertions d'alimentation"
    ;;
  status) statut_job ;;
  stop)   arreter_job ;;
  -h|--help|help) usage ;;
  *) usage >&2; exit 2 ;;
esac

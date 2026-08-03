#!/bin/bash
# Validateur des compétences du dépôt.
# Encode sous forme exécutable les règles de « competences-efficaces » et les modes de
# panne qui rendent une compétence silencieusement inopérante. À lancer avant chaque commit.
#
#   ./outils/valider-competences.sh
#
# Contrôles :
#   1. Chaque dossier de compétence contient un SKILL.md          (dossiers orphelins)
#   2. Le champ frontmatter « name » == nom du dossier
#   3. Le frontmatter YAML s'analyse en mode strict               (piège du « : » non quoté)
#   4. « description » présente, non vide, < 1024 caractères
#   5. Pas de « < » ni « > » dans le frontmatter                  (injection prompt système)
#   6. Les fichiers référencés (references/…, scripts/…) existent
#   7. Les scripts référencés sont exécutables
#   8. Aucun titre « ## » dupliqué dans un SKILL.md               (copier-coller)
#   9. Pas de README.md / CHANGELOG.md dans un dossier de compétence
#  10. Signalement des SKILL.md > 500 lignes                      (à découper en references/)

set -uo pipefail

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPETENCES="$RACINE/competences"
erreurs=0
avertissements=0

err()  { echo "ERREUR   $*"; erreurs=$((erreurs+1)); }
warn() { echo "ATTENTION $*"; avertissements=$((avertissements+1)); }

[ -d "$COMPETENCES" ] || { echo "Dossier introuvable : $COMPETENCES" >&2; exit 2; }

# 1. dossiers orphelins (profondeur 2 : competences/<categorie>/<competence>)
while IFS= read -r dossier; do
  [ -f "$dossier/SKILL.md" ] || err "dossier de compétence sans SKILL.md : ${dossier#$RACINE/}"
done < <(find "$COMPETENCES" -mindepth 2 -maxdepth 2 -type d | sort)

# 2-10. contrôles par SKILL.md
while IFS= read -r skill; do
  rel="${skill#$RACINE/}"
  dossier="$(dirname "$skill")"
  nom_dossier="$(basename "$dossier")"

  # frontmatter YAML strict + champs
  resultat=$(python3 - "$skill" "$nom_dossier" <<'PY'
import sys, re
chemin, attendu = sys.argv[1], sys.argv[2]
texte = open(chemin, encoding='utf-8').read()
m = re.match(r'^---\n(.*?)\n---\n', texte, re.S)
if not m:
    print("ERR frontmatter YAML absent ou mal délimité"); raise SystemExit
bloc = m.group(1)


def analyse_permissive(texte):
    """Repli sans PyYAML : imite un analyseur permissif et signale le piège du « : »."""
    resultat = {}
    for ligne in texte.split('\n'):
        if ligne.startswith((' ', '\t')) or ':' not in ligne:
            continue
        cle, val = ligne.split(':', 1)
        val = val.strip()
        if val and val[0] not in "'\"" and ': ' in val:
            print(f"ERR champ « {cle.strip()} » : « : » suivi d'une espace dans une valeur "
                  f"non quotée — les analyseurs YAML stricts refusent le fichier. "
                  f"Entourez la valeur d'apostrophes simples et doublez les apostrophes internes")
        resultat[cle.strip()] = val.strip("'\"")
    return resultat


meta = None
try:
    import yaml
except ImportError:
    meta = analyse_permissive(bloc)
else:
    try:
        charge = yaml.safe_load(bloc)
    except yaml.YAMLError as exc:
        # C'est LE cas qui compte : l'agent permissif charge la compétence, l'agent
        # strict la fait disparaître sans message. On signale et on continue les
        # autres contrôles via le repli permissif.
        detail = str(exc).replace('\n', ' ')[:160]
        print(f"ERR frontmatter YAML invalide en mode strict — {detail}")
        meta = analyse_permissive(bloc)
    else:
        if isinstance(charge, dict):
            meta = charge
        else:
            print("ERR le frontmatter n'est pas une table clé/valeur")
            meta = {}

nom = meta.get('name')
if not nom:
    print("ERR champ « name » manquant")
elif nom != attendu:
    print(f"ERR name={nom} != dossier={attendu}")

desc = meta.get('description')
if not desc:
    print("ERR champ « description » manquant ou vide")
elif len(str(desc)) > 1024:
    print(f"ERR description trop longue ({len(str(desc))} > 1024 caractères)")

if '<' in bloc or '>' in bloc:
    print("ERR « < » ou « > » dans le frontmatter (risque d'injection dans le prompt système)")
PY
)
  while IFS= read -r ligne; do
    [ -z "$ligne" ] && continue
    case "$ligne" in ERR\ *) err "$rel : ${ligne#ERR }" ;; *) warn "$rel : $ligne" ;; esac
  done <<<"$resultat"

  # 6-7. fichiers référencés.
  # Un sous-dossier n'est contrôlé que si la compétence en embarque un du même nom :
  # sinon « scripts/deploy.sh » désigne le dépôt de l'utilisateur, pas la compétence.
  for sous in references scripts assets; do
    [ -d "$dossier/$sous" ] || continue
    while IFS= read -r ref; do
      [ -z "$ref" ] && continue
      if [ ! -e "$dossier/$ref" ]; then
        err "$rel : référence vers un fichier inexistant → $ref"
      elif [[ "$ref" == scripts/* && ! -x "$dossier/$ref" ]]; then
        err "$rel : script référencé non exécutable → $ref"
      fi
    done < <(grep -ohE "$sous/[A-Za-z0-9._-]+\.[a-z0-9]+" "$skill" | sort -u)
  done

  # Fichier embarqué jamais référencé depuis SKILL.md (chargement impossible)
  for sous in references scripts assets; do
    [ -d "$dossier/$sous" ] || continue
    while IFS= read -r fichier; do
      base="$sous/$(basename "$fichier")"
      grep -qF "$base" "$skill" || warn "$rel : $base embarqué mais jamais référencé"
    done < <(find "$dossier/$sous" -maxdepth 1 -type f)
  done

  # 8. titres « ## » dupliqués
  while IFS= read -r dup; do
    [ -z "$dup" ] && continue
    err "$rel : titre dupliqué → $dup"
  done < <(grep -E '^## ' "$skill" | sort | uniq -d)

  # 10. longueur
  lignes=$(wc -l < "$skill")
  [ "$lignes" -gt 500 ] && warn "$rel : $lignes lignes — déplacer le détail dans references/"

done < <(find "$COMPETENCES" -name SKILL.md | sort)

# 9. documentation destinée aux humains à l'intérieur d'une compétence
while IFS= read -r parasite; do
  err "documentation humaine dans une compétence : ${parasite#$RACINE/}"
done < <(find "$COMPETENCES" \( -name 'README.md' -o -name 'CHANGELOG.md' -o -name 'INSTALL.md' \) | sort)

total=$(find "$COMPETENCES" -name SKILL.md | wc -l | tr -d ' ')
echo ""
echo "$total compétences vérifiées — $erreurs erreur(s), $avertissements avertissement(s)"
[ "$erreurs" -eq 0 ]

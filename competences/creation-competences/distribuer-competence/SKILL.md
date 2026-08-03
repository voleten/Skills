---
name: distribuer-competence
description: 'Distribuer une compétence dans tous les dossiers de compétences des agents installés (Codex, Claude Code, Pi, Hermes) pour qu''ils la voient tous. À utiliser quand l''utilisateur dit « distribue cette compétence », « synchronise les compétences entre agents », ou après avoir créé ou modifié une compétence destinée à être globale. Couvre la disposition en liens symboliques et le piège du chemin de Pi.'
---

# Distribuer une compétence à tous les agents

Une compétence doit exister dans le dossier de chaque agent (ou y être liée) pour être
découvrable par tous.

## Découvrir la disposition réelle avant d'agir

Ne supposez pas la disposition : mesurez-la. Les chemins varient selon les machines et
les versions d'agents.

```bash
for d in ~/.agents/skills ~/.claude/skills ~/.pi/agent/skills ~/.hermes/skills; do
  if [ -L "$d" ]; then echo "LIEN     $d -> $(readlink "$d")"
  elif [ -d "$d" ]; then echo "DOSSIER  $d"
  else echo "ABSENT   $d"; fi
done
```

Disposition de référence (voir `PROFIL.md` à la racine du dépôt pour la vôtre) :

| Agent | Dossier de compétences | Nature |
|---|---|---|
| Codex / OpenAI Agents | `~/.agents/skills/` | **Canonique** — écrivez ici en premier |
| Claude Code | `~/.claude/skills/` | Lien symbolique → `~/.agents/skills/` |
| Pi Agent | `~/.pi/agent/skills/` | Lien symbolique → `~/.agents/skills/` |
| Hermes Agent | `~/.hermes/skills/` | Copie indépendante — la seule à copier manuellement |

**Le chemin de Pi est `~/.pi/agent/skills/`, avec `/agent/` imbriqué — pas `~/.pi/skills/`.**
Une compétence placée dans `~/.pi/skills/` est invisible.

## Procédure

1. **Écrivez la compétence dans l'emplacement canonique**
   (`~/.agents/skills/<nom>/SKILL.md`). Suivez la compétence `competences-efficaces`.

2. **Copiez uniquement vers les emplacements qui sont de vrais dossiers**, pas vers les
   liens symboliques (`cp -r` vers un lien vers la source échoue avec « are identical ») :

   ```bash
   COMPETENCE=<nom-de-la-competence>
   for cible in ~/.hermes/skills; do
     [ -L "$cible" ] && continue          # lien symbolique : déjà couvert
     [ -d "$cible" ] || continue          # agent non installé
     rsync -a --delete "$HOME/.agents/skills/$COMPETENCE/" "$cible/$COMPETENCE/"
   done
   ```

   `rsync -a --delete` plutôt que `cp -r` : si un fichier a été supprimé de la compétence
   source, `cp -r` le laisserait en place dans la copie, ce qui produit des divergences
   silencieuses.

3. **Vérifiez que les quatre emplacements sont identiques** :

   ```bash
   for p in ~/.agents/skills ~/.claude/skills ~/.pi/agent/skills ~/.hermes/skills; do
     f="$p/$COMPETENCE/SKILL.md"
     if [ -f "$f" ]; then
       printf '%s : %s octets, somme %s\n' "$p" "$(wc -c < "$f")" "$(shasum -a 256 "$f" | cut -c1-12)"
     else
       printf '%s : ABSENT\n' "$p"
     fi
   done
   ```

   Les sommes de contrôle doivent toutes correspondre. Comparez les sommes, pas seulement
   la taille en octets : deux fichiers différents peuvent avoir la même taille.

## Pièges

- **`~/.claude/skills` est un lien symbolique, pas un dossier.** `cp -r` vers lui échoue
  avec « are identical ». Sautez la copie explicite vers Claude.
- **Idem pour `~/.pi/agent/skills`.** Ne copiez pas dedans ; il se synchronise tout seul.
  Seul `~/.hermes/skills` est une copie indépendante.
- **Si `~/.claude/skills` est un vrai dossier au lieu d'un lien**, l'utilisateur a des
  copies divergentes. **Demandez avant d'y toucher** — écraser silencieusement peut
  détruire du travail local.
- **Des compétences locales au projet existent aussi** (`./.claude/skills/`,
  `./.pi/agent/skills/` dans un dépôt) et l'emportent sur la version globale en cas de
  collision. Cette compétence ne traite que la distribution GLOBALE.
- **Certains agents figent les compétences au démarrage de session.** Une compétence
  nouvellement distribuée n'apparaîtra pas dans une session déjà en cours avant
  redémarrage. Elle fonctionne pour les sessions futures.
- **La casse des noms de fichiers compte** sur les volumes sensibles à la casse :
  `SKILL.md` doit être en majuscules.

## Quand NE PAS utiliser cette compétence

- La compétence est spécifique à un projet → placez-la dans le dépôt
  (`./.claude/skills/`, `./.pi/agent/skills/`), pas globalement.
- Vous n'éditez la compétence que d'un seul agent (flux propre à Hermes, par exemple) →
  corrigez ce fichier directement, ne propagez pas.
- Suppression globale → retirez de `~/.agents/skills/` (ce qui couvre les liens
  symboliques) et de `~/.hermes/skills/`. **Confirmez d'abord avec l'utilisateur** :
  la suppression est destructrice et irréversible.

---
name: worktree-git
description: 'Utiliser les worktrees Git pour faire tourner plusieurs agents de code en parallèle sur un même dépôt sans collision. À utiliser au démarrage d''une tâche dans un dépôt partagé, quand l''utilisateur dit « worktree », « agents en parallèle », « un worktree par tâche », ou quand les agents écrasent mutuellement leurs modifications. Couvre la création, l''amorçage complet (fichiers .env, dépendances, bases de données, ports), la fusion et le nettoyage.'
disable-model-invocation: true
---

# Worktrees Git pour agents parallèles

## Commencer ici (avant tout travail sur la tâche)

Déterminez où vous êtes :

```bash
[ "$(git rev-parse --path-format=absolute --git-dir)" = "$(git rev-parse --path-format=absolute --git-common-dir)" ] \
  && echo "copie principale" || echo "worktree"
```

- **Copie principale** → ne commencez PAS à éditer ici. Créez un worktree nommé d'après
  la tâche, amorcez-le (section « Rendre le worktree complet »), placez-vous dedans, et
  faites TOUT le travail là-bas.
- **Worktree** (votre outil vous y a déjà démarré) → poursuivez la tâche.

## Ce qu'est un worktree

Un dépôt, plusieurs dossiers. `git worktree add` crée une copie de travail supplémentaire
du même dépôt dans un répertoire séparé, sur sa propre branche. Tous les worktrees
partagent un unique historique `.git`, mais chacun a ses propres fichiers. Deux agents
dans deux worktrees ne **peuvent physiquement pas** écraser le travail l'un de l'autre.

## Le modèle de travail

- **Une tâche = un worktree = une session d'agent.** Ne laissez jamais deux agents
  partager un répertoire de travail.
- **La copie principale est le point d'intégration.** Elle reste sur la branche
  principale et sert uniquement à relire, fusionner et pousser. Ce n'est pas un brouillon.
- **Rien ne fusionne automatiquement.** Un humain relit le diff de chaque worktree, puis
  le fusionne (ou le jette), puis supprime le worktree.
- **Les branches de worktree sont locales et éphémères.** Ne les poussez pas sauf demande
  explicite. Seule la branche principale est poussée.
- Fusionnez un worktree à la fois. Rebasez un worktree périmé sur la branche principale
  avant de fusionner si celle-ci a bougé.

## Créer et supprimer

```bash
git worktree add ../mondepot-tache-x          # nouveau worktree + branche « mondepot-tache-x »
git worktree add ../corrige-y -b corrige-y main   # branche explicite depuis main
git worktree list                             # voir tous les worktrees
git worktree remove ../mondepot-tache-x       # supprimer une fois fusionné ou abandonné
git worktree prune                            # nettoyer les enregistrements orphelins
```

Une branche ne peut être extraite que dans UN seul worktree à la fois (y compris `main`).

## Rendre le worktree complet

Un worktree neuf ne contient QUE les fichiers suivis. Tout ce qui est ignoré par Git est
absent. Un agent lâché dans un worktree nu échoue de façon déroutante. Répliquez donc :

1. **Fichiers d'environnement et de secrets** — copiez `.env`, `.env.local` et similaires
   depuis la copie principale. **Copiez, ne faites jamais de lien symbolique** : un agent
   éditant un `.env` lié corromprait l'original partagé.
2. **Dépendances** — lancez l'installation (`npm ci`, `pnpm install`, `uv sync`,
   `bundle install`). Ne liez jamais `node_modules` : cela casse les compilations dans
   les deux copies.
3. **Bases de données et services locaux** — décidez service par service :
   - Serveur partagé (un seul conteneur Postgres) : fixez l'identité pour que les worktrees
     ne lancent pas de doublons se battant pour le même port. Avec Docker Compose,
     définissez un `name:` de premier niveau dans le fichier compose — sinon le nom de
     projet vient du nom du dossier et chaque worktree démarre son propre conteneur.
   - État par worktree (fichiers SQLite) : copiez-le ou régénérez-le.
4. **Ports** — serveurs de développement, serveurs de test et débogueurs se lient à des
   ports fixes. Soit vous n'en lancez qu'un à la fois, soit vous rendez le port
   configurable par worktree.
5. **Fichiers générés et caches** — reconstruisez dans le worktree (`npm run build`,
   génération de code) : la sortie de compilation est ignorée par Git et ne sera pas là.
6. **Hooks Git** — `core.hooksPath` et `.git/config` sont partagés automatiquement entre
   worktrees ; vérifiez que les scripts de hook ne supposent pas le chemin de la copie
   principale.

## Automatiser l'amorçage

Codifiez cette liste pour que chaque worktree s'amorce seul. Gardez un
`scripts/setup-worktree.sh` dans le dépôt et lancez-le comme première commande de tout
nouveau worktree. Depuis un worktree, le chemin de la copie principale est :

```bash
dirname "$(git rev-parse --path-format=absolute --git-common-dir)"
```

Exemple minimal :

```bash
#!/bin/bash
set -euo pipefail
PRINCIPAL="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
for f in .env .env.local; do
  [ -f "$PRINCIPAL/$f" ] && cp "$PRINCIPAL/$f" "./$f"
done
npm ci
```

Certains outils (Cursor, par exemple) exposent un fichier de configuration exécuté à la
création du worktree ; utilisez-le s'il existe, en pointant vers ce même script — un seul
endroit à maintenir.

## Fusionner

```bash
# depuis la copie principale, après avoir relu le diff du worktree :
git merge --no-ff branche-de-tache     # ou : git merge --squash branche-de-tache
git worktree remove ../mondepot-tache-x
git branch -d branche-de-tache
```

## Pièges

- **Les fichiers ignorés par Git silencieusement absents** sont la panne numéro un.
  Amorcez toujours avant que l'agent ne démarre.
- **Disque** : chaque worktree duplique les fichiers de travail plus ses propres
  dépendances. Supprimez les worktrees fusionnés, ne les accumulez pas.
- **Les worktrees de longue durée pourrissent.** Si une tâche traîne plusieurs jours,
  rebasez sur la branche principale ou repartez de zéro.
- **Le travail non committé d'un worktree supprimé est perdu.** Committez tôt et souvent
  dans le worktree : les commits vivent dans le dépôt partagé même après suppression du
  dossier.
- **Les worktrees isolent les fichiers, pas l'état Git.** Une seule liste de remisage
  (`stash`), une seule configuration, un seul espace de références partagés.

---
name: claude-md-de-dossier
description: 'Créer un CLAUDE.md spécialisé (avec lien symbolique AGENTS.md) dans un dossier précis pour donner aux agents futurs un contexte cadré sur ce dossier. À utiliser quand l''utilisateur demande de créer un CLAUDE.md pour un dossier, d''écrire des instructions de dossier, ou d''ajouter du contexte d''agent à un répertoire.'
user-invocable: true
---

# CLAUDE.md de dossier

Générer un `CLAUDE.md` ciblé dans un dossier donné, plus un lien symbolique `AGENTS.md`
pointant dessus. Le fichier donne à tout agent futur le contexte spécifique au dossier que
le `CLAUDE.md` global ne couvre pas.

## Procédure

### Étape 1 : confirmer le dossier cible et vérifier qu'il mérite un fichier

Demandez à l'utilisateur quel dossier. Utilisez un chemin absolu.

**Ne créez un fichier que si le dossier porte un contexte nécessaire sur plusieurs
sessions** — travail actif en évolution, conventions spécifiques, décisions en cours.
Un dossier de fichiers de référence statiques n'en a **pas** besoin : les agents peuvent
les lire à la demande. En cas de doute, demandez.

### Étape 2 : lire chaque fichier du dossier, INTÉGRALEMENT

- `ls -la` d'abord, pour énumérer fichiers et sous-dossiers.
- Lisez chaque fichier markdown, chaque fichier de configuration, et les fichiers source clés.
- Pour un sous-projet volumineux : lisez le manifeste de dépendances, le point d'entrée
  principal, un module représentatif, et les documents de description du dossier.
- Ne survolez pas. Ne sautez rien. Les corrections ultérieures de l'utilisateur supposent
  que vous avez le contexte complet.

### Étape 3 : proposer une liste à puces du contenu candidat

Avant d'écrire le fichier, donnez à l'utilisateur une liste à puces groupée par section
pour qu'il réagisse d'abord. Sections candidates (sautez celles qui ne s'appliquent pas) :

- **Produit / Objet** — ce qu'est ce dossier ou ce projet, son état actuel, ses indicateurs clés.
- **Public** — pour qui c'est, le cas échéant.
- **Fichiers essentiels** — un rôle en une ligne pour chaque fichier important, y compris
  les références inter-dossiers (syntaxe d'import `@chemin/fichier.md`).
- **Contraintes (À NE PAS FAIRE)** — négations dures explicites. Le contenu au meilleur
  rendement du fichier.
- **Conventions** — vocabulaire de l'utilisateur, émojis de statut, motifs de nommage,
  ce qui se fait « habituellement ».
- **Décisions verrouillées** — points actés et datés, à ne pas remettre en cause.
- **Contexte** — historique, autorité, crédibilité qui cadrent le travail.
- **Comment travailler avec l'utilisateur** — style de collaboration sur ce dossier précis.
- **Positionnement** — si le contenu est public.
- **Enseignements principaux** — les 3 à 5 signaux les plus marquants issus de la recherche,
  s'il y a eu recherche.

### Étape 4 : itérer avec l'utilisateur

- Répondez court. L'utilisateur éditera directement dans son éditeur.
- Quand il édite le fichier, RELISEZ-LE et signalez : contradictions, fautes, règles
  manquantes, mauvaise catégorisation.
- Ne revenez pas sur ses modifications sans qu'il le demande.

### Étape 5 : écrire le fichier

- Chemin : `<dossier>/CLAUDE.md`.
- Commencez par un en-tête d'une ligne expliquant l'objet du fichier.
- **Marqueur de sous-dossier** : si un dossier parent a déjà son propre `CLAUDE.md`,
  ouvrez par `Applique d'abord le CLAUDE.md racine, puis ce fichier.`
- Utilisez des titres `##` correspondant aux sections approuvées.
- Des puces plutôt que de la prose. Des puces courtes.
- **Références inter-dossiers** : syntaxe d'import `@chemin/relatif/fichier.md`, pas une
  mention en prose.
- **Documents de référence lourds** : annotez avec un déclencheur `**Lire quand :**`
  (par exemple « Lire quand : rédaction d'un texte d'offre »). Évite de tout charger à
  chaque session.

### Étape 6 : créer le lien symbolique AGENTS.md

```bash
cd <dossier> && ln -s CLAUDE.md AGENTS.md
ls -la CLAUDE.md AGENTS.md    # vérifier
```

Un **lien symbolique**, pas une copie : c'est ce qui garde les deux fichiers synchronisés.

### Étape 7 : committer seulement sur demande

Ne mettez rien en zone de préparation et ne poussez pas sans que l'utilisateur le demande.

## Règles

- **N'inventez jamais de contenu.** Chaque puce doit remonter à quelque chose que vous
  avez lu dans le dossier ou que l'utilisateur a dit. Aucun texte générique de remplissage.
- **La brièveté gagne.** L'utilisateur coupe agressivement pour raccourcir. Commencez serré.
- **Cadré sur le dossier uniquement.** Ne dupliquez pas le `CLAUDE.md` global.
- **Pas d'arborescence de fichiers, pas de vidage de répertoire, pas de détails de pile
  technique que le code montre déjà.** Tout ce qu'un agent peut dériver d'un `ls` ou d'un
  `grep` pourrit vite et gaspille des jetons. Épinglez les décisions, les règles et le
  contexte — pas la structure.
- **Contraintes contre conventions.** Les règles dures « NE PAS » vont dans Contraintes
  (négations explicites). Les motifs « on fait habituellement X » vont dans Conventions.
  Cette séparation améliore nettement le respect des règles.
- **Pas de TOUJOURS/JAMAIS absolu sans exception explicite.** Les cas limites font ignorer
  les règles absolues. « Ne jamais committer de secrets SAUF `.env.example` » vaut mieux
  que « ne jamais committer de secrets ».
- **Ne résumez ni ne raccourcissez jamais le fichier automatiquement.** L'effondrement de
  contexte le dégrade. Faites-le croître délibérément, élaguez à la main.
- **Boucle de maintenance.** Quand l'utilisateur corrige l'agent sur un point que ce
  fichier aurait dû prévenir, ajoutez la règle immédiatement. N'attendez pas.
- **Pas d'émojis sauf si l'utilisateur en utilise** (les marqueurs de statut sont
  l'exception : ce sont déjà des conventions).
- **Signalez les manques honnêtement.** Si les modifications de l'utilisateur introduisent
  des contradictions (« vends X » dans une section et « ne vends jamais X » dans une autre),
  dites-le avant qu'il ne le demande.

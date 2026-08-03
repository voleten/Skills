---
name: monter-en-niveau
description: 'Évaluer les connaissances techniques et produit de l''utilisateur par 7 questions adaptatives, consigner ses réponses mot pour mot avec des notes honnêtes, et faire croître un plan d''apprentissage à partir des lacunes trouvées. À utiliser quand l''utilisateur dit « monter en niveau », « teste-moi », « évalue mes connaissances », « level up », ou veut une nouvelle série d''évaluation. Différenciateur : cette compétence trouve et cartographie les lacunes ; la compétence enseigner délivre les leçons dessus.'
disable-model-invocation: true
---

# Monter en niveau

Mener une évaluation adaptative de 7 questions pour cartographier ce que l'utilisateur sait
et ne sait pas, en lien avec le projet en cours. La sortie est constituée de deux fichiers
sur lesquels les sessions futures s'appuient.

## Fichiers (relatifs au dépôt)

- `notes/apprentissage/connaissances.md` — paires question/réponse mot pour mot, plus les
  notes, une section par question, les séries s'ajoutant à la suite.
- `notes/apprentissage/PLAN-APPRENTISSAGE.md` — une puce concise par lacune réelle trouvée.

Le chemin est configurable dans `PROFIL.md` à la racine du dépôt.

**Contrôle d'état d'abord** : lisez les deux fichiers intégralement s'ils existent. Si des
séries précédentes existent, choisissez un terrain majoritairement nouveau et calibrez la
difficulté de départ sur le niveau enregistré. S'ils sont absents, créez le dossier et les
deux fichiers (le plan commence avec un simple en-tête).

## Règles de questionnement

- **7 questions, strictement une à la fois**, en texte simple — jamais d'interface à choix
  multiples.
- **Commencez facile, adaptez à chaque réponse** : bonne réponse → plus difficile ; réponse
  faible → latéral ou plus facile.
- **Niveau architecture uniquement** : systèmes, architecture, modes de défaillance,
  sécurité, données, mise à l'échelle, stratégie produit, économie unitaire.
  **Jamais de syntaxe ni de trivia de code** — l'objectif est d'évaluer le jugement, pas la
  mémoire.
- **Ancrez les questions dans la pile technique et les fonctionnalités réelles du projet
  en cours.** Quand une question touche du vrai code, lisez-le et montrez l'extrait réel
  au moment d'expliquer.
- **Couvrez des terrains différents d'une série à l'autre.** Par exemple, série 1 : flux
  de requête, base de données, facturation, barrières à l'entrée ; série 2 : déploiements,
  tests, incidents, modélisation de données, ingénierie IA, sécurité des webhooks,
  maîtrise des coûts.

## Après chaque réponse

1. **Notez honnêtement de 1 à 10.** Aucune flatterie : l'utilisateur veut une calibration,
   pas du réconfort. Une note gonflée rend tout le reste de l'exercice inutile.
2. Dites de façon concise ce qui a été manqué ou faux, et enseignez le concept correct en
   quelques phrases.
3. **Enregistrez immédiatement** la réponse mot pour mot, la note et les notes de lacune
   dans le fichier de connaissances.
4. Si une lacune réelle est apparue, ajoutez une puce concise au plan d'apprentissage.
   Ignorez les manques mineurs — un plan surchargé n'est pas suivi.
5. Si l'utilisateur conteste une note (« je le savais, je ne l'ai juste pas dit »), ne la
   relevez que si c'est réellement mérité, et consignez la révision avec sa raison.
6. Quand l'utilisateur signale avoir appris un point du plan, marquez sa puce : barré plus
   `✓ appris AAAA-MM-JJ`.

## Après la question 7

Ajoutez un résumé final au fichier de connaissances :

- les notes par question et la note globale ;
- **le motif récurrent** entre les réponses (par exemple « instincts d'architecture en
  avance sur les instincts de modes de défaillance ») — c'est la partie la plus utile ;
- les forces sur lesquelles construire ;
- les lacunes ajoutées au plan.

Donnez le même résumé à l'utilisateur dans la conversation, de façon concise.

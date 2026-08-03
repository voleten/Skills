---
name: noter-une-idee
description: 'Capturer rapidement une idée de contenu dans le carnet de l''utilisateur depuis n''importe quel dépôt ou conversation. Les idées de vidéo vont dans IDEES-VIDEO.md ; les sujets plus courts, invités, questions et observations vont dans SUJETS.md. Chaque entrée porte une ligne de provenance. À utiliser sur « /noter-une-idee », « note cette idée », « idée de vidéo », « ajoute un sujet ». Différenciateur : ajoute au carnet de contenu — ce n''est ni un rappel, ni une tâche, ni un outil de notes générales.'
---

# Noter une idée

Capturer une chose vite, puis s'effacer. Deux paniers, deux fichiers (chemins configurables
dans `PROFIL.md` à la racine du dépôt) :

| Panier | Fichier | Ce qui va dedans |
|---|---|---|
| Idée de vidéo | `<racine-contenu>/IDEES-VIDEO.md` | Un concept assez large pour une vidéo entière |
| Sujet | `<racine-contenu>/SUJETS.md` | Le reste : sujets de podcast, invités, questions, observations |

## Procédure

1. **Récupérez le texte.** Tout ce qui suit la commande est l'entrée. **Gardez la
   formulation de l'utilisateur mot pour mot** — ne reformulez jamais, ne raccourcissez
   jamais, n'« améliorez » jamais. La formulation d'origine porte l'intention ; une version
   nettoyée perd exactement ce qui rendait l'idée intéressante.

2. **Routez-la.**
   - Commence par `video:` → idée de vidéo (retirez le préfixe).
   - Commence par `sujet:` → sujet (retirez le préfixe).
   - Sans préfixe → jugez : concept de vidéo complet → idée de vidéo ; pensée plus courte
     → sujet. Ne posez une question courte que si c'est réellement ambigu.

3. **Lisez le fichier cible** et trouvez le dernier numéro d'entrée. Numéro suivant =
   dernier + 1. **Ne renumérotez jamais** : les numéros existants peuvent être référencés
   ailleurs.

4. **Ajoutez en bas** (lignes de contexte indentées par une vraie tabulation sous la ligne
   numérotée) :

   ```
   NNNN. Titre de l'idée exactement comme l'utilisateur l'a dit
   	source : ~/code/un-depot, conversation « Titre », 2026-08-03
   	liens ou notes supplémentaires fournis par l'utilisateur
   ```

5. **Construisez la ligne de provenance.**
   - Dépôt : le dossier depuis lequel la compétence a été invoquée, en chemin `~/…`
     (`git rev-parse --show-toplevel` ; si ce n'est pas un dépôt, le répertoire courant).
   - Conversation : le nom de l'agent, plus le titre ou l'identifiant de session si
     l'environnement l'expose. Si inconnu, le nom de l'agent seul.
   - Date : aujourd'hui, au format AAAA-MM-JJ.

6. **Confirmez à l'utilisateur** : le texte exact de l'entrée, son numéro, et le fichier
   dans lequel elle est allée.

## Règles

- **Ajout uniquement.** Ne modifiez, ne réordonnez et ne renumérotez jamais les entrées
  existantes.
- Plusieurs idées en une invocation → une entrée numérotée pour chacune.
- **Ne committez pas et ne poussez pas** le dépôt de contenu : l'utilisateur le fait lui-même.
- Si un fichier cible est absent, recréez-le avec son en-tête d'une ligne, puis ajoutez
  l'entrée 1.
- Indentez les lignes de contexte avec un **vrai caractère de tabulation**, pour rester
  cohérent avec les fichiers existants.

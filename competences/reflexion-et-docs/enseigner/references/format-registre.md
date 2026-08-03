# Format des registres d'apprentissage

Les registres d'apprentissage vivent dans `./registres-apprentissage/` et utilisent une
numérotation séquentielle : `0001-slug.md`, `0002-slug.md`, etc. Créez le dossier
paresseusement — seulement au moment d'écrire le premier registre.

Ils sont l'équivalent pédagogique des ADR : ils capturent les leçons non évidentes, les
constats clés et les connaissances préalables déclarées, qui orienteront les sessions
futures. Ils servent à calculer la zone proximale de développement.

## Modèle

```md
# {Titre court de ce qui a été appris ou établi}

{1 à 3 phrases : ce qui a été appris (ou quelle connaissance préalable a été établie),
et pourquoi cela compte pour les sessions futures.}
```

C'est tout le format. Un registre d'apprentissage peut tenir en un seul paragraphe. La
valeur est de consigner **que** ceci est désormais acquis et **pourquoi** cela change ce
qu'il faut enseigner ensuite — pas de remplir des sections.

## Sections optionnelles

À n'inclure que lorsqu'elles apportent une valeur réelle. La plupart des registres n'en
ont pas besoin.

- **Statut** en frontmatter (`actif | remplacé par RA-NNNN`) — utile quand une
  compréhension antérieure s'avère fausse et est remplacée.
- **Preuve** — comment l'utilisateur a démontré sa compréhension (une question à laquelle
  il a répondu, un exercice réussi, une expérience antérieure citée). Utile si l'affirmation
  risque d'être réexaminée.
- **Implications** — ce que cela débloque ou exclut pour les sessions futures. À consigner
  quand ce n'est pas évident.

## Numérotation

Parcourez `./registres-apprentissage/` pour trouver le numéro le plus élevé et
incrémentez-le de un.

## Quand écrire un registre

Écrivez-en un dès que l'une de ces conditions est vraie :

1. **L'utilisateur a démontré une compréhension réelle d'un point non trivial** — pas une
   simple exposition, mais la preuve qu'il sait utiliser le concept correctement. Cela
   fixe un nouveau plancher pour ce qu'il faut enseigner ensuite.
2. **L'utilisateur a déclaré une connaissance préalable** — « je sais déjà X ».
   Consignez-le pour que les sessions futures ne le réenseignent pas. Consignez aussi la
   **profondeur** revendiquée.
3. **Une idée fausse a été corrigée** — l'utilisateur croyait quelque chose de faux et
   comprend maintenant pourquoi. Ces registres ont une forte valeur : ils prédisent les
   obstacles futurs sur les sujets voisins.
4. **La mission a évolué en réponse à l'apprentissage** — l'utilisateur a découvert qu'il
   tenait à autre chose que ce qu'il pensait. Faites un lien croisé vers `MISSION.md` et
   mettez-le à jour.

### Ce qui ne qualifie **pas**

- Du matériel simplement couvert. **La couverture n'est pas l'apprentissage.** Attendez
  la preuve.
- Ce qui est déjà capturé de façon concise dans `GLOSSAIRE.md` comme définition de terme.
  Ne dupliquez pas.
- Des journaux d'activité session par session. Les registres d'apprentissage ne sont pas
  un journal de bord : ce sont des constats de niveau décision.

## Remplacement

Quand un registre plus récent contredit un plus ancien (la compréhension de l'utilisateur
s'est approfondie ou corrigée), marquez l'ancien `Statut : remplacé par RA-NNNN` plutôt que
de le supprimer. **L'histoire de l'évolution de la compréhension est elle-même un signal
utile** : elle montre quels concepts ont demandé plusieurs passes.

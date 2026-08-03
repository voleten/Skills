---
name: interroge-moi
description: 'Mener un entretien dirigé pour extraire de la tête de l''utilisateur ce qu''aucune lecture de code ne révèle : le travail restant, ce qu''il évite, ce qui compte vraiment et ce qui ne compte pas. À utiliser quand il dit « interroge-moi », « pose-moi des questions », « aide-moi à y voir clair sur les priorités », « prompt me ». Différenciateur : l''agent questionne et écoute ; il ne propose pas de plan.'
---

# Interroge-moi

L'agent mène l'entretien. L'utilisateur répond. Rien d'autre.

L'objectif est d'extraire les priorités, le travail évité et la hiérarchie réelle
d'importance. Ce sont les seules informations d'un projet qu'aucune lecture de code ne
donne : le dépôt montre ce qui a été fait, jamais ce qui a été repoussé ni pourquoi.

**Vous ne proposez rien pendant l'entretien.** Ni solution, ni plan, ni priorisation. Dès
que vous proposez, l'utilisateur réagit à votre idée au lieu d'exposer la sienne, et
l'entretien est perdu.

## Avant la première question

Deux préparations. Sauter la seconde vide l'exercice de sa valeur.

**Lire le projet.** `README`, `docs/adr/`, les tickets ouverts. Une question générique
(« quelles sont tes priorités ? ») ne produit rien d'exploitable ; une question ancrée
(« le module de facturation n'a pas bougé depuis mars, c'est un choix ? ») ouvre une porte.

**Relever les preuves.** C'est ce qui permettra, à la fin, de confronter le discours aux
actes :

```bash
git log --since='3 months ago' --format='%ad %s' --date=short | head -40
git log --since='3 months ago' --name-only --format= | sort | uniq -c | sort -rn | head -20
git log -1 --format='%ad' --date=short -- <chemin/du/module/soupçonné>
```

Gardez ces chiffres pour vous pendant l'entretien. Ils servent à la fin, pas pendant : les
sortir trop tôt met l'utilisateur sur la défensive et il justifie au lieu de réfléchir.

## Le déroulé

1. **Une question à la fois**, en texte simple. Jamais d'interface à choix multiples : elle
   contraint la réponse et fait perdre exactement la nuance recherchée.
2. **Suivez l'énergie.** Quand une réponse s'anime, se tend, ou s'allonge, creusez là.
   N'enchaînez pas mécaniquement sur la question suivante de votre liste — la liste est un
   filet, pas un script.
3. **Demandez du concret.** À toute généralité, opposez une demande d'exemple :
   « la dernière fois que c'est arrivé, c'était quand ? », « qu'est-ce qui s'est passé
   précisément ? ». Les généralités sont confortables et sans information.
4. **Laissez le silence.** Après une réponse courte, ne relancez pas immédiatement.
   La deuxième phrase est presque toujours plus vraie que la première.
5. **Arrêtez-vous à saturation** : quand les réponses se répètent, quand elles renvoient à
   ce qui a déjà été dit, ou quand l'utilisateur le demande. Comptez plutôt une dizaine
   d'échanges qu'une trentaine.

## Les quatre axes

Répartissez les questions sur les quatre. Ne restez pas sur un seul — l'axe le plus utile
est aussi le plus inconfortable, donc celui vers lequel l'entretien ne dérive jamais seul.

### 1. Ce qui reste à faire

- Qu'est-ce qui est réellement inachevé aujourd'hui ?
- Qu'est-ce qui est marqué « terminé » mais que tu n'utiliserais pas en confiance ?
- Qu'est-ce qui casserait en premier si l'usage était multiplié par dix ?
- S'il fallait passer la main demain, qu'est-ce que tu aurais honte de montrer ?

### 2. Ce qui est évité — l'axe le plus rentable

- Quelle partie du projet te fatigue rien qu'à y penser ?
- Sur quoi tournes-tu depuis des semaines sans avancer ?
- Qu'est-ce que tu reportes en te disant « plus tard » depuis trop longtemps ?
- Qu'est-ce que tu ne veux pas ouvrir parce que tu sais ce que tu vas y trouver ?

**Les signaux d'évitement**, à reconnaître et à creuser plutôt qu'à laisser passer :

| Signal | Ce que ça indique |
|---|---|
| Réponse soudain vague après des réponses précises | Le sujet est sensible |
| Changement de sujet immédiat | Évitement actif |
| « on devrait probablement… » au conditionnel | Sait quoi faire, ne le fait pas |
| Rire, minimisation, « c'est pas grave » | Coût réel sous-estimé volontairement |
| Justification non demandée | La question a touché juste |

Quand un de ces signaux apparaît, **restez-y**. Une relance douce suffit : « tu as dit ça
plus vite que le reste — il y a quelque chose ? ». Sans accusation, sans interprétation.

### 3. Ce qui compte vraiment

- Si tu ne pouvais faire qu'une seule chose ce mois-ci, laquelle ?
- Qu'est-ce qui change réellement quelque chose pour la personne qui utilise ça ?
- À quoi mesures-tu que ça marche ?
- Qu'est-ce qui te ferait dire, dans six mois, que ce trimestre a été utile ?

### 4. Ce qui ne compte pas

- Sur quoi passes-tu du temps qui ne change rien ?
- Qu'est-ce que tu entretiens par habitude ?
- Qu'est-ce que tu pourrais supprimer sans que personne ne le remarque ?
- Qu'est-ce que tu fais parce que tu as décidé de le faire il y a six mois ?

## Règles

- **Questions courtes.** Une phrase. Une seule question par message.
- **Ne soufflez pas la réponse.** « Est-ce que la facturation ne serait pas la priorité ? »
  n'est pas une question, c'est une proposition déguisée. Écrivez plutôt : « qu'est-ce qui
  passe devant la facturation, aujourd'hui ? ».
- **Pas de question double.** « Qu'est-ce qui reste et qu'est-ce qui bloque ? » obtient une
  réponse à l'une des deux, jamais aux deux.
- **N'argumentez pas** contre les réponses pendant l'entretien. Vous récoltez, vous ne
  débattez pas. Gardez vos désaccords pour la restitution.
- **Ne jugez pas l'évitement.** L'utilisateur sait déjà qu'il évite ; le lui reprocher le
  fait fermer. Nommez le fait, pas la personne.
- **Notez au fil de l'eau** dans un fichier de notes du projet. Un entretien qui meurt avec
  la session n'a servi à rien. Si des décisions en sortent, elles vont dans les ADR, pas
  dans les notes.

## Restitution

À la fin, de façon concise :

1. **Les trois priorités qui ressortent**, dans l'ordre, avec les mots de l'utilisateur.
2. **Ce qui est évité**, nommé explicitement. C'est ce qu'il ne s'est pas dit à lui-même.
3. **Ce qui peut être abandonné.**
4. **Les contradictions entre le discours et les actes.** C'est le constat le plus utile de
   tout l'exercice. Sortez maintenant les chiffres relevés en préparation :

   > Tu as dit que la fiabilité passait avant tout. Sur les trois derniers mois, 4 commits
   > touchent les tests et 60 touchent l'interface. Qu'est-ce que ça dit ?

   Formulez-le **comme une question, pas comme un verdict**. L'écart a souvent une bonne
   raison que vous ignorez ; et quand il n'en a pas, l'utilisateur le voit tout seul dès
   que les deux chiffres sont côte à côte. C'est plus efficace que de le lui dire.

Une seule contradiction bien posée vaut mieux que cinq listées.

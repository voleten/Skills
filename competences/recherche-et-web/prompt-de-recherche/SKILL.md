---
name: prompt-de-recherche
description: 'Rédiger une invite de recherche approfondie d''un seul paragraphe à confier à une personne chargée de la recherche (ou à une IA de recherche). À utiliser quand l''utilisateur veut un brief de recherche, une « invite de deep research », un paragraphe de mission, ou demande « que doit chercher notre chargé de recherche ». Produit UN paragraphe serré avec tout le contexte, des sous-questions numérotées, et un format de sortie par constat.'
---

# Invite de recherche

Objectif : transformer un besoin de recherche flou en UN paragraphe autonome sur lequel
une personne sans aucune connaissance préalable du projet peut agir sans aucun aller-retour.

## Règles

- **Un seul paragraphe.** Pas de titres, pas de liste à puces dans le livrable.
- **Prescrivez le travail, pas le sujet.** Donnez des prises de recherche (période,
  classement, type de source, logique de décision) — pas juste un thème.
- **Supposez zéro connaissance préalable.** Écrivez pour quelqu'un qui n'a jamais entendu
  parler du projet. Ouvrez en expliquant, en français simple, ce qu'est le projet ou le
  produit, pourquoi il existe, et quelle est la situation actuelle.
- **Menez avec l'objectif et la décision.** Juste après cet exposé, énoncez la question
  unique à laquelle la recherche doit répondre et la décision qu'elle éclaire.
- **Intégrez tout le contexte.** Noms, dates, produit, faits déjà connus, contraintes.
  La personne ne doit rien avoir à demander ni à deviner.
- **Numérotez les sous-questions en ligne** (1, 2, 3…) pour rendre la couverture explicite.
  Restez entre 3 et 6. **Une mission par invite** — n'entassez pas de questions sans lien.
- **Énoncez les contraintes.** Ce qu'il faut inclure, ce qu'il faut éviter (par exemple
  « uniquement les concurrents européens », « pas de discours marketing »).
- **Hiérarchie des sources.** Privilégiez les sources primaires (documentation officielle,
  dépôts, articles scientifiques, dépôts réglementaires, journaux de version). Les forums
  et réseaux sociaux sont un signal faible, jamais une preuve factuelle.
- **Gestion des contradictions.** Si les sources divergent, séparez faits confirmés,
  inférences et incertitudes non résolues. N'inventez pas un faux consensus. Signalez les
  affirmations à faible confiance pour vérification.
- **Barre d'achèvement (définir le « terminé »).** Ne pas s'arrêter à la première réponse
  plausible. Corroborer chaque affirmation clé par plusieurs sources primaires
  indépendantes quand elles existent ; là où les sources sont rares, le dire explicitement
  au lieu de remplir. Continuer jusqu'à ce que chaque sous-question numérotée atteigne
  cette barre.
- **Tour de comblement avant de conclure.** Exiger une passe d'autocritique finale : lister
  les manques, les contradictions et les affirmations à source unique, puis lancer un
  nouveau tour de recherche pour les combler — à répéter jusqu'à ce que ce soit propre.
- **Contraignez fortement la sortie, faiblement la méthode.** Soyez strict sur le livrable ;
  laissez le chemin de recherche flexible pour permettre l'exploration.
- **Exigez un format fixe par constat** : lien de la source + affirmation précise + une
  ligne « pourquoi ça compte ».
- Faits vérifiables et citables uniquement. Pas d'opinions.
- **Dernière phrase** : demander de tout consigner dans un unique fichier markdown détaillé.

## Procédure

1. Récupérez le contexte dans les fichiers du projet et la conversation (dates, noms,
   faits connus, public, usage final), et rédigez un exposé de 1 à 2 phrases en français
   simple sur ce qu'est le projet et pourquoi il existe, pour un lecteur qui ne sait rien.
2. Identifiez LA question unique à laquelle la recherche répond.
3. Rédigez 3 à 6 sous-questions numérotées qui la couvrent entièrement.
4. Ajoutez les contraintes d'inclusion et d'exclusion, plus le format de sortie par constat.
5. Compressez en un paragraphe propre. Coupez le remplissage.

## Modèle

> [Pour un lecteur sans connaissance préalable : en 1 à 2 phrases simples, ce qu'est le
> projet ou le produit, pourquoi il existe, et la situation actuelle.] Recherchez [SUJET
> + faits identifiants clés] pour répondre à une question : [LA QUESTION] — en vue de
> [DÉCISION / USAGE FINAL]. Trouvez : (1) … ; (2) … ; (3) … ; (4) …. [Contraintes :
> inclure X, éviter Y.] Privilégiez les sources primaires ; traitez les forums et réseaux
> sociaux comme un signal faible ; si les sources se contredisent, séparez le fait de
> l'inférence et signalez ce qui doit être vérifié. Ne vous arrêtez pas à la première
> réponse plausible : corroborez chaque affirmation clé par plusieurs sources primaires
> indépendantes quand elles existent (et dites-le explicitement quand elles n'existent
> pas), en continuant jusqu'à ce que chaque question numérotée atteigne cette barre. Avant
> de conclure, faites une passe d'autocritique : listez les manques, les contradictions et
> les affirmations à source unique, puis lancez un nouveau tour de recherche pour les
> combler, en répétant jusqu'à ce que ce soit propre. Pour chaque point, donnez le lien de
> la source, l'affirmation précise, et une ligne « pourquoi ça compte ». Pas de discours
> marketing — uniquement des faits vérifiables et citables. Consignez tout dans un unique
> fichier markdown détaillé.

## Exécuter l'invite

Pour lancer l'invite finie avec une IA de recherche, exécutez-la via
`POST /v1/research/deep` — suivez la compétence `recherche-approfondie`.

# Format de MISSION.md

`MISSION.md` vit à la racine de l'espace de travail. Il capture **la raison** pour laquelle
l'utilisateur apprend ce sujet. Chaque décision d'enseignement — quoi enseigner ensuite,
quelles ressources faire remonter, quels exercices concevoir — doit pouvoir se rattacher à
ce document.

## Modèle

```md
# Mission : {Sujet}

## Pourquoi
{1 à 3 phrases. L'objectif concret et réel que l'utilisateur poursuit. Qu'est-ce qui change
dans sa vie ou son travail quand il maîtrise cette compétence ? Évitez les formulations
abstraites du type « comprendre X » : poussez vers le résultat sous-jacent.}

## À quoi ressemble la réussite
- {Une chose précise et observable que l'utilisateur saura faire}
- {Une autre chose précise}
- {…}

## Contraintes
- {Temps, budget, engagements existants, préférences d'apprentissage — tout ce qui borne
  l'approche}

## Hors périmètre
- {Sujets voisins que l'utilisateur ne veut explicitement pas poursuivre maintenant —
  protège la zone proximale de développement}
```

## Règles

- **Une mission par espace de travail.** Si l'utilisateur veut apprendre deux choses sans
  rapport, ce sont deux espaces de travail.
- **Concret plutôt qu'abstrait.** « Courir un semi-marathon en octobre » vaut mieux que
  « me remettre en forme ». « Livrer un outil en ligne de commande à mon équipe » vaut
  mieux que « apprendre Rust ».
- **Poussez contre le flou.** Si l'utilisateur ne sait pas formuler le pourquoi,
  interrogez-le avant d'écrire quoi que ce soit. **Une mauvaise mission est pire que pas
  de mission** : elle oriente activement l'enseignement dans la mauvaise direction, et
  personne ne s'en aperçoit avant plusieurs sessions.
- **Révisez quand la réalité change.** Les missions évoluent. Quand l'objectif de
  l'utilisateur bouge, mettez ce fichier à jour — ne laissez pas une mission périmée
  piloter les sessions futures.
- **Gardez-le court.** Si `MISSION.md` dépasse un écran, il a cessé d'être une boussole et
  est devenu un plan.

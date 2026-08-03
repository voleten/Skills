---
name: revue-par-modele
description: 'Lancer un sous-agent d''un modèle donné pour une revue de code approfondie et neutre, façon développeur senior relisant un junior, puis restituer son rapport mot pour mot. Se déclenche sur « /revue », « fais relire le code », « revue par GPT », « revue par Fable », « second avis sur ce code », « code review by another model ». Remplace les compétences séparées fable-review et gpt-review : le modèle relecteur est un paramètre, pas une compétence distincte.'
---

# Revue de code par un modèle tiers

Une seule compétence, quel que soit le relecteur. Le modèle est un **paramètre** :
inutile de dupliquer cette procédure par fournisseur.

## Choisir le relecteur

1. Si l'utilisateur nomme un modèle (« fais relire par GPT », « revue Fable »), utilisez-le.
2. Sinon, demandez-lui en une ligne, ou prenez le modèle de raisonnement le plus capable
   disponible dans l'environnement courant.
3. **Le relecteur doit être un modèle différent de vous.** Une auto-revue par le même
   modèle reproduit les mêmes angles morts — c'est précisément ce que cette compétence
   sert à éviter.

Ne codez pas d'identifiant de modèle en dur ici : ils changent trop vite pour qu'une
compétence les fige sans devenir fausse.

## Rédiger le prompt du sous-agent

C'est la partie qui détermine la qualité de la revue. Trois règles.

**Neutralité.** Fournissez le contexte nécessaire, mais ne poussez vers aucune solution.
N'écrivez pas « vérifie que la mise en cache est correcte » si vous soupçonnez un bug de
cache : vous obtiendriez une confirmation de votre propre hypothèse, pas une revue.

**Portée large, pas de checklist.** Dites *quoi* relire (les fichiers, la branche, le
diff), pas *quoi chercher*. Laissez le relecteur trouver ses propres défauts.

**Exigence explicite.** Demandez-lui de travailler en profondeur et de faire remonter tout
problème critique ou sérieux.

Squelette de prompt :

```
Relis [portée : diff / fichiers / branche] comme un développeur senior relisant le
travail d'un junior. Contexte : [ce que fait le code, ce qui a changé, comment le lancer].

Travaille en profondeur. Cherche les bugs de correction, les conditions de course, les
cas limites non traités, les défauts de sécurité, les fuites de ressources et les pièges
de maintenance. Ne te limite pas à une liste : trouve ce qui est réellement là.

Rends un rapport concis, en français simple, qui répond d'abord à une question :
ce code est-il sûr à fusionner en production, oui ou non ? Puis liste les problèmes
critiques ou sérieux trouvés, et pour chacun, comment le corriger. Cite fichier et ligne.
Si tu ne trouves rien de sérieux, dis-le clairement plutôt que d'inventer des remarques
mineures pour remplir.
```

## Restituer le résultat

Affichez la réponse du sous-agent **en intégralité et mot pour mot**. Ne la réécrivez pas,
ne la résumez pas, ne la corrigez pas, n'en retirez pas les points avec lesquels vous êtes
en désaccord. L'utilisateur demande un avis extérieur : filtrer cet avis vide la
compétence de son sens.

Si vous êtes en désaccord avec un point de la revue, ajoutez votre objection **après** le
rapport intégral, clairement signalée comme votre commentaire.

## Après la revue

Un rapport de revue n'est pas une vérité établie. Avant d'agir sur une remarque, vérifiez-la
dans le code : les relecteurs externes n'ont pas vu la conversation et se trompent
régulièrement sur l'intention. Corrigez ce qui est réellement un défaut, expliquez le reste.

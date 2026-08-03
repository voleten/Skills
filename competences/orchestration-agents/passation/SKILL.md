---
name: passation
description: 'Compacter la conversation en cours en un unique message de passation détaillé — tout ce qui s''est passé, pourquoi, et ce qu''il reste — produit dans un bloc de code copiable vers une session d''agent neuve. À utiliser en approche de la limite de contexte, au changement de sujet, en fin de session de travail, ou pour découper une tâche entre plusieurs contextes frais. Se déclenche sur « passation », « handoff », « résume pour une nouvelle session ».'
disable-model-invocation: true
---

# Passation de contexte

Rédigez une passation complète permettant à un agent neuf — sans aucune mémoire de cette
session — de poursuivre le travail sans reposer de questions, sans redécouvrir, et sans
répéter les erreurs déjà commises.

Produisez la passation entière dans **un seul bloc de code délimité** afin que
l'utilisateur puisse la copier en un clic. Enregistrez aussi une copie dans un fichier.

## Principes

1. **De l'état, pas des instructions.** Décrivez ce qui *est vrai*, pas ce que l'agent
   suivant *devrait faire*. Écrivez « Le point d'entrée d'authentification est implémenté ;
   la déconnexion n'est pas commencée » — jamais « Implémente la déconnexion ensuite ».
   C'est l'agent neuf qui décide des actions ; vous lui fournissez le sol.
2. **Référencer, pas dupliquer.** Ne recopiez pas ce qui est déjà capturé ailleurs
   (spécifications, plans, ADR, tickets, commits, diffs). Pointez vers ces artefacts par
   chemin ou URL. Une passation qui réincorpore tout devient volumineuse et périmée.
3. **Capturer le « pourquoi ».** Les décisions et les approches rejetées sont l'information
   la plus précieuse et la moins récupérable. Le code montre le *quoi* ; vous seul vous
   souvenez du *pourquoi* et de ce qui a échoué.
4. **Ne rien faire croire aveuglément.** Présentez toutes les affirmations comme du contexte
   à vérifier contre le code réel, pas comme des faits à accepter.
5. **Expurger les secrets.** Retirez clés d'API, jetons, mots de passe et données
   personnelles. Indiquez où vivent les identifiants (« dans `.env.local`, non committé »)
   — jamais leur valeur.
6. **Être impitoyable.** Chaque ligne doit apporter quelque chose que l'agent suivant ne
   peut pas obtenir trivialement en lisant le code ou la configuration du projet.

## Procédure

1. S'il existe un fichier de configuration projet (`CLAUDE.md`, `AGENTS.md` ou équivalent),
   lisez-le d'abord. Ne répétez **rien** de ce qui s'y trouve : la passation est
   spécifique à la session.
2. Si une passation antérieure existe déjà, lisez-la et mettez-la à jour plutôt que de
   repartir de zéro.
3. Si l'utilisateur a passé des arguments, traitez-les comme l'axe de la prochaine session
   et orientez la passation vers cet objectif.
4. Remplissez chaque section du modèle. N'omettez une section que si elle est réellement
   vide — marquez-la alors `Aucun`.
5. Sortez le modèle rempli dans un unique bloc de code.
6. Enregistrez le même contenu dans un fichier et communiquez le chemin absolu.

## Format de sortie

Sortez exactement ceci, dans un seul bloc de code délimité :

```
# PASSATION : <titre court du travail>
Généré le : <horodatage> · Axe de la session : <une ligne>

## 1. Objectif
<Ce que l'on cherche fondamentalement à accomplir. 1 à 3 phrases. L'étoile polaire,
pour que l'agent suivant ne perde jamais le fil.>

## 2. Pourquoi c'est important / Contexte
<La motivation et les contraintes qui guident ce travail. Pourquoi maintenant, pour qui,
quelles exigences dures. Sautez ce qui est déjà dans la configuration du projet.>

## 3. État actuel
<Statut factuel. Ce qui est FAIT, PARTIEL, PAS COMMENCÉ.
Formulé comme un état, pas comme des actions :
- FAIT : flux de connexion OAuth (fournisseur Google), tests au vert en local
- PARTIEL : persistance de session — le magasin est branché, la logique de
  rafraîchissement manque
- PAS COMMENCÉ : point d'entrée de déconnexion>

## 4. Décisions clés (et pourquoi)
<Les choix faits et leur raisonnement. Section à plus forte valeur.
- Choix de passport.js plutôt qu'un OAuth maison — plus de support communautaire,
  surface d'attaque réduite
- Jetons stockés dans des cookies httpOnly, pas dans localStorage — atténuation XSS>

## 5. Pièges et impasses
<Approches déjà tentées qui ont ÉCHOUÉ, et ce que l'agent suivant sera tenté de faire
de travers. Évite de repayer des erreurs coûteuses.
- Tentative de simulacre de base de données dans les tests d'intégration — instable,
  abandonné au profit d'un conteneur de test
- NE PAS passer le SDK en v3 — casse l'API de flux dont on dépend>

## 6. Fichiers et points d'entrée
<Les fichiers qui comptent, avec plages de lignes et CE QUI s'y trouve précisément —
pas seulement ce qu'est le fichier. Référencez les artefacts externes au lieu de les coller.
- src/auth/oauth.ts:40-88 — configuration du fournisseur + échange de jeton
- docs/adr/0007-auth.md — justification complète (ne pas dupliquer ici)
- PR #142 — travail de session en cours
- Ticket #150 — exigences de déconnexion>

## 7. Travail restant (état et dépendances)
<Ce qui reste, décrit comme un état et un ordonnancement — PAS comme une liste d'ordres.
- Le point d'entrée de déconnexion n'est pas encore implémenté
- La persistance de session dépend de l'existence préalable de ce point d'entrée
- Les tests de bout en bout d'authentification sont bloqués tant que les deux
  points ci-dessus ne sont pas terminés>

---
## Prompt pour l'agent neuf
<Un prompt court, prêt à coller, donnant le contexte de fond. Employez des phrases
déclaratives (« X est terminé », « Y n'a pas été commencé »), jamais d'impératifs.
Terminez exactement par :>

Avant de répondre, lis chaque fichier listé sous « Fichiers et points d'entrée » ci-dessus.
Ne résume pas, ne paraphrase pas, et n'affirme pas que tu as déjà le contexte — lis
réellement chaque fichier. Traite chaque affirmation de cette passation comme du contexte
à vérifier contre le code, pas comme un fait à croire sur parole. Puis attends mes
instructions avant toute action.
```

## Fichier de sortie

Enregistrez la passation hors de l'arbre de travail pour ne pas polluer le dépôt :

- Préféré : le répertoire temporaire du système, par exemple
  `$TMPDIR/passation-<8-caracteres-aleatoires>.md`.
- Si l'utilisateur préfère une trace dans le dépôt, enregistrez plutôt `PASSATION.md`
  à la racine du projet.

Après enregistrement, communiquez le chemin absolu. L'utilisateur peut alors démarrer une
session neuve avec simplement :

```
Lis le fichier <chemin-absolu> pour prendre le contexte, puis attends mes instructions.
```

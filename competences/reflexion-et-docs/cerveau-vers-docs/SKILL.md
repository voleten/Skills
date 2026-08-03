---
name: cerveau-vers-docs
description: 'À utiliser quand l''utilisateur veut extraire de sa tête la vision, les décisions et les préférences d''un projet vers une documentation claire (README + ADR) par une boucle de questions-réponses. Se déclenche sur « cerveau vers docs », « construis la documentation », « extrais la vision », « documentons ce projet ».'
---

# Cerveau vers docs

Objectif : extraire le plus possible du goût, du jugement, des connaissances, de la vision,
des préférences et des décisions de l'utilisateur vers du texte — sauvegardé en documents
markdown clairs et concis. **Le README porte la vision ; `docs/adr/` porte les décisions.**

## La boucle

1. **Lisez la documentation existante à chaque tour.** Lisez `docs/adr/` et `README.md`
   avant toute action : d'autres agents et d'autres personnes ajoutent et modifient des ADR
   en permanence. Repartir d'une version périmée produit des contradictions.

2. **Posez 5 questions différentes** en texte simple (jamais d'interface à choix multiples).
   Cinq par défaut, sauf si l'utilisateur demande un autre nombre. Faites-les **très
   variées** : un large éventail d'angles distincts, pas cinq variantes du même sujet
   (pas tout sur la pile technique, ni tout sur le produit, ni tout sur le modèle
   économique). Exception : si l'utilisateur demande un domaine précis, suivez-le.
   Il répond à celles qui lui semblent les plus utiles.

3. **Mettez à jour la documentation après CHAQUE réponse** — sans exception. C'est vous
   qui décidez si cela met à jour `README.md` ou devient un nouvel ADR, selon ce qui a du
   sens. Attendre la fin pour tout écrire garantit que la moitié se perd.

4. Répétez jusqu'à ce que l'utilisateur dise que c'est terminé.

## Règles

- Toutes les réponses pendant ce processus doivent être **TRÈS CONCISES**, toutes les
  phrases **COURTES**, et tout doit être écrit en **FRANÇAIS SIMPLE**.
- **ADR** : courts, numérotés `NNNN-slug.md`, avec Statut + Contexte + Décision +
  Conséquences.
- **README** : la vision uniquement. Les décisions vont dans les ADR.
- **Ne contestez pas le raisonnement de l'utilisateur** sauf s'il le demande, ou s'il
  commet une erreur grave. Vous êtes là pour transcrire son jugement, pas pour le remplacer.
- **N'inventez rien.** Chaque ligne écrite doit remonter à quelque chose que l'utilisateur
  a dit. Si une réponse est ambiguë, demandez plutôt que de combler le blanc.
- **Ne réécrivez pas ce que l'utilisateur a déjà écrit** sans qu'il le demande. Ajoutez,
  n'écrasez pas.

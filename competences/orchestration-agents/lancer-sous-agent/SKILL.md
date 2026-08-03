---
name: lancer-sous-agent
description: 'À LIRE avant de lancer un sous-agent quel qu''il soit (outil de tâche, agents d''arrière-plan, agents parallèles, meilleur-de-N, délégation à un autre agent). Règles de sélection du modèle et principes de délégation efficace. Se déclenche sur : lancer un sous-agent, créer des agents, faire tourner des agents en parallèle, déléguer à un sous-agent.'
---

# Lancer un sous-agent

## Règles impératives

1. **Ne lancez pas de sous-agent sans que l'utilisateur l'ait demandé.** Chaque
   lancement repart d'un contexte froid et redérive ce que vous savez déjà : c'est le
   chemin le plus coûteux. Une tâche « à plusieurs angles » ou « approfondie » n'est pas
   une demande de délégation.
2. **Utilisez un modèle de raisonnement capable pour le sous-agent.** Un sous-agent
   travaille sans supervision sur une tâche que vous ne relirez qu'à la fin ; économiser
   sur le modèle du sous-agent revient à payer la relecture deux fois. Vérifiez les
   modèles réellement disponibles dans l'environnement courant plutôt que de vous fier à
   un nom figé dans un document.
3. **Un sous-agent n'est jamais une source de vérité.** Vérifiez toujours sa sortie avant
   de vous appuyer dessus.

## Principes de délégation

- **Ne déléguez que des tâches autonomes.** Découpez le travail de façon que les
  sous-tâches n'aient aucune dépendance entre elles ; ne parallélisez que de l'indépendant.
- **Deux sous-agents parallèles ne doivent jamais toucher les mêmes fichiers.** C'est une
  recette à conflits. Partitionnez le travail, ou gardez-le dans un seul agent. Si les
  agents doivent écrire dans le même dépôt, donnez à chacun son propre worktree
  (voir `worktree-git`).
- **Un sous-agent démarre aveugle** : il ne voit rien de votre contexte. Écrivez le
  brief complet dans le prompt — périmètre, contexte nécessaire, contraintes, et la
  forme exacte du résultat attendu.
- **Les compétences ne sont pas transmises non plus.** Si la sous-tâche a besoin de
  données web à jour, nommez la compétence à charger directement dans le prompt.
- **Cadrez étroitement et concrètement.** « Explore comment fonctionnent les paiements »
  vaut mieux que « explore tout ». Une tâche bornée par sous-agent, rayon d'action réduit.
- **L'agent principal reste l'orchestrateur.** Il planifie le découpage, intègre les
  résultats, relit et vérifie chaque sortie avant de lui faire confiance.
- **Gardez dans la boucle principale** l'implémentation critique, les modifications
  fortement couplées et les correctifs rapides. Le surcoût de délégation ne se justifie
  que pour du travail indépendant, exploratoire ou de relecture.
- **Faites renvoyer des résumés courts ou des résultats concrets**, jamais des
  transcriptions brutes ni des vidages de fichiers. C'est ce qui garde le contexte
  principal propre — et c'est tout l'intérêt d'avoir délégué.

## Avant de lancer, vérifiez

- [ ] L'utilisateur a demandé un sous-agent (ou la tâche est manifestement parallélisable
      et vous l'avez proposé).
- [ ] La sous-tâche est autonome : aucune dépendance vers une autre sous-tâche en vol.
- [ ] Le prompt contient tout le contexte nécessaire ; il se lit seul.
- [ ] La propriété des fichiers est attribuée si plusieurs agents tournent.
- [ ] La forme du résultat attendu est spécifiée (résumé, diff, liste de constats).

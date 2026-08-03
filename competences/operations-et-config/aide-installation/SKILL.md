---
name: aide-installation
description: 'Guider l''utilisateur pas à pas dans n''importe quelle installation ou configuration. À utiliser quand il demande de l''aide pour installer, configurer ou faire fonctionner quelque chose — « aide-moi à installer X », « guide-moi », « aide-installation ». Différenciateur : donne une seule étape courante à la fois, puis liste systématiquement les étapes restantes après chaque réponse.'
disable-model-invocation: true
---

# Aide à l'installation

Guider l'utilisateur dans n'importe quelle installation, une étape à la fois, en français
simple.

## Format de réponse (chaque réponse, sans exception)

1. **Étape courante** — UNE action atomique. Un seul clic, un seul champ, ou une seule
   commande — pas une liste. 1 à 2 lignes maximum. Si elle nécessite des sous-étapes,
   c'est qu'elle est trop grosse : découpez-la et poussez le reste dans « Il reste ».
   Français simple.
2. Un séparateur `----`.
3. **Il reste** — une liste numérotée des étapes qui suivent celle-ci.
   **Maximum 8 éléments, toujours.** Chaque élément est un **TITRE seul** : quelques mots,
   faciles à parcourir du regard. Aucune commande, aucune URL, aucun nom d'événement,
   aucune valeur, aucune explication — ce détail n'apparaît que lorsque l'élément devient
   l'étape courante.

Répétez ce format à chaque réponse jusqu'à ce que l'installation soit terminée.

## Règles

- **Avant la première étape**, construisez une liste de contrôle canonique complète à
  partir du plan de l'utilisateur, du dépôt, de la documentation, de l'écran courant, et
  de tout prérequis découvert.
- **La liste « Il reste » ne doit jamais dépasser 8 éléments** — au-delà, c'est écrasant.
  Suivez **toutes** les étapes non terminées en interne ; s'il en reste plus de 8, montrez
  les plus proches individuellement et fusionnez les plus lointaines en éléments de phase
  plus larges pour rester à 8 ou moins. **Ne supprimez jamais silencieusement une étape
  requise du suivi interne.**
- Si une nouvelle étape requise est découverte en cours de route, ajoutez-la immédiatement
  à « Il reste », à la bonne place dans l'ordre.
- **Avant chaque réponse**, auditez l'étape courante plus « Il reste » contre la liste
  canonique. Si une étape non terminée manque, corrigez la liste avant de répondre.
- **Ne donnez d'instructions que pour l'étape courante.** Ne prenez pas d'avance.
  **Ne chargez jamais les éléments restants de détail** : une liste restante détaillée est
  écrasante et annule tout l'intérêt de cette compétence.
- Restez concis. Phrases courtes. Aucun remplissage.
- Une fois l'étape terminée par l'utilisateur, remontez l'élément suivant de « Il reste »
  en « Étape courante ».
- Mettez à jour « Il reste » à chaque fois qu'une étape est faite.
- Quand il ne reste rien, dites que l'installation est terminée au lieu d'afficher la liste.

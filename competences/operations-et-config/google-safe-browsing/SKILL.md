---
name: google-safe-browsing
description: 'Prévenir et corriger les signalements « Site dangereux » de Google Safe Browsing. À utiliser au lancement d''une application web publique, à l''achat ou au choix d''un domaine, à la création d''une page de connexion ou d''inscription, ou quand un site affiche un avertissement rouge « Site dangereux » / « Site trompeur » dans Chrome, Brave, Safari, Firefox ou Edge. Se déclenche sur « site dangereux », « site trompeur », « site bloqué », « safe browsing », « signalé comme hameçonnage », « écran rouge ».'
---

# Google Safe Browsing : prévenir et corriger

Une seule liste de blocage en amont (Google Safe Browsing) alimente Chrome, Brave, Safari,
Firefox et Edge. Un signalement là-bas bloque le site **dans tous les navigateurs à la
fois**.

C'est une **classification de la surface publique, pas un piratage**. Ne commencez pas par
déboguer le code : dans la quasi-totalité des cas, le code n'a rien à voir.

## Vérification rapide : le site est-il signalé ?

```bash
# Remplacez le domaine. Vérifiez l'apex ET le www — ils sont évalués séparément.
curl -s "https://transparencyreport.google.com/transparencyreport/api/v3/safebrowsing/status?site=exemple.com"
```

La réponse est `)]}'` suivi de
`[["sb.ssr", STATUT, bool, bool, bool, bool, bool, horodatage_ms, "site"]]` :

- `STATUT 1` avec tous les booléens à `false` = propre.
- `STATUT 2` avec au moins un `true` = signalé. Le texte de l'écran d'avertissement indique
  la catégorie : « vous inciter à révéler vos mots de passe » = trompeur / ingénierie
  sociale ; « installer des programmes dangereux » = logiciel malveillant.

Version lisible :
`https://transparencyreport.google.com/safe-browsing/search?url=exemple.com`

## Liste de prévention (tout nouveau projet web public)

1. **Aucune marque tierce dans le nom de domaine.** `youtube-x.com`, `paypal-outil.fr` =
   marque plus formulaire de connexion = signalement automatique pour hameçonnage, plus un
   risque de plainte pour contrefaçon. Utilisez des sous-domaines d'un domaine que vous
   possédez (`outil.votrenom.fr`).
2. **Les robots d'indexation ne doivent jamais atterrir sur un formulaire d'identifiants.**
   L'URL racine, pour un visiteur anonyme, doit mener à une page d'accueil neutre : aucun
   champ de saisie, propriétaire clairement identifié (« Exploité par X »), et mention
   explicite « Non affilié à [marque] » si le produit touche à une marque. La connexion
   vit derrière un lien.
3. **Search Console dès le premier jour, sur chaque domaine.** Ajoutez une propriété de
   domaine, déposez l'enregistrement TXT chez le registraire. C'est le **seul** canal où
   Google vous avertit AVANT que les utilisateurs voient un écran rouge, et la seule porte
   pour demander une révision après un signalement.
4. **URL publique = site public.** « Outil interne » ne veut rien dire pour un
   classificateur. Supprimez les formulaires d'inscription ou de liste d'attente résiduels
   sur les outils qui sont en réalité sur invitation : un domaine jeune plus un formulaire
   de collecte d'adresses ressemble à un kit de moisson.
5. **Vérifiez comme un inconnu.** `curl -sL https://le-domaine/` et contrôlez : on atterrit
   sur du contenu neutre, il n'y a pas de champ de mot de passe, aucune marque tierce dans
   le titre ni les titres de section.

## Diagnostic (site déjà signalé)

1. Lancez la vérification rapide sur l'apex **et** le www. Confirmez le signalement et la
   catégorie.
2. Récupérez le site anonymement (`curl -sL`) pour voir exactement ce que voit le robot
   d'indexation. Cherchez : noms de marque dans le domaine, le titre ou les titres de
   section ; redirection immédiate vers un formulaire d'identifiants ; formulaires publics
   de collecte d'adresses ; jeunesse du domaine (`whois`).
3. **L'historique Git est en général une fausse piste** : le déclencheur est une
   réindexation ou un signalement d'utilisateur, pas un commit récent. Ne le parcourez que
   pour écarter un script injecté ou une dépendance compromise.
4. Si des téléversements d'utilisateurs ou du contenu tiers sont hébergés sur le domaine,
   vérifiez si un fichier ou une page précise a déclenché le signalement (Search Console
   liste des URL d'exemple).

## Rétablissement

1. **Corrigez la surface publique d'abord** (liste ci-dessus) et déployez. Une demande de
   révision sur une surface inchangée est refusée, et les récidives allongent les délais.
2. Vérifiez le domaine dans Search Console (enregistrement TXT DNS chez le registraire,
   propagation en quelques minutes).
3. Search Console → Problèmes de sécurité → Demander une révision. Une ou deux phrases
   factuelles : ce qu'est le site, qui l'utilise, ce qui a été changé.
4. Délai habituel : 1 à 3 jours. Validez en relançant la vérification rapide jusqu'à
   obtenir `STATUT 1`, puis confirmez dans un navigateur.
5. **Si le domaine lui-même contient la marque d'un tiers**, traitez le signalement levé
   comme temporaire : il restera propice aux récidives. Le correctif durable est le
   déménagement vers un domaine neutre.

## Cas vécu

Un outil d'équipe interne utilisait un domaine contenant un nom de marque connu ; les
visiteurs anonymes étaient redirigés directement vers un formulaire courriel + mot de passe
aux couleurs de la marque, et une page de liste d'attente publique existait. Signalé comme
site trompeur, bloqué dans Chrome et Brave. Correctif : suppression de la page de liste
d'attente, ajout d'une page d'accueil neutre `/bienvenue` (mention du propriétaire et de la
non-affiliation), retrait de toute identité de marque sur les pages déconnectées, puis
demande de révision. **Le code n'a jamais été le problème.**

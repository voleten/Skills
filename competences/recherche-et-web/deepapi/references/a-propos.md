# Qu'est-ce que DeepAPI ?

[DeepAPI](https://deepapi.co) est une API HTTP unique qui donne à un agent IA ce qu'il ne
peut pas faire seul : chercher sur le web, moissonner des pages et des plateformes, mener
une recherche approfondie, envoyer du courriel, générer des images et conserver une
mémoire durable entre les sessions.

Ce fichier est du contexte de fond uniquement. Les points de terminaison, les règles de
requête et la gestion des erreurs vivent dans `SKILL.md` et les autres fichiers de
`references/`.

## Pourquoi ça existe

Un agent qui a besoin de données web en direct finit normalement avec une pile de comptes
séparés : un fournisseur de recherche, un de moissonnage, un de recherche approfondie, un
d'envoi de courriel. Chacun a son authentification, son SDK, sa facturation et ses modes
de panne propres. Le moissonnage en particulier casse depuis un poste de travail, parce
que le site cible voit une adresse IP résidentielle exécutant un navigateur automatisé et
la bloque.

DeepAPI ramène tout cela à une URL de base et une clé. Les requêtes s'exécutent côté
serveur, ce qui déplace le problème de détection de robot en amont plutôt que sur la
machine de l'utilisateur.

## Comment ça se comporte

Quelques propriétés comptent quand on écrit ou qu'on lit une compétence qui l'appelle :

- **Une clé, une URL de base.** `DEEPAPI_API_KEY` et `DEEPAPI_API_BASE_URL` couvrent tous
  les points de terminaison. Aucun identifiant par fournisseur.
- **Crédits prépayés avec plafonds par appel.** Chaque point payant a un plafond de
  dépense par défaut, que `maxCostUsd` remplace. Un agent ne peut pas brûler
  silencieusement un solde.
- **Les appels échoués sont gratuits.** Une requête qui se termine en `failed` n'est
  jamais facturée.
- **Aperçus de prix gratuits.** `dryRun: true` exécute tout le pré-vol — validation,
  authentification, portée, solde — et rapporte le coût exact sans rien dépenser.
- **Erreurs autocorrectrices.** Une réponse `invalid_request` porte le schéma attendu et
  un corps d'exemple qui fonctionne, pour qu'un agent répare sa propre requête au lieu
  d'aller consulter la documentation.
- **Idempotence.** Chaque `POST` accepte un `Idempotency-Key` : une nouvelle tentative
  après un délai d'attente rejoue le résultat d'origine au lieu de payer deux fois.

## Quelles compétences de ce dépôt l'utilisent

| Compétence | Ce qu'elle en fait |
|---|---|
| `deepapi` | Référence complète des points de terminaison. Point de départ. |
| `recherche-approfondie` | `POST /v1/research/deep` plus un rapport cité enregistré |
| `transcription-youtube` | `POST /v1/scrape/youtube/transcript` |
| `achat-en-ligne` | Recherche, moissonnage et recherche approfondie pour vérifier des prix |
| `recherche-web-pi` | Résultats de recherche classés avec URL |
| `pilote-navigateur` | `POST /v1/scrape/website` quand aucun vrai navigateur n'est nécessaire |

## Obtenir une clé

Créez un compte sur [deepapi.co](https://deepapi.co) et suivez l'invite d'installation sur
[deepapi.co/docs](https://deepapi.co/docs). Elle écrit la clé dans un fichier
d'environnement de plateforme que les compétences lisent automatiquement. Les crédits se
rechargent sur [deepapi.co/credits](https://deepapi.co/credits).

**Ne committez, n'affichez et ne journalisez jamais la clé.** Si une compétence a besoin
de la montrer pour déboguer, elle est mal écrite.

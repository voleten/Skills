---
name: apify
description: 'Utiliser Apify comme alternative à DeepAPI pour le moissonnage web et la recherche : acteurs préfabriqués du Store (sites, Google, Instagram, X/Twitter, YouTube, Reddit, LinkedIn, publicités Meta), via le serveur MCP officiel ou l''API REST. À utiliser quand l''utilisateur mentionne Apify, un acteur Apify, veut moissonner une plateforme sans clé DeepAPI, ou demande une alternative à DeepAPI. Différenciateur : Apify couvre le moissonnage et la recherche web, mais NI la recherche approfondie, NI le courriel, NI la génération d''images, NI la mémoire.'
---

# Apify

Plateforme de moissonnage fondée sur des **acteurs** : des programmes préfabriqués et
publiés sur un Store, exécutés côté serveur, qui écrivent leurs résultats dans un jeu de
données. Des milliers d'acteurs couvrent les plateformes courantes.

## Choisir : Apify ou DeepAPI

C'est la seule décision qui compte vraiment. Ne branchez pas Apify par défaut.

### Ce qu'Apify remplace

| Besoin | DeepAPI | Apify |
|---|---|---|
| Contenu d'un site | `/v1/scrape/website` | acteur de moissonnage de contenu de site |
| Recherche web | `/v1/search/web` | acteur de moissonnage de résultats Google |
| Instagram | `/v1/scrape/instagram/*` | acteurs Instagram |
| X / Twitter | `/v1/scrape/twitter/*` | acteurs X/Twitter |
| YouTube | `/v1/scrape/youtube/*` | acteurs YouTube |
| Reddit | `/v1/scrape/reddit/*` | acteurs Reddit |
| LinkedIn | `/v1/scrape/linkedin/*` | acteurs LinkedIn (voir l'avertissement plus bas) |
| Publicités Meta | `/v1/scrape/facebook/ads` | acteurs de bibliothèque publicitaire |

### Ce qu'Apify **ne** remplace **pas**

| Besoin | Situation |
|---|---|
| Recherche approfondie sourcée | **Aucun équivalent.** Apify moissonne, il ne raisonne pas. Gardez `/v1/research/deep` |
| Envoi et lecture de courriel | Aucun équivalent |
| Génération d'images | Aucun équivalent |
| Mémoire durable entre sessions | Aucun équivalent |
| Déploiement de page, publication sur X | Aucun équivalent |
| GitHub | **Ni l'un ni l'autre** : l'API officielle GitHub est gratuite et documentée. Utilisez-la directement |
| Extraction de PDF | Une extraction locale (bibliothèque PDF) est plus simple et gratuite |

### Sur quoi trancher

**Prenez Apify quand** : vous n'avez pas de clé DeepAPI et voulez commencer sans payer
(palier gratuit mensuel) ; la cible est une plateforme de niche pour laquelle un acteur
spécialisé existe déjà ; vous avez besoin d'options de moissonnage fines que le point de
terminaison DeepAPI n'expose pas ; ou vous voulez éviter de dépendre d'un fournisseur unique.

**Gardez DeepAPI quand** : vous avez besoin de recherche approfondie, de courriel, d'images
ou de mémoire dans le même flux ; vous voulez un plafond de dépense **par appel**
(`maxCostUsd`) et l'idempotence ; vous voulez une enveloppe de réponse uniforme sur tous
les points de terminaison. La compétence `deepapi` détaille ces garanties.

**Le vrai coût du changement** n'est pas le prix : c'est que chaque acteur Apify est un
programme distinct avec **son propre schéma d'entrée et sa propre forme de sortie**. DeepAPI
donne une enveloppe unique ; Apify donne mille contrats différents. C'est précisément ce
que le serveur MCP résout.

## Voie 1 — serveur MCP officiel (préféré pour un agent)

Le serveur MCP expose la découverte d'acteurs, leur exécution et la lecture des jeux de
données comme des outils. **L'agent n'a donc pas besoin d'apprendre le schéma d'entrée de
chaque acteur** : il le demande.

- Hébergé : `https://mcp.apify.com` (connexion par OAuth, rien à installer).
- Local : `npx @apify/actors-mcp-server`, avec `APIFY_TOKEN` dans l'environnement.

Outils exposés (noms indicatifs — énumérez-les à la connexion plutôt que de les supposer) :
recherche d'acteurs, récupération du détail d'un acteur et de son schéma d'entrée, appel
d'un acteur, inspection d'une exécution et de son journal, lecture des jeux de données et
des magasins clé-valeur, plus la recherche dans la documentation Apify.

**Flux type** : chercher un acteur → lire son schéma d'entrée → l'appeler avec une petite
limite de résultats → lire le jeu de données.

Si le serveur MCP est disponible dans l'environnement, **utilisez-le plutôt que l'API REST**.
Il supprime la principale source d'erreur (un schéma d'entrée deviné).

## Voie 2 — API REST

### Authentification

```bash
[ -n "${APIFY_TOKEN:-}" ] || { echo "APIFY_TOKEN manquant — arrêter et prévenir l'utilisateur" >&2; exit 1; }
```

Le jeton se passe en en-tête `Authorization: Bearer $APIFY_TOKEN`. Il est aussi accepté en
paramètre de requête `?token=`, mais **préférez l'en-tête** : un paramètre d'URL se retrouve
dans les journaux et les historiques de shell. N'affichez et ne journalisez jamais le jeton.

### Identifiant d'acteur : le tilde, pas la barre oblique

C'est le piège numéro un. Un acteur s'écrit `utilisateur/nom-acteur` dans le Store, mais
**`utilisateur~nom-acteur` dans l'URL de l'API**.

```
apify/website-content-crawler   →   apify~website-content-crawler
```

Utilisez le préfixe `/v2/actors/`. L'ancien `/v2/acts/` fonctionne encore mais est déprécié.

### Exécution synchrone (le chemin simple)

Lance l'acteur et renvoie directement les éléments du jeu de données, en un seul appel.

```bash
curl -sS -X POST \
  "https://api.apify.com/v2/actors/apify~website-content-crawler/run-sync-get-dataset-items" \
  -H "Authorization: Bearer $APIFY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
        "startUrls": [{ "url": "https://exemple.com" }],
        "maxCrawlPages": 5
      }'
```

- Le corps JSON **est** l'entrée de l'acteur : il n'y a pas d'enveloppe.
- La réponse est **directement le tableau des éléments**, sans champ `data` autour.
- **Limite dure de 300 secondes.** Au-delà, la requête HTTP échoue en 408 — mais
  **l'exécution continue côté serveur** et sera facturée. Ne relancez pas aveuglément après
  un 408 : vous paieriez deux fois pour le même travail. Récupérez plutôt l'exécution en
  cours (voir ci-dessous).
- Configurez un délai d'attente client suffisamment long, sinon votre client coupera avant
  le serveur.

### Exécution asynchrone (dès que le travail dépasse quelques minutes)

```bash
# 1. démarrer
RUN=$(curl -sS -X POST "https://api.apify.com/v2/actors/apify~website-content-crawler/runs" \
  -H "Authorization: Bearer $APIFY_TOKEN" -H "Content-Type: application/json" \
  -d '{"startUrls":[{"url":"https://exemple.com"}],"maxCrawlPages":200}')

ID_RUN=$(printf '%s' "$RUN"     | jq -r '.data.id')
ID_JEU=$(printf '%s' "$RUN"     | jq -r '.data.defaultDatasetId')

# 2. sonder jusqu'à un état terminal : SUCCEEDED | FAILED | ABORTED | TIMED-OUT
curl -sS "https://api.apify.com/v2/actor-runs/$ID_RUN" \
  -H "Authorization: Bearer $APIFY_TOKEN" | jq -r '.data.status'

# 3. lire les résultats
curl -sS "https://api.apify.com/v2/datasets/$ID_JEU/items?clean=true&format=json" \
  -H "Authorization: Bearer $APIFY_TOKEN" > /tmp/apify_resultats.json
```

Sondez à intervalle raisonnable (10 à 30 secondes selon la taille du travail) — pas toutes
les secondes.

## Maîtrise des dépenses — la vraie différence avec DeepAPI

**Apify n'a pas d'équivalent de `maxCostUsd` par appel.** Il n'existe aucun plafond
générique qui interrompe une exécution au dépassement d'un montant. Le contrôle se fait en
amont, et c'est à vous de le poser :

1. **Limitez les résultats dans l'entrée de l'acteur.** Presque tous exposent un champ du
   type `maxItems`, `maxResults`, `maxCrawlPages`, `resultsLimit`. **Le nom varie par
   acteur** : lisez son schéma d'entrée. C'est le levier principal.
2. **Posez `timeout` et `memoryMbytes`** en paramètres de requête sur le démarrage de
   l'exécution : ils bornent le temps de calcul consommé.
3. **Fixez une limite de dépense au niveau du compte** dans la console Apify. C'est le seul
   filet réellement dur. Faites-le avant la première exécution non surveillée.
4. **Faites toujours un essai à faible limite avant un gros passage.** Une première
   exécution avec `maxItems` à 5 valide le schéma d'entrée et la forme de la sortie pour
   quelques centimes.

Modèle tarifaire : un palier gratuit mensuel modeste, puis paiement à l'usage. Les acteurs
facturent soit à l'événement (par résultat), soit à la consommation de calcul. **Les prix
et les paliers changent régulièrement** : ne vous fiez pas à un montant lu ici ou ailleurs,
consultez la page de l'acteur et la page de tarification au moment de l'exécution.

## Trouver le bon acteur

**Ne codez pas en dur une liste d'identifiants d'acteurs.** Le Store évolue, des acteurs
sont dépréciés, remplacés, ou changent de modèle tarifaire — une liste figée devient fausse
en silence.

Pour choisir :

1. Via MCP, utilisez l'outil de recherche d'acteurs. Sinon, cherchez dans le Store Apify.
2. **Préférez les acteurs officiels `apify/*`** quand ils existent : ils sont maintenus par
   l'éditeur de la plateforme. Un acteur tiers dépend d'une personne qui peut cesser de le
   maintenir.
3. Regardez, sur la page de l'acteur : la date de dernière modification, le nombre
   d'utilisateurs, le taux de réussite affiché, les tickets ouverts, et le modèle tarifaire.
4. **Lisez le schéma d'entrée avant d'appeler.** Un champ inventé est soit ignoré
   silencieusement, soit cause d'une exécution qui tourne à vide — et facturée.

Acteurs officiels utiles comme point de départ, à vérifier au moment de l'usage :
`apify/website-content-crawler` (contenu de site, pensé pour l'ingestion par un modèle),
`apify/google-search-scraper` (résultats de recherche), `apify/instagram-scraper`.

## Aspects juridiques et déontologiques

Le moissonnage n'est pas neutre. Avant de lancer un acteur :

- **Ne moissonnez que des données publiques.** N'utilisez jamais d'acteur exigeant les
  identifiants de connexion de l'utilisateur pour une plateforme tierce.
- **LinkedIn mérite une prudence particulière** : ses conditions d'utilisation interdisent
  le moissonnage, et la plateforme poursuit activement. Signalez le risque à l'utilisateur
  avant de lancer un acteur LinkedIn ; ne le faites pas de votre propre initiative.
- **Les données personnelles moissonnées restent des données personnelles** (RGPD).
  Profils, commentaires et publications nominatives ne se recopient pas dans un dépôt
  public, un ticket, ou un service tiers sans motif légitime.
- Respectez les limites de débit. Un moissonnage agressif nuit au site cible.

Si l'utilisateur demande de moissonner derrière une authentification ou en contournant une
protection anti-robot, arrêtez-vous et expliquez pourquoi, plutôt que de chercher un acteur
qui le fait.

## Modes d'échec

| Symptôme | Cause | Que faire |
|---|---|---|
| HTTP 404 sur l'URL de l'acteur | Barre oblique au lieu du tilde dans l'identifiant | `utilisateur~nom-acteur`, pas `utilisateur/nom-acteur` |
| HTTP 401 | Jeton absent ou invalide | Vérifier `APIFY_TOKEN` ; ne pas réessayer avec le même |
| HTTP 408 sur l'appel synchrone | Dépassement des 300 s | **L'exécution continue et sera facturée.** Récupérer son identifiant dans la console ou via la liste des exécutions, puis lire le jeu de données. Ne pas relancer |
| Exécution `SUCCEEDED` mais jeu de données vide | Champ d'entrée mal nommé, ou cible sans résultat | Relire le schéma d'entrée de l'acteur. Un champ inconnu est souvent ignoré sans erreur |
| Exécution `FAILED` | Erreur interne à l'acteur | Lire le journal de l'exécution ; vérifier les tickets de l'acteur dans le Store |
| Coût bien supérieur au prévu | Aucune limite de résultats dans l'entrée | Poser `maxItems` (ou son équivalent) et une limite de dépense sur le compte |
| L'acteur a disparu ou est déprécié | Le Store évolue | En chercher un autre ; ne pas épingler un identifiant sans vérifier qu'il vit encore |

## Vérifier avant de conclure

Une extraction n'est réussie que si l'état de l'exécution est `SUCCEEDED` **et** que le jeu
de données contient des éléments dont la forme correspond à ce que l'utilisateur a demandé.
Un état `SUCCEEDED` avec zéro élément est un échec silencieux — **rapportez-le comme tel**,
ne le présentez pas comme un résultat vide légitime sans avoir vérifié l'entrée.

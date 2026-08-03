# DeepAPI — détail des points de terminaison

Référence des corps de requête. Les règles communes (en-têtes, idempotence, sondage,
autocorrection, simulation) sont dans `SKILL.md` et **ne sont pas répétées ici** — c'est
volontaire : les recopier sous chacun des cinquante points de terminaison ajouterait
environ 300 lignes identiques, chargées à chaque activation, sans rien apprendre à l'agent.

## Rappel des règles communes (une fois pour toutes)

- En-têtes : `Authorization: Bearer $DEEPAPI_API_KEY`, `Content-Type: application/json`,
  et un `Idempotency-Key` unique par `POST`.
- Effets de bord : tout point `POST /v1/scrape/*`, `/v1/research/*`, `/v1/generate/*`
  démarre une exécution et peut débiter des crédits à la fin.
- Sondage : si `status` vaut `running`, attendez `next.afterSecs` puis appelez
  `next.method` `next.path` jusqu'à `succeeded` ou `failed`.
- `waitForFinishSecs` (souvent 60) demande au serveur d'attendre la fin avant de répondre,
  ce qui évite un cycle de sondage sur les tâches courtes.
- Commencez avec de petits plafonds de résultats (`maxItems`, `maxPages`) puis augmentez :
  un `maxItems` élevé sur un premier appel est le moyen le plus rapide de gaspiller des crédits.
- `maxCostUsd` est optionnel partout où un plafond par défaut existe.

## Table des matières

- [Web et documents](#web-et-documents)
- [GitHub](#github)
- [LinkedIn](#linkedin)
- [X / Twitter](#x--twitter)
- [YouTube](#youtube)
- [Instagram](#instagram)
- [Reddit](#reddit)
- [Publicités Meta](#publicités-meta)
- [Recherche et génération](#recherche-et-génération)
- [Courriel](#courriel)
- [Mémoire](#mémoire)
- [X — publication](#x--publication)
- [Compte et diagnostic](#compte-et-diagnostic)

---

## Web et documents

### `POST /v1/scrape/website`

Parcourt des pages et renvoie un contenu propre. `contentFormat` limite la sortie à
`markdown` ou `text` ; l'omettre conserve les deux formats. Pour un parcours profond,
`maxDepth` et les motifs glob `includeUrls` / `excludeUrls` orientent les liens suivis.

```json
{ "urls": ["https://exemple.com"], "maxPages": 1,
  "contentFormat": "markdown", "waitForFinishSecs": 60 }
```

### `POST /v1/scrape/pdf`

Extrait le texte d'une URL de PDF public : texte complet, titre, auteur, nombre de pages.
Réponse synchrone, prix fixe par document. Pas de `maxCostUsd`. Les extractions échouées
sont gratuites. **Pas d'OCR** : un PDF scanné sans couche texte renvoie `pdf_not_readable`.

```json
{ "url": "https://exemple.com/document.pdf" }
```

---

## GitHub

Toutes ces routes utilisent la portée `scrape:github`.

| Route | Objet | Corps minimal |
|---|---|---|
| `/v1/scrape/github/profile` | Profil public d'utilisateur ou d'organisation | `{"usernames": ["octocat"]}` |
| `/v1/scrape/github/repo` | Métadonnées, README, langages, licence, sujets, statistiques | `{"repository": "octocat/Hello-World"}` |
| `/v1/scrape/github/issues` | Tickets publics (hors PR), filtrables | `{"repository": "…", "state": "open", "maxItems": 10}` |
| `/v1/scrape/github/pulls` | PR avec état de fusion, auteurs, statistiques de diff | `{"repository": "…", "state": "open", "maxItems": 10}` |
| `/v1/scrape/github/search` | Recherche dépôts / tickets / PR / code | `{"type": "repositories", "query": "…", "language": "TypeScript", "maxItems": 1}` |
| `/v1/scrape/github/contents` | Fichier ou listage de répertoire à une branche, un tag ou un commit | `{"repository": "…", "path": "README", "ref": "main", "maxItems": 10}` |
| `/v1/scrape/github/commits` | Historique de commits, filtres auteur / chemin / date | `{"repository": "…", "maxItems": 10}` |
| `/v1/scrape/github` | Alias rétrocompatible du profil | `{"usernames": ["octocat"]}` |

`type` pour la recherche : `repositories`, `issues`, `pullRequests`, `code`.

---

## LinkedIn

Portée `scrape:linkedin`.

| Route | Objet | Corps minimal |
|---|---|---|
| `/v1/scrape/linkedin/profile` | Détails d'un profil public | `{"profiles": ["williamhgates"]}` |
| `/v1/scrape/linkedin/company` | Page entreprise, données firmographiques | `{"companies": ["microsoft"]}` |
| `/v1/scrape/linkedin/jobs` | Offres d'emploi publiques pour une requête | `{"query": "ingénieur logiciel", "location": "France", "maxItems": 5}` |
| `/v1/scrape/linkedin/people` | Recherche de profils par rôle, lieu, entreprise, école | `{"titles": ["Fondateur"], "locations": ["Paris"], "maxItems": 5}` |
| `/v1/scrape/linkedin/posts` | Publications récentes d'un profil ou d'une page | `{"profiles": ["williamhgates"], "maxItems": 3}` |
| `/v1/scrape/linkedin` | Alias rétrocompatible du profil | `{"profiles": ["williamhgates"]}` |

`people` : plafond par défaut 1,00 $ (2,00 $ avec `includeDetails`) et **ne peut pas
descendre plus bas**.

---

## X / Twitter

Portée `scrape:twitter`.

| Route | Objet | Corps minimal |
|---|---|---|
| `/v1/scrape/twitter/search` | Publications depuis une requête ou des comptes | `{"handles": ["nasa"], "maxItems": 1, "sort": "latest"}` |
| `/v1/scrape/twitter/user` | Profils de comptes publics, listes d'abonnés en option | `{"handles": ["nasa"]}` |
| `/v1/scrape/twitter/replies` | Fil de réponses public d'une publication | `{"url": "https://x.com/…/status/…", "maxItems": 5}` |
| `/v1/scrape/twitter` | Alias rétrocompatible de la recherche | `{"handles": ["nasa"], "maxItems": 1}` |

`replies` : plafond par défaut 1,00 $ ; les valeurs sous 0,40 $ sont rejetées.

---

## YouTube

Portée `scrape:youtube`.

| Route | Objet | Corps minimal |
|---|---|---|
| `/v1/scrape/youtube/transcript` | Transcription en texte brut | `{"url": "https://www.youtube.com/watch?v=…", "includeSegments": false}` |
| `/v1/scrape/youtube/channel` | Statistiques de chaîne et vidéos récentes | `{"channels": ["mkbhd"], "maxItems": 3}` |
| `/v1/scrape/youtube/search` | Recherche de vidéos par mot-clé | `{"query": "agents ia", "sort": "views", "maxItems": 3}` |
| `/v1/scrape/youtube/shorts` | Flux Shorts d'une chaîne (format court uniquement) | `{"channels": ["mkbhd"], "maxItems": 3}` |

- `includeSegments: false` donne une sortie compacte ; l'omettre conserve les segments
  horodatés par rétrocompatibilité.
- Une vidéo sans sous-titres renvoie un résultat vide — signalez-le, ne réessayez pas.
- Pour le texte parlé d'un Short, utilisez la route `transcript` avec l'URL du Short.

---

## Instagram

Portée `scrape:instagram`.

| Route | Objet | Corps minimal |
|---|---|---|
| `/v1/scrape/instagram/profile` | Bio, nombre d'abonnés, liens, comptes similaires | `{"usernames": ["natgeo"]}` |
| `/v1/scrape/instagram/posts` | Publications et reels récents, légendes, engagement | `{"usernames": ["natgeo"], "maxItems": 2}` |
| `/v1/scrape/instagram/comments` | Commentaires publics d'une publication ou d'un reel | `{"url": "https://www.instagram.com/p/…/", "maxItems": 3}` |

Les comptes similaires renvoyés par `profile` sont le meilleur levier de découverte de
nouveaux profils.

---

## Reddit

Portée `scrape:reddit`.

| Route | Objet | Corps minimal |
|---|---|---|
| `/v1/scrape/reddit/search` | Recherche de publications, tout Reddit ou un subreddit | `{"query": "…", "sort": "top", "since": "week", "maxItems": 2}` |
| `/v1/scrape/reddit/posts` | Publications récentes d'un ou plusieurs subreddits | `{"subreddits": ["startups"], "sort": "new", "maxItems": 2}` |
| `/v1/scrape/reddit/comments` | Fil de commentaires d'une publication | `{"url": "https://www.reddit.com/r/…/comments/…/", "maxItems": 2}` |
| `/v1/scrape/reddit/user` | Profil : karma, ancienneté, vérification, abonnés | `{"usernames": ["unpseudo"]}` |

`sort` : `hot`, `new`, `top`. `since` : `hour`, `day`, `week`, `month`, `year`, `all`.

---

## Publicités Meta

### `POST /v1/scrape/facebook/ads` — portée `scrape:facebook`

Moissonne la bibliothèque publicitaire Meta — toutes les publicités actives sur Facebook,
Instagram, Messenger et Audience Network — par mot-clé ou par page annonceur. Renvoie les
créations, les textes, les URL de destination, les dates de diffusion, les plateformes et
les données de transparence européennes.

```json
{ "query": "chaussures de course", "country": "FR", "maxItems": 10 }
```

---

## Recherche et génération

### `POST /v1/search/web` — portée `search:web`

Recherche sur le web, renvoie des résultats classés avec titre, URL et extrait.
Lancez environ 3 variantes de requête pour un meilleur recouvrement.
Gardez la requête sous 500 caractères.

```json
{ "query": "version LTS stable actuelle de Node.js", "maxResults": 3 }
```

### `POST /v1/research/deep` — portée `research:deep`

Répond à une question de recherche avec des preuves web actuelles. Une seule réponse
citée par appel (environ 700 mots maximum). Limites de champs : `query` ≤ 4 000 caractères,
`context` ≤ 8 000, `instructions` ≤ 2 000. **Ne passez pas `model` ni `provider`** :
l'API rejette les contrôles de fournisseur.

```json
{ "query": "Qu'est-ce qui a changé dans les délais de conformité du règlement IA européen ?",
  "context": "Nous vendons de l'outillage d'API à des clients européens." }
```

Pour un rapport complet, voir la compétence `recherche-approfondie` : un appel par
sous-question numérotée, puis synthèse.

### `POST /v1/generate/image` — portée `generate:image`

Génère une image depuis une invite textuelle. Le plafond par défaut dépend du modèle.

```json
{ "prompt": "Illustration plate et minimale d'une fusée décollant d'un écran d'ordinateur portable" }
```

### `POST /v1/deploy` — portée `deploy:create`

Publie une page HTML à une URL publique. Prix fixe par page.

```json
{ "html": "<!doctype html><html><body><h1>Bonjour</h1></body></html>" }
```

La politique de déploiement rejette : motifs d'hameçonnage, formulaires de mot de passe,
formulaires postant vers des URL externes, raccourcisseurs d'URL.

---

## Courriel

**Par défaut, créez un brouillon** (`send: false`) et laissez l'utilisateur relire avant
l'envoi. Ne passez jamais d'identifiant de boîte de réception : utilisez `emailIdentityId`
ou omettez-le.

| Route | Méthode | Objet |
|---|---|---|
| `/v1/email/send` | POST | Créer un brouillon depuis une identité ; `send: true` pour envoyer |
| `/v1/email/messages` | GET | Lire les messages d'une identité |
| `/v1/email/drafts` | GET | Lister les brouillons en attente |
| `/v1/email/drafts/{draftId}/send` | POST | Approuver et envoyer un brouillon existant (corps `{}`) |
| `/v1/email/identities` | GET | Lister les identités et les `emailIdentityId` acceptés |
| `/v1/email/identities` | POST | Créer une identité d'expéditeur et la définir par défaut |
| `/v1/email/domains` | POST | Ajouter un domaine d'envoi et obtenir les enregistrements DNS |
| `/v1/email/domains` | GET | Lister les domaines avec statut et enregistrements DNS en attente |
| `/v1/email/domains/{domainId}/verify` | POST | Revérifier le DNS (gratuit, répétable ; corps `{}`) |
| `/v1/email/domains/{domainId}` | DELETE | Retirer un domaine et suspendre ses identités |

```json
// POST /v1/email/send
{ "to": "destinataire@exemple.com", "subject": "Bonjour",
  "text": "Message rédigé par mon agent.", "send": false }

// POST /v1/email/domains
{ "domain": "agent.exemple.com" }

// POST /v1/email/identities
{ "username": "assistant", "displayName": "Assistant", "domain": "agent.exemple.com" }
```

Les plafonds d'envoi croissent automatiquement avec un historique d'envoi propre.

---

## Mémoire

Lectures et écritures **gratuites**. Portées `memory:read` / `memory:write`.

| Route | Méthode | Objet |
|---|---|---|
| `/v1/memory` | GET | Lister les fichiers markdown : tailles, versions, usage face aux limites |
| `/v1/memory/{path}` | GET | Lire un fichier : contenu complet + version courante |
| `/v1/memory/{path}` | POST | Créer ou remplacer un fichier ; incrémente sa version |
| `/v1/memory/{path}` | DELETE | Supprimer définitivement un fichier |

```json
{ "content": "# Mémoire\n\n- L'utilisateur préfère des réponses concises.\n- Le projet X livre vendredi." }
```

**Une écriture remplace tout le fichier.** Pour éviter d'écraser le travail d'un autre
agent, lisez d'abord, fusionnez vos changements, puis écrivez en passant `ifVersion` avec
la version lue. Un `memory_version_conflict` (409) signifie qu'un autre agent a écrit
entre-temps : relisez, refusionnez, réessayez.

---

## X — publication

| Route | Méthode | Objet |
|---|---|---|
| `/v1/x/post` | POST | Publier un message ou une réponse depuis le compte X connecté |
| `/v1/x/connection` | GET | Savoir si un compte X est connecté et depuis quel identifiant |

```json
{ "text": "Jour de livraison." }
```

Vérifiez `/v1/x/connection` avant de publier. Une publication est une action publique
irréversible : **confirmez le texte avec l'utilisateur avant d'appeler cette route.**

---

## Compte et diagnostic

Toutes gratuites, toute clé.

| Route | Objet |
|---|---|
| `GET /v1/balance` | Solde de crédits de l'espace de travail |
| `GET /v1/me` | Ce que cette clé peut faire : espace, portées, limites de dépense, budget restant, limites de débit, solde |
| `GET /v1/capabilities` | Chaque capacité avec son statut réel pour cette clé : `available`, `not_configured`, `missing_scope` |
| `GET /v1/usage` | Totaux de dépense, série par jour, ventilation par capacité sur `sinceDays` jours |
| `GET /v1/requests` | Requêtes récentes créées par cette clé, plus récentes d'abord — sert à retrouver un `requestId` perdu |
| `GET /v1/requests/{requestId}` | Sonder une requête en cours (ne crée pas de débit) |
| `GET /v1/health` | Public, sans authentification — distingue une panne d'un problème de requête |

`GET /v1/capabilities` est la source faisant autorité sur ce qui est réellement
disponible : préférez-la à toute liste figée dans un document.

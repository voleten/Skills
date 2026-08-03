---
name: recherche-web-pi
description: 'RÉSERVÉ aux agents Pi — tous les autres agents ont leurs propres outils web. Comment Pi accède au web via le paquet pi-web-access : recherche, récupération d''URL, PDF, YouTube, GitHub. À utiliser dès qu''une tâche Pi a besoin d''informations à jour, de documentation, d''actualités, de prix, ou du contenu d''une URL précise.'
---

# Recherche web (agents Pi)

Le paquet `pi-web-access` est installé globalement. Sans configuration via Exa MCP (aucune
clé d'API requise), avec repli en cascade Exa → Perplexity → Gemini.

## IMPÉRATIF : toujours passer `workflow: "none"`

Chaque appel `web_search` DOIT inclure `workflow: "none"`. Cela évite l'ouverture du
sélecteur interactif dans le navigateur, que l'utilisateur ne veut pas voir apparaître.
Aucune exception — requête unique ou lot de `queries`, toujours `workflow: "none"`.

```
web_search({ queries: ["requête 1", "requête 2"], workflow: "none" })
```

## Outils

| Outil | Rôle |
|---|---|
| `web_search` | Recherche web ; renvoie des réponses synthétisées avec citations. Appelable plusieurs fois par tour. **Toujours `workflow: "none"`** |
| `code_search` | Contexte de code Exa, sans clé. À préférer à `web_search` pour les recherches de bibliothèque, d'API ou de code |
| `fetch_content` | Récupère une ou plusieurs URL → markdown ; gère PDF, YouTube, GitHub |
| `get_search_content` | Les grandes pages (plus de 30 000 caractères) sont tronquées dans la réponse mais stockées entières ; cet outil récupère le reste à la demande sans saturer le contexte |

## Spécificités de `fetch_content`

- **Les URL GitHub sont clonées, pas moissonnées** : vous obtenez de vrais fichiers et un
  chemin local à explorer avec les outils de lecture et de shell (les dépôts privés
  exigent le CLI `gh`). C'est le bon chemin pour le travail de développement.
- **PDF** → extraits automatiquement en markdown dans le dossier de téléchargements,
  lisibles par sections (texte seul, pas d'OCR).
- **YouTube / vidéo** → transcriptions brutes complètes et extraction d'images. Nécessite
  une `GEMINI_API_KEY` (pas de configuration zéro) ; l'extraction d'images exige aussi
  `ffmpeg` et `yt-dlp`.

## Routage — calez-vous sur la formulation de l'utilisateur

Ces nombres sont des **minimums stricts**. Comptez vos requêtes avant de répondre et ne
vous arrêtez pas en dessous :

| Formulation | Minimum |
|---|---|
| « recherche web » | **au moins 2** requêtes, mots-clés et angles variés, puis synthèse |
| « recherche web approfondie » | **au moins 4** requêtes, mots-clés et angles totalement différents |
| « recherche approfondie » / « deep research » | **au moins 8** requêtes, angles totalement différents, réparties sur 2 à 3 lots successifs (affinez les angles après chaque lot) |

Un appel `web_search` groupé compte chaque requête de `queries[]` dans le total. Si votre
premier lot est sous le minimum, lancez-en un autre **avant** de synthétiser.

## Résultats classés avec URL — recherche web DeepAPI

`web_search` renvoie des réponses synthétisées. Quand vous avez besoin de la **liste
classée des sources elle-même** — des URL à citer, comparer ou moissonner — utilisez
DeepAPI. C'est aussi le chemin à prendre si la cascade Exa → Perplexity → Gemini échoue.

```bash
[ -n "${DEEPAPI_API_KEY:-}" ] || . ~/.deepapi/env
curl -sS --max-time 60 "https://deepapi.co/v1/search/web" \
  -H "Authorization: Bearer $DEEPAPI_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{"query": "vos termes de recherche", "maxResults": 5}'
```

Les résultats sont dans `.output` (titre, URL, extrait par élément). Gardez la requête
sous 500 caractères. Détail complet : compétence `deepapi`.

Sans clé DeepAPI, un acteur Apify de moissonnage de résultats de recherche rend le même
service — voir la compétence `apify`.

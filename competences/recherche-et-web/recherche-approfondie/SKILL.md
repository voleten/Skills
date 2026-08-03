---
name: recherche-approfondie
description: 'Mener une recherche approfondie sourcée via DeepAPI (POST /v1/research/deep). Construit une invite de recherche rigoureuse d''un seul paragraphe, la lance, et enregistre un rapport markdown cité. À utiliser quand l''utilisateur demande une « recherche approfondie », « deep research », « une étude sourcée », « creuse ce sujet ». Différenciateur face à la compétence deepapi : c''est le flux complet (invite + exécution + fichier de rapport), pas l''accès brut au point de terminaison.'
disable-model-invocation: true
---

# Recherche approfondie (via DeepAPI)

**Pas d'alternative Apify ici.** Apify moissonne, il ne raisonne pas : il n'a aucun
équivalent de la recherche approfondie sourcée. Si l'utilisateur veut se passer de DeepAPI
pour cette tâche, le chemin est un moteur de recherche plus une synthèse par le modèle,
pas Apify.

## Clé d'API

```bash
[ -n "${DEEPAPI_API_KEY:-}" ] || . ~/.deepapi/env
CLE="$DEEPAPI_API_KEY"
BASE="${DEEPAPI_API_BASE_URL:-https://deepapi.co}"
[ -n "$CLE" ] || { echo "CLÉ MANQUANTE — arrêter et prévenir l'utilisateur" >&2; exit 1; }
```

**Ne chargez jamais `~/.zshrc`** pour récupérer la clé : cela casse certains shells
d'agents (code de sortie 126). Clé absente → arrêtez-vous et demandez à l'utilisateur.
N'affichez et ne journalisez jamais la clé.

## Étape 1 — Construire l'invite de recherche

Écrivez UN paragraphe autonome, en suivant la compétence `prompt-de-recherche` :

- Ouvrez par la question unique et la décision qu'elle éclaire.
- Intégrez tout le contexte : aucun aller-retour ne doit être nécessaire.
- Numérotez 3 à 6 sous-questions en ligne (1, 2, 3…). **Une mission par invite.**
- Énoncez les contraintes d'inclusion et d'exclusion ; privilégiez les sources primaires ;
  séparez le fait de l'inférence.

Limites de champs : `query` ≤ 4 000 caractères (le paragraphe va là), `context` optionnel
≤ 8 000, `instructions` optionnel ≤ 2 000. **Ne passez pas de champ `model` ni
`provider`** — l'API rejette les contrôles de fournisseur.

## Étape 2 — Lancer

Un appel = une réponse citée (environ 700 mots maximum, aboutit ou échoue en une minute
environ côté serveur).

```bash
IDK=$(uuidgen)   # à conserver : une nouvelle tentative doit réutiliser LA MÊME clé
jq -n --rawfile p /tmp/rech_invite.txt '{query: $p}' > /tmp/rech_corps.json
curl -sS --max-time 120 "$BASE/v1/research/deep" \
  -H "Authorization: Bearer $CLE" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $IDK" \
  -d @/tmp/rech_corps.json > /tmp/rech_resultat.json
```

Le plafond de dépense par défaut du point de terminaison s'applique si vous ne passez
rien. N'ajoutez `maxCostUsd` que si l'utilisateur veut un budget précis — et sachez que
l'API rejette les valeurs sous son minimum avec `invalid_request`.

## Étape 3 — Lire le rapport et les sources

```bash
jq -r '.status'                /tmp/rech_resultat.json   # succeeded | running | failed
jq -r '.output.answer'         /tmp/rech_resultat.json   # le rapport
jq -r '.output.sources[]?.url' /tmp/rech_resultat.json   # les URL sources
```

Enregistrez le rapport dans un fichier markdown pour l'utilisateur et listez les URL de
citation en dessous. **Ne rapportez pas les coûts** sauf si l'utilisateur le demande.

Si `output.sources` revient vide alors que la réponse contient des marqueurs de citation
`[n]`, livrez quand même le rapport **mais dites-le à l'utilisateur** : les citations ne
sont pas vérifiables en l'état.

## Sujets larges — rapports multi-appels

Un appel est plafonné à environ 700 mots. Pour un vrai rapport approfondi, lancez **un
appel par sous-question numérotée** (chacun avec sa propre `Idempotency-Key`), puis
synthétisez toutes les réponses et toutes les sources dans un unique fichier markdown.

Structure recommandée du fichier final :

```markdown
# <Question de recherche>

## Résumé
<5 à 10 lignes : la réponse à la question unique, et son degré de certitude>

## 1. <Sous-question 1>
<réponse, avec citations [n]>

## 2. <Sous-question 2>
…

## Ce qui reste incertain
<contradictions entre sources, affirmations à source unique, angles non couverts>

## Sources
1. <URL> — <ce qu'elle appuie>
```

La section « Ce qui reste incertain » n'est pas facultative : sans elle, un rapport
présente des inférences avec la même assurance que des faits vérifiés.

## Modes d'échec

| Symptôme | Que faire |
|---|---|
| HTTP 402 `insufficient_credits` | Arrêter ; faire recharger sur deepapi.co/credits ; réessayer avec **la même** `Idempotency-Key` (les rejeux ne facturent pas deux fois) |
| HTTP 429 `rate_limit_exceeded` | Attendre `Retry-After` secondes, réessayer une fois |
| `status: failed` ou HTTP 502 | Rapporter `requestId` et `error.message` à l'utilisateur. **Ne pas réessayer en boucle** |
| Réponse HTTP 200 avec `replayed: true` | Requête rejouée avec la même clé — aucune nouvelle facturation, résultat identique |

Mécanique d'enveloppe, authentification et autres points de terminaison : compétence `deepapi`.

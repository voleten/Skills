---
name: transcription-fireflies
description: 'Récupérer les transcriptions brutes de réunions depuis Fireflies.ai via son API GraphQL, avec la clé enregistrée localement. À utiliser quand l''utilisateur veut la transcription d''un appel, des notes de réunion, « ce qui s''est dit pendant l''appel », ou des données Fireflies. Différenciateur : enregistrements de réunions Fireflies uniquement — pour les vidéos YouTube, utiliser transcription-youtube.'
---

# Transcription Fireflies

Récupérer une transcription de réunion depuis Fireflies.ai en texte brut via GraphQL.
**Lecture seule** : cette compétence ne modifie ni ne supprime jamais rien côté Fireflies.

## Authentification (contrôle d'état d'abord)

La clé d'API vit dans `~/.fireflies/env` (mode 600 ; ne jamais committer ni afficher) :

```bash
[ -f ~/.fireflies/env ] && . ~/.fireflies/env
[ -n "${FIREFLIES_API_KEY:-}" ] || { echo "CLÉ MANQUANTE — arrêter et prévenir l'utilisateur" >&2; exit 1; }
```

Chaque appel est un `POST` vers `https://api.fireflies.ai/graphql` avec
`Authorization: Bearer $FIREFLIES_API_KEY` et un corps JSON `{"query": "…"}`.

## Étape 1 — Trouver l'identifiant de la réunion

```bash
curl -sS -X POST https://api.fireflies.ai/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $FIREFLIES_API_KEY" \
  -d '{"query":"{ transcripts(limit: 25) { id title date duration } }"}' \
  | jq -r '.data.transcripts[] | "\(.id) | \(.title) | \(.date)"'
```

- `date` est en **millisecondes** epoch. Conversion : macOS `date -r $((VALEUR/1000))`,
  Linux `date -d @$((VALEUR/1000))`.
- **Le filtre `transcripts(title:)` est en correspondance EXACTE** : il renvoie `[]` pour
  un nom partiel. Listez les réunions récentes et filtrez localement à la place.
- Les réunions ad hoc n'ont pas de titre propre (par exemple
  `utilisateur@… - mer. 15 juil. 2026 17:00 - Untitled`). Identifiez-les par date et
  heure, puis confirmez par le contenu ou les participants — jamais par le titre seul.
- Paginez les réunions plus anciennes avec `skip:` (`transcripts(limit: 50, skip: 25)`).

## Étape 2 — Récupérer la transcription brute

```bash
curl -sS -X POST https://api.fireflies.ai/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $FIREFLIES_API_KEY" \
  -d '{"query":"{ transcript(id: \"ID_REUNION\") { title sentences { speaker_name text } } }"}' \
  > /tmp/ff.json

# texte brut avec locuteurs (livrable habituel)
jq -r '.data.transcript.sentences[] | "\(.speaker_name) : \(.text)"' /tmp/ff.json

# texte seul
jq -r '.data.transcript.sentences[].text' /tmp/ff.json
```

**Les transcriptions font des centaines de phrases : enregistrez-les dans un fichier, ne
les déversez jamais dans la conversation.** Un vidage de transcription complète sature le
contexte pour un contenu que l'utilisateur voulait dans un fichier.

Extras disponibles sur la même requête `transcript(id:)` :
`summary { overview short_summary keywords }`, `participants`, `duration`, `meeting_link`.

## Confidentialité

Une transcription de réunion contient des propos attribués à des personnes nommées.
Traitez-la comme une donnée personnelle : ne la recopiez pas dans un ticket public, un
commit, ou un service tiers sans que l'utilisateur le demande explicitement.

## Modes d'échec

| Symptôme | Cause | Que faire |
|---|---|---|
| `sentences: null` | Enregistrement en cours de traitement, ou aucun audio capturé | Rien à récupérer ; réessayer plus tard |
| `errors[]` au lieu de `data` | Généralement un nom de champ erroné | Corriger la requête GraphQL |
| 401 / clé invalide | Clé pivotée | Demander une nouvelle clé (Fireflies : Réglages → Paramètres développeur), mettre à jour `~/.fireflies/env` |

## Vérifier avant d'annoncer que c'est fait

Une récupération n'est réussie que si le nombre de phrases est supérieur à zéro **et** que
les locuteurs ou le sujet correspondent à la réunion demandée. Vérifiez les premières
lignes — ne faites pas confiance au titre seul.

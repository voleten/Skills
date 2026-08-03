---
name: transcription-youtube
description: 'Récupérer la transcription d''une vidéo YouTube — extraction, téléchargement, sous-titres, texte parlé depuis une URL YouTube. Se déclenche sur « récupère la transcription », « transcription de cette vidéo », « télécharge les sous-titres », « que dit cette vidéo YouTube », « get the transcript ». Chemin principal : DeepAPI ; yt-dlp en repli local.'
---

# Transcription YouTube

Récupérer la transcription d'une vidéo et enregistrer un fichier `.txt` propre. Le chemin
principal est DeepAPI `POST /v1/scrape/youtube/transcript` : il s'exécute côté serveur et
évite ainsi le marquage anti-robot de l'adresse IP locale qui plombe yt-dlp.

## Emplacement d'enregistrement

- Si l'utilisateur travaille dans un vrai projet ou répertoire de travail → enregistrez-y.
- Sinon (aucun répertoire donné, ou le répertoire courant n'a pas de sens) →
  `~/Téléchargements` (ou `~/Downloads` selon la locale du système ; vérifiez lequel existe).
- **Nommez toujours le fichier `Chaine_Titre`** avec les espaces remplacés par `_`.
  Si les métadonnées sont indisponibles, repliez sur l'identifiant de la vidéo.

## Chemin principal — DeepAPI

```bash
[ -n "${DEEPAPI_API_KEY:-}" ] || . ~/.deepapi/env
CLE="$DEEPAPI_API_KEY"
BASE="${DEEPAPI_API_BASE_URL:-https://deepapi.co}"
```

**Ne chargez jamais `~/.zshrc`** pour récupérer la clé (casse le shell, code 126).

```bash
IDK=$(uuidgen)   # à conserver : une nouvelle tentative réutilise LA MÊME clé
curl -sS --max-time 120 "$BASE/v1/scrape/youtube/transcript" \
  -H "Authorization: Bearer $CLE" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $IDK" \
  -d '{"url": "URL_VIDEO", "waitForFinishSecs": 60}' \
  > /tmp/yt_transcription.json
```

- Vidéos non anglophones : ajoutez `"language": "fr"` (ou autre) au corps.
- `status: running` → attendez `next.afterSecs`, puis sondez
  `curl "$BASE$(jq -r '.next.path' /tmp/yt_transcription.json)" -H "Authorization: Bearer $CLE"`
  jusqu'à `succeeded` ou `failed`.

Extraire le texte et l'enregistrer :

```bash
jq -r '.status' /tmp/yt_transcription.json                  # succeeded | running | failed
jq -r '.output[0].text' /tmp/yt_transcription.json > "$DEST/$NOM.txt"
```

`.output[0].segments` contient aussi les segments horodatés (`startSecs`, `durationSecs`,
`text`) si l'utilisateur veut des repères temporels. Un `output` vide signifie que la
vidéo n'a **pas** de sous-titres : signalez-le, ne réessayez pas.

Pour le nom de fichier `Chaine_Titre`, récupérez les métadonnées rapidement :

```bash
yt-dlp --print "%(channel)s|%(title)s" --skip-download "URL"
```

Si cela échoue, utilisez l'identifiant de la vidéo.

## Autre chemin : Apify

Si l'utilisateur n'a pas de clé DeepAPI mais un compte Apify, des acteurs de transcription
YouTube existent dans le Store et couvrent le même besoin. Voir la compétence `apify`.
Ne l'introduisez pas de vous-même quand DeepAPI est configuré : un chemin de plus, c'est un
mode de panne de plus.

## Quand basculer sur yt-dlp

- `DEEPAPI_API_KEY` non définie et `~/.deepapi/env` absent.
- HTTP 402 `insufficient_credits` (dites d'abord à l'utilisateur de recharger sur
  deepapi.co/credits ; ne basculez que s'il n'est pas disponible).
- La requête DeepAPI a échoué deux fois.

**Signalez toujours à l'utilisateur quand vous basculez.**

## Chemin de repli — yt-dlp (local)

```bash
DEST="$(pwd)"            # ou ~/Téléchargements si le répertoire courant n'a pas de sens
META=$(yt-dlp --print "%(channel)s|%(title)s" --skip-download "URL")
NOM=$(echo "$META" | tr '| ' '__' | tr -cd '[:alnum:]_.-')
yt-dlp --skip-download --write-subs --write-auto-subs \
  --sub-langs "fr.*,en.*" --sub-format json3 \
  -o "$DEST/$NOM.%(ext)s" "URL"
```

- Repli en cascade sur le nom de chaîne : `channel` → `uploader` → `uploader_id`.
- `--skip-download` = sous-titres seuls. `--write-subs` + `--write-auto-subs` = sous-titres
  manuels d'abord, automatiques en repli.
- **Utilisez toujours `json3`, jamais VTT ou SRT** : le VTT automatique répète chaque
  ligne deux fois (sous-titres déroulants).

Aplatir json3 → texte brut :

```bash
python3 - "$DEST" <<'PY'
import json, html, re, glob, sys, pathlib
f = glob.glob(sys.argv[1] + "/*.json3")
if not f:
    sys.exit("aucun fichier json3")
data = json.load(open(f[0], encoding="utf-8"))
parts = ["".join(s.get("utf8", "") for s in e.get("segs") or []) for e in data.get("events", [])]
txt = re.sub(r"\s+", " ", html.unescape(" ".join(p.strip() for p in parts if p.strip()))).strip()
out = pathlib.Path(f[0]).with_suffix(".txt")
out.write_text(txt, encoding="utf-8")
print(out)
PY
```

### Gestion des échecs yt-dlp

- Langue inconnue : lancez d'abord `yt-dlp --list-subs "URL"`, puis fixez `--sub-langs`.
- Les versions récentes de yt-dlp peuvent exiger `deno` sur le `PATH` pour l'extraction YouTube.
- Au premier échec : lancez `yt-dlp -U` une fois, réessayez une fois, puis arrêtez.
- **429 ou « Sign in to confirm you're not a bot »** = adresse IP marquée. **ARRÊTEZ.**
  Ne réessayez pas en boucle : cela aggrave le marquage et peut le rendre durable.
- Ne basculez jamais sur le téléchargement de l'audio pour une transcription automatique
  sans que l'utilisateur le demande explicitement : c'est lent, coûteux, et souvent moins
  fidèle que les sous-titres existants.

## Sortie

Rapportez le chemin enregistré ; affichez le texte s'il est court. Ne rapportez pas les
coûts sauf si l'utilisateur le demande.

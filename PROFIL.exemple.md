# PROFIL.md — configuration locale (modèle)

Copiez ce fichier en `PROFIL.md` à la racine du dépôt et remplissez-le.
`PROFIL.md` n'est **pas** committé (voir `.gitignore`).

Raison d'être : une compétence qui code en dur un chemin personnel, une identité Git, un
nom de dépôt ou une adresse IP devient inutilisable sur une autre machine sans être éditée,
et fuite des informations privées dès qu'elle est publiée. Ici, chaque compétence qui a
besoin d'une valeur locale renvoie vers ce fichier.

---

## Dossiers d'agents

| Agent | Dossier de compétences |
|---|---|
| Codex / OpenAI Agents | `~/.agents/skills/` (canonique) |
| Claude Code | `~/.claude/skills/` (lien symbolique → `~/.agents/skills/`) |
| Pi Agent | `~/.pi/agent/skills/` (lien symbolique → `~/.agents/skills/`) |
| Hermes Agent | `~/.hermes/skills/` (copie indépendante) |

## Dépôt de compétences

- Racine Git : `~/.agents`
- Branche par défaut : `main`

## Identité Git attendue pour les poussées en production

- Nom : `VOTRE NOM`
- Courriel : `vous@exemple.com`

## Projets

| Clé | Dépôt | URL de production | Sonde de santé |
|---|---|---|---|
| `principal` | `org/projet` | `https://exemple.com` | `GET /v1/health` |

## Contenu / notes

- Idées de contenu : `~/code/contenu/`
- Notes d'apprentissage : `notes/apprentissage/`

## Serveurs

Renseignez ici vos hôtes distants, ou pointez vers un fichier chiffré.
Ne committez jamais d'adresses IP, d'identifiants ou de dates d'expiration.

| Hôte | Rôle |
|---|---|
| `exemple.hote` | (rôle) |

## Fournisseurs de données web

Renseignez ceux que vous utilisez. Les compétences `deepapi` et `apify` couvrent le même
terrain pour le moissonnage et la recherche ; DeepAPI couvre en plus la recherche
approfondie, le courriel, les images et la mémoire.

| Fournisseur | Variable | Où se procure la clé |
|---|---|---|
| DeepAPI | `DEEPAPI_API_KEY` (+ `DEEPAPI_API_BASE_URL`) | deepapi.co |
| Apify | `APIFY_TOKEN` | console.apify.com — pensez à poser une limite de dépense sur le compte |

Préférence par défaut pour le moissonnage et la recherche web : `<deepapi | apify>`

## Préfixes

- Étiquette LaunchAgent (macOS) : `com.votrenom`
- Préfixe des clés d'environnement : `MONPROJET_`

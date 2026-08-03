---
name: sous-agent-codex
description: 'Lancer Codex CLI d''OpenAI comme sous-agent (authentification par abonnement ChatGPT, sans clé d''API). À utiliser pour déléguer une tâche de code autonome depuis un autre agent — travail d''implémentation en parallèle, second avis, ou passe de vérification indépendante. Se déclenche sur « délègue à Codex », « lance Codex », « sous-agent Codex ».'
disable-model-invocation: true
---

# Codex CLI comme sous-agent

`codex exec` exécute Codex de façon non interactive : il travaille en autonomie dans un
bac à sable, diffuse sa progression sur stderr et n'écrit que son message final sur stdout.

## Quand déléguer

- Tâche de code autonome avec un critère de réussite clair (correctif, fonctionnalité,
  refactorisation, revue).
- Travail parallèle : plusieurs tâches réellement indépendantes.
- Second avis ou vérification indépendante de vos propres modifications.

Ne déléguez **pas** une tâche qui dépend d'un contexte de conversation que vous ne pouvez
pas écrire intégralement dans le prompt : Codex ne voit rien de votre échange.

## Contrôle préalable

```bash
codex --version       # absent ? npm i -g @openai/codex  (ou : brew install --cask codex)
codex login status    # code 0 + « Logged in using ChatGPT » = prêt
```

Non connecté → arrêtez-vous et demandez à l'utilisateur de lancer `codex login`
(authentification OAuth en navigateur, une seule fois). Ne lisez, n'affichez et ne copiez
jamais les identifiants (`~/.codex/auth.json`).

## Lancement

```bash
SORTIE=$(mktemp /tmp/codex-out.XXXXXX)
codex exec \
  --cd /chemin/du/depot \
  --config model_reasoning_effort=high \
  --sandbox workspace-write \
  --output-last-message "$SORTIE" \
  "Prompt complet : objectif, contraintes, fichiers à toucher, définition du « terminé »." \
  </dev/null
```

- **`</dev/null` est OBLIGATOIRE** dès que stdin n'est pas un vrai terminal (shells en
  arrière-plan, scripts) : Codex considère un stdin ouvert comme du contexte supplémentaire
  et attend indéfiniment un EOF. C'est le mode de panne numéro un.
- **Codex ne voit RIEN de votre conversation.** Mettez tout dans le prompt : objectif,
  chemins pertinents, contraintes, et comment vérifier que c'est terminé.
- Effort de raisonnement : `high` par défaut pour du vrai travail de code.
- Prompt long ? Passez-le par stdin : `codex exec [options] - < /tmp/tache.md`.
- Enveloppez la commande dans un sous-agent shell ou un terminal d'arrière-plan si votre
  agent hôte le permet, pour que le flux verbeux de Codex reste hors de votre contexte.
- Les exécutions durent plusieurs minutes et n'ont pas de délai d'expiration intégré :
  mettez-les en arrière-plan et surveillez.
- `--json` produit un flux d'événements JSONL si vous devez l'analyser.

### Choix du modèle

Passez `--model` explicitement plutôt que de vous fier au défaut, et **vérifiez le nom du
modèle au moment de l'exécution** (`codex --help`, ou la documentation OpenAI). Ne codez
pas en dur dans cette compétence un identifiant de modèle : ils changent tous les quelques
mois et une compétence qui en fige un devient fausse en silence.

## Récupérer le résultat

```bash
cat "$SORTIE"                            # message final = le livrable
git -C /chemin/du/depot status --short   # ce que Codex a réellement modifié
git -C /chemin/du/depot diff             # à relire vous-même, systématiquement
```

Suite dans la même session (à lancer depuis le même dossier — la reprise filtre par
répertoire de travail) :

```bash
codex exec resume --last "instruction de suivi" </dev/null
```

## Exécutions parallèles

Ne parallélisez que des tâches réellement indépendantes, et attribuez la propriété des
fichiers en amont pour que les résultats fusionnent proprement. **Un worktree Git par
exécution Codex** — jamais deux dans le même arbre de travail :

```bash
git worktree add /tmp/wt-tacheA -b codex/tache-a
codex exec --cd /tmp/wt-tacheA \
  --config model_reasoning_effort=high --sandbox workspace-write \
  -o /tmp/sortieA.md "tâche A" </dev/null
```

Voir la compétence `worktree-git` pour l'amorçage complet d'un worktree.

## Modes d'échec

| Symptôme | Cause | Correctif |
|---|---|---|
| Bloqué indéfiniment, aucune sortie | stdin resté ouvert | tuer, relancer avec `</dev/null` |
| `codex login status` non nul | pas connecté | l'utilisateur lance `codex login` ; ne contournez pas |
| Limite de débit du forfait ChatGPT | quota atteint | signalez-le ; ne relancez jamais en boucle |
| « Not a git repo » | dossier hors dépôt | ajoutez `--skip-git-repo-check`, ou initialisez un dépôt |
| Appels réseau qui échouent | réseau bloqué par le bac à sable | `-c sandbox_workspace_write.network_access=true` si la tâche l'exige |

**N'utilisez JAMAIS `--dangerously-bypass-approvals-and-sandbox`.**

## Règles

- Une tâche par lancement. Découpez les gros chantiers en plusieurs lancements.
- Relisez vous-même le diff de Codex avant de déclarer la tâche terminée. Un sous-agent
  qui affirme avoir réussi n'est pas une preuve ; le diff en est une.

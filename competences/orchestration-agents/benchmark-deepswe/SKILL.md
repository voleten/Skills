---
name: benchmark-deepswe
description: 'Évaluer n''importe quel modèle IA sur le benchmark d''agent de code DeepSWE via l''API OpenRouter. À utiliser quand l''utilisateur veut une évaluation de code indépendante et reproductible — « lance DeepSWE », « benchmark ce modèle », « note le modèle X sur le benchmark de code », ou pour vérifier des scores annoncés par un éditeur. Couvre l''installation, le câblage OpenRouter de mini-swe-agent, les exécutions unitaires / partielles / complètes, et la soumission au classement.'
disable-model-invocation: true
---

# Exécuter DeepSWE via OpenRouter

DeepSWE (deepswe.datacurve.ai) est un benchmark d'agent de code de 113 tâches compatible
Harbor. Il tourne via **Pier** (un fork de Harbor) pilotant **mini-swe-agent** (agnostique
au modèle). Tout modèle joignable via OpenRouter peut être évalué.

## Prérequis — contrôle d'état d'abord

```bash
which uv git docker || echo "MANQUANT : installer uv, git, docker"
docker info >/dev/null 2>&1 || echo "MANQUANT : démon Docker arrêté (bac à sable par défaut de Pier)"
echo "OPENROUTER_API_KEY défini ? ${OPENROUTER_API_KEY:+OUI}"
```

**Docker doit tourner** : Pier isole chaque tâche dans un conteneur par défaut
(`--env modal` pour utiliser le cloud à la place).

Si `OPENROUTER_API_KEY` n'est pas défini, chargez le fichier d'environnement du shell
et revérifiez. S'il reste absent, **demandez à l'utilisateur — n'inventez jamais de clé.**

Posez une limite de dépense hebdomadaire sur la clé OpenRouter dédiée avant la première
exécution complète : le corpus complet consomme des jetons réels.

## Installation

```bash
git clone https://github.com/datacurve-ai/deep-swe && cd deep-swe
uv tool install datacurve-pier            # PyPI (préféré)
# ou : uv tool install git+https://github.com/datacurve-ai/pier
# pier embarque mini-swe-agent comme pilote --agent
```

Lancez toutes les commandes `pier` depuis `deep-swe/`, avec des chemins relatifs `-p tasks/…`.

## Câblage OpenRouter (le point que la documentation ne détaille pas)

mini-swe-agent a une classe de modèle OpenRouter native. Les deux routes ci-dessous
utilisent `OPENROUTER_API_KEY` et le slug OpenRouter (`fournisseur/modele`) :

**Route A — classe OpenRouter native (préférée, attaque directement l'API OpenRouter) :**

```bash
pier run -p deep-swe/tasks --agent mini-swe-agent \
  --model <fournisseur>/<modele> --model-class openrouter
```

**Route B — préfixe de fournisseur LiteLLM (repli, même clé) :**

```bash
pier run -p deep-swe/tasks --agent mini-swe-agent \
  --model openrouter/<fournisseur>/<modele>
```

Notes :

- Le slug doit être le slug OpenRouter exact. Vérifiez-le sur openrouter.ai/models avant
  de lancer — un slug erroné produit une erreur peu explicite.
- Modèles gratuits : le suivi de coût OpenRouter peut échouer. Posez
  `export MSWEA_COST_TRACKING=ignore_errors`.
- L'orthographe des options varie selon les versions : confirmez avec `pier run --help`
  et `mini --help`.

## Test de fumée D'ABORD (1 tâche — avant toute exécution complète)

Validez toujours le câblage de bout en bout sur une seule tâche avant de dépenser des
jetons sur le corpus :

```bash
ls deep-swe/tasks                          # lister les identifiants de tâches
pier run -p deep-swe/tasks/<id-de-tache> --agent mini-swe-agent \
  --model <fournisseur>/<modele> --model-class openrouter
```

Critères de réussite : l'exécution se termine, le modèle renvoie des actions (pas des
erreurs d'authentification ou de format), un score et une trajectoire sont émis.
Un HTTP 401 signifie une clé erronée. « provider not provided » ou « model not mapped »
signifie un slug à corriger ou une route à changer.

## Exécution partielle (échantillon déterministe)

```bash
pier run -p deep-swe/tasks --agent mini-swe-agent \
  --model <fournisseur>/<modele> --model-class openrouter \
  --n-tasks 10 --sample-seed 0
```

## Corpus complet, 113 tâches (coûte des jetons et du temps — confirmez d'abord avec l'utilisateur)

```bash
pier run -p deep-swe/tasks --agent mini-swe-agent \
  --model <fournisseur>/<modele> --model-class openrouter
# ajouter `--env modal` pour paralléliser dans des bacs à sable Modal (Modal doit être configuré)
```

## Sortie et classement

- Les essais atterrissent dans `jobs/<execution>/<id_essai>/`. Inspectez-les avec
  `pier view jobs/<execution>`, `pier analyze jobs/<execution>` ou
  `pier critique run jobs/<execution>`.
- Rapportez : la commande exacte utilisée, réussite/échec, le score, et tout blocage.
- La procédure de soumission au classement officiel est décrite sur deepswe.datacurve.ai —
  suivez-la plutôt qu'une adresse figée ici.

## Modes d'échec

| Symptôme | Cause | Correctif |
|---|---|---|
| HTTP 401 | clé absente ou invalide | réexportez `OPENROUTER_API_KEY` |
| « LLM Provider NOT provided » | préfixe de slug manquant | route B `openrouter/…`, ou route A avec `--model-class openrouter` |
| « model isn't mapped » / erreur de coût | coût inconnu pour ce modèle | `export MSWEA_COST_TRACKING=ignore_errors` |
| Option inconnue | dérive de version | vérifiez `pier run --help` |
| Toutes les tâches échouent instantanément | démon Docker arrêté | démarrez Docker, relancez le test de fumée |

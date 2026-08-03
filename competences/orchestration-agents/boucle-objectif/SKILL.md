---
name: boucle-objectif
description: 'Expliquer et rédiger des instructions efficaces pour la fonction « objectif persistant » d''un agent — la boucle auto-vérifiante planifier → agir → tester → relire → itérer. À utiliser quand l''utilisateur mentionne « /goal », « boucle objectif », « boucle Ralph », veut lancer une exécution autonome longue, demande comment écrire un prompt d''objectif, ou veut qu''on lui rédige un contrat d''objectif.'
---

# Boucle d'objectif persistante

## Ce que c'est

Une commande qui transforme un prompt en **agent persistant** bouclant
`planifier → agir → tester → relire → itérer` jusqu'à ce qu'une condition d'arrêt soit
atteinte, que l'utilisateur mette en pause, ou que le budget de jetons soit épuisé.
Surnommée « boucle Ralph ».

Différence clé avec un prompt normal : quand un tour se termine sans que l'objectif soit
atteint, l'agent **repart tout seul** au lieu d'attendre une entrée.

États du cycle de vie : `en cours`, `en pause`, `atteint`, `non atteint`, `budget épuisé`.

Ce que ce n'est **pas** : une commande de budget, une frontière de sécurité, un bouton
« tourne indéfiniment », ni un remplacement de la phase de planification. C'est un
**vérificateur de contrat doté d'une boucle de validation**.

## Prérequis

- Un agent disposant de la fonctionnalité (elle n'est pas universelle — vérifiez dans
  la liste de commandes de votre agent avant de promettre quoi que ce soit).
- La fonctionnalité activée dans la configuration de l'agent.
- Une authentification par abonnement. L'authentification par clé d'API ne fonctionne
  généralement pas pour ce mode ; un forfait de niveau professionnel est le minimum
  réaliste pour des exécutions longues.

## Quand l'utiliser

Uniquement si les **trois** conditions sont vraies :

1. La tâche représente plus de 30 minutes de travail mécanique.
2. Il existe une **condition d'arrêt vérifiable** (tests au vert, couverture atteinte,
   évaluation ≥ X, compilation réussie).
3. Le dépôt est prêt pour un agent (compilation qui fonctionne, tests corrects, fichier
   d'instructions projet présent).

**Bon terrain** : migrations, remontée de couverture de tests, développement piloté par
les tests, refactorisations avec tests de contrat, optimisation de prompts ou
d'évaluations, boucles de reprise de déploiement, reproduction puis correction de bug.

**Mauvais terrain** : travail exploratoire, « améliore ça » sans critère, tout ce qui n'a
pas de définition du « terminé », identifiants de production, opérations destructrices sur
une infrastructure partagée.

## Le contrat en 5 points

Tout objectif a besoin de ces cinq éléments :

1. **Objectif** — une phrase, un résultat concret.
2. **Contraintes** — ce qui ne doit PAS changer (API publique, fichiers, bibliothèques,
   conventions).
3. **Commande de validation** — la commande shell exacte qui prouve la progression.
4. **Condition d'arrêt** — vérifiable : « s'arrêter quand X passe » OU « quand la suite
   exige un arbitrage humain ou produit ».
5. **Documentation** — une phrase demandant à l'agent d'écrire une documentation concise
   et ciblée pour chaque changement.

Ajoutez : ce qu'il doit lire en premier, et une demande de travail par points de contrôle
avec un journal de progression court.

## Rédiger un objectif (le livrable principal)

Produisez un bloc markdown structuré, une ligne par élément du contrat (avec de vrais
retours à la ligne, pas de la prose continue). **Ne préfixez pas la sortie par la commande
slash** : l'utilisateur l'ajoute lui-même dans son composeur. N'émettez que le corps du contrat.

```
**Objectif :** <objectif en une phrase>
**Lire d'abord :** <fichiers / PLAN.md / ticket>
**Contraintes :** <ce qu'il ne faut pas changer, bibliothèques, conventions>
**Valider :** `<commande exacte>` après chaque modification
**Documenter :** rédiger une documentation concise et ciblée pour tous les changements —
créer de nouveaux fichiers `.md` ou mettre à jour les documents existants selon le besoin.
**Points de contrôle :** travailler par points de contrôle et journaliser brièvement la progression
**S'arrêter quand :** <condition vérifiable>, OU quand la suite exige un arbitrage humain ou produit
```

### Exemple — migration

```
**Objectif :** Migrer ce projet de Pydantic v1 vers v2.
**Lire d'abord :** pyproject.toml, src/, tests/
**Contraintes :** aucune modification de l'API publique ; conserver la compatibilité
ascendante des imports via des adaptateurs si nécessaire ; aucune nouvelle dépendance
**Valider :** `pytest -q` après chaque modification
**Points de contrôle :** travailler par points de contrôle ; journaliser brièvement
**S'arrêter quand :** la suite complète passe sans aucun avertissement de dépréciation,
OU quand un changement exige une décision d'architecture
```

### Exemple — remontée de couverture

```
**Objectif :** Faire passer la couverture de src/auth/ d'environ 38 % à ≥ 75 %.
**Lire d'abord :** src/auth/, tests/auth/, AGENTS.md
**Contraintes :** aucune nouvelle dépendance ; refléter le style de test existant ;
ne pas modifier le code de production sauf strict besoin de testabilité
**Valider :** `pytest --cov=src/auth --cov-report=term-missing`
**Points de contrôle :** journaliser l'écart de couverture à chaque point de contrôle
**S'arrêter quand :** couverture ≥ 75 % ET tous les tests passent, OU quand le code non
couvert exige un changement de conception
```

### Règles de rédaction

- **Un objectif, une condition d'arrêt.** Pas un carnet de commandes.
- **La documentation est obligatoire.** Une phrase engageant l'agent à documenter.
- **N'instruisez jamais l'agent de créer de nouveaux ADR** : un ADR exige l'accord
  explicite de l'utilisateur ; un prompt d'objectif ne doit pas le pré-approuver.
- **Interdisez explicitement le détournement de la récompense** : « Ne supprime pas, ne
  saute pas, n'affaiblis pas et ne restreins pas les tests pour faire passer l'objectif. »
  Sans cette phrase, l'agent finit par jouer contre la condition d'arrêt plutôt que contre
  le problème. C'est la règle la plus importante de la liste.
- **Limite d'environ 4 000 caractères** sur l'objectif. Au-delà, mettez le détail dans un
  fichier (`PLAN.md`, `BRIEF.md`) et faites pointer l'objectif dessus.
- Utilisez des **chaînes littérales** pour les chemins, commandes et numéros de tickets.
- Interdisez explicitement la dérive de périmètre : « Ne refactorise pas de code non
  concerné. N'ajoute pas de dépendances. »
- Dites quand faire une pause : « Si <condition>, mets en pause et demande avant de continuer. »
- Un objectif court et vague brûle des jetons sans rien apporter face à un prompt normal.

### Astuce de méta-prompting (le plus fort levier)

Les objectifs écrits à la main sous-spécifient. Demandez à une **seconde session IA**
d'inspecter le dépôt, de faire remonter les hypothèses implicites, contraintes et cas
limites, puis d'émettre un bloc de contrat structuré. Collez le résultat dans l'agent.
La différence de qualité d'exécution est d'un ordre de grandeur.

### Auto-définition de l'objectif

Certains agents peuvent écrire et poser leur propre objectif nativement. Donnez alors
votre intention de haut niveau : « Inspecte ce dépôt, puis écris-toi un objectif avec une
condition d'arrêt vérifiable et poursuis-le. » C'est le méta-prompting fait en ligne.
Fournissez quand même la même matière première (fichiers à lire, contraintes, commande de
validation) pour que l'objectif produit soit ancré. Ajoutez : « pose des questions de
clarification avant de t'engager si l'intention est sous-spécifiée » — cela attrape
l'ambiguïté en amont et évite la dérive.

## Lancer

1. Placez-vous dans le dépôt (les objectifs sont cadrés sur le répertoire de travail).
2. Lancez l'agent en mode interactif. **Pas** en mode exec/headless : c'est une commande
   de l'interface interactive.
3. Connectez-vous avec l'authentification par abonnement.
4. Tapez la commande suivie de votre contrat, puis validez.
5. Éloignez-vous.

## Piloter un objectif en cours

| Commande | Effet |
|---|---|
| la commande seule | Statut : point de contrôle courant, ce qui est vérifié, ce qui reste, blocages |
| `pause` | Gel |
| `resume` | Dégel (un objectif en pause ne reprend jamais tout seul) |
| `clear` | Suppression de l'objectif |
| un nouveau contrat | Remplacement de l'objectif courant |
| Ctrl+C / tout message tapé | Mise en pause automatique ; l'entrée utilisateur est toujours prioritaire |

L'état d'objectif est persisté côté serveur : revenez dans le dépôt, relancez l'agent,
demandez le statut, puis reprenez.

En état « budget épuisé », l'agent ne s'arrête pas brutalement : il résume, note ce qui
reste et sauvegarde l'état. La reprise fonctionne après réapprovisionnement.

## Quand un objectif dérive

- **Dérive mineure** : tapez simplement une correction (l'agent se met en pause,
  l'intègre, reprend).
- **Objectif trop lâche** : mettez en pause, lisez le statut, puis remplacez le contrat
  par une version plus serrée. N'empilez pas des instructions sur un objectif vague.
- **Situation dégradée** : supprimez l'objectif, inspectez l'état du dépôt (`git status`,
  `git stash`), réécrivez le contrat avec le méta-prompting, redémarrez.

Ne laissez pas un objectif dérivant tourner « pour voir où ça mène » : les jetons brûlent
et les diffs s'accumulent.

## Conseils d'exploitation

- Inspectez le statut périodiquement.
- **Relisez toujours le diff avant de fusionner.** Une autonomie plus longue signifie plus
  de code à valider, pas moins. La supervision humaine devient plus critique, pas optionnelle.
- Gardez les approbations et le bac à sable serrés ; les permissions par défaut sont
  les bonnes.
- Pour un premier essai, choisissez une tâche cadrée sur 30 minutes, afin d'apprendre
  comment la boucle s'arrête réellement avant de lui faire confiance toute une nuit.
- Inscrivez la politique récurrente dans le fichier d'instructions du dépôt (`AGENTS.md`)
  pour que chaque objectif en hérite sans la répéter : auto-revue adversariale avant de
  déclarer terminé, passe de contrôle qualité supplémentaire même quand les tests passent,
  et commande de validation standard.

## Dépannage

| Symptôme | Correctif |
|---|---|
| La commande n'apparaît pas dans la liste | Mettez l'agent à jour vers une version qui la prend en charge |
| Option activée mais commande absente | Quittez et relancez complètement l'agent |
| N'active rien | Déconnectez-vous, reconnectez-vous avec l'authentification par abonnement |
| Arrêt avec un résumé de progression | Budget épuisé — reprenez après réapprovisionnement, ou réduisez la portée |
| « Aucun objectif actif » à la reprise | État terminal ou objectif effacé — repartez sur un nouveau contrat |
| Actif mais ne repart pas tout seul | Bloqué en mode planification — la planification seule ne déclenche pas la continuation. Rédigez le plan, puis passez en exécution |

## Modèle mental

Une boucle d'objectif est un **vérificateur de contrat doté d'une boucle de validation**,
pas un bouton « tourne indéfiniment ». Le basculement : arrêtez d'écrire des prompts,
commencez à écrire des **spécifications avec conditions d'arrêt**. Le temps investi en
amont à définir le « terminé » est ce qui rend l'exécution autonome utile.

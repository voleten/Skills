# Audit de dépendances — commandes par écosystème

Détail sorti de `SKILL.md` pour n'être chargé qu'au moment de la phase 3. Identifiez
l'écosystème avant de choisir : **un audit lancé avec le mauvais outil ne trouve rien et
donne une fausse assurance.**

## Table des matières

- [Détecter l'écosystème](#détecter-lécosystème)
- [Commandes d'audit](#commandes-daudit)
- [Lire la sortie](#lire-la-sortie)
- [Appliquer les correctifs](#appliquer-les-correctifs)
- [Quand l'outil n'est pas installé](#quand-loutil-nest-pas-installé)

---

## Détecter l'écosystème

```bash
ls package.json pnpm-lock.yaml yarn.lock \
   requirements.txt pyproject.toml poetry.lock uv.lock \
   go.mod Gemfile Gemfile.lock Cargo.toml composer.json pom.xml build.gradle 2>/dev/null
```

Un dépôt peut en contenir plusieurs (une API Python plus une interface Node). **Auditez-les
tous** : la moitié des angles morts vient d'un sous-projet oublié.

## Commandes d'audit

| Écosystème | Commande | Notes |
|---|---|---|
| Node / npm | `npm audit --omit=dev` | `--omit=dev` cible ce qui part réellement en production |
| Node / pnpm | `pnpm audit --prod` | |
| Node / yarn | `yarn npm audit --environment production` | La syntaxe diffère selon la version majeure de Yarn |
| Python | `pip-audit` | Sur un projet à verrou : `pip-audit -r requirements.txt` |
| Python / uv | `uv pip list --format=freeze \| pip-audit -r /dev/stdin` | |
| Go | `govulncheck ./...` | Analyse les chemins d'appel réels : moins de faux positifs |
| Rust | `cargo audit` | |
| Ruby | `bundle audit check --update` | |
| PHP | `composer audit` | |
| Java / Maven | `mvn org.owasp:dependency-check-maven:check` | Long ; à réserver aux audits complets |
| Conteneurs | `trivy image <image>` ou `docker scout cves <image>` | Audite l'image, pas seulement le code |

Ajoutez `|| true` en fin de commande dans un script d'audit : ces outils sortent en code non
nul dès qu'ils trouvent quelque chose, ce qui interromprait une suite de contrôles.

## Lire la sortie

Trois questions dans cet ordre, pour chaque vulnérabilité remontée :

1. **Le paquet part-il en production ?** Une dépendance de développement ou de test n'est pas
   sur le chemin d'un attaquant distant. Elle compte quand même si elle s'exécute dans votre
   intégration continue avec des jetons en portée.
2. **Le code vulnérable est-il atteignable ?** Une faille dans une fonction que le projet
   n'appelle jamais n'est pas exploitable ici. `govulncheck` répond à cette question tout
   seul ; pour les autres écosystèmes, il faut regarder.
3. **Un correctif existe-t-il ?** Sinon, notez l'atténuation possible (désactiver la
   fonctionnalité, épingler une version, filtrer en amont) plutôt que de laisser la ligne
   sans suite.

Un score « critique » sur une dépendance de développement inatteignable passe **après** un
score « moyen » sur l'analyseur de requêtes entrantes. Écrivez cet arbitrage dans le rapport :
sans lui, l'utilisateur corrige dans l'ordre du score.

## Appliquer les correctifs

```bash
npm audit fix              # correctifs compatibles semver uniquement
npm audit fix --force      # PEUT casser : introduit des versions majeures
```

**Ne lancez jamais `--force` sans relancer la suite de tests derrière**, et ne le faites pas
de votre propre initiative sur un projet dont vous ne connaissez pas la couverture de tests.
Signalez-le à l'utilisateur comme une action à valider.

Après toute mise à jour : relancez l'outil d'audit **et** les tests. Une correction de
sécurité qui casse la production n'est pas une correction.

## Quand l'outil n'est pas installé

Ne l'installez pas globalement sans demander. Deux options honnêtes :

- Exécution ponctuelle sans installation permanente (`npx`, `uvx`, `pipx run`).
- Signalez simplement que l'écosystème n'a pas pu être audité, et listez-le dans la section
  « non couvert par cet audit » du rapport.

La seconde option est toujours préférable à un audit partiel présenté comme complet.

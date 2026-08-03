# Compétences d'agents

Bibliothèque de compétences réutilisables pour agents IA — Claude Code, Codex, Cursor, Pi,
Hermes, OpenCode, Grok.

**45 compétences** réparties en 5 catégories, plus un garde-fou global des commandes shell
et un validateur automatique.

Les choix de conception et les propriétés de sûreté du dépôt sont documentés dans
[DECISIONS.md](DECISIONS.md).

---

## Démarrage rapide

```bash
git clone <ce-depot> ~/competences-agents
cd ~/competences-agents

cp PROFIL.exemple.md PROFIL.md      # renseignez vos chemins et identités locales
./outils/valider-competences.sh     # doit afficher « 0 erreur(s) »
./hooks/test-garde.sh               # doit afficher « échoués : 0 »
```

Pour rendre une compétence visible par vos agents, copiez son dossier dans le dossier de
compétences de l'agent (voir la compétence `distribuer-competence`).

---

## Structure

```
competences/<categorie>/<competence>/
├── SKILL.md              # obligatoire : frontmatter YAML + instructions
├── agents/openai.yaml    # optionnel : politique d'invocation Codex
├── references/           # optionnel : détail chargé à la demande
└── scripts/              # optionnel : code exécutable
hooks/                    # garde-fou global des commandes shell
outils/                   # validateur du dépôt
PROFIL.exemple.md         # modèle de configuration locale (non committée)
```

---

## Les compétences

### `orchestration-agents/` — lancer, planifier et coordonner des agents

| Compétence | Ce qu'elle fait |
|---|---|
| `planification-agent` | Faire tourner un agent sur horaire, boucle ou intervalle (cron, battements de cœur, planificateurs intégrés) |
| `cmux` | Piloter l'application terminal macOS cmux : espaces, panneaux, surfaces, navigateur |
| `sous-agent-codex` | Déléguer une tâche de code autonome à Codex CLI |
| `revue-par-modele` | Faire relire le code par un sous-agent d'un autre modèle et restituer son rapport mot pour mot |
| `prompt-sans-blocage` | Réécrire chirurgicalement un prompt pour réduire les faux positifs des garde-fous |
| `worktree-git` | Worktrees Git pour agents parallèles, amorçage complet inclus |
| `boucle-objectif` | Écrire et piloter un contrat d'objectif auto-vérifiant (plan → agir → tester → itérer) |
| `passation` | Compacter une session en un message de passation vers un contexte neuf |
| `lancer-sous-agent` | Règles à lire avant tout lancement de sous-agent |
| `benchmark-deepswe` | Évaluer un modèle sur le benchmark d'agent de code DeepSWE |

### `creation-competences/` — écrire et distribuer des compétences

| Compétence | Ce qu'elle fait |
|---|---|
| `competences-efficaces` | Le guide complet : anatomie, divulgation progressive, motifs, anti-motifs, tests, sécurité |
| `distribuer-competence` | Synchroniser une compétence entre les dossiers de tous les agents installés |
| `claude-md-de-dossier` | Créer un CLAUDE.md cadré sur un dossier, avec lien AGENTS.md |
| `publier-competence` | Committer et pousser une modification de compétence |

### `recherche-et-web/` — chercher, moissonner, transcrire

| Compétence | Ce qu'elle fait |
|---|---|
| `deepapi` | Référence complète de l'API : recherche, moissonnage, recherche, courriel, images, mémoire |
| `apify` | Alternative pour le moissonnage et la recherche web : acteurs du Store, via MCP ou API REST |
| `recherche-approfondie` | Flux complet : invite rigoureuse + exécution + rapport markdown cité |
| `prompt-de-recherche` | Rédiger un brief de recherche autonome d'un seul paragraphe |
| `transcription-youtube` | Transcription d'une vidéo YouTube, avec repli local |
| `transcription-fireflies` | Transcriptions de réunions depuis Fireflies.ai |
| `achat-en-ligne` | Prix juste, meilleures offres, fiabilité du marchand — effort calibré sur le prix |
| `pilote-navigateur` | Pilotage direct du navigateur via CDP pour les tâches qui exigent un vrai navigateur |
| `recherche-web-pi` | Accès web pour les agents Pi, avec minimums de requêtes par niveau de profondeur |

### `reflexion-et-docs/` — penser, interroger, enseigner, documenter

| Compétence | Ce qu'elle fait |
|---|---|
| `avant-de-construire` | Faire remonter instantanément les 1 à 3 choix lourds cachés dans une idée |
| `cerveau-vers-docs` | Extraire la vision et les décisions vers un README et des ADR par questions-réponses |
| `decisions-incertaines` | Lister les choix déjà faits dont l'agent n'est pas sûr |
| `prochaine-decision` | Traiter les décisions ouvertes une par une, avec options et préférence |
| `interroge-moi` | Entretien dirigé : priorités, travail évité, importance réelle — puis confrontation du discours à l'historique Git |
| `lire-tous-les-adr` | Lire tous les ADR **et le prouver** par un relevé qu'un survol ne peut pas produire |
| `rappel` | Résumé de la conversation plus réécriture simplifiée de la dernière réponse |
| `version-courte` | Compresser la réponse précédente |
| `monter-en-niveau` | Évaluation adaptative en 7 questions, notes honnêtes, plan d'apprentissage |
| `noter-une-idee` | Capturer une idée de contenu avec sa provenance |
| `enseigner` | Enseignement suivi sur plusieurs sessions : mission, ressources, leçons, registres |

### `operations-et-config/` — machine, serveur, sécurité, livraison

| Compétence | Ce qu'elle fait |
|---|---|
| `anti-veille` | Empêcher la mise en veille d'un Mac de façon fiable (script fourni) |
| `audit-cyber` | Audit défensif classé par irréversibilité : secrets, **surface d'attaque des agents**, dépendances, surface web |
| `garde-fous-agents` | Liste de refus partagée des commandes catastrophiques, sur tous les agents |
| `google-safe-browsing` | Prévenir et corriger les signalements « Site dangereux » |
| `gestion-vps` | Gérer des serveurs distants et les agents qui y tournent |
| `metriques-mac` | Construire un collecteur de métriques Mac local et permanent |
| `modele-perso-pi` | Enregistrer un modèle ou une variante personnalisée dans l'agent Pi |
| `push-production` | Pousser et surveiller jusqu'à la mise en ligne vérifiée |
| `aide-installation` | Guider pas à pas, une étape atomique à la fois |
| `role-bdd-lecture-seule` | Créer un rôle PostgreSQL en SELECT seul pour les agents |
| `tuer-cursor` | Tuer proprement tous les processus de l'IDE Cursor |

---

## Garde-fou global des commandes

`hooks/` contient une liste de refus partagée qui bloque les commandes shell
catastrophiques avant qu'un agent ne les exécute — sur Claude Code, Codex, Cursor, Pi,
Hermes, OpenCode et Grok à la fois.

```bash
./hooks/test-garde.sh     # 214 assertions, doit afficher « échoués : 0 »
```

**C'est une ceinture de sécurité contre l'accident, pas un bac à sable contre un agent
malveillant** : une commande obfusquée passe à travers une expression régulière. Le
câblage par agent est décrit dans la compétence `garde-fous-agents`.

Deux propriétés à connaître : la garde ne s'ouvre **jamais en silence** — sans `jq` elle
bascule sur `python3`, et si aucun analyseur JSON n'est disponible elle écrit un fichier
témoin et un avertissement plutôt que de laisser croire à une protection active. Et les
répertoires système (`/usr`, `/etc`, `/var`, `/boot`, `/System`, `/Applications`,
`/Library`, `/Volumes`) sont couverts, au niveau racine et un cran en dessous, sans
bloquer les chemins profonds légitimes.

---

## Validateur

```bash
./outils/valider-competences.sh
```

Il encode sous forme exécutable les règles de `competences-efficaces` et les défauts
relevés à l'audit. Il vérifie : dossiers orphelins sans `SKILL.md`, correspondance
`name` ↔ nom du dossier, analyse YAML en **mode strict** (le piège du « : » non quoté qui
fait disparaître une compétence chez certains agents sans le moindre message), présence et
longueur de la description, caractères `<`/`>` dans le frontmatter, références vers des
fichiers inexistants, scripts non exécutables, fichiers embarqués jamais référencés, titres
dupliqués, documentation humaine égarée dans un dossier de compétence, et longueur
excessive.

À lancer avant chaque commit.

---

## Conventions de ce dépôt

- **Aucune donnée personnelle dans les compétences.** Chemins, identités Git, dépôts,
  adresses IP et échéances vivent dans `PROFIL.md` (non committé). Une compétence qui a
  besoin d'une valeur locale y renvoie.
- **Aucune information périssable.** Pas d'identifiant de modèle codé en dur, pas de tarif,
  pas de date. Ces valeurs se vérifient à l'exécution.
- **Prose neutre.** Aucune supposition sur le genre des personnes mentionnées.
- **Déclencheurs dans les deux langues.** Les descriptions couvrent les formulations que
  l'utilisateur emploiera réellement, pour que le routage ne dépende pas de la langue de
  la demande.
- **Une compétence, une préoccupation.** Les compétences quasi identiques sont fusionnées
  et paramétrées, pas dupliquées.

---

## Licence

MIT — voir [LICENSE](LICENSE).

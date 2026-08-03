---
name: competences-efficaces
description: 'Comment écrire des compétences d''agent efficaces — anatomie, divulgation progressive, motifs de conception, anti-motifs, tests, sécurité. À lire dès qu''une compétence (Agent Skill, SKILL.md) est créée, modifiée, relue ou déboguée. Se déclenche sur « crée une compétence », « nouvelle compétence », « améliore cette compétence », « pourquoi ma compétence ne se déclenche pas », « create a skill », « SKILL.md ».'
---

# Compétences d'agent : guide complet

Référence consolidée sur ce que sont les compétences d'agent, pourquoi elles existent,
comment elles fonctionnent, et comment en écrire d'efficaces.

---

## 1. Ce qu'est une compétence

Une compétence est un dossier contenant un fichier `SKILL.md` (frontmatter YAML +
instructions markdown), plus des sous-dossiers optionnels chargés à la demande.

```
ma-competence/
├── SKILL.md          # Obligatoire : métadonnées + instructions
├── scripts/          # Optionnel : code exécutable (CLI, validateurs, utilitaires)
├── references/       # Optionnel : documentation détaillée chargée au besoin
└── assets/           # Optionnel : modèles, polices, fichiers statiques
```

Les compétences sont un standard ouvert (agentskills.io), créé à l'origine par Anthropic
et adopté par de nombreux produits d'agents. Le format du dossier et de `SKILL.md` est
portable ; certains comportements optionnels, comme le contrôle d'invocation, sont
spécifiques au client.

---

## 2. Pourquoi cette abstraction existe

Les modèles de base sont généralistes. Le travail réel exige de la connaissance
procédurale, du contexte organisationnel et des flux de travail répétables. Chaque
alternative antérieure avait son mode de panne :

| Approche | Problème |
|---|---|
| Tout mettre dans le prompt système | Toujours chargé → saturation du contexte à l'échelle |
| Recoller les instructions à chaque session | Aucun contrôle de version, aucune cohérence |
| Affinage du modèle | Lent, coûteux, opaque, lié à un fournisseur |
| Serveurs MCP seuls | Donnent des outils à l'agent, mais aucun flux de travail pour les utiliser |

Les compétences résolvent quatre problèmes d'un coup : **efficacité du contexte**
(les instructions ne se chargent que quand elles sont pertinentes), **répétabilité**
(les procédures multi-étapes deviennent auditables), **composabilité** (plusieurs
compétences se combinent à l'exécution) et **portabilité** (les mêmes fichiers
fonctionnent chez plusieurs fournisseurs).

Modèle mental : les compétences sont aux LLM ce que les pages de manuel, les runbooks et
les manuels d'équipe sont aux ingénieurs — de la documentation de référence chargée en
mémoire de travail uniquement quand la tâche l'exige.

---

## 3. Comment ça marche — divulgation progressive

C'est le cœur architectural. Chargement en trois étapes :

**Niveau 1 — Découverte (~100 jetons par compétence, toujours en contexte).**
Seuls `name` et `description` du frontmatter sont injectés dans le prompt système au
démarrage. L'agent sait que la compétence existe et quand elle s'applique. On peut donc
installer des dizaines de compétences pour un coût négligeable.

**Niveau 2 — Activation (< 5 000 jetons, chargé sur correspondance).**
Quand la demande correspond à la description d'une compétence, l'agent lit le corps
complet de `SKILL.md`.

**Niveau 3 — Exécution (non borné, à la demande).**
L'agent lit les fichiers référencés ou exécute les scripts uniquement au besoin. Un script
peut s'exécuter sans que son code source entre jamais dans le contexte.

C'est pourquoi le contenu embarqué n'a pas de limite pratique : les fichiers ne consomment
pas de jetons tant qu'ils ne sont pas ouverts.

---

## 4. Anatomie de SKILL.md

```markdown
---
name: nom-de-la-competence
description: Ce que fait la compétence ET quand l'utiliser. Incluez les formulations
  déclenchantes que l'utilisateur emploiera réellement.
---

# Nom de la compétence

## Démarrage rapide
[Exemple minimal qui fonctionne]

## Procédure
[Étapes avec listes de contrôle]

## Format de sortie
[Ce que l'utilisateur ou l'agent doit recevoir en retour]

## Avancé
[Lien vers references/ pour le détail rarement nécessaire]
```

### Contraintes du frontmatter

- `name` en minuscules, tirets uniquement, 1 à 64 caractères, **identique au nom du
  dossier parent**.
- Évitez `<` et `>` dans le frontmatter : ils peuvent s'injecter dans le prompt système.
- Un YAML invalide empêche silencieusement le chargement — c'est la panne la plus
  frustrante à diagnostiquer car rien ne s'affiche.
- **Ne mettez jamais un « : » suivi d'une espace dans une `description` non quotée.**
  Les analyseurs YAML stricts le rejettent comme une table imbriquée, alors que les
  analyseurs permissifs l'acceptent : la compétence marche chez un agent et disparaît chez
  un autre. Si le texte a besoin d'un deux-points, mettez toute la valeur entre
  apostrophes simples et doublez les apostrophes internes :
  `description: 'Différenciateur : trouve les lacunes dans l''analyse.'`

### L'invocation manuelle uniquement est spécifique au client

`disable-model-invocation: true` ne fait **pas** partie du cœur de la spécification. C'est
une extension prise en charge par certains clients (Claude Code, VS Code/Copilot). Codex
utilise un fichier séparé `agents/openai.yaml` dans la compétence :

```yaml
policy:
  allow_implicit_invocation: false
```

Pour une compétence manuelle partagée entre plusieurs clients, incluez les deux
configurations. Ne supposez jamais qu'un champ spécifique à un client fonctionne partout :
vérifiez la documentation de chaque cible et testez l'invocation implicite dans chaque
environnement d'exécution.

---

## 5. Deux philosophies de conception

**Motif A — primitive de capacité (enveloppe d'outil).** La compétence est une fine couche
au-dessus d'une CLI ou d'un script déterministe. La logique vit dans le code ; `SKILL.md`
apprend à l'agent comment l'invoquer.
Apporte : de nouvelles capacités. Fiabilité par les outils shell, pas par les prompts.
Longueur typique : 30 à 80 lignes, surtout des exemples de commandes.
À utiliser quand le goulot d'étranglement est « l'agent ne sait pas faire X ».

**Motif B — primitive de processus (discipline cognitive).** La compétence encode une
méthodologie que l'agent doit suivre. Pure ingénierie de prompt, aucun script nécessaire.
Apporte : des flux de travail structurés. Fiabilité par la procédure explicite, les listes
de contrôle et les boucles de validation.
À utiliser quand le goulot d'étranglement est « la qualité ou le processus de l'agent est mauvais ».

Une installation mature utilise les deux. Le motif A donne de meilleurs outils à l'agent,
le motif B de meilleures méthodes pour les utiliser.

---

## 6. Ce qu'il faut faire

### La description est un contrat de routage

La description est la **seule** chose que l'agent voit avant de décider de charger la
compétence. Si votre compétence ne se déclenche pas, c'est la description qui est en
cause dans 95 % des cas, pas le corps.

Elle doit contenir trois éléments :

1. **Quoi** — ce que fait la compétence, en une formule.
2. **Quand** — formulations déclenchantes, situations.
3. **Différenciateur** face aux compétences voisines (évite les conflits de routage).

Motif : `« X via Y. À utiliser pour [situations]. [Différenciateur : sans Z / plus rapide
que W / gère le cas limite V]. »`

**Ne résumez jamais le flux de travail complet dans la description.** Si la description
contient un résumé pas-à-pas du *comment*, l'agent a tendance à suivre ce résumé et à ne
jamais charger le corps. Décrivez le *quoi* et le *quand*, jamais le *comment*. La
description répond à « dois-je ouvrir cette compétence maintenant ? », pas à
« quelles sont les étapes ? ».

**Dépôt multilingue** : incluez les formulations déclenchantes dans les deux langues
utilisées. Un agent qui reçoit « fais une revue de code » ne fera pas correspondre une
description contenant uniquement « code review ».

### Le bash d'abord, la prose ensuite

Des exemples de commandes concrets avec des commentaires en ligne battent les explications
en prose. L'agent fait de la correspondance de motifs sur la syntaxe. Montrez, ne décrivez pas.

### Poussez le déterminisme dans le code

Tout ce qui est fragile, répétitif, ou dont la variation est un bug → un script.
Réservez le markdown aux tâches qui demandent du jugement.

### Ajustez la rigidité à la fragilité de la tâche

- **Heuristiques en langage naturel souples** quand de nombreuses approches sont valables
  (revue de code).
- **Pseudocode ou modèles** quand un motif est préféré mais que la variation est
  acceptable (format de rapport).
- **Scripts exacts et listes d'étapes strictes** quand le flux est fragile, propice aux
  erreurs, ou que la cohérence est critique (migrations, correctifs de documents).

### Construisez des boucles de validation

C'est le plus grand gain unique de qualité. Énoncez explicitement une boucle
vérifier → corriger → revérifier.

- Compétences documentaires : passe de contrôle visuel avant livraison.
- Compétences de code : tests au vert et zéro erreur de typage avant de conclure.
- Compétences de données : validation de schéma avant sortie.

### Contrôlez l'état avant d'agir

Ne supposez pas que l'installation est faite. Faites vérifier l'état, puis brancher :

```
Vérifie d'abord si X est configuré : [commande]
Sinon, guide l'utilisateur dans l'installation : [étapes]
```

### Chargement juste-à-temps avec des pointeurs explicites

Dites à l'agent exactement quand lire chaque fichier référencé :

```
Pour les cas standard, suis les étapes ci-dessous.
Pour [cas limite précis], lis d'abord references/cas-limites.md.
```

### Gardez les références à un seul niveau

Liez les fichiers référencés directement depuis `SKILL.md`. Ne construisez jamais de
chaînes (`SKILL.md` → `avance.md` → `details.md` → `reel.md`) : l'agent peut ne
prévisualiser qu'une partie des fichiers imbriqués et manquer des instructions critiques.
Ajoutez une table des matières à tout fichier de référence dépassant 100 lignes.

### Documentez les formats de sortie

Si votre script renvoie des données structurées, montrez à l'agent à quoi elles
ressemblent. Cela permet une analyse fiable en aval.

### Déléguez à `--help` pour l'exhaustivité

Listez les 80 % d'opérations courantes dans `SKILL.md`. Dites à l'agent d'exécuter
`outil --help` pour le reste. `SKILL.md` reste petit sans perdre de fonctionnalité —
et ne se périme pas à chaque version de l'outil.

### Composez des primitives, n'empaquetez pas des flux entiers

Une compétence = une capacité ou une discipline. Résistez à l'envie d'empaqueter des
préoccupations dans « le flux de travail X ». Plusieurs petites compétences se combinent à
l'exécution ; une grosse compétence est rigide.

### Citez les principes établis quand ils s'appliquent

Si votre compétence encode une méthodologie connue (TDD, DDD, rouge-vert-refactorisation),
nommez la source. Cela donne à l'agent un modèle cohérent et aux utilisateurs un moyen de
vérifier la conception.

### Artefacts persistants pour la mémoire inter-sessions

Une compétence peut écrire dans des fichiers du dépôt (CONTEXTE.md, ADR, journaux de
décision) que les sessions futures relisent. C'est ainsi qu'on combat le problème de
l'absence de mémoire au niveau architectural.

---

## 7. Anti-motifs

### Ne réenseignez pas ce que le modèle sait déjà

Chaque ligne de `SKILL.md` doit apporter du contexte que le modèle n'a pas. Pas de tutoriel
de syntaxe Python. Pas de « qu'est-ce que git ». Remettez chaque paragraphe en question.

### N'incluez pas de documentation destinée aux humains

Pas de `README.md`, pas de `CHANGELOG.md`, pas de guide d'installation **à l'intérieur du
dossier de compétence**. Les compétences s'adressent aux agents. La documentation humaine
vit à la racine du dépôt.

### N'écrivez pas de descriptions vagues

- Mauvais : « Une compétence utile pour les documents. »
- Bon : « Remplir des champs de formulaire PDF, extraire des données de formulaire,
  aplatir des PDF complétés. À utiliser quand l'utilisateur mentionne des formulaires PDF,
  des formulaires à remplir, ou le remplissage programmatique de champs. »

### N'empaquetez pas de code de bibliothèque

Si vous avez besoin d'une bibliothèque d'analyse, installez-la via npm/pip. Ne collez pas
le code source dans la compétence.

### N'écrivez pas de méga-compétences monolithiques

Si une compétence fait conception + planification + implémentation + tests + déploiement,
vous avez construit un cadriciel, pas une compétence. Découpez.

### Ne supposez pas que l'agent devinera

Soyez explicite sur chaque étape qui compte.

- Mauvais : « Puis déploie-le. »
- Bon : « Exécute `npm run deploy:staging` et attends un HTTP 200 sur `/healthz` avant
  d'annoncer un succès. »

### N'écrivez pas de variantes purement stylistiques

Une compétence qui ne change que le ton ou le formatage relève des préférences
utilisateur ou du prompt système, pas d'une compétence.

### N'ignorez pas les modes d'échec

Pour chaque étape qui peut échouer, documentez à quoi ressemble l'échec et quoi faire.
Les compétences qui ne décrivent que le chemin heureux cassent en production.

### N'incluez pas d'information périssable

« Depuis le T4 2024… » pourrit vite. Les identifiants de modèles, les tarifs et les
versions changent tous les quelques mois : une compétence qui les fige devient fausse
en silence, ce qui est pire que de ne rien dire. Récupérez les données à l'exécution
via un script, ou renvoyez vers `--help` et la documentation officielle.

### N'utilisez pas de chemins absolus

Toujours relatifs. Barres obliques quel que soit le système. Utilisez les substituants
d'exécution pour référencer le dossier de la compétence.

### Ne faites pas confiance à une compétence inconnue

Une compétence peut exécuter du code arbitraire et orienter le comportement de l'agent.
Une compétence malveillante est un vecteur d'exfiltration de données. Auditez les scripts
à la recherche d'appels réseau inattendus, d'accès à des fichiers hors périmètre, ou
d'instructions cachées dans les références. Méfiez-vous des noms de compétences
typosquattés. Exécutez en environnement isolé.

---

## 8. Flux de création

1. **Identifiez le manque.** Faites tourner votre agent sur de vraies tâches. Là où il
   échoue systématiquement ou exige d'être relancé, il y a une compétence candidate.
2. **Choisissez le motif.** Primitive de capacité (nouveaux outils) ou primitive de
   processus (meilleure méthodologie) ?
3. **Rédigez la description en premier.** Quoi + quand + différenciateur. Relisez-la :
   l'agent saurait-il quand la déclencher ?
4. **Écrivez le plus petit corps qui fonctionne.** N'ajoutez que quand les tests révèlent
   un manque.
5. **Déplacez le détail dans `references/`** dès que `SKILL.md` devient long.
6. **Testez le déclenchement.** Demandez à l'agent quelque chose que la compétence devrait
   traiter, sans l'invoquer explicitement. Si elle ne se déclenche pas, corrigez la description.
7. **Testez l'exécution.** Invoquez explicitement. Si la sortie est mauvaise, corrigez le corps.
8. **Test adversarial.** Faites demander à un autre modèle : « Quels cas limites cassent
   cette compétence ? » Colmatez.
9. **Contrôle de version.** Traitez les compétences comme du code : branches, revues, tags.

---

## 9. Tests et débogage

- **« Quelle compétence as-tu utilisée ? »** — demandez-le à l'agent après la tâche.
  C'est le diagnostic de routage le plus rapide.
- **Le routage échoue → problème de description.** Ajoutez des formulations déclenchantes
  précises.
- **L'exécution échoue → problème de corps.** Ajoutez des étapes explicites, des exemples,
  ou une validation.
- **Les compétences sont figées au démarrage de session.** Une édition en cours de session
  exige un redémarrage — c'est la cause numéro un des « j'ai corrigé mais rien ne change ».
- **Testez contre le modèle le plus faible que vous déploierez.** Les modèles forts
  pardonnent les compétences vagues ; les faibles les exposent.
- **Faites tourner une suite d'évaluation** : quelques prompts représentatifs qui doivent
  et ne doivent pas déclencher la compétence, avec les sorties attendues.

---

## 10. Composition

Les compétences se composent à l'exécution : l'agent en charge plusieurs pour une même
tâche. Concevez pour cela.

- **Une compétence = une préoccupation.**
- **Définissez les interfaces entre compétences.** Si A produit des artefacts que B
  consomme, documentez leur forme.
- **Utilisez un substrat de configuration au niveau du dépôt.** Un fichier partagé
  (`AGENTS.md`, `CONTEXTE.md`, `settings.json`) que plusieurs compétences lisent et
  écrivent les coordonne sans passation explicite.
- **Des boucles plutôt que des menus.** Un ensemble coordonné formant un flux de travail
  (aligner → spécifier → construire → vérifier → refactoriser) est bien plus adopté qu'un
  catalogue de capacités sans lien.

---

## 11. Liste de contrôle de sécurité

Avant d'installer une compétence tierce :

- [ ] Lire chaque fichier du dossier.
- [ ] Auditer les scripts : appels réseau sortants, accès fichiers hors périmètre,
      exécution de commandes.
- [ ] Vérifier les références : injection de prompt (« ignore les instructions précédentes… »).
- [ ] Vérifier que le nom ne typosquatte pas une compétence populaire.
- [ ] Exécuter d'abord en environnement isolé.
- [ ] Épingler une version ou un commit précis, jamais `latest`.

---

## 12. Liste de contrôle de publication

- [ ] `name` du frontmatter identique au nom du dossier
- [ ] Description : quoi + quand + différenciateur
- [ ] Description contenant les formulations déclenchantes réelles de l'utilisateur
- [ ] Pas de documentation humaine dans le dossier de compétence
- [ ] Pas d'information périssable (versions, tarifs, identifiants de modèles)
- [ ] Chemins relatifs uniquement
- [ ] Contrôle d'état avant action, là où c'est pertinent
- [ ] Boucle de validation documentée
- [ ] Format de sortie documenté si pertinent
- [ ] Testée avec un modèle faible et un modèle fort
- [ ] Testée pour le déclenchement ET pour l'exécution
- [ ] La compétence fait une seule chose
- [ ] Elle se compose proprement avec les compétences voisines
- [ ] Versionnée

Dans ce dépôt, `outils/valider-competences.sh` vérifie automatiquement les points
mécaniques de cette liste (nom/dossier, YAML, références cassées, titres dupliqués,
documentation humaine égarée). Lancez-le avant chaque commit.

---

## 13. Premiers principes, compressés

1. **La description route ; le corps exécute.** Réussissez les deux indépendamment.
2. **Les jetons sont rares ; les fichiers sont bon marché.** Poussez le détail hors du
   contexte jusqu'à ce qu'il soit nécessaire.
3. **Le déterminisme vient du code ; le jugement vient des prompts.** Mettez chacun à sa place.
4. **Une compétence, une préoccupation.** La composition bat l'empaquetage.
5. **Les agents n'ont pas de mémoire.** Utilisez des artefacts persistants pour leur en donner une.
6. **Le modèle sait déjà beaucoup.** Ne réenseignez pas. N'ajoutez que ce qui manque.
7. **Validez avant de conclure.** Les boucles d'autocorrection dominent la qualité de sortie.
8. **Les compétences sont du code.** Versionnez, testez, auditez et relisez-les comme tel.

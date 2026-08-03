---
name: audit-cyber
description: 'Audit de sécurité défensif d''un projet et de son outillage d''agents : secrets exposés, surface d''attaque propre aux agents IA (jetons, compétences, injection par contenu moissonné, serveurs MCP, permissions shell), dépendances, surface web publique. À utiliser sur « audit de sécurité », « audit cyber », « vérifie la sécurité du projet », « ai-je des secrets exposés », avant une mise en ligne publique ou après un incident. Défensif uniquement : produit un rapport et des correctifs, jamais d''exploitation.'
disable-model-invocation: true
---

# Audit de sécurité défensif

## Périmètre

**Défensif uniquement.** Cette compétence trouve des faiblesses dans un projet que
l'utilisateur possède et propose des correctifs. Elle n'exploite rien, ne teste rien contre
un système tiers, ne produit aucune charge utile.

Si l'utilisateur demande de tester un système qui ne lui appartient pas, arrêtez-vous et
demandez la preuve d'une autorisation écrite (périmètre, dates, commanditaire). Sans elle,
déclinez en une phrase et proposez l'audit défensif à la place.

## Principe d'organisation : l'irréversibilité, pas la sévérité

Les scores de sévérité classent mal le travail réel. Classez par **ce qui ne se rattrape
pas** :

1. **Déjà irréversible** — un secret publié est compromis, même supprimé depuis. Rien ne
   défait une divulgation. C'est la phase 1, et rien ne passe devant.
2. **Chemin vers l'irréversible** — un agent avec accès shell et un jeton en clair peut
   provoquer la catégorie 1 tout seul. C'est la phase 2, et c'est le point aveugle habituel.
3. **Exploitable à distance** — dépendances, surface web publique. Grave, mais on corrige et
   on redéploie.
4. **Durcissement** — en-têtes, permissions, configuration. Utile, jamais urgent.

Un rapport qui mélange ces quatre niveaux ne sera pas traité. Un rapport qui les sépare l'est.

## Phase 0 — cadrer

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "hors dépôt Git"
ls package.json requirements.txt pyproject.toml go.mod Gemfile Cargo.toml composer.json 2>/dev/null
```

Identifiez l'écosystème avant de choisir les outils : un audit lancé avec le mauvais
gestionnaire de paquets ne trouve rien et **donne une fausse assurance**, ce qui est pire
que pas d'audit du tout.

Demandez à l'utilisateur, en une question : ce projet est-il déjà public, et y a-t-il des
agents avec accès shell dessus ? Les deux réponses changent l'ordre des phases.

Commandes par écosystème : `references/commandes-par-ecosysteme.md`.

## Phase 1 — secrets exposés

Première phase parce que c'est la seule dont les conséquences sont déjà acquises au moment
de la découverte.

```bash
# fichiers d'environnement et clés suivis par Git
git ls-files | grep -E '(^|/)\.env($|\.)|\.pem$|\.p12$|\.pfx$|id_rsa|\.keystore$'

# motifs de secrets dans l'arbre de travail
# -i est OBLIGATOIRE : les secrets s'écrivent le plus souvent en majuscules
# (API_KEY, SECRET_KEY, DATABASE_PASSWORD). Sans -i, ce grep les rate tous.
grep -rInEi '(api[_-]?key|secret|token|passwd|password|bearer|private[_-]?key)[[:space:]]*[:=][[:space:]]*["'"'"'][A-Za-z0-9_/+\-]{16,}' \
  --exclude-dir={.git,node_modules,vendor,dist,build,.venv} . | head -40

# clés privées
grep -rl 'BEGIN .*PRIVATE KEY' --exclude-dir={.git,node_modules} . 2>/dev/null
```

**L'historique compte autant que l'arbre de travail.** Un secret retiré par un commit
ultérieur reste dans l'historique, donc dans tous les clones :

```bash
git log --all --oneline -S 'BEGIN RSA PRIVATE KEY' | head
git log --all --diff-filter=A --name-only --format= -- '*.env*' '*.pem' | sort -u | head
```

### Conduite à tenir sur un secret trouvé

**Un secret présent dans l'historique est compromis. Point.** Le dépôt a pu être cloné,
mis en cache, indexé, ou lu par un service tiers d'intégration continue. Nettoyer
l'historique ne défait rien de cela.

L'ordre correct, et il n'est pas négociable :

1. **Révoquer** la clé chez le fournisseur. En premier, avant tout le reste.
2. **Émettre** une nouvelle clé, la placer hors du dépôt.
3. **Vérifier les journaux d'accès** du fournisseur pour la période d'exposition. C'est
   l'étape que tout le monde saute, et la seule qui répond à « est-ce que ça a servi ? ».
4. **Ajouter le motif au `.gitignore`**, puis seulement envisager la réécriture d'historique.

Une réécriture d'historique sans rotation préalable est du théâtre : elle donne le sentiment
d'avoir agi sans rien changer au fait que la clé est dehors.

**Dans votre rapport, ne recopiez jamais un secret en clair.** Donnez le fichier, la ligne,
le type, et si possible les quatre premiers caractères. Un rapport d'audit qui contient les
secrets devient lui-même un secret.

## Phase 2 — surface d'attaque des agents

La partie que les audits génériques manquent, et la plus pertinente sur un poste où des
agents IA ont un accès shell.

### 2.1 Jetons dans la configuration des agents

Les agents stockent des identifiants sur disque. Ces fichiers ne sont pas dans le dépôt, ils
ne sont donc jamais audités — et ils donnent accès à tout.

```bash
ls -la ~/.claude ~/.codex ~/.pi/agent ~/.hermes ~/.cursor ~/.config/opencode 2>/dev/null
# les fichiers d'identifiants doivent être en 600
find ~/.claude ~/.codex ~/.pi ~/.hermes -maxdepth 2 \
  \( -name 'auth*' -o -name '*token*' -o -name '.env' -o -name '*credential*' \) \
  -exec ls -l {} \; 2>/dev/null
```

Contrôlez : droits trop larges, jetons dans des fichiers sauvegardés par un service de
synchronisation cloud, jetons dupliqués dans plusieurs agents (une rotation en oubliera un).
**N'affichez jamais le contenu de ces fichiers.**

### 2.2 Les compétences comme vecteur d'exécution

Une compétence peut exécuter du code arbitraire et orienter le comportement de l'agent.
Une compétence tierce installée sans lecture est un vecteur d'exfiltration.

```bash
# scripts embarqués dans les compétences installées
find ~/.agents/skills ~/.claude/skills -type f \( -name '*.sh' -o -name '*.py' -o -name '*.ts' \) 2>/dev/null

# appels réseau sortants dans ces scripts
grep -rInE '\b(curl|wget|fetch|requests\.|urllib|nc |socket)\b' \
  ~/.agents/skills 2>/dev/null | head -20

# instructions d'injection dans les fichiers de compétences
grep -rInE 'ignore (all )?(previous|prior|above) instructions|disregard .* instructions|tu es maintenant' \
  ~/.agents/skills 2>/dev/null
```

Contrôlez aussi les noms typosquattant une compétence connue, et les compétences épinglées
sur `latest` plutôt que sur un commit.

### 2.3 Injection de prompt par contenu ingéré

C'est la faiblesse structurelle des agents qui moissonnent le web. Une page, un ticket, un
commentaire de PR ou une transcription peuvent contenir des instructions rédigées pour
l'agent qui les lira.

Ce n'est pas un défaut à corriger dans le code, c'est une propriété à contenir par la
conception. Contrôlez que le projet respecte trois règles :

- **Le contenu récupéré est traité comme des données, jamais comme des instructions.**
  Si un flux concatène du contenu moissonné dans un prompt système, c'est un défaut.
- **Les actions à effet de bord ne sont jamais déclenchées par du contenu ingéré** sans
  confirmation humaine : envoi de courriel, publication, poussée, suppression, dépense.
- **Les données sensibles ne sont pas dans le même contexte que du contenu non fiable.**
  Un agent qui a lu une page web hostile et détient une clé d'API peut être amené à
  l'exfiltrer dans une URL.

Cherchez les concaténations suspectes :

```bash
grep -rInE '(system_?prompt|messages|instructions).{0,40}(scraped|fetched|crawl|content|body|html)' \
  --include='*.py' --include='*.ts' --include='*.js' --exclude-dir={node_modules,.venv} . | head
```

### 2.4 Serveurs MCP et permissions shell

```bash
grep -rIl 'mcpServers' ~/.claude ~/.cursor ~/.codex . 2>/dev/null | head
grep -rInE 'bypassPermissions|--yolo|--dangerously|skip-permissions|allowAll' \
  ~/.claude ~/.codex ~/.cursor . 2>/dev/null | head
```

Contrôlez : serveurs MCP tiers et leur portée réelle, drapeaux de contournement des
permissions laissés dans une configuration ou un script d'intégration continue, et
**présence effective du garde-fou de commandes** (voir la compétence `garde-fous-agents` —
son absence silencieuse est elle-même un constat d'audit).

### 2.5 Accès des agents aux systèmes de production

- Un agent dispose-t-il d'identifiants en écriture sur la base de production ?
  Il ne devrait avoir qu'un rôle en lecture seule (voir `role-bdd-lecture-seule`).
- Un jeton d'intégration continue avec droits d'écriture sur le dépôt est-il exposé aux
  exécutions déclenchées par des contributions externes ?
- Les actions tierces sont-elles épinglées à un commit plutôt qu'à une étiquette mobile ?

## Phase 3 — dépendances

Lancez l'outil de l'écosystème (`references/commandes-par-ecosysteme.md`).

Triez par **exploitabilité réelle**, pas par score brut. Une vulnérabilité critique dans une
dépendance de développement jamais expédiée compte moins qu'une vulnérabilité moyenne sur le
chemin de traitement des requêtes. **Dites-le explicitement dans le rapport**, sinon
l'utilisateur corrige dans l'ordre du score et perd son temps.

## Phase 4 — surface publique

Uniquement si le projet expose un service web.

```bash
curl -sSI https://votre-domaine/ | grep -iE 'content-security|strict-transport|x-content-type|referrer|permissions-policy'
```

Contrôlez : en-têtes de sécurité manquants ; `Access-Control-Allow-Origin: *` combiné à des
routes authentifiées ; points d'entrée d'administration ou de débogage sans authentification ;
messages d'erreur renvoyant des traces d'appels ou des chaînes de connexion ; absence de
limitation de débit sur l'authentification et la réinitialisation de mot de passe.

Revue de code, sans test actif : autorisation vérifiée **côté serveur** sur chaque route ;
identifiants d'objets contrôlés contre l'utilisateur courant ; session en cookies `httpOnly`
et `Secure` plutôt qu'en stockage local ; mots de passe hachés avec un algorithme lent dédié ;
requêtes de base de données paramétrées.

## Rapport

La hiérarchisation **est** la valeur ajoutée. Une liste plate de trente constats ne sera
pas traitée.

```markdown
# Audit de sécurité — <projet> — <date>

## Déjà irréversible — agir aujourd'hui
- <constat> — <fichier:ligne> — <exposition> — <rotation à faire>

## Chemin vers l'irréversible
- <constat> — <où> — <ce qu'un agent compromis pourrait en faire> — <correctif>

## Exploitable à distance
- …

## Durcissement
- …

## Vérifié, rien à signaler
- <ce qui a été contrôlé et qui est propre>

## Non couvert par cet audit
- <logique métier, infrastructure, chaîne d'approvisionnement, facteur humain…>
```

Pour chaque constat : **où**, **pourquoi c'est atteignable**, **quel correctif précis**.
Un constat sans correctif actionnable n'est pas un constat, c'est une inquiétude.

La section « vérifié, rien à signaler » n'est pas du remplissage : elle évite de
recontrôler la même chose au prochain audit, et elle délimite honnêtement ce que le rapport
couvre.

## Vérifier les correctifs

Un audit dont les correctifs ne sont pas revérifiés ne sert qu'une fois. Après application :

1. Rejouez la commande de détection exacte qui avait produit le constat. Elle doit être muette.
2. Pour un secret : confirmez que l'ancienne clé est **révoquée côté fournisseur**, pas
   seulement remplacée dans le fichier.
3. Pour une dépendance : relancez l'outil d'audit, et vérifiez que la mise à jour n'a pas
   introduit de régression.

## Règles

- **N'exploitez rien.** Démontrer une faille en l'exploitant, même sur un système de
  l'utilisateur, sort du périmètre.
- **N'affichez jamais un secret trouvé en clair**, ni dans le rapport, ni dans la
  conversation, ni dans un commit.
- **Ne corrigez pas silencieusement** un problème de sécurité au milieu d'autres
  modifications : signalez-le, corrigez-le explicitement, dites-le.
- **N'envoyez rien à un service tiers** — analyseur en ligne, service de vérification de
  fuites — sans l'accord explicite de l'utilisateur. Cela publierait précisément ce que
  vous auditez.
- **Ne prétendez jamais à l'exhaustivité.** Un audit automatisé trouve les défauts connus et
  courants. La section « non couvert » est obligatoire.

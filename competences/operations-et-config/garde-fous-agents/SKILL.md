---
name: garde-fous-agents
description: 'Une liste de refus partagée de commandes shell catastrophiques (rm -rf sur / ou ~, dd/mkfs, sudo rm, fork bombs, curl|sh, git push --force, gh repo delete) appliquée en garde pré-exécution sur tous les agents de code IA de la machine. À utiliser pour ajouter ou ajuster des motifs bloqués, câbler la garde sur un nouvel agent ou une nouvelle machine, déboguer pourquoi une commande a été (ou n''a pas été) bloquée, ou quand l''utilisateur mentionne garde-fou, command guard, hook de commande dangereuse, PreToolUse.'
---

# Garde-fous globaux des agents

Un « videur » qui bloque les commandes shell catastrophiques avant qu'un agent IA ne les
exécute. Un seul fichier de motifs est la source de vérité ; chaque agent le lit via un
script de hook partagé ou un petit adaptateur natif.

**C'est une ceinture de sécurité contre l'accident, PAS un bac à sable contre un agent
malveillant.** Une obfuscation du type `python3 -c "shutil.rmtree(…)"` passe à travers une
expression régulière. Ne présentez jamais cette garde comme une frontière de sécurité.

## Cartographie des fichiers

```
~/.agents/hooks/motifs-dangereux.txt        # LA liste : une regex POSIX-ERE par ligne
~/.agents/hooks/refus-dangereux.sh          # garde partagée : JSON sur stdin -> exit 2 bloque
~/.agents/hooks/test-garde.sh               # suite de tests : à lancer après TOUT changement
~/.config/opencode/plugins/command-guard.ts # adaptateur OpenCode (lève une exception)
~/.pi/agent/extensions/command-guard.ts     # adaptateur Pi (renvoie {block:true})
~/.hermes/plugins/command-guard/            # extension Hermes (renvoie {"action":"block"})
```

Les trois premiers fichiers sont fournis dans ce dépôt sous `hooks/`.

## Contrôle d'état : est-ce installé ?

```bash
ls ~/.agents/hooks/refus-dangereux.sh ~/.agents/hooks/motifs-dangereux.txt
~/.agents/hooks/test-garde.sh   # doit se terminer par « échoués : 0 »
```

Test direct du script, sans agent :

```bash
echo '{"tool_input":{"command":"rm -rf /"}}' | ~/.agents/hooks/refus-dangereux.sh; echo "sortie=$?"
# attendu : sortie=2
```

## Ajouter ou ajuster un motif

1. Éditez `motifs-dangereux.txt`. Écrivez en POSIX ERE (`grep -E`). **Utilisez
   `[[:space:]]`, jamais `\s`** — les adaptateurs convertissent automatiquement
   `[:space:]` en `\s` pour les moteurs JavaScript et Python.
2. Ajoutez des cas bloqués **et des cas autorisés** dans `test-garde.sh`, puis lancez-le.
   Il doit passer à 100 %. Les cas autorisés comptent autant que les cas bloqués : un
   motif trop large casse l'agent sans qu'on s'en rende compte.
3. Vérifiez que le nouveau motif compile dans les moteurs des adaptateurs :

   ```bash
   python3 -c 'import re,pathlib; [re.compile(l.strip().replace("[:space:]",r"\s")) for l in pathlib.Path.home().joinpath(".agents/hooks/motifs-dangereux.txt").read_text().splitlines() if l.strip() and not l.startswith("#")]; print("ok")'
   ```

4. Les changements s'appliquent instantanément partout (tous les consommateurs relisent le
   fichier à chaque commande). Exception : les agents à liste de blocage native intégrée à
   leur propre configuration doivent être mis à jour manuellement.

**Règle de conception** : ne bloquez que l'irréversible et le catastrophique (perte de
données, effacement disque, suppression de dépôt, exfiltration de jeton). Le
destructeur-mais-récupérable (`git clean -fdx`, `rm -rf node_modules`,
`docker system prune`) reste AUTORISÉ. **Sur-bloquer tue l'utilité de l'agent** et pousse
les utilisateurs à désactiver la garde entièrement — ce qui est bien pire.

## Câblage par agent (global utilisateur)

| Agent | Configuration | Événement | Blocage par |
|---|---|---|---|
| Claude Code | `~/.claude/settings.json` | `PreToolUse`, matcher `Bash` | script partagé, exit 2 |
| Codex CLI/app/IDE | `~/.codex/hooks.json` | `PreToolUse`, matcher `Bash` | script partagé, exit 2 |
| Cursor IDE + CLI | `~/.cursor/hooks.json` | `beforeShellExecution` | script partagé avec l'argument `cursor`, JSON de refus |
| Grok | charge les fichiers de hooks Claude + Cursor (compatibilité activée par défaut) | `PreToolUse` | script partagé (lit `.toolInput.command`) |
| OpenCode | `~/.config/opencode/plugins/command-guard.ts` | `tool.execute.before` | l'adaptateur lève une exception |
| Pi | `~/.pi/agent/extensions/command-guard.ts` | `pi.on("tool_call")` | l'adaptateur renvoie `{block:true}` |
| Hermes | `~/.hermes/plugins/command-guard/` | hook `pre_tool_call` | l'extension renvoie `{"action":"block"}` |
| Droid (Factory) | `~/.factory/settings.json` | `commandBlocklist` natif | blocage dur, aucune approbation possible |
| Devin CLI | `~/.config/devin/config.json` | `PreToolUse`, matcher `^exec$` | script partagé, exit 2 |

Forme de l'entrée de hook pour Claude / Codex / Devin (**fusionnez** dans l'objet `hooks`
existant, ne l'écrasez jamais) :

```json
{"hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "/CHEMIN/ABSOLU/HOME/.agents/hooks/refus-dangereux.sh"}]}]}}
```

Entrée Cursor (la charge utile porte `.command`, d'où l'argument `cursor`) :

```json
{"beforeShellExecution": [{"command": "/CHEMIN/ABSOLU/HOME/.agents/hooks/refus-dangereux.sh cursor", "failClosed": false}]}
```

**Utilisez des chemins absolus** dans les configurations : l'expansion de `~` est
incohérente entre agents.

## Pièges durement acquis

- **La confiance Codex est épinglée par empreinte.** Toute modification de l'ENTRÉE de hook
  dans `hooks.json` (pas du fichier de motifs) invalide la confiance ; lancez `/hooks` dans
  Codex et refaites confiance, sinon **Codex ignore silencieusement la garde**. Les
  empreintes vivent dans `[hooks.state]` de `~/.codex/config.toml` et sont partagées par
  la CLI, l'application et l'extension IDE.
- **`failClosed` doit rester à `false` chez Cursor.** Les hôtes d'arrière-plan de Cursor ne
  peuvent pas exécuter les scripts de hook ; en mode fermé, TOUTE commande y serait
  bloquée. Compromis assumé : les agents d'arrière-plan de Cursor tournent sans garde.
- **La clé du manifeste d'extension Hermes est `provides_hooks`** (pas `hooks`).
  L'extension doit être activée dans la liste `plugins.enabled` de `~/.hermes/config.yaml` ;
  la commande d'activation interactive bloque dans un shell non interactif. Les hooks
  Hermes sont **ouverts en cas d'exception** — gardez l'extension triviale.
- **Une erreur du gestionnaire `tool_call` de Pi bloque l'outil** (sécurité par défaut
  fermée). L'adaptateur doit donc attraper ses propres erreurs et échouer en mode ouvert,
  sinon un fichier de motifs cassé rend tous les appels shell impossibles.
- **Sémantique Droid** : `commandDenylist` = demander confirmation ; `commandBlocklist` =
  ne s'exécute jamais, même en autonomie totale. Utilisez la liste de blocage pour les
  entrées catastrophiques.
- **Détection de la charge utile** : la commande vit dans `.tool_input.command`
  (Claude/Codex/Devin), `.toolInput.command` (Grok), `.command` (Cursor). Gardez les trois
  dans la chaîne de repli.
- **Classe de faux positifs** : une commande inoffensive dont un ARGUMENT contient une
  chaîne dangereuse (par exemple passer une invite mentionnant `git push --force`) se fait
  bloquer. Contournement : mettez le texte dans un fichier et référencez-le.
- **Non couvrable nativement** : les agents sans système de hooks, ainsi que les tâches
  cloud et les agents d'arrière-plan, contournent la garde locale. Sachez-le et ne
  supposez pas une couverture universelle.

## Deux propriétés à ne pas casser

1. **La garde ne s'ouvre jamais en silence.** Une garde qui laisse tout passer sans le dire
   est pire que pas de garde : l'utilisateur se croit protégé. Sans `jq`, le script bascule
   sur `python3` ; si aucun analyseur JSON n'est disponible, il écrit un fichier témoin et
   un avertissement sur stderr au lieu d'autoriser discrètement. Si vous modifiez le script,
   conservez ce comportement.
2. **Les répertoires système sont couverts.** `rm -rf /usr`, `/etc`, `/var`, `/boot`,
   `/System`, `/Applications`, `/Library`, `/Volumes` sont bloqués à la racine et au niveau
   immédiatement en dessous, tout en laissant passer les chemins plus profonds légitimes
   (`/var/folders/T/mon-tmp`). Une liste qui ne couvre que `/` et `~` laisse passer des
   commandes tout aussi destructrices.

## Recette de vérification de bout en bout

Sonde sans risque : demandez à l'agent d'exécuter `git push --force` depuis un dossier qui
**n'est pas** un dépôt Git. Bloqué = la garde fonctionne ; « not a git repository » = la
garde a échoué, mais sans dégât.

```bash
cd "$(mktemp -d)"
claude -p 'Exécute exactement : git push --force. Rapporte le résultat en une ligne.' --permission-mode bypassPermissions
codex exec --skip-git-repo-check 'Exécute exactement : git push --force. Rapporte en une ligne.' < /dev/null
pi -p --no-session 'Exécute exactement : git push --force. Rapporte en une ligne.'
```

Pour les agents sujets au faux positif d'argument, mettez le texte de l'invite dans un
fichier et passez le fichier.

# Installation et connexion du pilote de navigateur

Ce fichier couvre **uniquement** l'installation, la connexion au navigateur et le dépannage
de connexion. Pour le travail quotidien, lisez `SKILL.md`.

## Table des matières

- [Installation](#installation)
- [Rendre le pilote global pour l'agent courant](#rendre-le-pilote-global-pour-lagent-courant)
- [Maintenir le pilote à jour](#maintenir-le-pilote-à-jour)
- [Architecture](#architecture)
- [Référence de connexion au navigateur](#référence-de-connexion-au-navigateur)
- [Première configuration et dépannage](#première-configuration-et-dépannage)

---

## Installation

Clonez le dépôt une fois dans un emplacement durable, puis installez-le en mode éditable
pour que la commande fonctionne depuis n'importe quel répertoire :

```bash
git clone https://github.com/browser-use/browser-harness
cd browser-harness
uv tool install -e .
command -v browser-harness
```

Le mode éditable garde la commande globale tout en pointant vers la copie de travail
réelle : quand l'agent modifie les utilitaires, l'appel suivant utilise immédiatement le
nouveau code. Préférez un chemin stable comme `~/Developer/browser-harness`, **pas
`/tmp`** — un pilote installé dans un répertoire temporaire disparaît au redémarrage.

## Rendre le pilote global pour l'agent courant

- **Codex** : ajoutez le `SKILL.md` comme compétence globale dans
  `$CODEX_HOME/skills/pilote-navigateur/SKILL.md` (souvent `~/.codex/skills/…`).
  Un lien symbolique convient :

  ```bash
  mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills/pilote-navigateur" \
    && ln -sf "$PWD/SKILL.md" "${CODEX_HOME:-$HOME/.codex}/skills/pilote-navigateur/SKILL.md"
  ```

- **Claude Code** : ajoutez un import dans `~/.claude/CLAUDE.md` pointant vers le
  `SKILL.md` du dépôt, par exemple `@~/Developer/browser-harness/SKILL.md`.

Les nouvelles sessions dans d'autres dossiers chargent alors automatiquement les
instructions du pilote.

## Maintenir le pilote à jour

- À chaque exécution, `browser-harness` affiche `update available: X -> Y` (une fois par
  jour) quand une version plus récente existe.
- Quand vous voyez cette bannière, lancez `browser-harness --update -y` vous-même — ne le
  demandez pas à l'utilisateur. La commande récupère le nouveau code et arrête le démon en
  cours pour que l'appel suivant utilise la nouvelle version. Avec `-y`, elle ne pose
  aucune question.
- `--update` **refuse** de s'exécuter sur une copie éditable avec des modifications non
  committées. Dans ce cas, dites-le à l'utilisateur et laissez-le résoudre son arbre de
  travail — ne committez pas ni ne remisez son travail à sa place.

Diagnostic : `browser-harness --doctor` affiche la version, le mode d'installation, l'état
du démon et de Chrome, et l'existence d'une mise à jour en attente.

## Architecture

```text
Chrome / navigateur cloud -> WebSocket CDP -> démon -> IPC -> exécuteur
```

- Le protocole est une ligne JSON dans chaque sens.
- Les requêtes sont `{method, params, session_id}` pour CDP, ou `{meta: …}` pour le
  contrôle du démon.
- Les réponses sont `{result}` / `{error}` / `{events}` / `{session_id}`.
- IPC : socket Unix `/tmp/bu-<NOM>.sock` sur les systèmes POSIX ; boucle locale TCP plus
  fichier de port sur Windows.
- `BU_NAME` isole les fichiers d'IPC, de PID et de journal du démon — c'est ce qui permet
  à plusieurs sous-agents de tourner en parallèle sans se marcher dessus.
- `BU_CDP_WS` remplace la découverte locale de Chrome pour un navigateur distant.
- `BU_CDP_URL` remplace la découverte locale par un point d'accès HTTP DevTools précis.
- `BU_BROWSER_ID` avec `BROWSER_USE_API_KEY` permet au démon d'arrêter un navigateur cloud
  à sa fermeture.

---

## Référence de connexion au navigateur

Le pilote peut se connecter à tout navigateur Chrome ou dérivé de Chromium présent sur la
machine, ou à un navigateur cloud.

### Navigateurs cloud

Gérés par une API cloud. Démarrez-en un avec `start_remote_daemon("travail", …)`.
L'authentification passe par la variable `BROWSER_USE_API_KEY` ; le pilote gère l'URL
WebSocket lui-même.

Pour transporter les cookies du Chrome local vers un navigateur cloud, installez l'outil de
synchronisation de profil une fois, puis :

```python
uuid = sync_local_profile("MonProfilChrome")
start_remote_daemon("travail", profileId=uuid)
```

**Seuls les cookies sont synchronisés** — ni le stockage local, ni les extensions, ni
l'historique.

### Navigateurs locaux

Le débogage distant doit être activé. Il y a deux voies, qui servent des usages différents.

#### Voie 1 : la case à cocher `chrome://inspect/#remote-debugging` — utilise votre vrai profil

Dans le Chrome en cours d'exécution, allez sur `chrome://inspect/#remote-debugging` et
cochez « Allow remote debugging for this browser instance ». Ce réglage est **par profil et
persistant** : cochez-le une fois et il survit à tous les lancements futurs de ce profil.
Lancez ensuite n'importe quelle commande du pilote.

Sur les versions récentes de Chrome, le premier rattachement déclenche une fenêtre
« Allow remote debugging ? » sur laquelle il faut cliquer. Elle peut réapparaître lors de
rattachements ultérieurs dans des conditions qui ne sont pas entièrement caractérisées.

Cette voie hérite des connexions, extensions, historique et favoris du Chrome quotidien :
c'est le bon choix quand l'agent aide l'utilisateur dans son vrai navigateur.

#### Voie 2 : l'option en ligne de commande — profil isolé, aucune fenêtre surgissante

Lancez Chrome avec `--remote-debugging-port=9222 --user-data-dir=<chemin>`.

Deux précisions qui font échouer la plupart des tentatives :

- Le chemin doit être un répertoire qui **n'est pas** le répertoire par défaut de Chrome
  pour la plateforme. Sur les versions récentes, l'option de port est **silencieusement
  ignorée** quand le répertoire de données est celui par défaut, même si vous la passez
  explicitement. Un chemin vide ou nouveau donne un profil propre que Chrome conservera.
- Cette voie **ne permet pas** de réutiliser votre profil Chrome quotidien. Copier les
  fichiers du profil par défaut dans un répertoire personnalisé fait accepter l'option,
  mais les cookies sont chiffrés avec une clé liée au répertoire d'origine et ne survivent
  pas à la copie : vous récupérez les favoris et les extensions, et vous perdez toutes les
  sessions connectées. Si vous voulez vos vraies connexions, utilisez la voie 1.

Indiquez le port au pilote en définissant `BU_CDP_URL=http://127.0.0.1:9222` avant de
lancer la commande.

### Choisir

Pour les tâches où l'agent agit pour le compte de l'utilisateur dans son navigateur
habituel : **voie 1**. Pour de l'automatisation sans surveillance, ou tout cas où une
interruption par fenêtre surgissante est inacceptable : **voie 2** ou un navigateur cloud.

---

## Première configuration et dépannage

Essayez vous-même avant de demander quoi que ce soit à l'utilisateur. Réessayez brièvement
les erreurs transitoires. Ne sollicitez l'utilisateur que quand une étape l'exige vraiment
— cocher une case, cliquer sur « Autoriser ».

Si l'utilisateur n'a pas indiqué de méthode de connexion : voie 1 par défaut si Chrome
tourne déjà, voie 2 sinon. Le cloud n'est utilisé que s'il le demande.

1. **Essayez le pilote :**

   ```bash
   browser-harness -c 'print(page_info())'
   ```

   S'il affiche les informations de page, c'est terminé.

2. **Sinon, lancez `browser-harness --doctor`.** Les deux lignes qui comptent pour la
   connexion sont `chrome running` et `daemon alive`.

3. **Faites correspondre la sortie à un cas :**

   - **`chrome` en échec** → aucun processus Chrome détecté.
     - *Voie 1* : demandez à l'utilisateur d'ouvrir lui-même son Chrome cible.
     - *Voie 2* : lancez Chrome vous-même avec `--remote-debugging-port=9222
       --user-data-dir=<chemin non par défaut>`, puis définissez
       `BU_CDP_URL=http://127.0.0.1:9222`.

   - **`chrome` OK, `daemon` en échec** → la configuration de la voie 1 est incomplète.
     Demandez à l'utilisateur de :
     - naviguer vers `chrome://inspect/#remote-debugging` et cocher la case si ce n'est
       pas déjà fait (une seule fois par profil) ;
     - cliquer sur « Autoriser » dans la fenêtre surgissante si elle apparaît.

     Sur macOS, vous pouvez ouvrir la page d'inspection dans son Chrome vous-même plutôt
     que de lui demander de naviguer :

     ```bash
     osascript -e 'tell application "Google Chrome" to activate' \
               -e 'tell application "Google Chrome" to open location "chrome://inspect/#remote-debugging"'
     ```

   - **`chrome` OK, `daemon` OK, mais l'étape 1 échoue toujours** → démon périmé.
     Redémarrez-le :

     ```bash
     browser-harness -c 'restart_daemon()'
     ```

     Si cela reste bloqué, escaladez : tuez tous les processus Chrome et le démon, rouvrez
     Chrome et réessayez. Sur macOS et Linux, supprimez aussi `/tmp/bu-default.sock` et
     `/tmp/bu-default.pid` s'ils traînent.

4. **Après toute correction, refaites l'étape 1.**

Si la voie 1 échoue de façon répétée, ou si la tâche de l'utilisateur doit tourner sans
surveillance, passez à la voie 2 ou à un navigateur cloud : aucune des deux n'affiche de
fenêtre surgissante.

Pour un premier test de connexion, ouvrez une page connue dans un nouvel onglet et
activez-le (`switch_tab`) pour que l'utilisateur voie que le pilote s'est rattaché.
Demandez-lui ensuite ce qu'il veut faire.

---
name: pilote-navigateur
description: 'Pilotage direct du navigateur via CDP (browser-harness). À utiliser quand l''utilisateur veut automatiser, tester ou interagir avec des pages web : clics, connexions, formulaires, flux riches en JavaScript, sessions authentifiées, vérification visuelle. Se connecte au Chrome déjà ouvert de l''utilisateur. Différenciateur : pour du simple contenu de page sans interaction, utiliser le moissonnage DeepAPI, pas un vrai navigateur.'
---

# Pilote de navigateur (CDP)

Pilotage direct du navigateur via le protocole DevTools de Chrome. Installation, connexion
et dépannage : `references/installation.md`.

**Vérification de routage, d'abord.** Si la tâche ne demande aucune interaction (pas de
clic, pas de connexion, pas de formulaire) et que vous voulez seulement le contenu de la
page, utilisez `POST /v1/scrape/website` — voir la compétence `deepapi`. Un vrai navigateur
coûte du temps et de la fragilité : ne le sortez que quand la tâche l'exige réellement.

Utilisez ce pilote quand il faut : une interaction, un flux riche en JavaScript, une
session authentifiée, ou une vérification visuelle.

Pour du contenu de site sans interaction, un acteur de moissonnage Apify est une autre
option côté serveur — voir la compétence `apify`. Elle ne remplace pas ce pilote : les
sessions authentifiées de l'utilisateur restent son domaine exclusif.

## Usage

```bash
browser-harness -c '
new_tab("https://exemple.com")
wait_for_load()
print(page_info())
'
```

- Invoquez `browser-harness` directement — il est sur le `PATH`. Pas de `cd`, pas de `uv run`.
- **La première navigation est `new_tab(url)`, pas `goto_url(url)`** : `goto_url` s'exécute
  dans l'onglet actif de l'utilisateur et détruit son travail en cours.
- Le démon démarre tout seul ; vous n'avez jamais à le lancer ou l'arrêter manuellement.

## Ce qui marche vraiment

- **Les captures d'écran d'abord.** `capture_screenshot()` est le moyen le plus rapide de
  comprendre l'état de la page, de trouver les cibles visibles, et de décider s'il faut un
  clic, un sélecteur, ou plus de navigation.
- **Cliquer** : `capture_screenshot()` → lire les coordonnées sur l'image →
  `click_at_xy(x, y)` → `capture_screenshot()` pour vérifier. Réprimez le réflexe
  Playwright « localiser d'abord, cliquer ensuite » : pas de `getBoundingClientRect`, pas
  de chasse au sélecteur. Le test de survol se fait dans le processus navigateur de Chrome,
  donc les clics traversent les iframes, le shadow DOM et les origines croisées sans
  travail supplémentaire.
- **Descendez au DOM** seulement quand la cible n'a pas de géométrie visible (champ caché,
  nœud de taille nulle).
- **HTTP en masse** : `http_get(url)` avec un pool de threads. Pas de navigateur pour des
  pages statiques — des centaines de pages en quelques secondes.
- **Après une navigation** : `wait_for_load()`.
- **Onglet périmé ou interne** : `ensure_real_tab()`. Le démon se rattrape aussi tout seul
  sur les sessions périmées au prochain appel.
- **Vérification** : `print(page_info())` répond à « est-ce vivant ? », mais la capture
  d'écran reste la façon par défaut de vérifier qu'une action visible a bien eu lieu.
- **Lectures DOM** : `js(…)` pour l'inspection et l'extraction quand la capture montre que
  les coordonnées ne sont pas le bon outil.
- **Sites en iframes** (consoles d'administration cloud, CRM) : `click_at_xy(x, y)`
  traverse ; ne descendez au DOM de l'iframe que si le clic par coordonnées ne convient pas.
- **CDP brut** pour tout ce que les utilitaires ne couvrent pas : `cdp("Domaine.methode", params)`.

**Mur d'authentification** : si vous êtes redirigé vers une page de connexion, **arrêtez-vous
et demandez à l'utilisateur**. Ne saisissez jamais d'identifiants lus sur une capture d'écran.

## Extraction de contenu authentifié

Le pilote se connecte au vrai navigateur de l'utilisateur avec ses sessions actives : c'est
le bon outil pour extraire du contenu de sites derrière une connexion, là où un moissonnage
serveur échoue.

```bash
browser-harness -c '
new_tab("https://exemple.com/contenu-prive")
wait_for_load()
import time
time.sleep(5)  # laisser les pages riches en JS se rendre
texte = js("""
    const article = document.querySelector("article");
    if (article) return article.innerText;
    return document.body.innerText;
""")
with open("/tmp/extrait.txt", "w") as f:
    f.write(texte)
print("Écrit", len(texte), "caractères")
'
```

- **Écrivez dans un fichier temporaire** pour éviter les problèmes d'échappement shell sur
  de gros volumes de texte, et pour ne pas saturer le contexte.
- Utilisez `time.sleep()` généreusement sur les applications monopage riches en JavaScript
  (3 à 5 secondes sont souvent nécessaires).
- `js(…)` avec `innerText` récupère tout, y compris le contenu sous la ligne de flottaison.

## Navigateurs distants

À utiliser pour des sous-agents parallèles (chacun obtient son navigateur isolé via un
`BU_NAME` distinct) ou sur un serveur sans interface graphique.
`BROWSER_USE_API_KEY` doit être définie.

```bash
browser-harness -c '
start_remote_daemon("travail")                                   # défaut — navigateur propre, sans profil
# start_remote_daemon("travail", profileName="mon-profil")       # réutiliser un profil cloud (déjà connecté)
# start_remote_daemon("travail", proxyCountryCode="fr", timeout=120)
# start_remote_daemon("travail", proxyCountryCode=None)          # désactiver le proxy
'

BU_NAME=travail browser-harness -c '
new_tab("https://exemple.com")
print(page_info())
'
```

`start_remote_daemon` affiche une URL de visualisation en direct et l'ouvre localement si
une interface graphique est détectée, pour que l'utilisateur puisse suivre. Sur un serveur
sans interface, l'URL est seulement affichée : transmettez-la à l'utilisateur.

**Les démons distants sont facturés jusqu'à leur expiration.** Le démon demande l'arrêt du
navigateur cloud à la fermeture, ce qui persiste aussi l'état du profil — mais un démon
oublié coûte de l'argent. Vérifiez-le avant de terminer une session.

Quand vous supervisez ces sous-agents, envoyez après chaque vérification **une seule
ligne** de statut : ce qu'ils font et s'ils sont sur la bonne voie.

Note Claude Code dans cmux : après avoir terminé, Claude peut pré-remplir un message
utilisateur prédit. Ce brouillon vient de Claude, pas de l'utilisateur.

## Mécaniques d'interface

Si vous butez sur une mécanique précise pendant la navigation, le projet browser-harness
fournit des fiches réutilisables (`interaction-skills/`) couvrant : connexion, cookies, iframes et
iframes multi-origines, boîtes de dialogue, téléchargements, glisser-déposer, listes
déroulantes, requêtes réseau, impression en PDF, synchronisation de profils, captures
d'écran, défilement, shadow DOM, onglets, téléversements, fenêtre d'affichage.

Consultez-les **avant** d'inventer un contournement spécifique à un cadriciel : c'est là
que vit la connaissance sur les listes déroulantes, les dialogues, les iframes et les
formulaires.

## Contraintes de conception (à ne pas contourner)

- **Les clics par coordonnées sont le défaut.** L'envoi d'événements souris passe à travers
  les iframes, le shadow DOM et les origines croisées au niveau du compositeur.
- **Connectez-vous au Chrome de l'utilisateur.** Ne lancez pas votre propre navigateur.
- **Gardez le lanceur minimal.** Pas d'analyse d'arguments, pas de sous-commandes, pas de
  couche de contrôle supplémentaire.
- **N'ajoutez pas de couche de gestion** : pas de cadriciel de nouvelles tentatives, pas de
  gestionnaire de session, pas de superviseur de démon, pas de système de configuration,
  pas de cadriciel de journalisation. Chacune de ces couches est une source de panne
  supplémentaire pour un gain marginal.
- Les ajouts d'utilitaires spécifiques à une tâche vont dans l'espace de travail de l'agent,
  pas dans le paquet cœur.

## Pièges éprouvés

- **Brave** fonctionne exactement comme Chrome : activez le débogage distant sur
  `brave://inspect/#remote-debugging` (même case à cocher). Le pilote découvre
  automatiquement le dossier de profil de Brave.
- **Les fenêtres surgissantes de la barre d'adresse sont de fausses cibles de page.**
  Filtrez les cibles internes (`chrome://omnibox-popup…`) quand vous cherchez un vrai onglet.
- **L'ordre des cibles CDP ne correspond PAS à l'ordre visible des onglets.** Quand
  l'utilisateur dit « le premier onglet que je vois », il faut passer par l'automatisation
  de l'interface ; `Target.activateTarget` ne fait qu'afficher une cible déjà connue.
- **Les sessions du démon par défaut peuvent devenir périmées.** `ensure_real_tab()` se
  rattache à une vraie page.
- **L'API du service distant est en camelCase sur le fil** : `cdpUrl`, `proxyCountryCode`.
- **L'URL CDP distante est en HTTPS, pas en WebSocket.** Résolvez l'URL WebSocket via
  `/json/version`.
- **Après chaque action significative, refaites une capture** avant de supposer qu'elle a
  fonctionné. Servez-vous de l'image pour vérifier l'état, les menus ouverts, la
  navigation, les erreurs visibles.
- **Piège de frontmatter** : le paquet browser-harness livre `name: browser` dans son frontmatter, ce
  qui entre en collision avec la boîte à outils `browser` intégrée de certains agents. En
  copiant la compétence, renommez-la (`pilote-navigateur` ici) pour éviter que l'agent ne
  masque ses propres outils.

## Fiches par site (optionnel)

Certaines installations embarquent des fiches communautaires par site. Elles sont
**désactivées par défaut** ; activez-les avec `BH_DOMAIN_SKILLS=1`.

Quand elles sont activées et que la tâche est spécifique à un site, **lisez tous les
fichiers de la fiche correspondante avant d'inventer une approche**.

Si vous apprenez quelque chose de non évident — une API interne, un sélecteur stable, un
travers de cadriciel, un motif d'URL, une attente cachée, un piège propre au site —
contribuez-le. Consignez la **forme durable** du site (la carte, pas le journal de bord).
N'écrivez jamais de coordonnées en pixels (elles cassent au moindre changement de mise en
page), de narration de tâche, ni de secrets : ces dossiers sont publics.

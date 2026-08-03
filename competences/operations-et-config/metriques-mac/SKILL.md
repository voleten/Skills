---
name: metriques-mac
description: 'Construire un collecteur de métriques système local et permanent sur un Mac (CPU, GPU, RAM, disque, réseau, batterie, thermique) : binaire compilé, lancé par launchd toutes les 60 secondes, stocké en SQLite, sauvegardé vers un dépôt Git privé. À utiliser quand quelqu''un veut un suivi de performance Mac sur la durée, demande comment ce type de collecteur fonctionne, ou veut le mettre en place sur une nouvelle machine. Différenciateur : couvre l''architecture et la philosophie d''installation, pas l''interrogation quotidienne d''une installation existante.'
---

# Collecteur de métriques Mac

Comment construire un collecteur de métriques Mac à faible surcoût, sur la durée, que vous
possédez entièrement. Aucun cloud, aucune télémétrie, aucun compte : un binaire, un fichier
SQLite, deux tâches launchd, un dépôt Git privé.

## Philosophie (à lire avant de construire)

1. **Local et déterministe.** Le collecteur ne fait **jamais** d'appel réseau, n'utilise
   jamais de LLM, n'envoie jamais d'analytique. N'importe qui doit pouvoir lire le code et
   prédire exactement ce qu'il écrit.
2. **Les données vivent hors du dépôt**, dans `~/Library/Application Support/<projet>/`,
   pour que les réinstallations et les opérations Git ne touchent jamais aux mesures.
3. **Le faible surcoût est une exigence dure.** Un échantillon par minute, compilation en
   mode release, `LowPriorityIO`. **Le moniteur ne doit jamais devenir la charge** — sinon
   il mesure surtout lui-même.
4. **Les lectures non documentées restent nullables et échouent bruyamment.** L'utilisation
   GPU et les températures SMC passent par des interfaces privées qui peuvent casser à
   chaque mise à jour de macOS. Stockez-les en colonnes nullables et faites remonter les
   erreurs — **ne fabriquez jamais de valeurs de remplacement**, sinon vos graphiques
   mentiront sans que personne ne s'en aperçoive.
5. **Les décisions sont écrites.** Chaque choix d'architecture donne un ADR dans
   `docs/adr/` ; chaque changement de schéma donne un fichier SQL numéroté dans
   `docs/base-de-donnees/`. Agents et humains suivent les ADR comme des contrats.
6. **Le suivi par processus est optionnel.** La collecte système est le défaut ; surveiller
   une application précise est un collecteur séparé et isolé, ajouté par son propre ADR.

## Structure du dépôt

```
Sources/<Bibliotheque>/   # échantillonneurs, stockage SQLite, génération de rapports
Sources/<projet-cli>/     # CLI mince : collect | doctor | report
launchd/                  # modèles de plist avec des jetons __SUBSTITUANT__
scripts/                  # installer.sh, desinstaller.sh, synchroniser.sh
docs/adr/                 # décisions d'architecture numérotées
docs/base-de-donnees/     # migrations SQL numérotées
sauvegardes/              # instantanés SQLite suivis par Git (écrits par la synchronisation)
```

Swift avec SwiftPM est le choix naturel (API IOKit et Mach natives, zéro dépendance), mais
l'architecture fonctionne dans n'importe quel langage compilé. Un langage interprété
convient moins : le coût de démarrage de l'interpréteur, payé chaque minute, devient
comparable au travail utile.

## Collecte de données

- Échantillonnez **à l'échelle du système** : CPU %, GPU %, mémoire (utilisée, verrouillée,
  compressée, pression), swap, capacité disque et compteurs d'E/S, compteurs réseau,
  batterie, état thermique, températures, vitesse des ventilateurs.
- Stockez les compteurs cumulatifs du système d'exploitation (disque, réseau) en **deltas
  par intervalle**. Un compteur cumulatif brut est inutilisable après un redémarrage.
- Une ligne par minute dans SQLite (mode WAL). Une année ne fait qu'environ 500 000
  lignes — ajoutez une table d'agrégation à 15 minutes pour que les rapports sur longue
  période restent rapides.
- Verbes de la CLI : `collect` (un échantillon puis sortie), `doctor` (affiche une lecture
  en direct et échoue bruyamment sur un échantillonneur cassé), `report --hours N`
  (résumé texte).

## Les deux tâches launchd

Toutes deux sont des agents de lancement utilisateur dans `~/Library/LaunchAgents/` — pas
de root, pas de démon système. Les modèles vivent dans le dépôt ; `installer.sh` remplit
les substituants.

**1. Le collecteur** — lance le binaire avec `collect` toutes les 60 secondes :
`RunAtLoad true`, `StartInterval 60`, `ProcessType Background`, `LowPriorityIO true`,
sortie standard et erreurs vers `~/Library/Logs/<projet>/`.

Le processus tourne moins d'une seconde puis se termine ; **launchd est l'ordonnanceur**.
Un `launchctl list` affichant un PID `-` avec un statut `0` est le signe d'une tâche saine,
pas d'une tâche morte.

**2. La synchronisation Git** — lance `scripts/synchroniser.sh` toutes les 3 heures
(`StartInterval 10800`) :

```bash
# instantané sûr pendant que la base est vivante, puis normalisation pour Git
sqlite3 "$chemin_base" ".backup '$temp'"
sqlite3 "$temp" 'PRAGMA journal_mode=DELETE;'   # replier le WAL dans un seul fichier
mv -f "$temp" sauvegardes/metriques.sqlite3
# committer UNIQUEMENT le chemin des sauvegardes, sauter si rien n'a changé
git add sauvegardes && git commit -m "Sauvegarde $(date '+%Y-%m-%d %H:%M')" -- sauvegardes
git push origin HEAD
```

**Ne copiez jamais une base SQLite vivante avec `cp`** — utilisez toujours `sqlite3
.backup`. Une copie brute pendant une écriture WAL produit un fichier corrompu qui
paraît valide jusqu'au jour où vous en avez besoin.

**Gardez le dépôt privé** : les métriques révèlent vos habitudes d'activité quotidiennes.

## Motif de `installer.sh`

```bash
swift build -c release
# exécuter le binaire depuis Application Support, PAS depuis le dossier de compilation,
# pour qu'une reconstruction ou un changement de branche ne casse jamais la tâche en cours
install -m 755 .build/release/<projet> "$dossier_donnees/bin/"
install -m 644 launchd/<etiquette>.plist ~/Library/LaunchAgents/
sed -i '' -e "s|__EXECUTABLE__|$binaire|" ... "$chemin_agent"   # remplir les substituants
plutil -lint "$chemin_agent"                                     # valider AVANT de charger
launchctl bootout "gui/$UID" "$chemin_agent" 2>/dev/null || true # réinstallation idempotente
launchctl bootstrap "gui/$UID" "$chemin_agent"
```

`desinstaller.sh` fait l'inverse : décharger les deux agents, supprimer les plists.
Utilisez une étiquette en DNS inversé (`com.<votrenom>.<projet>`).

## Vérifier l'installation

```bash
launchctl list | grep <projet>          # statut de sortie 0 = dernière exécution correcte
sqlite3 "$base" "SELECT datetime(MAX(timestamp),'unixepoch','localtime') FROM echantillons;"
# doit avoir moins d'une minute ; lancez aussi le verbe doctor
```

Si les échantillons s'arrêtent, regardez `~/Library/Logs/<projet>/stderr.log` **en premier** :
c'est presque toujours là que se trouve la réponse.

## Optionnel : moniteur isolé par application

Pour surveiller une application précise (par exemple un éditeur Electron qui fuit en
mémoire), ajoutez un collecteur optionnel séparé avec son propre schéma, son script
d'installation et son ADR.

Trouvez les processus de l'application **par chemin de paquet, jamais par sous-chaîne de
nom** — une correspondance par nom attrape des processus système sans rapport. Lisez les
CPU, RSS et E/S par processus via les API système dédiées (`proc_pid_rusage`,
`proc_pidinfo`) : c'est bon marché et sans droits root. **Ne lancez jamais `ps` en boucle** :
c'est en soi une cause connue de ralentissement.

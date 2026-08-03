---
name: planification-agent
description: 'Faire tourner un agent IA selon un horaire, une boucle ou un intervalle — cron, battements de cœur, vérifications autonomes récurrentes. À utiliser pour « lance ça toutes les N minutes », « planifie une tâche », « fais tourner en boucle », « heartbeat », « run every N minutes », « schedule a task ». Couvre les horloges externes (Claude Code, Codex, Pi) face aux planificateurs intégrés.'
---

# Planification et boucles d'agents

Première question : l'agent a-t-il un planificateur intégré (→ camp B) ou devez-vous
fournir l'horloge vous-même (tout le reste → camp A) ?

Plancher universel : cron descend à 1 minute (expression à 5 champs, pas de secondes),
dans tous les camps. En dessous de la minute, il faut une boucle `while … ; sleep N ; done`,
une extension TypeScript, ou un hook événementiel. Ne mettez jamais un LLM sur un
minuteur serré : le coût en jetons croît linéairement avec la fréquence, pas avec l'utilité.

## Camp A — agents à exécution unique, vous tenez l'horloge

Ces agents s'exécutent une fois puis se terminent (amnésiques sauf reprise explicite).

```bash
claude -p "PROMPT" --output-format json --allowedTools "Read,Edit,Bash"  # Claude Code
codex exec --json "PROMPT"                                              # Codex
pi run "PROMPT"                                                         # Pi
```

Enveloppez-les dans une horloge :

```bash
# 1. cron (plancher : 1 min)
*/10 * * * * cd /chemin/du/projet && pi run "vérifie X et rapporte" >> ~/agent.log 2>&1

# 2. minuteur systemd (Linux : survit au redémarrage, meilleurs journaux)
#    OnUnitActiveSec=10min

# 3. boucle simple (sous la minute, ou cron indisponible)
while true; do pi run "vérifie X"; sleep 30; done
```

Pièges — chacun casse silencieusement une exécution non surveillée :

- **Les demandes de permission bloquent indéfiniment.** Passez `--allowedTools`
  (Claude) ou les options de bac à sable / approbation automatique (Codex),
  sinon l'exécution attend une réponse humaine qui ne viendra jamais.
- **Utilisez une sortie JSON** (`--output-format json` / `--json`) pour que l'enveloppe
  analyse le résultat de façon déterministe plutôt qu'en devinant dans du texte libre.
- **Chaque exécution est amnésique.** Reprenez la session (`codex exec resume --last`)
  ou persistez l'état dans un fichier que l'exécution suivante relit.
- **Empêchez les recouvrements.** Une exécution plus lente que l'intervalle finit par
  se marcher dessus. Posez un verrou :

```bash
# `flock` sur Linux ; sur macOS, un répertoire de verrou fait l'affaire
exec 9>/tmp/mon-agent.lock
flock -n 9 || exit 0
pi run "vérifie X"
```

Pi n'a **aucun** planificateur, boucle ou battement de cœur intégré, par conception :
horloge externe uniquement (ou extension TypeScript pour des minuteurs côté agent).

### Orchestrateurs de terminaux (cmux et similaires) — pas de planificateur

Un orchestrateur de panneaux n'est pas un planificateur : ni minuteur, ni watch, ni cron.
Trois façons de le boucler, par ordre de préférence croissante :

1. Piloté par l'orchestrateur : `send` → `sleep` → lecture d'écran, sur votre horloge.
2. Enveloppe `while` + `sleep` bête et méchante.
3. **Préféré** : événementiel via une notification et des hooks de terminal — moins cher
   et plus réactif que le sondage.

La lecture d'écran est non intrusive : elle peut être sondée sans risque.

## Camp B — planificateur intégré

Certains agents (Hermes, par exemple) embarquent une passerelle qui bat toutes les
60 secondes et lance les tâches dues dans des sessions fraîches et isolées.

```bash
hermes gateway install                    # au niveau utilisateur (--system pour survivre au reboot)
hermes cron create "every 1h" "résume les nouveaux courriels et rapporte"
hermes cron create "0 9 * * *" "publie le point quotidien"
hermes cron create "30m" "rappel unique dans 30 minutes"
```

Ce que permet un planificateur intégré et qu'une horloge externe ne fait pas facilement :

- **Mode zéro jeton** : exécuter un script et livrer sa sortie telle quelle, sans appel
  au modèle. C'est le bon mode pour un chien de garde.
- **Chaînage** : la sortie d'une tâche alimente le contexte de la suivante.
- **Boucles auto-terminantes** et garde-fous (une session planifiée ne peut pas créer
  d'autres tâches cron — ne planifiez donc jamais depuis l'intérieur d'une tâche planifiée).

Chaque exécution est une session fraîche : le prompt doit porter tout le contexte.

## Motif du battement de cœur

Un tic rapide et récurrent arbitre de nombreuses vérifications plus lentes : il lit une
liste de tâches avec leur horodatage `derniere_execution` et n'agit que sur celles qui
sont dues. Définissez des heures d'activité, et **restez silencieux quand rien n'est dû** —
un rapport « rien à signaler » toutes les cinq minutes est du bruit qui finit par être ignoré.

Un tic de chien de garde se réduit à une commande dont la sortie est livrée telle quelle.
Gardez-la à un seul appel, bon marché, sans authentification :

```bash
curl -s --max-time 10 https://exemple.com/v1/health   # n'alerter que si la réponse n'est pas « ok »
```

## Superviser une boucle qui surveille un autre agent

À chaque vérification, envoyez à l'utilisateur **une seule ligne** de statut : ce que
l'agent fait, et s'il est sur la bonne voie. Rien de plus.

## Vérifier que ça se déclenche (avant d'annoncer que c'est en place)

1. **Camp A** : le fichier de journal grossit après un intervalle, ou l'exécution
   manuelle de la commande enveloppée renvoie du JSON propre et un code de sortie 0.
2. **Camp B** : la liste des tâches montre le travail avec un `next_run` cohérent ;
   déclenchez une exécution immédiate pour confirmer la livraison.
3. Confirmez la présence des options de permission / bac à sable — la panne
   silencieuse numéro un est une demande de permission restée en attente.
4. Battements de cœur : confirmez qu'un tic sans tâche due reste silencieux.
5. Vérifiez le comportement au redémarrage si la tâche doit y survivre
   (`crontab -l`, `systemctl --user is-enabled`, `launchctl print`).

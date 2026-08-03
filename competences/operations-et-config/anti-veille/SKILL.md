---
name: anti-veille
description: 'Empêcher de façon fiable la mise en veille du Mac de l''utilisateur avec caffeinate, pour une durée fixée ou tant qu''un processus tourne. À utiliser pour « empêche mon Mac de dormir », « garde l''écran allumé », « anti-veille », « caffeinate », un travail de nuit, ou une compilation longue. Différenciateur : contrairement à une tâche d''arrière-plan ordinaire, cette méthode survit au nettoyage des shells temporaires des agents.'
---

# Anti-veille (macOS, caffeinate)

Utilisez le lanceur fourni dans ce dossier de compétence. Il crée un agent de lancement
utilisateur à usage unique, avec les seuls outils intégrés de macOS.

**Ne lancez jamais `caffeinate` avec un `&` brut, `nohup`, `disown` ou `launchctl submit`.**
Les shells d'exécution temporaires peuvent tuer leurs descendants, et `launchctl submit`
peut relancer une tâche minutée après son expiration.

Résolvez `scripts/anti-veille.sh` relativement à ce `SKILL.md` ; ne supposez jamais le
répertoire courant de l'utilisateur.

## Procédure

1. **Inspectez l'état courant :**

   ```bash
   scripts/anti-veille.sh status
   ```

2. **Démarrez la nouvelle temporisation.** Si une session est déjà active et que
   l'utilisateur demande une nouvelle durée, `start` la remplace automatiquement.
   **Ne demandez jamais de confirmation** pour ce remplacement — l'utilisateur vient
   d'exprimer son intention.

   ```bash
   scripts/anti-veille.sh start 10800    # 3 heures
   ```

   Pour suivre un processus précis, utilisez `start-pid` :

   ```bash
   scripts/anti-veille.sh start-pid <PID>
   ```

   Pour refuser explicitement le remplacement d'une session active, utilisez
   `--no-replace` : le script échoue alors au lieu de remplacer.

3. **Vérifiez, dans un appel d'outil ou de shell SÉPARÉ**, après le retour de `start` :

   ```bash
   scripts/anti-veille.sh verify
   ```

   **N'annoncez un succès que si la vérification renvoie `STATUT=actif` et
   `ASSERTIONS=actives`.** Confirmez le PID, les options et l'heure d'expiration. Si la
   vérification échoue, lancez `stop` et ne prétendez pas que le Mac est protégé.

## Options d'assertion

Le défaut est `-d -i` : garder l'écran allumé et empêcher la veille système par inactivité.
Passez les options explicitement après la durée ou le PID si nécessaire.

| Options | Effet |
|---|---|
| `-i` | Empêche la veille système par inactivité ; l'écran peut s'éteindre |
| `-d` | Empêche la veille de l'écran |
| `-d -i -s` | Empêche aussi la veille système sur secteur |

```bash
scripts/anti-veille.sh start 10800 -i
```

## Arrêter

```bash
scripts/anti-veille.sh status
scripts/anti-veille.sh stop
```

Le lanceur suit une étiquette d'agent de lancement exacte, un PID, une heure de début et
une heure d'expiration, stockés sous `~/Library/Caches`. **Il n'utilise jamais un `pkill`
large** — un `pkill caffeinate` tuerait aussi les sessions lancées par d'autres outils.

## Repli

Si `launchctl bootstrap` échoue, utilisez un terminal persistant visible. Si aucune surface
persistante n'est disponible, **dites-le à l'utilisateur** plutôt que de démarrer une tâche
d'arrière-plan peu fiable qui donnera une fausse impression de protection.

`caffeinate` ne peut pas garder le rétroéclairage du clavier allumé. Ce réglage est
manuel : Réglages Système → Clavier → « Éteindre le rétroéclairage après inactivité » →
Jamais.

## Personnalisation

L'étiquette de l'agent de lancement est configurable par la variable d'environnement
`ANTI_VEILLE_LABEL` (défaut : `local.anti-veille`). Renseignez votre préfixe dans
`PROFIL.md` à la racine du dépôt si vous voulez un identifiant en DNS inversé.

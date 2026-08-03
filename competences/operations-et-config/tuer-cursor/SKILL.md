---
name: tuer-cursor
description: 'Quitter et tuer proprement TOUS les processus de l''IDE Cursor sur un Mac pour récupérer après la fuite mémoire connue du processus de rendu qui rend Cursor lent. Invocation manuelle uniquement — à lancer UNIQUEMENT quand l''utilisateur l''invoque explicitement (/tuer-cursor, « tue Cursor », « nuke cursor »). Différenciateur : tue l''application de bureau Cursor ; les sessions de la CLI cursor ne sont pas concernées.'
disable-model-invocation: true
---

# Tuer l'application Cursor

## Pourquoi cette compétence existe

Cursor est un dérivé de VS Code basé sur Electron. Il souffre d'une fuite mémoire connue et
reconnue : le processus de rendu accumule l'état des appels d'outils (diffs, contextes de
fichiers) au fil des longues sessions d'agent et ne le libère jamais, en particulier dans
la fenêtre des agents. L'interface devient lente, puis se fige. Le seul rétablissement
fiable est un redémarrage complet — c'est ce que fait cette compétence.

## Comment Cursor tourne

Un processus principal à `/Applications/Cursor.app/Contents/MacOS/Cursor`, plus des
processus auxiliaires (rendu, GPU, hôte d'extensions, service réseau, rapport de plantage)
qui vivent tous sous le chemin de paquet `/Applications/Cursor.app`.

## Règles de sécurité

- **Ne faites correspondre les processus QUE par le chemin de paquet
  `/Applications/Cursor.app`** — jamais par le mot « cursor » seul. Une correspondance sur
  le mot nu attrape des processus système sans rapport.
- **Ne touchez PAS à `CursorUIViewService`** : malgré son nom, c'est un service de saisie
  de texte de macOS, pas un composant de Cursor.
- **Prévenez l'utilisateur d'abord** si vous avez une raison de penser qu'une exécution
  d'agent importante est en cours : tuer Cursor tue ses sessions d'agent locales et le
  travail non sauvegardé.

## Procédure

```bash
# 1. Voir ce qui tourne (lecture seule)
ps -axo pid,rss,comm | grep "/Applications/Cursor.app" | grep -v grep

# 2. Quitter proprement d'abord — laisse Cursor sauvegarder l'état de session
osascript -e 'tell application "Cursor" to quit' 2>/dev/null
sleep 3

# 3. Tuer ce qui est encore vivant sous le chemin de paquet
pkill -f "/Applications/Cursor.app" 2>/dev/null
sleep 1

# 4. Vérifier ; forcer par PID si nécessaire
ps -axo pid,comm | grep "/Applications/Cursor.app" | grep -v grep
# s'il en reste :  kill -9 <pid> …

# 5. Contrôle final — ne doit rien afficher
ps -axo pid,comm | grep "/Applications/Cursor.app" | grep -v grep \
  && echo "ENCORE EN COURS" || echo "tous les processus Cursor sont terminés"
```

La sortie propre (étape 2) **échoue souvent précisément quand cette compétence est
nécessaire** — un processus de rendu qui a fui bloque le fil principal, donc l'événement
« quitter » n'est jamais traité. C'est exactement pour cela que les étapes 3 et 4 existent :
ne concluez pas à un échec si l'étape 2 ne répond pas.

**Rapportez le résultat du contrôle final à l'utilisateur. N'annoncez jamais un succès sans
l'avoir exécuté.**

---
name: push-production
description: 'Pousser sur la branche principale et surveiller le changement jusqu''à ce qu''il soit vérifiablement en production, en corrigeant les échecs d''intégration continue et de déploiement au passage. À utiliser quand l''utilisateur dit « pousse », « pousse en prod », « déploie », « ship it ». Différenciateur : pousser exige l''accord explicite de l''utilisateur ; ceci est la procédure pour APRÈS qu''il l''a donné.'
---

# Pousser en production

**Ne lancez cette procédure qu'après que l'utilisateur vous a explicitement dit de pousser.
Ne poussez jamais de votre propre initiative.**

Les valeurs propres au projet (dépôt, identité Git attendue, URL de production, sonde de
santé) vivent dans `PROFIL.md` à la racine du dépôt de compétences. Lisez-le d'abord ; ne
codez jamais ces valeurs en dur ici.

## Modèle de livraison de référence

Cette compétence suppose le modèle suivant. Si votre projet en diffère, adaptez les étapes,
pas les règles dures.

- Poussées directes sur la branche principale, sans PR ni branches latérales.
- Une intégration continue qui publie un contrôle requis unique. Les contrôles lourds
  (navigateur, base de données, multi-plateforme) ne tournent que sur les chemins concernés.
- Une plateforme de déploiement qui construit chaque poussée sur la branche principale et
  promeut en production **uniquement** quand le contrôle requis est au vert.
- Les nouvelles exécutions sur la même branche annulent celles en cours.

## Faire atterrir du travail venant d'un worktree

Les agents construisent dans des worktrees liés ; la boucle ci-dessous **refuse** d'y
tourner. Pour livrer du travail de worktree :

1. Dans le worktree : committez tout sur votre propre branche. **Ne committez jamais sur la
   branche principale depuis un worktree.**
2. Dans la copie principale : l'arbre doit être propre
   (`git status --porcelain --untracked-files=no` n'affiche rien). S'il est sale avec du
   travail en cours qui n'est pas le vôtre, **arrêtez et prévenez l'utilisateur** — ne
   remisez jamais autour.
3. `git pull --rebase origin <principale>`, puis faites atterrir VOTRE branche :
   `git merge <branche>` (avance rapide si possible), ou picorez ses commits si son
   historique est désordonné. **Une branche à la fois** — ne faites jamais atterrir deux
   branches d'agents en une seule passe.
4. Résolvez les conflits ici, dans la copie principale, relancez les contrôles concernés,
   puis reprenez la boucle ci-dessous à l'étape 2.
5. Après vérification de la mise en ligne, laissez le worktree et sa branche en place :
   les supprimer est toujours la décision de l'utilisateur, jamais la vôtre.

## La boucle

Répétez jusqu'à ce que le changement exact soit en ligne.

```bash
# 0. Échouer en amont, avant de toucher à Git.
PRINCIPALE="${BRANCHE_PRINCIPALE:-main}"
[ "$(git branch --show-current)" = "$PRINCIPALE" ] || {
  echo "push-production : pas sur $PRINCIPALE" >&2; exit 1; }

git_dir=$(git rev-parse --path-format=absolute --git-dir)
git_common=$(git rev-parse --path-format=absolute --git-common-dir)
[ "$git_dir" = "$git_common" ] || {
  echo "push-production : les poussées depuis un worktree lié sont interdites" >&2; exit 1; }

# L'identité Git attendue vient de PROFIL.md. Une surcharge locale inattendue signale
# soit une erreur de configuration, soit un dépôt qui n'est pas celui que vous croyez.
if git config --local --get-regexp '^user\.(name|email)$' >/dev/null; then
  echo "push-production : surcharge locale d'identité Git inattendue" >&2; exit 1
fi
[ "$(git config user.name)"  = "$NOM_GIT_ATTENDU" ]     || { echo "push-production : identité Git inattendue" >&2; exit 1; }
[ "$(git config user.email)" = "$COURRIEL_GIT_ATTENDU" ] || { echo "push-production : identité Git inattendue" >&2; exit 1; }

# 1. Committer UNIQUEMENT vos fichiers. Le travail en cours vit dans les worktrees, jamais
#    garé dans cette copie principale : elle doit rester propre entre deux poussées.
#    N'utilisez JAMAIS `git add -A`, `git add .`, ni `commit -a`.
git add <vos fichiers> && git commit

# 2. Synchroniser puis pousser (d'autres agents committent aussi sur la principale).
#    Le rebase exige un arbre PROPRE. `--autostash` est BANNI ici : rejouer des
#    modifications sales sur des commits amont frais crée des conflits et des remisages
#    orphelins.
[ -z "$(git status --porcelain --untracked-files=no)" ] || {
  echo "push-production : arbre non propre ; committez le vôtre ou arrêtez" >&2; exit 1; }
# N'utilisez JAMAIS `--no-verify` : le hook de pré-poussée vérifie le commit exact poussé.
git pull --rebase origin "$PRINCIPALE"
git push origin "$PRINCIPALE"
SHA=$(git rev-parse HEAD)

# 3. Trouver l'exécution d'intégration continue, puis la suivre jusqu'au bout.
#    (Adaptez les commandes à votre plateforme d'intégration continue.)
#    Attendez son statut terminal — ne concluez rien depuis une exécution en cours.

# 4. Intégration au vert -> confirmer que le déploiement a promu CE commit exact.
#    Vérifiez TOUJOURS le déploiement ; ne le sautez jamais sur un jugement du type
#    « ce n'est que de la documentation ».

# 5. Confirmer que la production sert bien le changement.
curl -sS -m 15 "$URL_SANTE"
```

**Terminé** = intégration au vert, **plus** un déploiement en production réussi, **plus** une
sonde de santé saine pour le SHA exact. Rapportez ensuite à l'utilisateur ce qui a été livré.

## Modes d'échec

| Symptôme | Cause | Que faire |
|---|---|---|
| Intégration en échec | Un contrôle casse | Récupérez l'étape et la sortie exactes en échec, reproduisez en local, corrigez, committez, **relancez la boucle** (le nouveau SHA est celui à suivre) |
| Intégration au vert, déploiement en échec | La construction de déploiement casse | Reproduisez avec la commande de construction locale. Si c'est côté plateforme (variables d'environnement, limites), **arrêtez** et donnez le lien des journaux à l'utilisateur |
| Intégration `cancelled` | Une poussée plus récente a supplanté la vôtre | Votre commit ne se déploiera jamais seul. Confirmez que le SHA plus récent contient votre changement (`git merge-base --is-ancestor $SHA <nouveau-sha>`) et suivez celui-là |
| Santé en échec (503) alors que le déploiement a réussi | Dérive de migration : le code déployé attend une migration non appliquée | **Les agents n'écrivent jamais en production.** Dites à l'utilisateur quelle migration appliquer et arrêtez la boucle |
| Poussée rejetée (non fast-forward) | Quelqu'un a poussé entre-temps | `git pull --rebase origin <principale>` puis repoussez |

## Règles dures

- **Ne poussez JAMAIS sans l'accord explicite de l'utilisateur.** Ne forcez jamais une
  poussée. Ne poussez jamais de branches latérales.
- **Ne contournez et n'affaiblissez jamais l'intégration continue pour obtenir du vert** :
  pas de suppression ou de neutralisation de tests, pas de `--no-verify`, pas de fusion
  autour d'un contrôle rouge. Un vert obtenu ainsi est un mensonge qui coûtera plus cher
  plus tard.
- **N'utilisez pas les vérifications de production payantes** (suites de fumée facturées) :
  elles dépensent de l'argent réel et relèvent de l'utilisateur. Votre contrôle gratuit est
  la sonde de santé.
- Si le changement inclut une migration de base de données, **c'est l'utilisateur qui
  l'applique manuellement en production**. Attendez-vous à ce que la santé reste rouge
  jusque-là, et **dites-le dans votre rapport** plutôt que de laisser croire à un échec.

## Voie incident

Si le projet a un mécanisme de gel en cas d'incident, ne l'utilisez que si vous êtes le
responsable de rétablissement désigné. Ne mélangez jamais de travail sans rapport dans un
commit de rétablissement : exactement un commit minimal. Suivez ce SHA exact à travers
l'intégration, le déploiement et la santé avec la boucle normale. **Ne poussez pas une
seconde tentative de rétablissement tant que le premier SHA n'a pas de résultat terminal.**
L'utilisateur seul décide quand le rétablissement est prouvé et quand le gel peut être levé.

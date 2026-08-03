---
name: publier-competence
description: 'Committer et pousser des modifications de compétences vers le dépôt Git de compétences de l''utilisateur. À utiliser après avoir créé ou modifié une compétence, quand l''utilisateur dit « publie la compétence », « pousse les compétences sur GitHub », « sauvegarde la compétence dans mon dépôt », ou « mets à jour le dépôt de compétences ».'
---

# Publier une compétence sur GitHub

Committer une modification de compétence dans le dépôt de compétences de l'utilisateur.
La racine Git est indiquée dans `PROFIL.md` à la racine de ce dépôt (par défaut :
`~/.agents`, qui est aussi le dossier canonique des compétences).

À utiliser après avoir créé ou modifié une compétence. Si la compétence doit être
distribuée à tous les agents, faites-le d'abord (`distribuer-competence`), puis publiez
la copie canonique.

## Prérequis

**Ne poussez que si l'utilisateur l'a demandé.** Une poussée est une action tournée vers
l'extérieur : elle publie du contenu qui peut être mis en cache ou indexé même s'il est
supprimé ensuite. Ne poussez jamais spéculativement.

## Procédure

Exécutez Git directement dans le shell courant. Une poussée est une commande synchrone
rapide : aucun terminal persistant ni panneau n'est nécessaire.

1. **Validez la compétence avant de publier.** Depuis ce dépôt :

   ```bash
   ./outils/valider-competences.sh
   ```

   Ne publiez pas une compétence qui ne passe pas la validation.

2. **Regardez ce qui est en attente** dans la racine du dépôt :

   ```bash
   cd "$RACINE_COMPETENCES" && git status --short
   ```

   S'il y a des modifications non liées non committées, ne mettez en zone de préparation
   que le ou les dossiers de compétences que vous avez modifiés. Ne regroupez jamais du
   travail sans rapport sous un même message de commit.

3. **Vérifiez la branche.** Ne poussez pas sur la branche par défaut sans y être :

   ```bash
   git branch --show-current
   ```

4. **Préparer, committer, pousser** :

   ```bash
   git add competences/<categorie>/<nom-de-la-competence>
   git commit -m "<message concis et précis>"
   git push -u origin "$(git branch --show-current)"
   ```

5. **Vérifiez que la poussée a abouti.** La sortie doit montrer la mise à jour de la
   référence distante. Si ce n'est pas le cas, rapportez l'erreur — n'annoncez pas un
   succès. En cas d'échec réseau, réessayez avec un délai croissant (2 s, 4 s, 8 s, 16 s),
   quatre fois au maximum.

## Règles

- Exécutez toujours Git depuis la racine du dépôt, pas depuis le sous-dossier de la compétence.
- Écrivez un message de commit concis et précis décrivant la modification de la compétence.
- Ne poussez jamais sur une branche autre que celle demandée.
- Si le dépôt publie un miroir public, ne poussez jamais directement vers ce miroir :
  poussez vers le dépôt canonique et laissez la synchronisation opérer.
- Ne committez jamais de secrets. Vérifiez le diff avant de préparer si une compétence
  touche à des clés d'API ou des fichiers d'environnement.

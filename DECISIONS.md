# Décisions de conception et propriétés de sûreté

Ce que ce dépôt garantit, pourquoi, et ce qu'il ne faut pas casser en le modifiant.

Chaque propriété listée ici est **vérifiée mécaniquement** — par
`outils/valider-competences.sh` ou par `hooks/test-garde.sh` — et non seulement affirmée.
La méthode de vérification est indiquée à chaque fois.

---

## 1. Le garde-fou ne s'ouvre jamais en silence

**Une garde qui laisse tout passer sans le dire est pire que pas de garde du tout** :
l'utilisateur se croit protégé et prend des risques qu'il n'aurait pas pris autrement.

`hooks/refus-dangereux.sh` doit analyser du JSON pour extraire la commande à inspecter.
Si l'analyseur manque, la tentation est d'autoriser silencieusement pour ne pas casser les
agents. C'est ce qu'il ne faut pas faire.

Comportement retenu, dans cet ordre :

1. `jq` s'il est présent ;
2. sinon `python3` ;
3. sinon : écriture d'un fichier témoin (`~/.agents/hooks/.garde-inactive`) et d'un
   avertissement sur stderr, **puis** autorisation.

L'ouverture reste le comportement final — bloquer toutes les commandes casserait les agents
— mais elle devient visible. Le fichier témoin est effacé dès qu'une exécution réussit,
il signale donc un état courant et non un incident passé.

Un fichier de motifs absent produit également un avertissement, pas un silence.

**Si vous modifiez ce script, conservez cette propriété.**

## 2. La liste de refus couvre les répertoires système

Une liste qui ne protège que `/`, `~` et le dossier des utilisateurs laisse passer des
commandes tout aussi définitives. Vérification, en faisant passer chaque commande dans
l'ensemble des motifs :

| Commande | Doit être bloquée |
|---|---|
| `rm -rf /usr` · `/etc` · `/var` · `/boot` | oui |
| `rm -rf /System` · `/Applications` · `/Library` · `/Volumes/…` | oui |
| `shred -u /dev/sda` | oui |
| `rm -rf /var/folders/T/mon-tmp` | **non** — chemin profond légitime |
| `rm -rf node_modules` · `git clean -fdx` | **non** — destructeur mais récupérable |

Le motif couvre la racine système et **un seul niveau** en dessous. C'est délibéré : au-delà,
on entre dans les chemins de travail légitimes, et sur-bloquer rend les agents inutiles —
ce qui pousse les utilisateurs à désactiver la garde entièrement, résultat pire que le
problème traité.

**Règle générale** : ne bloquer que l'irréversible et le catastrophique. Le
destructeur-mais-récupérable reste autorisé.

Vérification : `./hooks/test-garde.sh` — 214 assertions, dans les deux formes de charge
utile (code de sortie et JSON), avec autant de cas « doit passer » que de cas « doit être
bloqué ».

## 3. Ce qui rend une compétence silencieusement inopérante

Une compétence cassée ne produit **aucun message d'erreur** : elle n'est simplement jamais
chargée. C'est le mode de panne le plus coûteux du format, parce que rien ne le signale.
Quatre causes, toutes détectées par le validateur :

**Dossier sans `SKILL.md`.** Le dossier peut contenir des scripts, des références, un
fichier de politique — sans `SKILL.md`, aucun agent ne le découvre. Il est mort.

**Le piège du `:` non quoté.** Une `description:` non quotée contenant un deux-points suivi
d'une espace est acceptée par les analyseurs YAML permissifs et **rejetée par les
analyseurs stricts**. La compétence fonctionne donc chez un agent et disparaît chez un
autre, sans message dans les deux cas. Le validateur analyse le frontmatter en **mode
strict** précisément pour attraper ça, et donne la correction : entourer la valeur
d'apostrophes simples, doubler les apostrophes internes.

**`name` différent du nom du dossier.** Le chargement échoue ou la compétence est
enregistrée sous un nom que personne n'invoque.

**Référence vers un fichier inexistant.** L'agent tente une lecture qui échoue au moment où
il en a besoin, c'est-à-dire au pire moment.

Le validateur ne contrôle une référence `references/`, `scripts/` ou `assets/` que si la
compétence embarque effectivement le sous-dossier correspondant — sinon `scripts/deploy.sh`
dans un exemple désigne le dépôt de l'utilisateur, pas la compétence.

## 4. Divulgation progressive : le corps est chargé en entier

Le corps d'un `SKILL.md` entre **intégralement** en contexte à chaque activation. Tout ce
qui y est redondant se paie à chaque fois.

Conséquence pratique sur les grosses références d'API : les règles communes (en-têtes,
idempotence, sondage, gestion d'erreurs) s'énoncent **une seule fois** dans `SKILL.md`, et
le détail par point de terminaison part dans `references/`. Recopier un bloc de six lignes
de consignes sous chacun de cinquante points de terminaison ajoute environ 300 lignes
identiques chargées à chaque activation, sans rien apprendre à l'agent.

Même logique pour les tables d'erreurs : une quinzaine de codes qui partagent exactement la
même conduite à tenir se regroupent en une règle, avec les exceptions listées à part.

Le validateur avertit au-delà de 500 lignes. Ce n'est pas une limite dure — c'est le seuil
au-delà duquel il faut se demander ce qui devrait partir dans `references/`.

## 5. Une compétence, une préoccupation

Deux compétences identiques à un paramètre près sont une dette de maintenance et un
conflit de routage : leurs descriptions ne se distinguant que par ce paramètre, l'agent
choisit mal.

Le cas typique est la revue de code par un modèle tiers. Le modèle relecteur est un
**paramètre**, pas une compétence distincte. Une seule procédure, un modèle choisi à
l'exécution — et une règle que la duplication faisait perdre de vue : le relecteur doit
être un modèle **différent** de celui qui a écrit le code, sinon la revue reproduit les
mêmes angles morts.

Le validateur détecte aussi les titres `##` dupliqués à l'intérieur d'un même fichier :
c'est la signature d'un copier-coller, et il produit deux versions divergentes de la même
instruction sans que l'agent sache laquelle fait foi.

## 6. Aucune donnée personnelle dans une compétence

Chemins personnels, identités Git, noms de dépôts, adresses IP, étiquettes de service :
codés en dur, ils rendent la compétence inutilisable ailleurs sans édition, et ils fuitent
dès la publication du dépôt.

Toutes ces valeurs vivent dans `PROFIL.md`, non committé (voir `PROFIL.exemple.md`). Les
compétences y renvoient ; les scripts prennent des variables d'environnement avec des
valeurs par défaut génériques.

Corollaire pour les compétences de livraison : la logique de sûreté est conservée
intégralement (refus de pousser depuis un worktree lié, interdiction de `--autostash` et de
`--no-verify`, vérification du déploiement même pour un commit de documentation), mais
paramétrée plutôt que liée à un projet unique.

## 7. Aucune information périssable

Pas d'identifiant de modèle codé en dur, pas de tarif présenté comme stable, pas de date de
constat. Ces valeurs changent tous les quelques mois, et une compétence qui les fige
**devient fausse en silence** — ce qui est pire que de ne rien dire, parce que l'agent la
croit.

À la place : une instruction de vérification à l'exécution (`--help`, un point de
terminaison de capacités, la page de tarification du fournisseur). Les plafonds qui font
partie du contrat d'une API sont conservés, mais accompagnés du renvoi vers la source
faisant autorité.

## 8. La documentation et le code doivent concorder

Quand un `SKILL.md` décrit un comportement que son script n'implémente pas, l'agent suit la
documentation et échoue. C'est une classe de bug propre aux compétences qui embarquent du
code, et elle ne se voit ni en lisant seulement la documentation, ni en lisant seulement le
script.

Exemple concret dans ce dépôt : `anti-veille` documente le remplacement automatique d'une
session active — l'utilisateur qui demande une nouvelle durée a déjà exprimé son intention.
Le script implémente donc ce remplacement par défaut, avec `--no-replace` pour le refuser
explicitement.

**Vérification** : exécuter les commandes des compétences, pas seulement les relire. C'est
ainsi qu'a été trouvé un `grep` de détection de secrets sensible à la casse, qui ratait
`API_KEY`, `SECRET_KEY` et `DATABASE_PASSWORD` — la forme de loin la plus courante — dans
une compétence d'audit de sécurité. Une commande d'audit qui ne trouve rien produit
exactement la fausse assurance qu'elle prétend éviter.

## 9. Prose neutre

Aucune supposition sur le genre des personnes mentionnées. Aucune injonction abusive : une
consigne plus ferme ne rend pas un agent plus rigoureux, elle rend seulement son
affirmation plus assurée. Quand une tâche doit être faite complètement, la bonne réponse
est de **rendre le résultat vérifiable**, pas de hausser le ton — voir
`lire-tous-les-adr`, qui exige un relevé qu'un survol ne peut pas produire.

---

## Le validateur

```bash
./outils/valider-competences.sh
```

| Contrôle | Ce qu'il empêche |
|---|---|
| Dossier de compétence sans `SKILL.md` | Compétence invisible pour tous les agents |
| `name` ≠ nom du dossier | Chargement échoué ou nom non invocable |
| Frontmatter YAML invalide en **mode strict** | Compétence qui marche chez un agent, disparaît chez un autre |
| `description` absente, vide, ou > 1024 caractères | Routage impossible |
| `<` ou `>` dans le frontmatter | Injection dans le prompt système |
| Référence vers un fichier inexistant | Lecture qui échoue au moment du besoin |
| Script référencé non exécutable | Échec à l'exécution |
| Fichier embarqué jamais référencé | Contenu jamais chargeable |
| Titre `##` dupliqué | Copier-coller, instructions divergentes |
| `README.md` / `CHANGELOG.md` dans une compétence | Documentation humaine dans un espace destiné aux agents |
| `SKILL.md` > 500 lignes | Contexte gaspillé à chaque activation |

Le validateur a été testé contre un jeu de compétences délibérément défectueuses : il
remonte chaque classe de défaut et sort en code 1.

## Les tests du garde-fou

```bash
./hooks/test-garde.sh
```

214 assertions, dans les deux formes de charge utile. **Autant de cas « doit être
autorisé » que de cas « doit être bloqué »** : un motif trop large casse les agents sans
que personne ne s'en aperçoive, et c'est un défaut aussi grave qu'un motif trop étroit.

À lancer après toute modification du fichier de motifs.

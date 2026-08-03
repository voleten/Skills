---
name: lire-tous-les-adr
description: 'Lire réellement et intégralement chaque ADR du projet, et le prouver par un relevé vérifiable, pour disposer du contexte complet sur les décisions passées avant de travailler. À n''utiliser que sur invocation explicite, par /lire-tous-les-adr. Différenciateur : produit une preuve de lecture par ADR, là où « lis les ADR » donne un survol que rien ne distingue d''une vraie lecture.'
disable-model-invocation: true
---

# Lire tous les ADR

## Le problème que cette compétence résout

Demander à un agent de « lire tous les ADR » produit presque toujours la même chose : il en
ouvre trois, en survole cinq, et annonce avoir le contexte. Rien dans sa réponse ne permet
de distinguer une lecture réelle d'un survol — ni pour l'utilisateur, ni pour l'agent
lui-même, qui croit sincèrement avoir lu.

Insister ne corrige pas ça. Une consigne plus ferme, en majuscules ou grossière, ne rend
pas la lecture plus complète : elle rend seulement l'affirmation plus assurée. C'est la
mauvaise variable.

**Le correctif est la vérifiabilité** : produire un relevé qu'il est impossible de rédiger
sans avoir ouvert chaque fichier. La preuve remplace la promesse.

## Procédure

### 1. Localiser et dénombrer

Établissez le dénominateur avant de commencer. Sans lui, « j'ai tout lu » n'a pas de sens.

```bash
for d in docs/adr doc/adr docs/decisions docs/architecture/decisions adr .adr; do
  [ -d "$d" ] && echo "TROUVÉ : $d ($(ls "$d"/*.md 2>/dev/null | wc -l | tr -d ' ') fichiers)"
done
```

Si rien n'est trouvé, cherchez plus largement avant de conclure à l'absence d'ADR :

```bash
grep -rlim1 -E '^#+ *(Status|Statut|Decision|Décision)\b' --include='*.md' . 2>/dev/null | head -20
```

Annoncez le nombre trouvé **avant** de lire. C'est le chiffre contre lequel votre relevé
final sera vérifié.

### 2. Lire chaque fichier, en entier

Lisez-les dans l'ordre numérique. Pas de survol, pas d'échantillonnage, pas de « je lis les
plus récents, les anciens sont sûrement obsolètes ». **Un ADR ancien est souvent celui qui
explique pourquoi une contrainte apparemment absurde existe encore** — c'est exactement
celui que le survol écarte.

Si un ADR en référence un autre (« remplace le 0012 », « voir 0007 »), notez le lien : la
structure compte autant que le contenu.

### 3. Produire le relevé — la preuve de lecture

Une ligne par ADR, dans l'ordre, **sans exception** :

```
0001 · Choix de PostgreSQL · Accepté · Besoin de transactions ACID sur la facturation
0002 · Découpage en services · Remplacé par 0019 · Un service par domaine métier
0003 · Authentification par jeton · Accepté · Cookies httpOnly, pas de stockage local
…
```

Format : `numéro · titre · statut · la décision en dix mots maximum`.

La contrainte des dix mots est délibérée. Un résumé long peut se paraphraser depuis un
titre ; une décision compressée en dix mots exige d'avoir compris ce que l'ADR tranche.
C'est ce qui rend le relevé infalsifiable par survol.

Le relevé doit contenir **autant de lignes que le dénombrement de l'étape 1**. Si les deux
nombres diffèrent, dites-le et expliquez l'écart.

### 4. Synthétiser

Le relevé prouve la lecture ; la synthèse en donne la valeur. Trois points seulement :

- **Ce qui contraint le travail en cours.** Les décisions qui ferment des options ici et
  maintenant. C'est la seule partie que l'utilisateur lira à coup sûr.
- **Les contradictions.** Deux ADR actifs qui se contredisent, ou une décision que le code
  ne respecte plus.
- **Les ADR marqués remplacés sans remplaçant**, ou marqués « proposé » depuis longtemps.
  Ce sont des décisions en suspens que personne ne suit.

**Ne résumez pas les ADR un par un.** L'utilisateur les a déjà et vous a demandé de les
lire pour que **vous** ayez le contexte — pas pour qu'il relise le sien.

## Quand le volume dépasse le contexte disponible

Cela arrive à partir de quelques dizaines d'ADR. Deux règles :

1. **Traitez par lots** et tenez le relevé au fil de l'eau, en le persistant dans un fichier
   temporaire plutôt qu'en mémoire. Le relevé survit ainsi à la compaction du contexte, et
   vous pouvez reprendre sans relire.
2. **Dites ce qui n'a pas été lu.** Indiquez combien d'ADR ont été traités, lesquels
   restent, et proposez de poursuivre. **N'annoncez jamais une lecture complète qui n'a pas
   eu lieu** — c'est exactement le défaut que cette compétence existe pour empêcher, et le
   commettre ici est pire qu'ailleurs.

Une lecture partielle honnête est utile. Une lecture complète prétendue est un piège pour
toutes les décisions qui suivront.

## Pourquoi payer ce coût

La lecture se paie une fois. La non-lecture se paie à chaque tour : l'agent repropose des
solutions déjà écartées, pour des raisons déjà écrites, et l'utilisateur doit expliquer une
nouvelle fois ce qu'un fichier du dépôt disait déjà.

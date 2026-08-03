---
name: role-bdd-lecture-seule
description: 'Créer un rôle PostgreSQL durci en SELECT seul pour que des agents IA puissent lire sans risque une base de production. Fonctionne sur Supabase et tout PostgreSQL. À utiliser quand l''utilisateur veut que ses agents interrogent des données de production, dit « rôle en lecture seule », « accès prod sûr pour les agents », ou en a assez d''exécuter du SQL à la main pour ses agents. Différenciateur : cette compétence CRÉE le rôle et le câblage ; l''interrogation quotidienne relève d''une compétence propre au projet.'
---

# Créer un rôle de base de données en lecture seule pour les agents

Un rôle en SELECT seul supprime les écritures catastrophiques **au niveau des permissions**,
pas au niveau des bonnes intentions. Les risques résiduels (fuite de données, requêtes
lourdes) sont traités par une liste de refus et des délais d'expiration. Les agents cessent
d'être aveugles sur la production ; l'humain cesse d'être le goulot d'étranglement SQL.

## Le motif — 3 couches

1. **Le mur dur : les droits.** Le rôle reçoit `SELECT` et rien d'autre. Les écritures sont
   **impossibles**, pas seulement déconseillées.
2. **Liste de refus, pas liste d'autorisation.** Accordez `SELECT` sur toutes les tables
   actuelles **et futures** du schéma `public` (via les privilèges par défaut), puis
   révoquez les joyaux de la couronne (clés d'API, charges utiles de webhooks, secrets).
   N'accordez jamais le schéma `auth`. Les tables futures sont lisibles par conception ;
   une nouvelle table sensible exige donc une révocation manuelle — **c'est le compromis
   assumé de ce modèle, et le point à surveiller.**
3. **Garde-fous souples.** `default_transaction_read_only = on` plus
   `statement_timeout = '10s'`.

**Piège RLS** : si les tables de production ont la sécurité au niveau des lignes activée et
qu'aucune politique ne mentionne le nouveau rôle, **chaque `SELECT` renvoie 0 ligne**.
Correctif : `alter role … bypassrls` — sans danger, car le contournement ne saute que le
filtrage par ligne ; les droits `SELECT` seuls et la liste de refus s'appliquent toujours.

## Procédure

1. **Contrôle d'état.** `select rolname from pg_roles where rolname = 'agents_lecture';`
   S'il existe, vous mettez à jour, vous ne créez pas.
2. **Choisissez la liste de refus AVEC l'humain.** Demandez quelles tables contiennent des
   secrets ou des données personnelles que les agents ne doivent jamais voir (clés d'API,
   événements de webhooks, tables d'authentification et d'utilisateurs).
3. **Écrivez le SQL dans un fichier du dépôt d'abord** (par exemple
   `docs/base-de-donnees/creer-role-agents-lecture.sql`) avec des commentaires : quoi,
   pourquoi, comment appliquer, comment vérifier, comment revenir en arrière.
   **Ne livrez jamais du SQL uniquement dans la conversation** : il disparaît, et personne
   ne peut plus auditer ce qui a été appliqué.
4. **C'est l'humain qui applique.** Les agents n'exécutent jamais de DDL en production.
   Sur Supabase : collez le fichier entier dans l'éditeur SQL, puis **SUPPRIMEZ la requête
   de l'historique de l'éditeur** (elle contient le mot de passe). Stockez le mot de passe
   dans un gestionnaire de mots de passe.
5. **Câblez la chaîne de connexion** en variable d'environnement locale, jamais committée,
   par exemple `MONPROJET_URL_BDD_LECTURE`. Sur le pooler de session Supabase, le nom
   d'utilisateur est `agents_lecture.<ref-projet>`, port 5432.
6. **Vérifiez** avec la boucle ci-dessous.
7. **Écrivez une compétence d'usage propre au projet** pour que les agents futurs
   connaissent les tables clés, les motifs de requête et les règles dures (lecture seule à
   jamais, ne jamais coller de données personnelles dans un commit ou un document).

## Modèle SQL

```sql
-- 1. rôle + garde-fous souples
create role agents_lecture with login password 'A_REMPLACER';
alter role agents_lecture set default_transaction_read_only = on;
alter role agents_lecture set statement_timeout = '10s';

-- 2. le vrai mur : droits SELECT seuls, modèle liste de refus
grant usage on schema public to agents_lecture;
grant select on all tables in schema public to agents_lecture;
alter default privileges for role postgres in schema public
  grant select on tables to agents_lecture;   -- tables futures lisibles automatiquement

-- 3. liste de refus : les joyaux restent invisibles (à adapter par projet)
revoke select on table public.cles_api from agents_lecture;
revoke select on table public.evenements_webhook_email from agents_lecture;

-- 4. uniquement si RLS est activé et qu'aucune politique ne couvre ce rôle
alter role agents_lecture bypassrls;
```

Retour arrière : `drop owned by agents_lecture; drop role agents_lecture;`

## Boucle de vérification (tout doit passer avant de déclarer terminé)

```bash
URL="$MONPROJET_URL_BDD_LECTURE"
psql "$URL" -X -c "select current_user;"                          # -> agents_lecture
psql "$URL" -X -c "show statement_timeout;"                       # -> 10s
psql "$URL" -X -c "select count(*) from public.<grande_table>;"   # -> un vrai nombre, PAS 0

psql "$URL" -X -c "delete from public.<une_table> where false;"
# -> ERREUR : transaction en lecture seule (garde-fou souple)

psql "$URL" -X -c "begin; set transaction read write; delete from public.<une_table> where false; rollback;"
# -> ERREUR : permission refusée (le mur dur)

psql "$URL" -X -c "select * from public.<table_refusee> limit 1;" # -> ERREUR : permission refusée
psql "$URL" -X -c "select * from auth.users limit 1;"             # -> ERREUR : permission refusée
```

**Les écritures doivent être bloquées DEUX fois** : une fois par le garde-fou de lecture
seule, et **encore** par un « permission refusée » quand le garde-fou est désactivé. Si un
seul contrôle échoue, corrigez les droits et **relancez TOUS les contrôles** — pas seulement
celui qui a échoué.

## Modes d'échec

| Symptôme | Cause | Correctif |
|---|---|---|
| Toutes les tables renvoient 0 ligne | RLS activé, aucune politique pour ce rôle | Ajouter `bypassrls` (étape 4 du modèle) |
| Une écriture a réussi pendant la vérification | Les droits sont faux | **Arrêter.** Tout révoquer, réappliquer le modèle depuis zéro |
| Authentification Supabase en échec | Nom d'utilisateur du pooler incomplet | Utiliser `agents_lecture.<ref-projet>`, pas `agents_lecture` seul |
| `statement timeout` sur des requêtes légitimes | Requête trop lourde | Ajouter des filtres et des limites. **Ne pas relever le délai en premier réflexe** |

## Maintenance

- Nouvelle table sensible → ajoutez un `revoke select` à côté du bloc de liste de refus.
  **C'est la seule opération de maintenance obligatoire de ce modèle ; l'oublier expose
  silencieusement la nouvelle table.**
- Rotation du mot de passe : `alter role agents_lecture with password '…'` puis mise à jour
  de la variable d'environnement.
- Ne laissez jamais les agents écrire par ce rôle. Les écritures en production restent
  humaines.

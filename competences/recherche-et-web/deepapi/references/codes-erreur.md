# DeepAPI — codes d'erreur complets

Les codes les plus fréquents et la règle générale sont dans `SKILL.md`. Ce fichier
contient les codes spécifiques par domaine.

**Règle de base** : ne réessayez jamais à l'identique un code `403` ou `404`. Ils signalent
une requête structurellement erronée, pas une panne transitoire — une nouvelle tentative
produira la même erreur et consommera votre quota de débit.

## Authentification, quotas, validation

| Code | HTTP | Signification | Que faire |
|---|---|---|---|
| `missing_api_key` | 401 | Aucune clé porteuse sur la requête | Envoyer `Authorization: Bearer $DEEPAPI_API_KEY` |
| `invalid_api_key` | 401 | Clé inconnue, révoquée ou expirée | Demander une clé valide. Ne pas réessayer avec la même |
| `missing_idempotency_key` | 400 | `POST` sans en-tête `Idempotency-Key` | Envoyer une clé unique et réessayer |
| `missing_scope` | 403 | La clé n'a pas la portée de `error.requiredScope` | Demander une clé avec cette portée |
| `invalid_request` | 400 | Champ invalide ; `error.field` le nomme | Corriger selon `error.message` et `error.fix`, réessayer avec une **nouvelle** clé |
| `insufficient_credits` | 402 | Le solde ne couvre pas le plafond demandé | Faire recharger sur deepapi.co/credits, réessayer avec **la même** clé |
| `api_key_limit_exceeded` | 402 | Une limite de dépense de la clé bloque la requête | Baisser `maxCostUsd`, ou faire relever la limite |
| `rate_limit_exceeded` | 429 | Trop de requêtes (ou d'échecs d'authentification) cette minute | Attendre `retryAfterSecs`, réessayer avec **la même** clé |
| `upstream_rate_limited` | 429 | Le fournisseur en amont a limité la requête | Attendre `retryAfterSecs`, réessayer avec une **nouvelle** clé |
| `idempotency_conflict` | 409 | Cette `Idempotency-Key` appartient à une requête encore en cours | Attendre puis réessayer avec la même clé pour recevoir le résultat final |

## Routage et configuration

| Code | HTTP | Signification | Que faire |
|---|---|---|---|
| `unknown_capability` | 404 | Cible ou type de moissonnage inexistant | Utiliser un chemin documenté |
| `resource_not_found` | 404 | Ressource absente ou inaccessible | Vérifier l'identifiant et les droits |
| `capability_not_configured` | 501 | La route existe mais aucun service en aval n'est configuré | Ne pas réessayer. Le signaler à l'utilisateur |
| `request_not_found` | 404 | Aucune requête avec cet identifiant pour cette clé | Vérifier `requestId` ; ne sonder que les requêtes créées avec la même clé |

## Courriel

| Code | HTTP | Signification | Que faire |
|---|---|---|---|
| `email_identity_not_found` | 404 | `emailIdentityId` n'appartient pas à cet espace | Omettre le champ pour utiliser l'identité par défaut |
| `email_draft_not_found` | 404 | Aucun brouillon de ce nom pour cette identité | Lister via `GET /v1/email/drafts` et utiliser un `draftId` renvoyé |
| `email_policy_rejected` | 403 | Politique d'envoi : règles de destinataire, de contenu, espace suspendu, ou plafond quotidien/mensuel atteint | Suivre `error.message`. Si un plafond est atteint, attendre la réinitialisation ou créer un brouillon |
| `email_not_configured` | 503 | Aucune boîte de réception active | Ajouter des crédits ou l'activer sur deepapi.co/email |
| `email_domain_not_found` | 404 | Aucun domaine d'envoi avec ce `domainId` | Lister via `GET /v1/email/domains` |
| `email_domain_not_verified` | 403 | Le domaine existe mais son DNS n'est pas vérifié | Publier les `dnsRecords`, puis `POST /v1/email/domains/{id}/verify` jusqu'à `verified: true` (gratuit) |
| `email_domain_limit_exceeded` | 403 | Limite de domaines d'envoi atteinte | Supprimer un domaine inutilisé, puis réessayer |
| `email_domain_conflict` | 409 | Domaine déjà enregistré par un autre espace de travail | Arrêter et prévenir l'utilisateur ; s'il possède le domaine, il doit contacter le support |

## Déploiement

| Code | HTTP | Signification | Que faire |
|---|---|---|---|
| `deploy_content_rejected` | 403 | Contenu bloqué : hameçonnage, formulaire de mot de passe, formulaire postant vers une URL externe, raccourcisseur d'URL | Retirer le contenu signalé, réessayer avec une **nouvelle** clé |
| `deploy_limit_exceeded` | 403 | Quota atteint : trop de pages vivantes ou trop de déploiements aujourd'hui | Attendre l'expiration des pages ou la réinitialisation quotidienne |

## PDF

| Code | HTTP | Signification | Que faire |
|---|---|---|---|
| `pdf_too_large` | 403 | Le fichier dépasse la limite (environ 50 Mo). **Rien n'a été facturé** | Utiliser un PDF plus petit ou une URL servant le document en parties |
| `pdf_not_readable` | 422 | L'URL n'a pas livré de texte lisible : pas un PDF, protégé par mot de passe, corrompu, ou image scannée sans couche texte. **Rien n'a été facturé** | Vérifier que l'URL sert un PDF texte non chiffré. Les PDF scannés exigent de l'OCR, que cette route ne fait pas. Ne pas réessayer à l'identique |

## Mémoire

| Code | HTTP | Signification | Que faire |
|---|---|---|---|
| `memory_file_not_found` | 404 | Aucun fichier mémoire à ce chemin | Lister via `GET /v1/memory`. Pour créer le fichier, le `POST` avec `content` |
| `memory_limit_exceeded` | 403 | Quota atteint : trop de fichiers, fichier trop gros, ou total plein | Supprimer ou réduire via `GET /v1/memory` et `DELETE /v1/memory/{path}` |
| `memory_version_conflict` | 409 | Le fichier a changé depuis la version envoyée en `ifVersion` — un autre agent a écrit avant vous | Relire le fichier, fusionner vos changements dans le contenu le plus récent, réessayer avec la nouvelle version |

## X (Twitter)

| Code | HTTP | Signification | Que faire |
|---|---|---|---|
| `x_not_connected` | 403 | Aucun compte X connecté, ou accès révoqué | Faire connecter le compte sur deepapi.co/x, réessayer avec une **nouvelle** clé |
| `x_post_rejected` | 403 | X a rejeté la publication : doublon, trop long, ou blocage de politique. **Rien n'a été facturé** | Modifier le texte selon `error.message`, réessayer avec une **nouvelle** clé. Ne pas réessayer à l'identique |
| `x_post_limit_exceeded` | 403 | Quota quotidien de publications atteint (garde-fou contre le verrouillage de compte) | Attendre la réinitialisation quotidienne |

## Erreurs serveur transitoires (502)

Tous ces codes partagent la **même** conduite à tenir. Rien n'a été facturé. Attendez
`error.retryAfterSecs`, puis réessayez avec **la même** `Idempotency-Key`. Si l'échec
persiste, vérifiez `GET /v1/health` pour distinguer une panne d'un problème de requête.

`scrape_request_failed`, `search_request_failed`, `research_request_failed`,
`generate_image_request_failed`, `deploy_request_failed`, `memory_request_failed`,
`x_request_failed`, `email_draft_failed`, `email_send_failed`, `email_retrieval_failed`,
`email_draft_send_failed`, `email_domain_request_failed`, `email_identity_create_failed`,
`request_lookup_failed`, `request_list_failed`, `balance_lookup_failed`,
`account_lookup_failed`, `usage_lookup_failed`, `capability_list_failed`.

**Exception : `request_failed` (502).** L'exécution du fournisseur a échoué pour une
requête déjà démarrée. Elle n'est **pas** rejouable avec la même clé : démarrez une
nouvelle requête avec une nouvelle clé si le besoin subsiste.

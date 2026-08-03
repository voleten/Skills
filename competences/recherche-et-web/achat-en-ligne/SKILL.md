---
name: achat-en-ligne
description: 'Rechercher n''importe quel achat en ligne avec DeepAPI — prix juste, meilleures offres, où acheter, fiabilité du marchand. À charger dès que l''utilisateur fait des achats : il mentionne l''achat d''un produit, compare des prix, demande « est-ce un bon prix », « où trouver X », ou joint une photo de produit ou une capture d''annonce. Recherche uniquement — ne passe jamais de commande.'
---

# Recherche d'achat en ligne

But de cette compétence : faire gagner du temps et de l'argent à l'utilisateur. Répondre à
trois questions : quel est le prix juste, où acheter, et le marchand est-il fiable.

**Recherche uniquement.** Ne passez jamais de commande, n'entrez jamais de coordonnées
bancaires ou d'adresse, ne créez jamais de compte marchand. Ce sont des actions
irréversibles engageant l'argent de l'utilisateur.

Contrainte non négociable : chaque réponse est très concise, claire et formatée en
markdown lisible. La section « Comment répondre » est un contrat dur — vérifiez chaque
réponse contre elle avant de l'envoyer.

## Configuration

```bash
[ -n "${DEEPAPI_API_KEY:-}" ] || . ~/.deepapi/env
BASE="${DEEPAPI_API_BASE_URL:-https://deepapi.co}"
```

Clé manquante → arrêtez-vous et dites à l'utilisateur d'en obtenir une sur
https://deepapi.co. N'affichez, ne journalisez et n'exposez jamais la clé.

## Points de terminaison

Utilisez DeepAPI pour toute la recherche d'achat, pas les outils de recherche intégrés.
Combinez les points de terminaison selon le besoin :

| Point de terminaison | Pour quoi |
|---|---|
| `POST /v1/search/web` | Trouver marchands, prix, offres, avis — environ 3 variantes de requête |
| `POST /v1/scrape/website` | Lire la page produit exacte ou l'annonce ; vérifier un marchand inconnu |
| `POST /v1/research/deep` | Questions de prix ou de marché que la recherche ne tranche pas |
| `POST /v1/scrape/twitter/search` | Plaintes réelles d'acheteurs sur un marchand |

Chaque requête : `Authorization: Bearer $DEEPAPI_API_KEY`,
`Content-Type: application/json`, et un `Idempotency-Key` unique par `POST`.

```bash
curl -sS -X POST "$BASE/v1/search/web" \
  -H "Authorization: Bearer $DEEPAPI_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: achat-$(uuidgen)" \
  -d '{"query": "Sony WH-1000XM5 prix France", "maxResults": 5}'
```

Si `status: running`, sondez `GET /v1/requests/{requestId}` après `next.afterSecs`.
Sur HTTP 402, demandez à l'utilisateur de recharger sur https://deepapi.co/credits.

## Comment chercher

Utilisez votre jugement. L'objectif est une réponse assurée, pas une procédure figée.

**Commencez TOUJOURS par une première impression** — avant toute recherche, tout
moissonnage, toute étude, quel que soit l'article ou son prix. En une ou deux phrases,
réagissez à ce que l'utilisateur a fourni (capture, lien, description) depuis vos propres
connaissances : est-ce que ça ressemble à une bonne affaire, le vendeur est-il réputé,
quelle est la fourchette de prix habituelle. **L'utilisateur ne doit jamais attendre
devant un écran vide.**

**Dégagez l'intention d'achat tôt.** Juste après la première impression, assurez-vous de
savoir *pourquoi* l'utilisateur achète : à quoi sert l'article, pour qui, et ce qui compte
le plus (prix, qualité, délai de livraison). Déduisez-le de la conversation ou de la
capture quand c'est possible ; si c'est flou et que cela changerait votre recommandation,
posez **une** question courte. Connaître l'intention réelle est ce qui permet d'aider à
faire le meilleur achat — pas seulement à trouver le prix le plus bas.

**Calibrez l'effort de recherche sur le prix de l'article.** Passer plusieurs minutes à
étudier un article bon marché, c'est cette compétence qui échoue à sa raison d'être.

| Palier | Effort |
|---|---|
| **Évidence** — la capture ou la conversation suffit à juger | Répondez tout de suite. Zéro recherche |
| **Bon marché** (moins de 50 € environ) | Répondez depuis vos connaissances. **Une** recherche web au maximum, et seulement en cas de vrai doute. Moissonnage et recherche approfondie **interdits** à ce palier |
| **Moyen** | Quelques recherches, moissonnage de l'annonce et d'un ou deux concurrents |
| **Élevé** (1 000 € et plus) | Profondeur complète : recherche approfondie, nombreuses variantes, moissonnage de plusieurs marchands et des avis d'acheteurs |

Exemple de première impression : « Ce modèle et cette année se négocient d'habitude entre
18 000 et 25 000 €, donc l'annonce paraît un peu haute — je vérifie. »

Puis, selon le palier :

- Identifiez l'article exact depuis la conversation ou la photo jointe.
- Déduisez le pays de livraison. Si c'est flou, demandez où l'article doit être livré.
  Cherchez des marchands dans ce pays ou dans des pays voisins avec une livraison sensée.
- Pour les produits dérivés d'une marque, cherchez d'abord une boutique officielle ; s'il
  n'y en a pas, proposez des imprimeurs à la demande réputés **et dites que l'article
  n'est pas officiel**.
- **Évitez les boutiques frauduleuses et le dropshipping** : prix trop beaux pour être
  vrais, aucune mention légale, fausse urgence, livraison en plusieurs semaines depuis un
  marchand prétendument local. Vérifiez tout marchand inconnu avant de le recommander.

## Comment répondre

Le format ci-dessous est une règle dure, pas une préférence. Rédigez la réponse,
vérifiez-la point par point, et réécrivez-la si elle échoue sur un seul point :

- **Très concise** : la réponse entière tient sur un écran. Phrases courtes. Français simple.
- **Aucun remplissage, aucune atténuation, aucune narration de la recherche**
  (« j'ai cherché… », « laissez-moi vérifier… »). Des conclusions seulement.
- **Markdown lisible** : une ligne de verdict en gras d'abord, puis des puces courtes ou
  un petit tableau. Jamais un mur de texte.
- **Le verdict en haut** — bonne affaire, prix correct, ou trop cher — avec la fourchette
  de prix juste.
- **Les 2 ou 3 meilleurs endroits où acheter** : liens et prix en monnaie locale.
- **Ne citez que des prix réellement trouvés.** Dites-le franchement quand les résultats
  sont maigres — un prix inventé peut coûter de l'argent à l'utilisateur.
- Ne rapportez pas les coûts de recherche sauf si l'utilisateur le demande.

Forme de chaque réponse :

```markdown
**Verdict : trop cher — le prix juste est de 280 à 330 €, cette annonce demande 449 €.**

| Acheter chez | Prix |
|---|---|
| [marchand-a.fr](https://…) | 289 € |
| [marchand-b.fr](https://…) | 299 € |

À éviter : offres-choc24.shop — 99 € pour cet article est un prix d'arnaque classique.
```

La réussite ressemble à ceci : l'utilisateur a trouvé le bon produit rapidement et l'a
acheté chez un marchand fiable au bon prix — pas chez un revendeur trop cher ni chez un
dropshipper.

---
name: modele-perso-pi
description: 'Enregistrer un modèle personnalisé ou une variante (par exemple un slug OpenRouter « :nitro » / « :floor » / « :exacto ») dans l''agent Pi pour pouvoir le définir comme modèle par défaut. À utiliser quand Pi retombe silencieusement sur un autre modèle après avoir défini defaultModel, ou quand un slug n''est pas dans la liste embarquée de Pi. Se déclenche sur « Pi a réinitialisé mon modèle », « Pi refuse d''utiliser ce modèle », « ajoute un modèle à Pi », « le défaut de Pi revient tout seul ».'
disable-model-invocation: true
---

# Modèle personnalisé ou variante dans Pi

## Quand l'utiliser

Le modèle par défaut enregistré dans Pi ne se charge que si le couple exact
`fournisseur/identifiant` existe dans son registre de modèles. Pi livre une liste
**statique** par fournisseur — donc les **variantes de routage** OpenRouter (`:nitro` = tri
par débit, `:floor` = le moins cher, `:exacto` = usage d'outils de qualité) et tout slug
récent n'y sont **pas**.

Quand le défaut ne se résout pas, Pi retombe silencieusement sur son défaut interne pour ce
fournisseur — ce qui donne l'impression que Pi a « réinitialisé » votre modèle.
**Le symptôme est un modèle différent dans le pied de page, sans aucun message d'erreur.**

Le correctif consiste à enregistrer le slug comme modèle personnalisé pour que la recherche
interne trouve une correspondance.

## Fichiers (globaux)

| Fichier | Contenu |
|---|---|
| `~/.pi/agent/settings.json` | `defaultProvider`, `defaultModel`, `defaultThinkingLevel` |
| `~/.pi/agent/models.json` | Modèles personnalisés, indexés par fournisseur |
| `~/.pi/agent/auth.json` | Identifiants des fournisseurs |

## Étapes

1. **Confirmez que le slug est réel** avant de l'ajouter (vérifiez que le modèle ou la
   variante existe chez le fournisseur). Un identifiant mal orthographié retombe aussi
   silencieusement — vous chercherez le bug ailleurs pendant longtemps.

2. **Confirmez l'authentification.** Le fournisseur doit avoir une clé dans `auth.json` ou
   une variable d'environnement. Sans authentification, le modèle est enregistré mais
   indisponible → repli silencieux, même symptôme.

3. **Ajoutez le modèle dans `models.json`** sous `providers.<fournisseur>.models`.
   Pour un **fournisseur intégré** (openrouter, anthropic, etc.), vous ne fournissez que
   les métadonnées : `api`, `baseUrl` et l'authentification sont hérités des défauts
   embarqués.

   ```json
   {
     "providers": {
       "openrouter": {
         "models": [
           {
             "id": "fournisseur/modele:nitro",
             "name": "Modèle (nitro)",
             "reasoning": true,
             "thinkingLevelMap": { "xhigh": "xhigh" },
             "input": ["text"],
             "cost": { "input": 0.95, "output": 3, "cacheRead": 0.18, "cacheWrite": 0 },
             "contextWindow": 1048576,
             "maxTokens": 32768,
             "compat": { "supportsDeveloperRole": false, "thinkingFormat": "openrouter" }
           }
         ]
       }
     }
   }
   ```

   **Copiez `cost`, `contextWindow` et `compat` depuis le modèle de base** (la variante les
   partage). Trouvez l'entrée embarquée dans les fichiers de définition de modèles du
   paquet Pi installé. Ne codez pas en dur des valeurs génériques (128k / 16k) si le vrai
   modèle est plus grand : vous perdriez de la fenêtre de contexte sans le savoir.

4. **Définissez le défaut** dans `settings.json` : `defaultProvider` et `defaultModel`
   égaux à l'identifiant exact. Laissez `defaultThinkingLevel` tel que l'utilisateur l'a.

5. **Vérifiez** : `pi --list-models | grep <identifiant>` doit l'afficher, et le JSON doit
   s'analyser. Test de fumée optionnel :
   `pi --provider <f> --model "<id>" "quel modèle es-tu ?"`.

## Particularités

- **Correspondance exacte uniquement.** La recherche est une égalité stricte sur
  `fournisseur` + `identifiant` — aucun rapprochement approximatif, aucun retrait du
  deux-points pour le chemin du défaut enregistré. Le slug dans `settings.json` et dans
  `models.json` doit être **identique octet pour octet**.
- **Repli silencieux.** Pi n'affiche aucune erreur quand le défaut ne se résout pas ; il
  montre simplement un autre modèle dans le pied de page. C'est le seul indice.
- **N'éditez pas `settings.json` seul.** Définir `defaultModel` sur un slug non enregistré
  ne fait rien : `models.json` est le vrai correctif.
- **`enabledModels`** (optionnel) épingle le sélecteur de modèle pour que le cycle au
  clavier ne dérive pas : `"enabledModels": ["<fournisseur>/<id>:<niveau>"]`.
- **Surcharge par projet.** Un `.pi/settings.json` dans un dépôt l'emporte sur le global.
  Si un défaut ne revient que dans un projet, regardez ce fichier en premier.
- **Redémarrez Pi complètement** : le registre est chargé au démarrage.

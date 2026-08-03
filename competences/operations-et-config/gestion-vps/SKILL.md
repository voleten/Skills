---
name: gestion-vps
description: 'À utiliser quand l''utilisateur veut gérer ses serveurs VPS et les agents IA qui tournent dedans — connexion, déploiement, surveillance, redémarrage, exploitation des hôtes distants et de leurs agents. Se déclenche sur VPS, gestion de serveur, hôte distant, « connecte-toi au serveur », « gère mes serveurs », « les agents sur le serveur ».'
---

# Gestion de VPS

**Source de vérité** : le fichier d'inventaire d'infrastructure de l'utilisateur (chemin
indiqué dans `PROFIL.md` à la racine du dépôt de compétences). Lisez-le à chaque fois :
les adresses IP, les rôles et les échéances changent.

**Ne consignez jamais d'adresses IP, d'identifiants ou de dates d'expiration dans une
compétence.** Une compétence est versionnée, souvent publiée, et ces données pourrissent.
Elles vivent dans l'inventaire, hors du dépôt.

## Niveaux d'accès (ne partagez jamais plus haut que nécessaire)

C'est la partie de cette compétence qui compte le plus : un niveau d'accès partagé par
inadvertance ne se reprend pas.

| Niveau | Ce que ça donne | À qui le partager |
|---|---|---|
| **1. Compte applicatif** | Construire et modifier des flux ; aucun accès serveur | Le plus sûr à partager |
| **2. SSH sur le VPS** | Docker, fichiers, configuration système | Personnes techniques de confiance uniquement |
| **3. Panneau d'hébergement** | Facturation, redémarrage, réinstallation du système | **L'utilisateur seul.** Expose les identifiants SSH et un terminal navigateur, donc il donne aussi l'accès serveur |

Le niveau 3 est régulièrement sous-estimé : on le voit comme « juste la facturation »,
alors qu'il contient une porte vers le niveau 2.

## Gérer un VPS via un agent

Pour du travail exploratoire ou en plusieurs étapes, **connectez-vous en SSH puis lancez
l'agent SUR le VPS**, et dialoguez avec cet agent local à la machine. Il a le contexte
complet du système de fichiers et des processus, et cela évite des allers-retours SSH
fragiles où chaque commande perd l'état de la précédente.

Pour de courtes séquences (mise à jour, changement de configuration, redémarrage), piloter
directement une session SSH existante convient très bien.

Quand vous surveillez un agent distant, envoyez à l'utilisateur **une seule ligne** de
statut à chaque vérification : ce qu'il fait et s'il est sur la bonne voie.

Note Claude Code dans cmux : après avoir terminé, Claude peut pré-remplir un message
utilisateur prédit. Ce brouillon vient de Claude, pas de l'utilisateur.

## Précautions

- **Confirmez sur quel hôte vous êtes** avant toute commande destructrice : `hostname`,
  `hostnamectl`. Une commande lancée sur le mauvais VPS est le mode de panne classique.
- **Les redémarrages de service coupent les utilisateurs.** Demandez avant de redémarrer
  un service en production, sauf si l'utilisateur vous l'a explicitement demandé.
- **Ne modifiez jamais la configuration du pare-feu ou de SSH sans confirmation** : une
  erreur vous verrouille hors de la machine, et le rétablissement passe par le panneau
  d'hébergement de niveau 3.
- **Sauvegardez avant d'éditer** tout fichier de configuration : `cp fichier fichier.bak.$(date +%s)`.

## Exploitation d'un agent hébergé

Motifs typiques, à adapter à l'agent réellement installé :

```bash
<agent> --version               # version et retard éventuel
<agent> update                  # met à jour et redémarre la passerelle
<agent> gateway status|restart
journalctl --user -u <service> --since '5 min ago' --no-pager   # journaux (service systemd utilisateur)
```

Points d'attention récurrents :

- **Le modèle par défaut vit souvent dans le fichier de configuration YAML de l'agent,
  pas dans `.env`.** Le modifier dans `.env` ne fait rien, sans message d'erreur.
  Changez-le dans la configuration, puis redémarrez la passerelle pour propager.
- **Les avertissements de version de moteur pendant une mise à jour** (des dépendances
  demandant une version de Node plus récente que celle de la machine) sont en général non
  bloquants. **Ne les « corrigez » pas** en mettant à jour Node globalement : vous casserez
  autre chose.
- Les journaux d'un service utilisateur systemd exigent `--user` ; sans lui, vous
  interrogez le journal système et ne voyez rien.

## Vérifier avant de conclure

Après toute opération, vérifiez explicitement :

```bash
<agent> gateway status          # ou : systemctl --user is-active <service>
curl -sS -m 10 http://localhost:<port>/health   # si le service expose une sonde
```

N'annoncez jamais qu'un service est rétabli sans avoir vu sa sonde répondre.

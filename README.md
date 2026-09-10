# APT auto update

## Table des matières

- [APT auto update](#apt-auto-update)
    - [Table des matières](#table-des-matières)
    - [Description](#description)
    - [Installation](#installation)
    - [Désinstallation](#désinstallation)

## Description

APT auto update est une application graphique simple et intuitive qui permet de mettre à jour les paquets APT sur un système Linux.

Elle vous avertit lorsque des mises à jour sont disponibles et vous permet de les installer facilement en un seul clic.

Elle vérifie à chaque démarrage et une fois par semaine si des mises à jour sont disponibles et vous en informe par une notification.

Vous pouvez également lancer manuellement à tout moment la vérification des mises à jour via la commande `apt-auto-update` ou directement depuis la liste des applications.

## Installation

- Téléchargez le fichier `apt-auto-update.deb` depuis la page des [releases]()
- Installez le paquet avec la commande suivante :

```bash
sudo apt install ./apt-auto-update.deb
```

## Désinstallation

- Lancez la commande suivante pour désinstaller le paquet :

```bash
sudo apt remove apt-auto-update
```

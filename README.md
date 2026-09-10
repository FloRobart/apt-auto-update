# APT auto update

## Table des matières

- [APT auto update](#apt-auto-update)
    - [Table des matières](#table-des-matières)
    - [Description](#description)
    - [Installation](#installation)
        - [Installation via le dépôt APT](#installation-via-le-dépôt-apt)
        - [Installation via le fichier `.deb`](#installation-via-le-fichier-deb)
    - [Désinstallation](#désinstallation)

## Description

APT auto update est une application graphique simple et intuitive qui permet de mettre à jour les paquets APT sur un système Linux.

Elle vous avertit lorsque des mises à jour sont disponibles et vous permet de les installer facilement en un seul clic.

Elle vérifie à chaque démarrage et une fois par semaine si des mises à jour sont disponibles et vous en informe par une notification.

Vous pouvez également lancer manuellement à tout moment la vérification des mises à jour via la commande `apt-auto-update` ou directement depuis la liste des applications.

## Installation

### Installation via le dépôt APT

- Téléchargez et exécutez le script d'installation `install.sh` :

```bash
curl -fsSL https://FloRobart.github.io/apt-auto-update/install.sh | sudo bash
```

- Vous pouvez supprimer le fichier `install.sh` après l'installation si vous le souhaitez.

```bash
rm install.sh
```

### Installation via le fichier `.deb`

- Téléchargez le fichier `apt-auto-update.deb` depuis la page des [releases]()
- Installez le paquet avec la commande suivante :

```bash
sudo apt install ./apt-auto-update.deb
```

- Vous pouvez supprimer le fichier `apt-auto-update.deb` après l'installation si vous le souhaitez.

```bash
rm apt-auto-update.deb
```

## Désinstallation

- Lancez la commande suivante pour désinstaller le paquet :

```bash
sudo apt remove apt-auto-update
```

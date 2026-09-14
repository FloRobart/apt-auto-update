#!/bin/bash
set -e

# 1. Création du dossier de clés si manquant
mkdir -p -m 755 /etc/apt/keyrings

# 2. Ajout de la clé publique (l'option --yes permet d'écraser proprement si déjà présent)
curl -fsSL https://FloRobart.github.io/apt-auto-update/public.key | gpg --dearmor --yes -o /etc/apt/keyrings/apt-auto-update.gpg
chmod 644 /etc/apt/keyrings/apt-auto-update.gpg

# 3. Ajout du dépôt
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/apt-auto-update.gpg] https://FloRobart.github.io/apt-auto-update stable main" > /etc/apt/sources.list.d/apt-auto-update.list
chmod 644 /etc/apt/sources.list.d/apt-auto-update.list

# 4. Installation silencieuse sans interruption
apt update -q
apt install -y apt-auto-update

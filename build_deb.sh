#!/bin/bash
set -e

SOURCE_SCRIPT="./src/apt-auto-update.sh"
TARGET_DIR="./package/usr/bin"
PACKAGE_DIR="./package"
OUTPUT_DEB="apt-auto-update.deb"

# 1. Vérification de l'existence du script source
if [ ! -f "$SOURCE_SCRIPT" ]; then
    echo "Erreur : le fichier source '$SOURCE_SCRIPT' est introuvable." >&2
    exit 1
fi

# 2. Suppression de l'ancien paquet si il existe
if [ -f "$OUTPUT_DEB" ]; then
    rm "$OUTPUT_DEB"
fi

# 3. Copie du binaire dans l'arborescence du paquet
mkdir -p "$TARGET_DIR"
cp "$SOURCE_SCRIPT" "$TARGET_DIR/apt-auto-update"
chmod 755 "$TARGET_DIR/apt-auto-update"

# 4. Ajustement des permissions critiques (DEBIAN/postinst et sudoers)
if [ -f "$PACKAGE_DIR/DEBIAN/postinst" ]; then
    chmod 755 "$PACKAGE_DIR/DEBIAN/postinst"
fi

if [ -f "$PACKAGE_DIR/etc/sudoers.d/apt-auto-update" ]; then
    chmod 440 "$PACKAGE_DIR/etc/sudoers.d/apt-auto-update"
fi

# 5. Construction du fichier .deb
dpkg-deb --build --root-owner-group "$PACKAGE_DIR" "$OUTPUT_DEB"

echo "Paquet généré avec succès : $OUTPUT_DEB"

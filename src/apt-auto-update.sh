#!/bin/bash

# --- Fonction : Interface graphique complète (Zenity) ---
run_full_gui() {
    (
        sudo apt update >/dev/null 2>&1
        echo 100
    ) | zenity --progress --pulsate --auto-close --no-cancel --title="Mise à jour" --text="Actualisation des paquets en cours..."

    items=()
    while IFS= read -r line; do
        pkg=$(echo "$line" | cut -d'/' -f1)
        new_v=$(echo "$line" | awk '{print $2}')
        old_v=$(echo "$line" | sed -n 's/.*: *\([^]]*\)\]/\1/p')
        items+=(TRUE "$pkg" "${old_v:-inconnue}" "$new_v")
    done < <(LC_ALL=C apt list --upgradable 2>/dev/null | tail -n +2)

    if [ ${#items[@]} -eq 0 ]; then
        zenity --info --title="Système à jour" --text="Aucune mise à jour n'est disponible."
        exit 0
    fi

    selected_pkgs=$(zenity --list --checklist \
        --title="Sélection des mises à jour" \
        --column="Installer" --column="Paquet" --column="Version actuelle" --column="Nouvelle version" \
        --width=700 --height=400 \
        --separator=" " \
        --ok-label="Installer" --cancel-label="Annuler" \
        "${items[@]}")

    zenity_status=$?

    if [ $zenity_status -ne 0 ] || [ -z "$selected_pkgs" ]; then
        zenity --info --title="Annulation" --text="Aucune mise à jour n'a été installée."
        exit 0
    fi

    log_file=$(mktemp)
    (
        sudo apt install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --only-upgrade -y $selected_pkgs >"$log_file" 2>&1
        echo "$?" > "${log_file}.status"
        echo 100
    ) | zenity --progress --pulsate --auto-close --no-cancel --title="Installation" --text="Installation des mises à jour en cours..."

    upgrade_status=$(cat "${log_file}.status" 2>/dev/null || echo 1)

    if [ "$upgrade_status" -eq 0 ]; then
        zenity --info --title="Succès" --text="Mise à jour terminée avec succès."
        rm -f "$log_file"
    else
        last_logs=$(tail -n 5 "$log_file")
        zenity --error \
            --title="Erreur lors de la mise à jour" \
            --width=550 \
            --text="Une erreur est survenue lors de l'installation.\n\n<b>Dernières lignes du journal :</b>\n<tt>${last_logs}</tt>\n\n<a href=\"file://${log_file}\">Ouvrir le fichier de log</a>\n\nSi vous n'arrivez pas à ouvrir le fichier, il se trouve ici : ${log_file}"
    fi

    rm -f "${log_file}.status"
}

# --- Mode silencieux / vérification d'arrière-plan ---
check_and_notify() {
    # Récupère le premier argument (le délai en secondes), par défaut 0 si non renseigné
    local timer="${1:-0}"

    # Si le timer est supérieur à 0, on attend
    if [ "$timer" -gt 0 ]; then
        sleep "$timer"
    fi

    sudo apt update >/dev/null 2>&1

    # Compte le nombre de paquets à jour
    count=$(LC_ALL=C apt list --upgradable 2>/dev/null | tail -n +2 | grep -c '^[^ ]')

    if [ "$count" -gt 0 ]; then
        # On nettoie la sortie avec tr -d '\r\n' pour éviter les faux négatifs
        action=$(notify-send \
            --icon=system-software-update \
            --urgency=normal \
            --wait \
            --app-name="Mises à jour" \
            --action="upgrade=Installer les mises à jour" \
            "Mises à jour disponibles" \
            "$count mise(s) à jour logicielle(s) disponible(s) pour votre système." 2>/dev/null | tr -d '\r\n')

        # Accepte le clic sur le bouton ("upgrade")
        if [ "$action" = "upgrade" ]; then
            run_full_gui
        fi
    fi
}

# --- Point d'entrée ---
if [ "$1" == "--check" ]; then
    check_and_notify
else
    if [ "$1" == "--boot" ]; then
        check_and_notify 30
    else
        run_full_gui
    fi
fi

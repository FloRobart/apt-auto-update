#!/bin/bash

# Height (in pixels) of the "Détails" area once opened
readonly DETAILS_AREA_HEIGHT=400

# --- Function: open a yad window, always centered and with the same look as the others ---
# Arguments: <yad_option>...
show_yad_window() {
    # On Wayland, an application can't choose where its windows appear, so "--center"
    # would be ignored: yad goes through XWayland to be centered, and falls back to
    # Wayland if XWayland isn't available
    GDK_BACKEND=x11,wayland yad \
        --center \
        --borders=10 \
        --window-icon="system-software-update" \
        "$@"
}

# --- Function: show a message with an icon and a single "OK" button ---
# Arguments: <icon_name> <title> <text> [yad_option]...
show_message_window() {
    local icon_name="$1"
    local title="$2"
    local text="$3"
    shift 3

    show_yad_window \
        --image="$icon_name" \
        --title="$title" \
        --text="$text" \
        --width=400 \
        --button="OK:0" \
        "$@"
}

# --- Function: create a temporary GTK configuration folder whose stylesheet sets the "Détails" area height ---
# Prints the folder path, the caller has to delete it.
create_details_gtk_config() {
    local gtk_config_directory
    gtk_config_directory=$(mktemp -d)
    mkdir "$gtk_config_directory/gtk-3.0"

    local stylesheet="$gtk_config_directory/gtk-3.0/gtk.css"
    local user_stylesheet="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/gtk.css"

    # This folder replaces the user's one, so their own GTK styles are kept by importing them
    if [ -f "$user_stylesheet" ]; then
        echo "@import url(\"$user_stylesheet\");" > "$stylesheet"
    fi

    echo "#yad-dialog-window expander scrolledwindow { min-height: ${DETAILS_AREA_HEIGHT}px; }" >> "$stylesheet"

    echo "$gtk_config_directory"
}

# --- Function: run a command in a progress window, its output being shown live in a "Détails" area ---
# Arguments: <log_file> <title> <text> <command>...
# The command exit code is written to "<log_file>.status".
run_with_details_window() {
    local log_file="$1"
    local title="$2"
    local text="$3"
    shift 3

    # yad 0.40 ignores "--log-height" when the "Détails" area is opened after the window
    # is shown: GTK then only gives the area its minimum height, which is almost zero.
    # yad has no option to set this minimum, and GTK only loads extra styles from the
    # user's configuration folder, so this window gets a temporary one.
    local gtk_config_directory
    gtk_config_directory=$(create_details_gtk_config)

    (
        # tee ignores a broken pipe and keeps writing the log file, so closing
        # the window never interrupts the command (e.g. apt in the middle of an upgrade).
        # yad only sends lines starting with "#" to the "Détails" area and
        # unescapes the "\" sequences in them, hence the doubled backslashes.
        "$@" 2>&1 \
            | tee --output-error=warn-nopipe "$log_file" \
            | sed --unbuffered -e 's/\\/\\\\/g' -e 's/^/# /'

        echo "${PIPESTATUS[0]}" > "${log_file}.status"
        echo 100
    ) | XDG_CONFIG_HOME="$gtk_config_directory" show_yad_window --progress --pulsate --auto-close --no-buttons --no-escape \
        --title="$title" \
        --text="$text" \
        --enable-log="Détails" \
        --width=600

    if [ -d "$gtk_config_directory" ]; then
        rm -rf "$gtk_config_directory"
    fi
}

# --- Fonction : Interface graphique complète (yad) ---
run_full_gui() {
    # Only the "Détails" area needs this log: a failed refresh is still ignored, as before
    update_log_file=$(mktemp)
    run_with_details_window "$update_log_file" "Mise à jour" "Actualisation des paquets en cours..." \
        sudo apt update
    rm -f "$update_log_file" "${update_log_file}.status"

    items=()
    while IFS= read -r line; do
        pkg=$(echo "$line" | cut -d'/' -f1)
        new_v=$(echo "$line" | awk '{print $2}')
        old_v=$(echo "$line" | sed -n 's/.*: *\([^]]*\)\]/\1/p')
        items+=(TRUE "$pkg" "${old_v:-inconnue}" "$new_v")
    done < <(LC_ALL=C apt list --upgradable 2>/dev/null | tail -n +2)

    if [ ${#items[@]} -eq 0 ]; then
        show_message_window "dialog-information" "Système à jour" "Aucune mise à jour n'est disponible."
        exit 0
    fi

    # "--print-column=2" outputs only the package name of each checked row
    selected_pkgs=$(show_yad_window --list --checklist \
        --title="Sélection des mises à jour" \
        --column="Installer" --column="Paquet" --column="Version actuelle" --column="Nouvelle version" \
        --print-column=2 \
        --separator=" " \
        --width=700 --height=400 \
        --button="Annuler:1" --button="Installer:0" \
        "${items[@]}")

    selection_status=$?

    if [ $selection_status -ne 0 ] || [ -z "$selected_pkgs" ]; then
        show_message_window "dialog-information" "Annulation" "Aucune mise à jour n'a été installée."
        exit 0
    fi

    log_file=$(mktemp)
    run_with_details_window "$log_file" "Installation" "Installation des mises à jour en cours..." \
        sudo apt install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --only-upgrade -y $selected_pkgs

    upgrade_status=$(cat "${log_file}.status" 2>/dev/null || echo 1)

    if [ "$upgrade_status" -eq 0 ]; then
        show_message_window "dialog-information" "Succès" "Mise à jour terminée avec succès."
        rm -f "$log_file"
    else
        last_logs=$(tail -n 5 "$log_file")
        show_message_window "dialog-error" "Erreur lors de la mise à jour" \
            "Une erreur est survenue lors de l'installation.\n\n<b>Dernières lignes du journal :</b>\n<tt>${last_logs}</tt>\n\n<a href=\"file://${log_file}\">Ouvrir le fichier de log</a>\n\nSi vous n'arrivez pas à ouvrir le fichier, il se trouve ici : ${log_file}" \
            --width=550
    fi

    rm -f "${log_file}.status"
}

# --- Mode silencieux / vérification d'arrière-plan ---
check_and_notify() {
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
# The delay before the check at login is set by the systemd timer (OnStartupSec), not here.
# "--boot" is the option used by the service up to version 1.1.0: it is still accepted so that
# a session that has kept this old service loaded doesn't open the full window instead.
if [ "$1" == "--check" ] || [ "$1" == "--boot" ]; then
    check_and_notify
else
    run_full_gui
fi

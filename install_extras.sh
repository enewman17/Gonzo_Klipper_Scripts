#!/bin/bash
# Force script to exit if an error occurs
set -e

KLIPPER_PATH="${HOME}/klipper"
KLIPPER_SERVICE_NAME="klipper"
SYSTEMDDIR="/etc/systemd/system"
CONFIG_DIR="${HOME}/printer_data/config"

# Find SRCDIR from the pathname of this script
#SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/src" && pwd )"
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


set_permissions() 
{
    echo -n "Setting file and directory permissions"
    find . -type d -exec chmod 0744 {} +
    find . -type f -exec chmod 0744 {} +
    echo "[OK]"
}

# ---------------------------
# Helper functions

verify_ready()
{
    if [ "$EUID" -eq 0 ]; then
        echo "[ERROR] This script must not be run as root. Exiting."
        exit 1
    fi
}

check_klipper()
{
    if systemctl list-units --full -all -t service --no-legend | grep -qF "$KLIPPER_SERVICE_NAME.service"; then
        echo "Klipper service found with name \"$KLIPPER_SERVICE_NAME\"."
    else
        echo "[ERROR] Klipper service \"$KLIPPER_SERVICE_NAME\" not found. Please install Klipper first or specify the service name."
        exit 1
    fi
}

check_folders()
{
    if [ ! -d "$KLIPPER_PATH/klippy/extras/" ]; then
        echo "[ERROR] Klipper installation not found at \"$KLIPPER_PATH\". Exiting."
        exit 1
    fi
    echo "Klipper installation found at $KLIPPER_PATH"

    if [ ! -f "${CONFIG_DIR}/moonraker.conf" ]; then
        echo "[ERROR] Moonraker configuration not found in \"$CONFIG_DIR\". Exiting."
        exit 1
    fi
    echo "Moonraker configuration found at $CONFIG_DIR"
}

stop_klipper()
{
    echo -n "Stopping Klipper... "
    sudo systemctl stop "$KLIPPER_SERVICE_NAME"
    echo "[OK]"
}

link_extension()
{
    echo -n "Creating symlinks to klippy/extras... "
    for f in "${SRCDIR}/extras/"*; do
        ln -sf "$f" "${KLIPPER_PATH}/klippy/extras/"
    done
    echo "[OK]"
}

start_klipper()
{
    echo -n "Starting Klipper... "
    sudo systemctl start "$KLIPPER_SERVICE_NAME"
    echo "[OK]"
}


# Run steps
verify_ready
set_permissions
check_klipper
check_folders
stop_klipper
link_extension
start_klipper

#!/bin/bash
# Force script to exit if an error occurs
set -e

KLIPPER_PATH="${HOME}/klipper"
KLIPPER_SERVICE_NAME=klipper
SYSTEMDDIR="/etc/systemd/system"
CONFIG_DIR="${HOME}/printer_data/config"

# Find SRCDIR from the pathname of this script
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/src/ && pwd )"

# Run steps
verify_ready
check_klipper
check_folders
stop_klipper
link_extension
start_klipper



# Helper functions
verify_ready()
{
    if [ "$EUID" -eq 0 ]; then
        echo "[ERROR] This script must not run as root. Exiting."
        exit -1
    fi
}

# Verify Klipper has been installed
check_klipper()
{
    if [ "$(sudo systemctl list-units --full -all -t service --no-legend | grep -F "$KLIPPER_SERVICE_NAME.service")" ]; then
        echo "Klipper service found with name "$KLIPPER_SERVICE_NAME"."
    else
        echo "[ERROR] Klipper service with name "$KLIPPER_SERVICE_NAME" not found, please install Klipper first or specify name with -s."
        exit -1
    fi
}

check_folders()
{
    if [ ! -d "$KLIPPER_PATH/klippy/extras/" ]; then
        echo "[ERROR] Klipper installation not found in directory \"$KLIPPER_PATH\". Exiting"
        exit -1
    fi
    echo "Klipper installation found at $KLIPPER_PATH"

    if [ ! -f "${CONFIG_DIR}/moonraker.conf" ]; then
        echo "[ERROR] Moonraker configuration not found in directory \"$CONFIG_DIR\". Exiting"
        exit -1
    fi
    echo "Moonraker configuration found at $CONFIG_DIR"
}

stop_klipper()
{
    echo -n "Stopping Klipper... "
    sudo systemctl stop $KLIPPER_SERVICE_NAME
    echo "[OK]"
}

# Link extension to Klipper
link_extension()
{
    echo -n "Creating symlinks to klippy/extras... "
    ln -sf "${SRCDIR}/extras/*" "${KLIPPER_PATH}/klippy/extras/"
    echo "[OK]"
}

# Restart moonraker
restart_moonraker()
{
    echo -n "Restarting Moonraker... "
    sudo systemctl restart moonraker
    echo "[OK]"
}

restart_klipper()
{
    echo -n "Restarting Klipper... "
    sudo systemctl restart $KLIPPER_SERVICE_NAME
    echo "[OK]"
}

start_klipper()
{
    echo -n "Starting Klipper... "
    sudo systemctl start $KLIPPER_SERVICE_NAME
    echo "[OK]"
}

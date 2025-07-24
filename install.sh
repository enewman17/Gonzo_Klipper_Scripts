#!/bin/bash
# Force script to exit if an error occurs
set -e

KLIPPER_PATH="${HOME}/klipper"
KLIPPER_SERVICE_NAME=klipper
SYSTEMDDIR="/etc/systemd/system"
CONFIG_DIR="${HOME}/printer_data/config"

# Fall back to old directory for configuration as default
if [ ! -d "${CONFIG_DIR}" ]; then
    echo "\"$CONFIG_DIR\" does not exist. Falling back to "${HOME}/klipper_config" as default."
    CONFIG_DIR="${HOME}/klipper_config"
fi

usage(){ echo "Usage: $0 [-k <klipper path>] [-s <klipper service name>] [-c <configuration path>] [-u]" 1>&2; exit 1; }
# Parse command line arguments
while getopts "k:s:c:uh" arg; do
    case $arg in
        k) KLIPPER_PATH=$OPTARG;;
        s) KLIPPER_SERVICE_NAME=$OPTARG;;
        c) CONFIG_DIR=$OPTARG;;
        u) UNINSTALL=1;;
        h) usage;;
    esac
done

# Find SRCDIR from the pathname of this script
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/src/ && pwd )"

# Run steps
verify_ready
check_klipper
check_folders
stop_klipper
if [ ! $UNINSTALL ]; then
    link_extension
	copy_scripts
    add_updater
else
    uninstall
fi
start_klipper

#!/bin/bash
# Define the target directory using the user's home directory
TARGET_DIR="$HOME/printer_data/config"

# Ensure the target directory exists, create it if it doesn't
mkdir -p "$TARGET_DIR"

# Get the directory where the script is located
SCRIPT_DIR=$(dirname "$0")

# Inform the user and copy all .cfg files to the target directory
echo "Copying macro .cfg files to $TARGET_DIR"
cp "$SCRIPT_DIR"/*.cfg "$TARGET_DIR/"

# Inform the user and append the contents of gonzo.txt to printer.cfg
echo "Appending gonzo.txt to $TARGET_DIR/printer.cfg"
cat "$SCRIPT_DIR/gonzo.txt" >> "$TARGET_DIR/printer.cfg"

# Confirm completion
echo "Installation complete."


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

copy_scripts()
{
    echo -n "Copying scripts to config folder... "
    cp -r "${SRCDIR}/Klipper_Macros/*" "${CONFIG_DIR}"
    echo "[OK]"
}

# Add updater to moonraker.conf
add_updater()
{
    echo -e -n "Adding update manager to moonraker.conf... "

    update_section=$(grep -c '\[update_manager Gonzo_Klipper_Scripts\]' ${CONFIG_DIR}/moonraker.conf || true)
    if [ "${update_section}" -eq 0 ]; then
        echo -e "\n" >> ${CONFIG_DIR}/moonraker.conf
        while read -r line; do
            echo -e "${line}" >> ${CONFIG_DIR}/moonraker.conf
        done < "$PWD/file_templates/moonraker_update.txt"
        echo -e "\n" >> ${CONFIG_DIR}/moonraker.conf
        echo "[OK]"
        restart_moonraker
        else
        echo -e "[update_manager increase_neopixel_chain_length] already exists in moonraker.conf [SKIPPED]"
    fi
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

uninstall()
{
    if [ -f "${KLIPPER_PATH}/klippy/extras/" ]; then
        echo -n "Uninstalling... "
        rm -f "${KLIPPER_PATH}/klippy/extras/"
        echo "[OK]"
        echo "You can now remove the [update_manager increase_neopixel_chain_length] section in your moonraker.conf and delete this directory. Also remove all (increase_neopixel_chain_length) configurations from your Klipper configuration."
    else
        echo " not found in \"${KLIPPER_PATH}/klippy/extras/\". Is it installed?"
        echo "[FAILED]"
    fi
}

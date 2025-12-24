#!/bin/bash


KLIPPER_HOME="${HOME}/klipper"
MOONRAKER_HOME="${HOME}/moonraker"
KLIPPER_CONFIG_HOME="${HOME}/printer_data/config"

# Find SRCDIR from the pathname of this script
# SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/ && pwd )"
SRCDIR="${HOME}/Happy-Hare"

# Force script to exit if an error occurs
set -e

link_mmu_plugins() {
    echo -e "${INFO}Linking mmu extensions to Klipper..."
    if [ -d "${KLIPPER_HOME}/klippy/extras" ]; then
        mkdir -p "${KLIPPER_HOME}/klippy/extras/mmu"
        for dir in extras extras/mmu; do
            for file in ${SRCDIR}/${dir}/*.py; do
                ln -sf "$file" "${KLIPPER_HOME}/klippy/${dir}/$(basename "$file")"
            done
        done
    else
        echo -e "${WARNING}Klipper extensions not installed because Klipper 'extras' directory not found!"
    fi

    echo -e "${INFO}Linking mmu extension to Moonraker..."
    if [ -d "${MOONRAKER_HOME}/moonraker/components" ]; then
        for file in `cd ${SRCDIR}/components ; ls *.py`; do
            ln -sf "${SRCDIR}/components/${file}" "${MOONRAKER_HOME}/moonraker/components/${file}"
        done
    else
        echo -e "${WARNING}Moonraker extensions not installed because Moonraker 'components' directory not found!"
    fi
}


link_mmu_plugins

#!/bin/bash

SHAPER_SCRIPT=~/klipper/scripts/calibrate_shaper.py
OUTPUT_DIR=~/printer_data/config/Klipper_Macros/shaper

run_cal() {
    local axis=$1
    echo "Processing $axis axis..."
    $SHAPER_SCRIPT /tmp/calibration_data_${axis}_*.csv -o ${OUTPUT_DIR}/shaper_calibration_graph_${axis}.png
}

# The input is now expected as a clean string (e.g., xyz)
INPUT_ARGS="$1"

if [[ -z "$INPUT_ARGS" ]]; then
    echo "No axis specified. Usage: convert_stats xyz"
    exit 1
fi

# Loop through each letter in the argument
for (( i=0; i<${#INPUT_ARGS}; i++ )); do
    axis="${INPUT_ARGS:$i:1}"
    case $axis in
        x|y|z)
            run_cal "$axis"
            ;;
        *)
            echo "Ignoring unknown character: $axis"
            ;;
    esac
done

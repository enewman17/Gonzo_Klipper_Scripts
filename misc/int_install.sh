#!/bin/bash
set -e

CONFIG_DIR="${HOME}/printer_data/config"
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

declare -A FILE_SELECTIONS

echo "Scanning directories under: $SOURCE_DIR"
echo "Target config directory: $CONFIG_DIR"
echo

# Step 1: Recursively find all folders
mapfile -t FOLDERS < <(find "$SOURCE_DIR" -type d | grep -v "$CONFIG_DIR")

# Step 2: Show files in each folder and ask what to install
for folder in "${FOLDERS[@]}"; do
    REL_FOLDER="${folder#$SOURCE_DIR/}"  # Relative path from script dir
    mapfile -t FILES < <(find "$folder" -maxdepth 1 -type f)

    if [ ${#FILES[@]} -eq 0 ]; then
        continue
    fi

    echo "📁 Folder: $REL_FOLDER"
    select_option=()
    i=1
    for file in "${FILES[@]}"; do
        fname=$(basename "$file")
        echo "  [$i] $fname"
        select_option+=("$file")
        ((i++))
    done

    echo "Select files to install (e.g., 1 2 3, or press Enter to skip):"
    read -r selection

    for sel in $selection; do
        index=$((sel - 1))
        if [[ $index -ge 0 && $index -lt ${#select_option[@]} ]]; then
            FILE_SELECTIONS["${select_option[$index]}"]="$REL_FOLDER"
        fi
    done
    echo
done

# Step 3: Copy selected files to CONFIG_DIR preserving folder structure
echo "Installing selected files..."
for src_file in "${!FILE_SELECTIONS[@]}"; do
    target_subdir="${FILE_SELECTIONS[$src_file]}"
    dest_dir="$CONFIG_DIR/$target_subdir"

    mkdir -p "$dest_dir"
    cp "$src_file" "$dest_dir/"
    echo "✅ Copied $(basename "$src_file") to $dest_dir"
done

echo
echo "🎉 Installation complete."

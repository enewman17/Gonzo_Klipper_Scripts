#!/usr/bin/env bash
set -e

CONFIG_DIR="${HOME}/printer_data/config"
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/src" && pwd )"

# Ensure CONFIG_DIR exists
mkdir -p "$CONFIG_DIR"

# Collect files by subfolder
declare -A files_by_dir

while IFS= read -r -d '' file; do
    rel_path="${file#$SRCDIR/}"
    rel_dir="$(dirname "$rel_path")"
    files_by_dir["$rel_dir"]+="${file}"$'\n'
done < <(find "$SRCDIR" -type f -print0)

echo "Available files to install:"
echo "----------------------------"

i=1
menu_items=()
file_paths=()

# Display all folders and files
for folder in "${!files_by_dir[@]}"; do
    echo "[$folder]"
    while read -r file; do
        [[ -z "$file" ]] && continue
        rel_file="${file#$SRCDIR/}"
        echo "  [$i] $rel_file"
        menu_items+=("$rel_file")
        file_paths+=("$file")
        ((i++))
    done <<< "${files_by_dir[$folder]}"
    echo
done

# Prompt user
echo "Enter the numbers of the files to install (e.g. 1 3 5), or type 'all' to install everything:"
read -rp "> " selections

install_all=false
if [[ "$selections" == "all" ]]; then
    install_all=true
fi

echo
echo "Installing files into $CONFIG_DIR ..."
echo "-------------------------------------"

# Install folder-by-folder
for folder in "${!files_by_dir[@]}"; do
    echo "[$folder]"
    while read -r file; do
        [[ -z "$file" ]] && continue
        rel_path="${file#$SRCDIR/}"
        dest_path="$CONFIG_DIR/$rel_path"

        if $install_all; then
            mkdir -p "$(dirname "$dest_path")"
            cp "$file" "$dest_path"
            echo "✔ Copied: $rel_path"
        else
            # Find index of file in menu_items
            for i in "${!menu_items[@]}"; do
                if [[ "${menu_items[$i]}" == "$rel_path" ]]; then
                    index=$((i + 1))
                    if [[ $selections =~ (^|[[:space:]])$index($|[[:space:]]) ]]; then
                        mkdir -p "$(dirname "$dest_path")"
                        cp "$file" "$dest_path"
                        echo "✔ Copied: $rel_path"
                    fi
                fi
            done
        fi
    done <<< "${files_by_dir[$folder]}"
    echo
done

echo "[DONE] Selected files installed to $CONFIG_DIR."

#!/usr/bin/env bash
set -e

# Constants
CONFIG_DIR="${HOME}/printer_data/config"
KLIPPER_PATH="${HOME}/klipper"
KLIPPER_SERVICE_NAME="klipper"
SYSTEMDDIR="/etc/systemd/system"
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/src" && pwd )"

# Ensure CONFIG_DIR exists
mkdir -p "$CONFIG_DIR"

# Check klipper extras folder
KLIPPER_EXTRAS_PATH="$KLIPPER_PATH/klippy/extras"
if [ ! -d "$KLIPPER_EXTRAS_PATH" ]; then
    echo "[ERROR] Expected Klipper extras path not found at: $KLIPPER_EXTRAS_PATH"
    exit 1
fi

# Collect files by subfolder
declare -A files_by_dir
while IFS= read -r -d '' file; do
    rel_path="${file#$SRCDIR/}"
    rel_dir="$(dirname "$rel_path")"
    files_by_dir["$rel_dir"]+="${file}"$'\n'
done < <(find "$SRCDIR" -type f -print0)

echo "Available files to install:"
echo "----------------------------"

i=1
menu_items=()
file_paths=()

# Display all folders and files
for folder in "${!files_by_dir[@]}"; do
    echo "[$folder]"
    while read -r file; do
        [[ -z "$file" ]] && continue
        rel_file="${file#$SRCDIR/}"
        echo "  [$i] $rel_file"
        menu_items+=("$rel_file")
        file_paths+=("$file")
        ((i++))
    done <<< "${files_by_dir[$folder]}"
    echo
done

# Prompt user
echo "Enter the numbers of the files to install (e.g. 1 3 5), or type 'all' to install everything:"
read -rp "> " selections

install_all=false
if [[ "$selections" == "all" ]]; then
    install_all=true
fi

echo
echo "Installing files into $CONFIG_DIR ..."
echo "-------------------------------------"

# Install folder-by-folder
for folder in "${!files_by_dir[@]}"; do
    echo "[$folder]"
    while read -r file; do
        [[ -z "$file" ]] && continue
        rel_path="${file#$SRCDIR/}"
        dest_path="$CONFIG_DIR/$rel_path"

        should_install=false
        if $install_all; then
            should_install=true
        else
            for i in "${!menu_items[@]}"; do
                index=$((i + 1))
                if [[ "${menu_items[$i]}" == "$rel_path" && $selections =~ (^|[[:space:]])$index($|[[:space:]]) ]]; then
                    should_install=true
                    break
                fi
            done
        fi

        if $should_install; then
            mkdir -p "$(dirname "$dest_path")"
            cp "$file" "$dest_path"
            echo "✔ Copied: $rel_path → $dest_path"

            # Handle extras/*.py symlinking
            if [[ "$folder" == extras* && "$file" == *.py ]]; then
                ln -sf "$file" "$KLIPPER_EXTRAS_PATH/"
                echo "🔗 Symlinked to Klipper extras: $(basename "$file")"
            fi
        fi
    done <<< "${files_by_dir[$folder]}"
    echo
done

echo "[DONE] Selected files installed to $CONFIG_DIR."

#!/usr/bin/env bash

set -euo pipefail


# ─────────────────────────────────────────────
# Basic setup
# ─────────────────────────────────────────────

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAME="$(whoami)"

CONFIG="/etc/nixos/configuration.nix"
IMPORT="./whitebox/imports.nix"

BACKUP_CREATED=false

echo "Whitebox installer"
echo "User: $USERNAME"
echo "Repo: $REPO_DIR"


# ─────────────────────────────────────────────
# Safety checks
# ─────────────────────────────────────────────

if [ "$(id -u)" -eq 0 ]; then
    echo
    echo "ERROR: Do not run install.sh with sudo."
    echo "Run it as your normal user instead."
    exit 1
fi

if [ ! -f "$CONFIG" ]; then
    echo
    echo "ERROR: $CONFIG does not exist."
    echo "This installer expects a standard NixOS configuration."
    exit 1
fi


# ─────────────────────────────────────────────
# Generate local settings
# ─────────────────────────────────────────────

cat > "$REPO_DIR/settings.nix" <<EOF
{
  username = "$USERNAME";
}
EOF

echo "Generated settings.nix"


# ─────────────────────────────────────────────
# Link Whitebox into /etc/nixos
# ─────────────────────────────────────────────

if [ -L /etc/nixos/whitebox ]; then
    CURRENT_TARGET="$(readlink -f /etc/nixos/whitebox)"

    if [ "$CURRENT_TARGET" = "$REPO_DIR" ]; then
        echo "Whitebox symlink already correct."
    else
        echo "Updating existing Whitebox symlink..."

        sudo rm /etc/nixos/whitebox
        sudo ln -s "$REPO_DIR" /etc/nixos/whitebox
    fi

elif [ -e /etc/nixos/whitebox ]; then
    echo
    echo "ERROR: /etc/nixos/whitebox already exists and is not a symlink."
    exit 1

else
    sudo ln -s "$REPO_DIR" /etc/nixos/whitebox
fi

echo "Linked:"
echo "/etc/nixos/whitebox -> $REPO_DIR"


# ─────────────────────────────────────────────
# Add Whitebox import
# ─────────────────────────────────────────────

if grep -Fq "$IMPORT" "$CONFIG"; then
    echo "Whitebox import already present."

else
    echo "Adding Whitebox to configuration.nix..."

    # Back up configuration.nix before changing it.
    sudo cp \
        "$CONFIG" \
        "${CONFIG}.whitebox-backup"

    BACKUP_CREATED=true

    # Inject Whitebox into the imports list.
    #
    # Supports both:
    #
    #   imports = [
    #
    # and:
    #
    #   imports =
    #     [
    #
    # including the default NixOS format:
    #
    #   imports =
    #     [ # Include the results of the hardware scan.
    #       ./hardware-configuration.nix
    #     ];

    TEMP_CONFIG="$(mktemp)"

    if awk -v import="$IMPORT" '
        BEGIN {
            waiting_for_bracket = 0
            inserted = 0
        }

        /^[[:space:]]*imports[[:space:]]*=/ {
            print

            # Opening bracket is already on this line.
            if ($0 ~ /\[/) {
                print "    " import
                inserted = 1
            } else {
                waiting_for_bracket = 1
            }

            next
        }

        waiting_for_bracket && /\[/ {
            print
            print "    " import

            waiting_for_bracket = 0
            inserted = 1

            next
        }

        {
            print
        }

        END {
            if (!inserted)
                exit 42
        }
    ' "$CONFIG" > "$TEMP_CONFIG"; then

        sudo cp \
            "$TEMP_CONFIG" \
            "$CONFIG"

        rm "$TEMP_CONFIG"

        echo "Whitebox import added."

    else
        rm -f "$TEMP_CONFIG"

        echo
        echo "ERROR: Could not find an imports list."
        echo "Restoring original configuration.nix..."

        sudo cp \
            "${CONFIG}.whitebox-backup" \
            "$CONFIG"

        BACKUP_CREATED=false

        echo "Original configuration restored."

        exit 1
    fi
fi


# ─────────────────────────────────────────────
# Validate configuration
# ─────────────────────────────────────────────

echo
echo "Validating NixOS configuration..."

if ! sudo nixos-rebuild dry-build; then
    echo
    echo "ERROR: Whitebox configuration failed to build."

    # Only restore configuration.nix if this particular
    # installer run modified it.
    if [ "$BACKUP_CREATED" = true ]; then
        echo "Restoring original configuration.nix..."

        sudo cp \
            "${CONFIG}.whitebox-backup" \
            "$CONFIG"

        echo "Original configuration restored."
    fi

    exit 1
fi

echo "Configuration valid."


# ─────────────────────────────────────────────
# Activate configuration
# ─────────────────────────────────────────────

echo
echo "Activating Whitebox..."

if ! sudo nixos-rebuild switch; then
    echo
    echo "ERROR: Failed to activate Whitebox."
    echo "The previous NixOS generation remains available."
    exit 1
fi


# ─────────────────────────────────────────────
# Finished
# ─────────────────────────────────────────────

echo
echo "Whitebox installation complete."

if [ "$BACKUP_CREATED" = true ]; then
    echo
    echo "Original configuration backup:"
    echo "${CONFIG}.whitebox-backup"
fi

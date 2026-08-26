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
# PCI bus ID conversion
#
# Linux:
#   0000:01:00.0
#
# NixOS PRIME:
#   PCI:1:0:0
# ─────────────────────────────────────────────

pci_to_nix_bus_id() {
    local pci_address="$1"

    # Remove PCI domain.
    local address="${pci_address#*:}"

    local bus="${address%%:*}"
    local rest="${address#*:}"

    local device="${rest%%.*}"
    local function="${rest#*.}"

    printf 'PCI:%d:%d:%d' \
        "$((16#$bus))" \
        "$((16#$device))" \
        "$((16#$function))"
}


# ─────────────────────────────────────────────
# Detect graphics hardware
# ─────────────────────────────────────────────

echo
echo "Detecting graphics hardware..."

NVIDIA=false
NVIDIA_PRIME=false

NVIDIA_DEVICE=""
INTEL_DEVICE=""
AMD_DEVICE=""

NVIDIA_BUS_ID=""
IGPU_BUS_ID=""
PRIME_IGPU=""

for DEVICE in /sys/bus/pci/devices/*; do
    [ -f "$DEVICE/vendor" ] || continue
    [ -f "$DEVICE/class" ] || continue

    VENDOR="$(cat "$DEVICE/vendor")"
    CLASS="$(cat "$DEVICE/class")"

    # PCI class 0x03xxxx = display controller.
    [[ "$CLASS" == 0x03* ]] || continue

    PCI_ADDRESS="$(basename "$DEVICE")"

    case "$VENDOR" in

        # NVIDIA
        0x10de)
            if [ -z "$NVIDIA_DEVICE" ]; then
                NVIDIA_DEVICE="$PCI_ADDRESS"
            fi
            ;;

        # Intel
        0x8086)
            if [ -z "$INTEL_DEVICE" ]; then
                INTEL_DEVICE="$PCI_ADDRESS"
            fi
            ;;

        # AMD / ATI
        0x1002)
            if [ -z "$AMD_DEVICE" ]; then
                AMD_DEVICE="$PCI_ADDRESS"
            fi
            ;;
    esac
done


# ─────────────────────────────────────────────
# NVIDIA detection
# ─────────────────────────────────────────────

if [ -n "$NVIDIA_DEVICE" ]; then
    NVIDIA=true

    NVIDIA_BUS_ID="$(
        pci_to_nix_bus_id "$NVIDIA_DEVICE"
    )"

    echo "NVIDIA GPU detected:"
    echo "  PCI device: $NVIDIA_DEVICE"
    echo "  Bus ID:     $NVIDIA_BUS_ID"
else
    echo "No NVIDIA GPU detected."
fi


# ─────────────────────────────────────────────
# Laptop detection
#
# PRIME is mainly relevant to hybrid laptops.
# Requiring a battery prevents a multi-GPU
# desktop from being mistaken for one.
# ─────────────────────────────────────────────

HAS_BATTERY=false

for BATTERY in /sys/class/power_supply/BAT*; do
    if [ -e "$BATTERY" ]; then
        HAS_BATTERY=true
        break
    fi
done


# ─────────────────────────────────────────────
# PRIME detection
# ─────────────────────────────────────────────

if [ "$NVIDIA" = true ] \
    && [ "$HAS_BATTERY" = true ]; then

    if [ -n "$INTEL_DEVICE" ]; then
        NVIDIA_PRIME=true
        PRIME_IGPU="intel"

        IGPU_BUS_ID="$(
            pci_to_nix_bus_id "$INTEL_DEVICE"
        )"

    elif [ -n "$AMD_DEVICE" ]; then
        NVIDIA_PRIME=true
        PRIME_IGPU="amd"

        IGPU_BUS_ID="$(
            pci_to_nix_bus_id "$AMD_DEVICE"
        )"
    fi
fi


if [ "$NVIDIA_PRIME" = true ]; then
    echo
    echo "Hybrid NVIDIA laptop detected."

    if [ "$PRIME_IGPU" = "intel" ]; then
        echo "Integrated GPU: Intel"
    else
        echo "Integrated GPU: AMD"
    fi

    echo "  iGPU Bus ID:   $IGPU_BUS_ID"
    echo "  NVIDIA Bus ID: $NVIDIA_BUS_ID"

elif [ "$NVIDIA" = true ]; then
    echo
    echo "NVIDIA GPU detected without hybrid PRIME configuration."
fi


# ─────────────────────────────────────────────
# Generate local settings
# ─────────────────────────────────────────────

cat > "$REPO_DIR/settings.nix" <<EOF
{
  username = "$USERNAME";

  nvidia = $NVIDIA;
  nvidiaPrime = $NVIDIA_PRIME;

  primeIGPU = "$PRIME_IGPU";
  igpuBusId = "$IGPU_BUS_ID";
  nvidiaBusId = "$NVIDIA_BUS_ID";
}
EOF

echo
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
    # Supports:
    #
    #   imports = [
    #
    # and:
    #
    #   imports =
    #     [
    #
    # including the stock NixOS style:
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

    # Only restore configuration.nix if this
    # particular installer run modified it.
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

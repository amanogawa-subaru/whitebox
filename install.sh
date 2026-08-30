#!/usr/bin/env bash

set -euo pipefail


# ─────────────────────────────────────────────
# Basic setup
# ─────────────────────────────────────────────

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAME="$(whoami)"

CONFIG="/etc/nixos/configuration.nix"
PORTAL="/etc/nixos/flake.nix"

echo "whitebox installer"
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
# Generate local user packages
# ─────────────────────────────────────────────

USER_PACKAGES="$REPO_DIR/modules/user-packages.nix"
USER_PACKAGES_EXAMPLE="$REPO_DIR/modules/user-packages.example.nix"

if [ ! -f "$USER_PACKAGES" ]; then
    if [ ! -f "$USER_PACKAGES_EXAMPLE" ]; then
        echo
        echo "ERROR: $USER_PACKAGES_EXAMPLE does not exist."
        exit 1
    fi

    cp "$USER_PACKAGES_EXAMPLE" "$USER_PACKAGES"

    echo
    echo "Generated user-packages.nix"
else
    echo
    echo "Existing user-packages.nix preserved."
fi


# ─────────────────────────────────────────────
# Generate local mounts
# ─────────────────────────────────────────────

MOUNT_CONFIG="$REPO_DIR/modules/mount.nix"
MOUNT_EXAMPLE="$REPO_DIR/modules/mount.example.nix"

if [ ! -f "$MOUNT_CONFIG" ]; then
    if [ ! -f "$MOUNT_EXAMPLE" ]; then
        echo
        echo "ERROR: $MOUNT_EXAMPLE does not exist."
        exit 1
    fi

    cp "$MOUNT_EXAMPLE" "$MOUNT_CONFIG"

    echo
    echo "Generated mount.nix"
else
    echo
    echo "Existing mount.nix preserved."
fi


# ─────────────────────────────────────────────
# Set up profile composition portal
# ─────────────────────────────────────────────

PORTAL_MARKER="# Generated by whitebox"

if [ -f "$PORTAL" ]; then
    if grep -Fq "$PORTAL_MARKER" "$PORTAL"; then
        echo
        echo "Existing whitebox Portal detected."
        echo "Updating Portal configuration."
    else
        echo
        echo "ERROR: $PORTAL already exists and was not generated by whitebox."
        echo "Refusing to overwrite an existing NixOS flake."
        echo
        echo "Your existing flake has been left untouched."
        exit 1
    fi
fi

sudo tee "$PORTAL" > /dev/null <<EOF
$PORTAL_MARKER
{
  description = "NixOS profile composition portal";

  inputs = {
    whitebox.url = "path:$REPO_DIR";

    nixpkgs.follows = "whitebox/nixpkgs";
  };

  outputs = { nixpkgs, whitebox, ... }:
  {
    nixosConfigurations.portal = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./configuration.nix
        whitebox.nixosModules.default
      ];
    };
  };
}
EOF

echo
echo "Portal configured at $PORTAL"


# ─────────────────────────────────────────────
# Validate configuration
# ─────────────────────────────────────────────

echo
echo "Validating NixOS configuration..."

if ! sudo nixos-rebuild dry-build \
    --flake /etc/nixos#portal \
    --no-write-lock-file \
    --option experimental-features "nix-command flakes"; then

    echo
    echo "ERROR: whitebox configuration failed to build."
    echo "No system changes were activated."
    exit 1
fi

echo "Configuration valid."


# ─────────────────────────────────────────────
# Activate configuration
# ─────────────────────────────────────────────

echo
echo "Activating whitebox..."

if ! sudo nixos-rebuild switch \
    --flake /etc/nixos#portal \
    --no-write-lock-file \
    --option experimental-features "nix-command flakes"; then

    echo
    echo "ERROR: Failed to activate whitebox."
    echo "The previous NixOS generation remains available."
    exit 1
fi


# ─────────────────────────────────────────────
# Finished
# ─────────────────────────────────────────────

echo
echo "whitebox installation complete."


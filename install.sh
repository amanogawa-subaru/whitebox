#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAME="$(whoami)"

echo "Whitebox installer"
echo "User: $USERNAME"
echo "Repo: $REPO_DIR"

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
    sudo rm /etc/nixos/whitebox
elif [ -e /etc/nixos/whitebox ]; then
    echo "ERROR: /etc/nixos/whitebox already exists and is not a symlink."
    exit 1
fi

sudo ln -s "$REPO_DIR" /etc/nixos/whitebox

echo "Linked:"
echo "/etc/nixos/whitebox -> $REPO_DIR"

# ─────────────────────────────────────────────
# Add Whitebox import
# ─────────────────────────────────────────────

CONFIG="/etc/nixos/configuration.nix"
IMPORT="./whitebox/imports.nix"

if grep -q 'whitebox/imports.nix' "$CONFIG"; then
    echo "Whitebox import already present."
else
    echo
    echo "Whitebox import is not yet present in:"
    echo "$CONFIG"
    echo
    echo "Add this to the existing imports list:"
    echo
    echo "    ./whitebox/imports.nix"
    echo
    echo "Then run:"
    echo
    echo "    sudo nixos-rebuild switch"
    echo
    exit 0
fi

# ─────────────────────────────────────────────
# Rebuild
# ─────────────────────────────────────────────

echo "Rebuilding NixOS..."

sudo nixos-rebuild switch

echo
echo "Whitebox installation complete."

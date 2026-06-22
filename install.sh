#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing packages..."
grep -v '^\s*#' "$DOTFILES_DIR/packages.txt" | grep -v '^\s*$' \
    | sudo pacman -S --needed -

echo "==> Stowing dotfiles..."
STOW_PACKAGES=(backgrounds fastfetch gtk hyprland hyprpaper kitty mise rofi starship thunar waybar)
for pkg in "${STOW_PACKAGES[@]}"; do
    echo "    stow: $pkg"
    stow -v -t "$HOME" -d "$DOTFILES_DIR" "$pkg"
done

echo "==> Installing mise tools..."
mise install

echo "==> Done."
echo "    Reload Hyprland with: hyprctl reload"
echo "    Activate mise in your shell by adding to ~/.bashrc:"
echo '      eval "$(mise activate bash)"'

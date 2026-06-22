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

echo "==> Installing greetd system files..."
getent group greeter > /dev/null || { echo "ERROR: greeter group missing — install greetd first"; exit 1; }
sudo mkdir -p /etc/greetd
sudo cp "$DOTFILES_DIR/greetd/etc/greetd/config.toml" /etc/greetd/config.toml
sudo cp "$DOTFILES_DIR/greetd/etc/greetd/tuigreet.sh"  /etc/greetd/tuigreet.sh
sudo cp "$DOTFILES_DIR/greetd/etc/greetd/issue"        /etc/issue
sudo chmod +x /etc/greetd/tuigreet.sh
sudo chmod 750 /etc/greetd
sudo chown -R root:greeter /etc/greetd

echo "==> Enabling greetd..."
sudo systemctl enable greetd.service

echo "==> Installing mise tools..."
mise install

echo "==> Done."
echo "    Reload Hyprland with: hyprctl reload"
echo "    Activate mise in your shell by adding to ~/.bashrc:"
echo '      eval "$(mise activate bash)"'

#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    echo "ERROR: [multilib] repo is not enabled in /etc/pacman.conf"
    echo "       Uncomment [multilib] and its Include line, then re-run."
    exit 1
fi

echo "==> Installing packages..."
grep -v '^\s*#' "$DOTFILES_DIR/packages.txt" | grep -v '^\s*$' \
    | sudo pacman -Syu --needed -

echo "==> Stowing dotfiles..."
STOW_PACKAGES=(backgrounds dunst fastfetch fish gtk hyprland hyprpaper kitty mise rofi starship thunar waybar infra opencode uwsm)
for pkg in "${STOW_PACKAGES[@]}"; do
    echo "    stow: $pkg"
    stow --adopt -v -t "$HOME" -d "$DOTFILES_DIR" "$pkg" && git -C "$DOTFILES_DIR" checkout -- "$pkg" 2>/dev/null || true
done

echo "==> Applying GTK theme..."
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

echo "==> Seeding Discord config..."
if pacman -Qs discord &>/dev/null; then
    mkdir -p "$HOME/.config/discord"
    if [ ! -f "$HOME/.config/discord/settings.json" ]; then
        printf '{\n  "SKIP_HOST_UPDATE": true,\n  "OPEN_ON_STARTUP": false\n}\n' \
            > "$HOME/.config/discord/settings.json"
        echo "    Wrote ~/.config/discord/settings.json"
    fi
fi

echo "==> Setting fish as default shell..."
chsh -s /usr/bin/fish "$USER"

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

echo "==> Setting up Docker..."
sudo systemctl enable --now docker.service
sudo usermod -aG docker "$USER"
echo "    Added $USER to docker group (re-login to apply)"

echo "==> Installing mise tools..."
mise install

echo "==> Done."
echo "    Reload Hyprland with: hyprctl reload"

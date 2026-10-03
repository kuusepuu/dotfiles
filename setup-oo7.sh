#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Run this script as your desktop user, without sudo." >&2
    exit 1
fi

echo "==> Enabling oo7 for the current user..."
systemctl --user daemon-reload
systemctl --user enable --now oo7-daemon.service

echo "==> Installing greetd PAM integration for oo7..."
# Keep the original PAM configuration once, including on repeated installs.
if ! sudo test -e /etc/pam.d/greetd.before-oo7; then
    sudo cp -p /etc/pam.d/greetd /etc/pam.d/greetd.before-oo7
fi
sudo install -m644 "$DOTFILES_DIR/greetd/etc/pam.d/greetd" /etc/pam.d/greetd

echo "    oo7 startup is managed by systemd; PAM only sends the login password."

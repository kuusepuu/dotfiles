#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 0 ]; then
    echo "Usage: bash setup-vm.sh" >&2
    exit 2
fi

if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Run this script as your login user, without sudo." >&2
    exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Checking hardware virtualization..."
cpu_info="$(LC_ALL=C lscpu)"
if grep -Eq '^Virtualization:[[:space:]]*AMD-V' <<< "$cpu_info"; then
    kvm_module=kvm_amd
elif grep -Eq '^Virtualization:[[:space:]]*VT-x' <<< "$cpu_info"; then
    kvm_module=kvm_intel
else
    echo "ERROR: AMD-V or Intel VT-x is unavailable. Enable SVM/AMD-V or VT-x in BIOS/UEFI, then rerun." >&2
    exit 1
fi

if ! grep -Eq "^${kvm_module}[[:space:]]" <<< "$(lsmod)"; then
    echo "    Loading $kvm_module..."
    if ! sudo modprobe "$kvm_module"; then
        echo "ERROR: Could not load $kvm_module. Check BIOS/UEFI virtualization settings and kernel support." >&2
        exit 1
    fi
fi

loaded_modules="$(lsmod)"
if ! grep -Eq "^${kvm_module}[[:space:]]" <<< "$loaded_modules" ||
   ! grep -Eq '^kvm[[:space:]]' <<< "$loaded_modules"; then
    echo "ERROR: KVM modules are unavailable. Check BIOS/UEFI virtualization settings and kernel support." >&2
    exit 1
fi

echo "==> Installing VM packages..."
sudo pacman -Syu --needed qemu-desktop libvirt virt-manager dnsmasq edk2-ovmf

echo "==> Enabling libvirt..."
sudo systemctl enable --now libvirtd.socket

login_user="$(id -un)"
sudo usermod -aG libvirt "$login_user"
echo "    Added $login_user to libvirt group (log out and back in to apply)"

echo "==> Configuring default VM network..."
virsh_system=(sudo virsh -c qemu:///system)
networks="$("${virsh_system[@]}" net-list --all --name)"
if ! grep -Fxq default <<< "$networks"; then
    default_xml=/etc/libvirt/qemu/networks/default.xml
    if [ ! -f "$default_xml" ]; then
        echo "ERROR: The default network is missing and $default_xml is unavailable." >&2
        exit 1
    fi
    "${virsh_system[@]}" net-define "$default_xml"
fi

inactive_networks="$("${virsh_system[@]}" net-list --inactive --name)"
if grep -Fxq default <<< "$inactive_networks"; then
    "${virsh_system[@]}" net-start default
fi

autostart_networks="$("${virsh_system[@]}" net-list --autostart --name)"
if ! grep -Fxq default <<< "$autostart_networks"; then
    "${virsh_system[@]}" net-autostart default
fi

"${virsh_system[@]}" net-info default

echo "==> Allowing VM network forwarding through Docker..."
sudo install -Dm755 "$DOTFILES_DIR/vm/libvirt-docker-forwarding" /usr/local/libexec/libvirt-docker-forwarding
sudo install -Dm644 "$DOTFILES_DIR/vm/libvirt-docker-forwarding.service" /etc/systemd/system/libvirt-docker-forwarding.service
sudo systemctl daemon-reload
sudo systemctl enable libvirt-docker-forwarding.service
sudo systemctl restart libvirt-docker-forwarding.service

echo "==> VM setup complete. Log out and back in before opening virt-manager."

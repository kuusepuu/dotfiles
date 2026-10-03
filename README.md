# dotfiles

Hyprland + Wayland desktop configuration for Arch Linux. Includes Waybar, Kitty, Fish + Starship, rofi, tuigreet (greetd), Hyprpaper, Hyprlock + Hypridle, Thunar, and fastfetch. Theme is Catppuccin Mocha throughout. Runtime versions (Node, Go, Rust, Python, Java, Kotlin, .NET, and usage) are managed by mise.

---

## Full install guide

### 1. Download the ISO

Go to <https://archlinux.org/download/> and download the latest ISO from a mirror near you.

```
archlinux-YYYY.MM.DD-x86_64.iso
```

### 2. Verify integrity

Download the checksum file from the same mirror page, then verify:

```bash
sha256sum -c sha256sums.txt --ignore-missing
```

Optionally verify the PGP signature:

```bash
gpg --keyserver-options auto-key-retrieve --verify archlinux-YYYY.MM.DD-x86_64.iso.sig
```

### 3. Write to USB

Find your USB drive with `lsblk`, then write the ISO. Replace `/dev/sdc` with your actual device.

```bash
sudo dd if=~/Downloads/arch_iso/archlinux-2026.06.01-x86_64.iso \
        of=/dev/sdc bs=4M status=progress oflag=sync
sync
```

### 4. Boot from USB

1. Plug in the USB and reboot.
2. Enter your firmware/BIOS (usually Del, F2, or F12 during POST).
3. Disable Secure Boot (or enroll the Arch certificate if your board supports it).
4. Set the USB as the first boot device and save.
5. At the Arch boot menu, select **Arch Linux install medium (x86_64, UEFI)**.

### 5. Run archinstall

Once the live environment loads, run:

```bash
archinstall
```

Use the following settings:

| Option | Value|
|---|-----------------------------------------------------------------------------------|
| Archinstall language | English |
| Locales | `en_US.UTF-8`, `us` |
| Mirrors and repositories | Pick your region |
| Disk configuration | Best-effort default layout → select your drive → ext4, no separate home partition |
| Swap | zram: `enabled`, zstd |
| Bootloader | Bootloader: Limine, UKI: up to you, Removable: enabled |
| Kernels | linux |
| Hostname | `archlinux` |
| Authentication | Root password: setp one, User account: add name/password, add to sudo |
| Profile | **Minimal** (no desktop — install.sh handles everything) |
| Applications | Audio: pipewire, firewall: leave empty, others whatever |
| Network | Network Manager (default backend) |
| Pacman | Color: True |
| Additional packages | `git`, `nano` |
| Timezone | xxxx |


Select **Install**, wait for it to finish, then **reboot** and remove the USB.

### 6. Log in and clone the dotfiles

Log in as `xxxx` on the TTY, then clone this repo:

```bash
git clone https://github.com/kuusepuu/dotfiles.git ~/dotfiles
```

### 7. Run install.sh

```bash
cd ~/dotfiles
bash install.sh
```

To set up QEMU/KVM and virt-manager during installation, use `bash install.sh --vm` instead. VM setup runs after the normal install. If KVM is unavailable, the normal install will finish and the VM step will report how to enable it.

This will:

- Install all packages listed in `packages.txt` via pacman
- Stow all config directories into `~` with GNU Stow
- Set fish as the default shell
- Copy greetd system files to `/etc/greetd/` and enable `greetd.service`
- Enable oo7's user service and install greetd PAM integration for keyring unlocking
- Enable Docker, Bluetooth, LACT, and CUPS
- Run `mise install` to download all language runtimes

You can also add VM support later without rerunning the full installer:

```bash
cd ~/dotfiles
bash setup-vm.sh
```

The VM setup checks hardware virtualization, installs QEMU, libvirt, virt-manager, dnsmasq, and UEFI firmware, then enables libvirt and the default VM network. It also installs a systemd service that allows the default IPv4 VM network through Docker's `DOCKER-USER` chain whenever Docker starts. The service adds rules only when they are missing, and setup does not restart Docker or its containers. Log out and back in afterward so your `libvirt` group membership takes effect. In virt-manager, use the **QEMU/KVM system** connection.

### 8. Reboot

```bash
reboot
```

greetd + tuigreet will appear on VT1. Select the **Hyprland** session and log in.

The installer adds a greetd service override to delay the greeter until queued
boot jobs have been dispatched and send service output to the journal. This
reduces boot messages appearing over the login screen. Late kernel or systemd
console messages may still appear; `Type=idle` waits at most five seconds.

To apply the override to an existing installation:

```bash
sudo install -Dm644 greetd/etc/systemd/system/greetd.service.d/override.conf \
    /etc/systemd/system/greetd.service.d/override.conf
sudo systemctl daemon-reload
```

The override takes effect on the next boot. To investigate an error shown before
entering a password, temporarily add `--debug=/var/cache/tuigreet/debug.log` to
`/etc/greetd/tuigreet.sh`, reboot, then inspect that file and
`sudo journalctl -b -u greetd --no-pager`. Remove the debug option afterward.

The greeter remembers the last user without enabling `--user-menu`, avoiding
tuigreet's duplicate authentication request at startup.

oo7 starts through `oo7-daemon.service`. The greetd PAM configuration captures
and sends the login password without `auto_start`, so PAM does not start a second
daemon. The login keyring password must match your account password.
The installer replaces `/etc/pam.d/greetd` with the repository version and saves
the previous configuration as `/etc/pam.d/greetd.before-oo7` on the first run.

To apply only the oo7 setup to an existing installation, run as your desktop user:

```bash
bash setup-oo7.sh
```

Reboot afterward to verify automatic unlocking on a fresh login. The
`/usr/bin/oo7-daemon` workaround symlink is unnecessary when PAM does not start
the daemon.

---

## Notes

- **Monitors** — the config targets `DP-1` at 2560×1440@171 Hz and `DP-2` at 1920×1080@144 Hz. Edit `~/.config/hypr/monitors.lua` to match your setup.
- **Keyboard layouts** — `us` and `ee` (Estonian), toggled with Alt+Shift. Edit `~/.config/hypr/input.lua` to change.
- **Idle and lock** — Hypridle locks the session after 10 minutes and powers displays off after 15 minutes. Activity powers the displays back on; idle time never suspends the machine.
- **AMD microcode** — loaded automatically by GRUB. On Intel systems, install `intel-ucode` manually after step 7.
- **mise runtimes** — `mise install` fetches Node.js (LTS), Go, Rust, Python, Java 25, Kotlin, .NET, and usage. This takes a while on first run; see [`mise/README.md`](mise/README.md) for common commands.

---

## Tips

### Local Postgres

The development Postgres container only listens on localhost and requires a
password from an untracked `.env` file:

```bash
cd ~/infra
cp env.example .env
zeditor --wait .env
docker compose up -d
```

Replace `change-me` before starting the container. Compose will fail with a
clear error if `POSTGRES_PASSWORD` is missing.

### SSH with named keys

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_$(hostname) -C "$(hostname)"
```

### JetBrains Toolbox

Download the tarball from [jetbrains.com/toolbox-app](https://www.jetbrains.com/toolbox-app/), then:

```bash
sudo mkdir -p /opt/jetbrains-toolbox
sudo tar xzf jetbrains-toolbox-*.tar.gz -C /opt/jetbrains-toolbox --strip-components=1
/opt/jetbrains-toolbox/bin/jetbrains-toolbox
```

Toolbox creates its own `.desktop` entry and handles all IDE installations — rofi picks everything up automatically.

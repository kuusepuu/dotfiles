# dotfiles

Hyprland + Wayland desktop configuration for Arch Linux. Includes Waybar, Kitty, Fish + Starship, rofi, tuigreet (greetd), Hyprpaper, Thunar, and fastfetch. Theme is Catppuccin Mocha throughout. Runtime versions (Node, Go, Rust, Python, Java, Kotlin, .NET, PHP, Haskell) are managed by mise.

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

| Option | Value                                                                             |
|---|-----------------------------------------------------------------------------------|
| Archinstall language | English                                                                           |
| Mirrors | Pick your region                                                                  |
| Locale | `en_US.UTF-8`                                                                     |
| Keyboard layout | `us`                                                                              |
| Timezone | `Europe/Tallinn`                                                                  |
| Hostname | `archlinux`                                                                       |
| Root password | set one                                                                           |
| User account | username `xxxx`, add to `wheel` group, enable sudo                                |
| Profile | **Minimal** (no desktop — install.sh handles everything)                          |
| Audio | pipewire                                                                          |
| Kernels | linux                                                                             |
| Additional packages | `git`                                                                             |
| Network | NetworkManager                                                                    |
| Swap | zram                                                                              |
| Bootloader | GRUB                                                                              |
| Disk configuration | Best-effort default layout → select your drive → ext4, no separate home partition |
| Encryption | none                                                                              |
| Multilib | enable                                                                            |

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

This will:

- Install all packages listed in `packages.txt` via pacman
- Stow all config directories into `~` with GNU Stow
- Set fish as the default shell
- Copy greetd system files to `/etc/greetd/` and enable `greetd.service`
- Run `mise install` to download all language runtimes

### 8. Reboot

```bash
reboot
```

greetd + tuigreet will appear on VT1. Select the **Hyprland** session and log in.

---

## Notes

- **Monitors** — the config targets `DP-1` at 2560×1440@165 Hz and `DP-2` at 1920×1080@144 Hz. Edit `~/.config/hypr/monitors.conf` to match your setup.
- **Keyboard layouts** — `us` and `et` (Estonian), toggled with Alt+Shift. Edit `~/.config/hypr/input.conf` to change.
- **AMD microcode** — loaded automatically by GRUB. On Intel systems, install `intel-ucode` manually after step 7.
- **mise runtimes** — `mise install` fetches node (LTS), go, rust, python, java (Temurin 21), kotlin, dotnet 10, php, and haskell. This takes a while on first run.

---

## Tips

### SSH with named keys

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_$(hostname) -C "$(hostname)"
```

### JetBrains Toolbox

Download the tarball from [jetbrains.com/toolbox-app](https://www.jetbrains.com/toolbox-app/), then:

```bash
sudo mkdir -p /opt/jetbrains-toolbox
sudo tar xzf jetbrains-toolbox-*.tar.gz -C /opt/jetbrains-toolbox --strip-components=1
/opt/jetbrains-toolbox/jetbrains-toolbox
```

Toolbox creates its own `.desktop` entry and handles all IDE installations — rofi picks everything up automatically.

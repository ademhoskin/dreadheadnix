# dreadheadnix

A NixOS configuration for a **Dell Inspiron 16 7630 2-in-1** (Intel 13th gen, Iris Xe, Intel AX211 Wi-Fi, touchscreen, 360° hinge).

Flake + home-manager + disko. Hyprland as the desktop. Doom Emacs for editing. The installer is a **custom ISO with this repo baked in**, built by GitHub Actions, so installing is: boot the USB, run one command.

## Install

### 1. Get the ISO

The ISO is built in CI, not locally. Push to `main`, then grab it from the run:

- **Actions** → the `iso` workflow → **Artifacts** → `dreadheadnix-iso`
- Or trigger it by hand: **Actions → iso → Run workflow**

Building locally works too, if you have Nix: `nix build .#nixosConfigurations.installer.config.system.build.isoImage`

### 2. Write it to a USB

```sh
sudo dd if=dreadheadnix.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

### 3. Boot the laptop from it and install

The live environment has NetworkManager, so `nmtui` gets you on Wi-Fi:

```sh
nmtui
sudo /etc/dreadheadnix/install.sh
```

`install.sh` shows you the target disk, makes you type the device path back to confirm, asks for your account password, then partitions with disko and runs `nixos-install`. **It erases the whole disk.**

Override the defaults if needed: `DISK=/dev/nvme0n1 MOUNT=/mnt sudo -E /etc/dreadheadnix/install.sh`

### 4. Reboot

```sh
sudo reboot
```

The repo is baked into the installed system too, so updates come from there:

```sh
sudo nixos-rebuild switch --flake /etc/dreadheadnix#inspiron
```

## Rehearse it first

disko is whole-disk destructive and there is no undo, so test the flow in a VM before touching real hardware. Boot the ISO in QEMU and install onto a throwaway disk:

```sh
./scripts/qemu-run.sh --cdrom ./dreadheadnix.iso --disk ./test.qcow2 --ram 8192
```

Then run `install.sh` inside the VM against `/dev/vda` (not `/dev/nvme0n1`).

## Repo layout

| Path | Purpose |
| --- | --- |
| `flake.nix` | Inputs and the two systems: `inspiron` (the laptop) and `installer` (the ISO) |
| `nixos/configuration.nix` | The laptop: users, services, desktop, home-manager wiring |
| `nixos/hardware.nix` | Intel 13th gen laptop specifics — firmware, microcode, VA-API, initrd modules |
| `nixos/disko.nix` | Disk layout: GPT, 1 GiB ESP, Btrfs with `@root`/`@home`/`@nix`/`@log` |
| `nixos/tablet.nix` | 2-in-1 support: accelerometer rotation + on-screen keyboard |
| `nixos/installer.nix` | The custom ISO: bakes the repo in at `/etc/dreadheadnix` |
| `home-manager/home.nix` | Shell, git, zsh/p10k, Doom Emacs, dev toolchain |
| `install.sh` | Runs on the ISO: disko, then `nixos-install` |
| `dotfiles/` | Hyprland, alacritty, kitty, tmux, nvim, Doom, p10k, wallpaper |
| `.github/workflows/iso.yml` | Builds and uploads the ISO |

## Editors

**Doom Emacs** is the default, with evil mode. It is a port of the Spacemacs setup that used to live here — `dotfiles/doom/` holds `init.el` (the module list, translated from the old `dotspacemacs-configuration-layers`), `config.el` (the settings from `dotspacemacs/user-config`), and `packages.el`.

The old `dotfiles/.spacemacs` is still in the repo as a fallback; it is simply not installed.

Doom cannot live in the Nix store, because `doom sync` compiles packages into `~/.config/emacs/.local`. So `home-manager` clones Doom into `~/.config/emacs` on first activation and symlinks only the three config files. After changing `init.el` or `packages.el`:

```sh
~/.config/emacs/bin/doom sync
```

If the `:term vterm` module fails to compile, either run `doom sync` again once `libvterm` has settled, or switch that one module out in `dotfiles/doom/init.el`.

**Neovim** (LazyVim) is also configured. Its `lazyvim.json` and `lazy-lock.json` are seeded as *writable* copies on first activation rather than symlinked, because LazyVim rewrites both at runtime and a read-only store path would break plugin changes. That is also why `~/.config/nvim` is symlinked file-by-file rather than as a whole directory.

## 2-in-1 notes

- **Rotation** comes from `iio-sensor-proxy` plus `iio-hyprland`, which rotates the display *and* the touch/stylus devices together. On this Dell the accelerometer is in the base rather than the display; if rotation comes out inverted, change the `exec-once = iio-hyprland` line in `dotfiles/hypr/hyprland.conf` to `iio-hyprland --transform 3,0,1,2`.
- **On-screen keyboard**: `Super+Escape` toggles `wvkbd`. It is not automatic — that needs `zwp_input_method_v2`, which Hyprland does not implement.
- Disabling the physical keyboard when the lid is folded back is not configured. That needs udev/libinput plumbing on the hinge sensor.

## Secrets

This repo is **public**. Nothing secret goes in it.

- The account password is hashed at install time by `install.sh` and written to `/var/lib/nixos-secrets/passwd` on the target. `nixos/configuration.nix` points at it via `hashedPasswordFile`.
- `ANTHROPIC_API_KEY` is read from the environment, never committed. Put it in a file the repo does not track.

## After install

Things worth verifying on real hardware, because CI can prove the config evaluates but not that the hardware works:

```sh
lspci -k | grep -A3 -i network    # AX211 / iwlwifi
aplay -l                          # speakers — Intel SOF
libinput list-devices | grep -i touch
hyprctl version                   # and check the windowrule comment in hyprland.conf
```

## Known gaps

- **Webcam** is unverified. Some 13th-gen Dells route the camera through IPU6, which needs extra configuration.
- **Hibernation** is not set up. `zramSwap` covers memory pressure, and `criticalPowerAction` is `PowerOff` because there is no disk swap to hibernate into. Adding a swap partition would enable it.
- The two `windowrule` lines in `dotfiles/hypr/hyprland.conf` are commented out: they use Hyprland v1 syntax, removed in versions newer than those dotfiles were written for. See the comment there.

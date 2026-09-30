# dreadheadnix

A NixOS configuration for a **Dell Inspiron 16 7630 2-in-1** (Intel 13th gen, Iris Xe, Intel AX211 Wi-Fi, touchscreen, 360° hinge).

Flake + home-manager + disko. Hyprland as the desktop. Doom Emacs for editing. The installer is a **custom ISO with this repo baked in**, built by GitHub Actions, so installing is: boot the USB, run one command.

## Install

### 1. Flash a USB

```sh
./scripts/flash-usb.sh
```

This downloads the newest ISO, verifies its published checksum, lists removable disks, refuses to touch the disk holding `/`, and makes you type the device path back before writing.

The ISO it fetches **has already been installed successfully in a VM**. CI publishes a release only after the install rehearsal passes, so the download URL never serves an image that cannot install:

```
https://github.com/ademhoskin/dreadheadnix/releases/latest/download/dreadheadnix.iso
```

Use `-i ./local.iso` for a locally built image, or `-d /dev/sdX` to skip discovery. To do it by hand instead:

```sh
curl -fLO https://github.com/ademhoskin/dreadheadnix/releases/latest/download/dreadheadnix.iso
sudo dd if=dreadheadnix.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Building locally works too, if you have Nix: `nix build .#nixosConfigurations.installer.config.system.build.isoImage`

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

Then run `install.sh` inside the VM against `/dev/vda`, not `/dev/nvme0n1` — `qemu-run.sh` attaches disks as virtio-blk, so the guest sees `vda` where the laptop has `nvme0n1`. (The CI rehearsal attaches its disk as NVMe instead, so there it is `/dev/nvme0n1` and matches the laptop exactly.)

## What CI actually checks

Two jobs, and they check very different things.

**`build-iso`** evaluates the whole configuration and builds the ISO. This is where a wrong option name or a broken module import fails — worth having, because there is no Nix on the development machine, so nothing else evaluates it.

**`install-test`** is the one that matters for safety. It boots the ISO under UEFI in QEMU against a blank disk, runs `install.sh` for real, then reboots into the installed system and asserts it came up. It is the only thing that ever executes `install.sh`, which is otherwise the most dangerous file here with zero coverage.

It uses two CI-only flake outputs, `installerTest` and `inspironTest`, which differ from the real ones only in SSH policy and hostname — that is how the job gets a shell to drive the install with, and the hostname is how it proves it reached the installed system rather than the live image. The disk layout, `install.sh`, `nixos-install` and the bootloader are identical, so the rehearsal exercises the same code path you will.

A green `build-iso` means "this should install". A green `install-test` means "this does install". Neither says anything about the hardware — only the laptop can tell you that.

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
| `docs/toolchain.md` | Every dev tool: what it is, how to use it, and what it's wired into |
| `docs/doom.md` | Doom Emacs workflow — leader menu, LSP, debugger, git, Neovim translation |
| `install.sh` | Runs on the ISO: disko, then `nixos-install` |
| `scripts/flash-usb.sh` | Downloads the published ISO, verifies it, writes it to a USB |
| `dotfiles/` | Hyprland, alacritty, kitty, tmux, nvim, Doom, p10k, wallpaper |
| `.github/workflows/iso.yml` | Builds and uploads the ISO |

## Editors

**Doom Emacs** is the default, with evil mode. `dotfiles/doom/` holds `init.el` (the module list), `config.el` (settings), and `packages.el` (extra packages).

Note that Doom skips a module it cannot resolve without any error or warning — a typo in `init.el` costs you the feature and tells you nothing.

**[docs/doom.md](docs/doom.md) is the orientation guide** — the leader menu, LSP and debugger bindings, magit, and a Neovim-to-Doom translation table. Worth reading if you are arriving from Neovim, which is how this was written.

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

## Claude Code

Installed from nixpkgs as `claude-code` — not via npm — and preconfigured for DeepSeek's Anthropic-compatible endpoint. The only thing you supply after install is the token.

User config lives in `claude/` and is symlinked into `~/.claude/`:

| Path | Purpose |
| --- | --- |
| `claude/CLAUDE.md` | Global rules: code style, commenting, doc-comment conventions, commit format. Applies to every project, not just this repo. |
| `claude/settings.json` | Claude Code settings |

`~/.claude` itself is **not** symlinked — it stays a real writable directory, because Claude Code writes history, sessions and caches into it.

To add subagents or slash commands, drop `.md` files into `claude/agents/` or `claude/commands/` and add a matching `home.file` entry; they are picked up by filename.

## Secrets

This repo is **public**. Nothing secret goes in it.

- The account password is hashed at install time by `install.sh` and written to `/var/lib/nixos-secrets/passwd` on the target. `nixos/configuration.nix` points at it via `hashedPasswordFile`.
- The Claude token is read at shell start from `~/.config/claude/env`, which the repo does not track. Create it once:

  ```sh
  install -Dm600 /dev/null ~/.config/claude/env
  printf 'export ANTHROPIC_AUTH_TOKEN=%s\n' '<token>' > ~/.config/claude/env
  ```

  Note the variable name: **`ANTHROPIC_AUTH_TOKEN`**, not `ANTHROPIC_API_KEY`. DeepSeek's endpoint takes the former, and setting the wrong one produces an auth failure that looks like a bad key.

  It cannot go in `home.sessionVariables`: those are evaluated at build time and land in the world-readable Nix store.

## After install

### 1. Required, not optional: sync Doom

Doom is cloned into `~/.config/emacs` but has no packages until this runs. Skip it and you have no working editor.

```sh
~/.config/emacs/bin/doom sync
```

### 2. Required: add the Claude token

Claude Code is installed and pointed at DeepSeek, but has no credential — it lives outside the repo because this repo is public.

```sh
install -Dm600 /dev/null ~/.config/claude/env
printf 'export ANTHROPIC_AUTH_TOKEN=%s\n' '<token>' > ~/.config/claude/env
```

Open a new shell and `claude` should start. See [Claude Code](#claude-code) below.

### 3. Update to the current repo state

```sh
sudo nixos-rebuild switch --flake /etc/dreadheadnix#inspiron
```

### 4. Verify the hardware

CI proves the config evaluates. It cannot prove any of this, because it has no Dell:

```sh
lspci -k | grep -A3 -i network   # Wi-Fi: expect AX211 with iwlwifi in use
aplay -l                         # audio: expect a SOF device, not "no soundcards"
bluetoothctl show                # expect a controller, not "No default controller"
hyprctl devices                  # touchscreen: expect a touch entry
pgrep -a iio-hyprland            # rotation listener is running
systemctl suspend                # suspend: should resume on the power button
sudo fwupdmgr get-devices        # firmware: devices listed for capsule updates
```

Then fold the lid back and check the screen rotates, and press `Super+Escape` for the on-screen keyboard.

If rotation comes out **inverted**, the accelerometer is in the base rather than the display. Change the `exec-once = iio-hyprland` line in `dotfiles/hypr/hyprland.conf` to:

```
exec-once = iio-hyprland --transform 3,0,1,2
```

Webcam is the one item with no reliable way to check from here — try any video app.

## Known gaps

- **Webcam** is unverified. Some 13th-gen Dells route the camera through IPU6, which needs extra configuration.
- **Hibernation** is not set up. `zramSwap` covers memory pressure, and `criticalPowerAction` is `PowerOff` because there is no disk swap to hibernate into. Adding a swap partition would enable it.
- The two `windowrule` lines in `dotfiles/hypr/hyprland.conf` are commented out: they use Hyprland v1 syntax, removed in versions newer than those dotfiles were written for. See the comment there.

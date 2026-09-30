#!/usr/bin/env bash
#
# Run this from the dreadheadnix installer ISO, as root.
#
# It partitions and formats the target disk with disko, then installs the
# system from the copy of this repo baked into the ISO at /etc/dreadheadnix.
#
#   DESTROYS THE ENTIRE TARGET DISK. There is no undo and no dual-boot support.
#
set -euo pipefail

REPO="${REPO:-/etc/dreadheadnix}"
# Must match the git remote. The repo lands on the target as a store path with
# no .git, so this cannot be derived at runtime — it only ever appears in the
# printed update instructions.
REPO_SLUG="ademhoskin/dreadheadnix"
# The rehearsal overrides HOST so it can install a CI-only variant of the same
# config. Everything below the flake attribute is identical either way.
HOST="${HOST:-inspiron}"
FLAKE_ATTR="${REPO}#${HOST}"
DISK="${DISK:-/dev/nvme0n1}"
MOUNT="${MOUNT:-/mnt}"
SECRET_DIR="${MOUNT}/var/lib/nixos-secrets"
SECRET_FILE="${SECRET_DIR}/passwd"

log()  { printf '\033[1;31m[dreadheadnix]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[dreadheadnix] error:\033[0m %s\n' "$*" >&2; exit 1; }

# --- Preconditions -----------------------------------------------------------

[[ $EUID -eq 0 ]] || die "run this as root."

[[ -d "$REPO" ]] || die "$REPO not found. This script is meant to run from the
custom ISO, which bakes the repo in there. On a stock NixOS ISO, clone the repo
and point REPO at it: REPO=/path/to/dreadheadnix $0"

[[ -f "$REPO/flake.nix" ]] || die "$REPO has no flake.nix — the baked copy looks wrong."

[[ -b "$DISK" ]] || die "$DISK is not a block device. Set DISK=/dev/... and retry.
Available disks:
$(lsblk -dpno NAME,SIZE,MODEL)"

[[ -d /sys/firmware/efi ]] || die "not booted in UEFI mode; this layout assumes UEFI."

# Evaluate the target config before touching the disk. The flake's inputs are
# github: URLs, so this also proves the network is up — and it is much better to
# discover a broken config or a dead network now than after the disk is wiped.
log "Evaluating $FLAKE_ATTR (this fetches the flake's inputs)..."
# The flag is passed explicitly rather than relying on the ISO's nix.conf, so
# this also works if someone runs the script from a stock NixOS ISO with a
# cloned copy of the repo (which the REPO check above suggests).
nix eval --extra-experimental-features 'nix-command flakes' --raw \
  "${REPO}#nixosConfigurations.${HOST}.config.system.build.toplevel.drvPath" >/dev/null \
  || die "$FLAKE_ATTR failed to evaluate. Fix that before wiping the disk."

# --- Confirm the destructive step --------------------------------------------

log "Target disk : $DISK"
# FSTYPE, not FILESYSTEM — there is no FILESYSTEM column, and lsblk aborts the
# whole call on one bad name rather than dropping it. That matters more here
# than anywhere else: this is the preview shown immediately before an
# irreversible wipe, and an empty preview is worse than no preview.
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL "$DISK" || true
echo
log "Everything on $DISK will be erased."
read -r -p "Type the disk path again to confirm: " confirm
[[ "$confirm" == "$DISK" ]] || die "confirmation did not match; nothing was changed."

# --- User password -----------------------------------------------------------
#
# The repo is public, so no password (hashed or otherwise) is committed. The
# hash is generated here and written straight into the target's /var/lib, which
# is outside the repo. nixos/configuration.nix reads it via hashedPasswordFile.

echo
read -r -s -p "Password for dreadheadcoder: " pw1; echo
read -r -s -p "Repeat: " pw2; echo
[[ "$pw1" == "$pw2" ]] || die "passwords did not match."
[[ -n "$pw1" ]] || die "empty password refused."

hash_password() {
  if command -v mkpasswd >/dev/null 2>&1; then
    mkpasswd -m sha-512 -s
  elif command -v openssl >/dev/null 2>&1; then
    openssl passwd -6 -stdin
  else
    die "neither mkpasswd nor openssl is available to hash the password."
  fi
}

# Read from stdin so the password never reaches the process list.
pw_hash="$(printf '%s' "$pw1" | hash_password)"
unset pw1 pw2

# --- Partition, format, mount ------------------------------------------------

log "Partitioning $DISK with disko..."
# --argstr, not --arg: nix-build would read a bare /dev/vda as a path, and
# disko's `device` wants a string. The option type is (str), so --arg silently
# produces a path attr instead.
disko --mode destroy,format,mount "$REPO/nixos/disko.nix" \
  --argstr disk "$DISK" --yes-wipe-all-disks

# disko mounts the installed system by partition *label* (via
# /dev/disk/by-partlabel), so a label that failed to appear means an unbootable
# system rather than a cosmetic problem. Check before going further.
log "Verifying partition labels..."
for label in disk-main-ESP disk-main-root; do
  if [[ ! -e "/dev/disk/by-partlabel/${label}" ]]; then
    udevadm trigger --subsystem-match=block || true
    udevadm settle || true
    [[ -e "/dev/disk/by-partlabel/${label}" ]] || die "missing /dev/disk/by-partlabel/${label}.
The btrfs partition did not get its label, which would produce an unbootable
system. Nothing has been installed. Re-run disko, or switch the root partition
in nixos/disko.nix from \`size = \"100%\"\` to an explicit size."
  fi
done

# --- Install -----------------------------------------------------------------

mkdir -p "$SECRET_DIR"
printf '%s\n' "$pw_hash" > "$SECRET_FILE"
chmod 600 "$SECRET_FILE"
chmod 700 "$SECRET_DIR"
unset pw_hash

log "Installing NixOS from $FLAKE_ATTR (this fetches inputs and builds)..."
nixos-install \
  --flake "$FLAKE_ATTR" \
  --root "$MOUNT" \
  --no-root-password \
  --no-channel-copy

log "Done. Remove the USB and reboot."
log ""
log "After reboot, sign in as dreadheadcoder and run these in order:"
log ""
log "  1. ~/.config/emacs/bin/doom sync"
log "       Required. Doom is cloned but has no packages until this runs."
log ""
log "  2. Add the Claude token (it is not in the repo — that repo is public):"
log "       install -Dm600 /dev/null ~/.config/claude/env"
log "       printf 'export ANTHROPIC_AUTH_TOKEN=%s\n' '<token>' > ~/.config/claude/env"
log ""
log "  3. To rebuild from what was just installed (works offline):"
log "       sudo nixos-rebuild switch --flake ${REPO}#${HOST}"
log "     To update to the latest push:"
log "       sudo nixos-rebuild switch --flake github:${REPO_SLUG}#${HOST}"
log ""
log "  4. Check the hardware — CI validates the config, not the machine:"
log "       lspci -k | grep -A3 -i network   # Wi-Fi"
log "       aplay -l                         # Intel SOF audio"
log "       pgrep -a iio-hyprland            # auto-rotation"
log "       hyprctl devices                  # touchscreen"
log ""
log "See the 'After install' section of README.md for the full checklist."

#!/usr/bin/env bash
#
# Download the latest installer ISO and write it to a USB stick.
#
# The published ISO is only ever one that passed the CI install rehearsal — the
# workflow's publish job runs after install-test succeeds, so a build that
# cannot install is never downloadable.
#
#   ./scripts/flash-usb.sh                  # list removable disks, then prompt
#   ./scripts/flash-usb.sh -d /dev/sdX      # skip discovery
#   ./scripts/flash-usb.sh -i ./local.iso   # use a local ISO, skip the download
#
# DESTROYS EVERYTHING ON THE TARGET DEVICE. There is no undo.
#
set -euo pipefail

REPO_SLUG="ademhoskin/dreadheadnix"
ISO_NAME="dreadheadnix.iso"
RELEASE_URL="https://github.com/${REPO_SLUG}/releases/latest/download"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dreadheadnix"

ISO=""
DEVICE=""
ASSUME_YES=no

log() { printf '\033[1;36m[flash]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[flash] error:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while getopts ":d:i:yh" opt; do
  case "$opt" in
    d) DEVICE="$OPTARG" ;;
    i) ISO="$OPTARG" ;;
    y) ASSUME_YES=yes ;;
    h) usage 0 ;;
    :) die "option -$OPTARG needs a value" ;;
    \?) die "unknown option -$OPTARG (try -h)" ;;
  esac
done

require() { command -v "$1" >/dev/null || die "$1 is required but not on PATH."; }
require lsblk
require dd
require curl   # only strictly needed for the download path; cheap to insist on

# --- Get the ISO -------------------------------------------------------------

if [[ -z "$ISO" ]]; then
  require sha256sum
  mkdir -p "$CACHE_DIR"
  ISO="$CACHE_DIR/$ISO_NAME"

  log "fetching $RELEASE_URL/$ISO_NAME"
  curl -fL --progress-bar "$RELEASE_URL/$ISO_NAME" -o "$ISO.part" \
    || die "download failed. Has the iso workflow published a release yet?"

  log "fetching checksum"
  curl -fsL "$RELEASE_URL/$ISO_NAME.sha256" -o "$ISO.sha256" \
    || die "could not fetch the checksum file; refusing to flash an unverified image."

  # Move into place before verifying. The published .sha256 names the file
  # "dreadheadnix.iso", and sha256sum -c looks for exactly that name in the
  # working directory — so the .part file has to be renamed first.
  mv "$ISO.part" "$ISO"

  log "verifying checksum"
  ( cd "$CACHE_DIR" && sha256sum -c "$ISO_NAME.sha256" ) \
    || die "checksum mismatch — the download is corrupt or tampered with."
fi

[[ -f "$ISO" ]] || die "ISO not found: $ISO"
[[ -s "$ISO" ]] || die "ISO is empty: $ISO"
log "ISO: $ISO ($(du -h "$ISO" | cut -f1))"

# --- Pick a device -----------------------------------------------------------

# Removable whole disks only. A USB stick reports RM=1 and TYPE=disk; its
# partitions report TYPE=part and are never valid targets.
list_candidates() {
  lsblk -dno NAME,RM,SIZE,MODEL,TRAN | awk '$2 == 1 { $2 = ""; print }'
}

if [[ -z "$DEVICE" ]]; then
  log "removable disks:"
  echo
  list_candidates | sed 's/^/  \/dev\//'
  echo
  read -r -p "Device to write to (e.g. /dev/sdb): " DEVICE
  [[ -n "$DEVICE" ]] || die "no device given."
fi

[[ -b "$DEVICE" ]] || die "$DEVICE is not a block device."

# --- Refuse the dangerous targets --------------------------------------------

# Writing to the disk that holds / would destroy the running system.
root_src="$(findmnt -no SOURCE / 2>/dev/null || true)"
if [[ -n "$root_src" ]]; then
  root_disk="/dev/$(lsblk -no PKNAME "$root_src" 2>/dev/null | head -n1 || true)"
  if [[ -n "$root_disk" && "$root_disk" != "/dev/" && "$DEVICE" == "$root_disk" ]]; then
    die "$DEVICE holds the running root filesystem. Refusing."
  fi
fi

if [[ "$(lsblk -dno TYPE "$DEVICE")" != "disk" ]]; then
  die "$DEVICE is not a whole disk. Pass the disk (e.g. /dev/sdb), not a partition."
fi

if [[ "$(lsblk -dno RM "$DEVICE")" != "1" && "$ASSUME_YES" != "yes" ]]; then
  die "$DEVICE does not report as removable. If it really is the right disk, re-run with -y to override."
fi

# Any mounted child means something is using it, and writing would corrupt it.
if lsblk -no MOUNTPOINT "$DEVICE" | grep -q '[^[:space:]]'; then
  die "$DEVICE (or a partition on it) is mounted. Unmount it first."
fi

# --- Confirm and write -------------------------------------------------------

log "About to write to:"
lsblk -o NAME,SIZE,TYPE,FILESYSTEM,MOUNTPOINT,MODEL "$DEVICE" | sed 's/^/  /'
echo
log "Every byte on $DEVICE will be destroyed."
if [[ "$ASSUME_YES" != "yes" ]]; then
  read -r -p "Type the device path again to confirm: " confirm
  [[ "$confirm" == "$DEVICE" ]] || die "confirmation did not match; nothing was written."
fi

log "writing (this takes a few minutes and prints progress)..."
sync
dd if="$ISO" of="$DEVICE" bs=4M status=progress oflag=sync conv=fsync
sync

log "done. $DEVICE now holds $(basename "$ISO")."
log "Boot the Inspiron from it, connect Wi-Fi with nmtui, then run:"
log "  sudo /etc/dreadheadnix/install.sh"

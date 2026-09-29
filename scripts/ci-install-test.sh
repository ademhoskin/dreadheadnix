#!/usr/bin/env bash
#
# Install rehearsal: boot the installer ISO under UEFI in QEMU, run install.sh
# against a blank virtio disk, then reboot into the installed system and confirm
# it comes up.
#
# This is the only thing in CI that actually executes install.sh. Everything
# else only proves the configuration evaluates — it never touches a disk.
#
# UEFI matters: install.sh refuses to run on a BIOS boot because the layout
# assumes an ESP, and QEMU defaults to SeaBIOS. Hence the OVMF pflash drives.
#
# usage: ci-install-test.sh <installer.iso> [workdir]
set -euo pipefail

ISO="${1:?usage: ci-install-test.sh <installer.iso> [workdir]}"
WORK="${2:-$(mktemp -d)}"
mkdir -p "$WORK"

PORT="${SSH_PORT:-2222}"
MEM="${MEM:-4096}"
DISK_SIZE="${DISK_SIZE:-20G}"
# The device name inside the VM. virtio-blk, so vda — not the laptop's nvme0n1.
VM_DISK="/dev/vda"
PW="ci-rehearsal"
BOOT_TIMEOUT="${BOOT_TIMEOUT:-600}"     # seconds to reach a shell in the live ISO
INSTALL_TIMEOUT="${INSTALL_TIMEOUT:-2700}"  # seconds for nixos-install

DISK_IMG="$WORK/disk.qcow2"
OVMF_VARS="$WORK/ovmf_vars.fd"
LOG_INSTALL="$WORK/serial-install.log"
LOG_BOOT="$WORK/serial-boot.log"
QEMU_PID="$WORK/qemu.pid"

log() { printf '\033[1;36m[rehearsal]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[rehearsal] error:\033[0m %s\n' "$*" >&2; exit 1; }

cleanup() {
  if [[ -f "$QEMU_PID" ]]; then
    kill "$(cat "$QEMU_PID")" 2>/dev/null || true
    wait 2>/dev/null || true
  fi
}
trap cleanup EXIT

# --- Preflight ---------------------------------------------------------------

[[ -f "$ISO" ]] || die "ISO not found: $ISO"
[[ -w /dev/kvm ]] || die "/dev/kvm is not writable; the runner needs KVM."
command -v qemu-system-x86_64 >/dev/null || die "qemu-system-x86_64 not on PATH."
command -v sshpass >/dev/null || die "sshpass not on PATH (needed for password auth)."

OVMF_CODE=""
OVMF_VARS_SRC=""
for pair in \
  /usr/share/OVMF/OVMF_CODE_4M.fd:/usr/share/OVMF/OVMF_VARS_4M.fd \
  /usr/share/OVMF/OVMF_CODE.fd:/usr/share/OVMF/OVMF_VARS.fd \
  /usr/share/OVMF/OVMF_CODE.ms.fd:/usr/share/OVMF/OVMF_VARS.ms.fd \
  /usr/share/ovmf/OVMF.fd:/usr/share/ovmf/OVMF_VARS.fd; do
  c="${pair%%:*}"; v="${pair##*:}"
  if [[ -f "$c" && -f "$v" ]]; then OVMF_CODE="$c"; OVMF_VARS_SRC="$v"; break; fi
done
[[ -n "$OVMF_CODE" ]] || die "no OVMF firmware found; install the 'ovmf' package."

log "ISO       : $ISO"
log "workdir   : $WORK"
log "OVMF      : $OVMF_CODE"

cp "$OVMF_VARS_SRC" "$OVMF_VARS"
qemu-img create -f qcow2 "$DISK_IMG" "$DISK_SIZE" >/dev/null

# --- Helpers -----------------------------------------------------------------

ssh_vm() {
  sshpass -p "$PW" ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    -o ConnectTimeout=10 \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=120 \
    -p "$PORT" root@127.0.0.1 "$@"
}

wait_for_ssh() {
  local timeout="$1" label="$2" waited=0
  log "waiting for SSH ($label, up to ${timeout}s)..."
  while (( waited < timeout )); do
    if ssh_vm true 2>/dev/null; then
      log "SSH is up after ${waited}s"
      return 0
    fi
    sleep 10
    waited=$((waited + 10))
  done
  return 1
}

start_qemu() {
  local serial_log="$1" with_cdrom="$2"
  local args=(
    -enable-kvm -m "$MEM" -smp 2 -cpu host
    -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE"
    -drive "if=pflash,format=raw,file=$OVMF_VARS"
    -drive "file=$DISK_IMG,format=qcow2,if=virtio,cache=unsafe"
    -netdev "user,id=n0,hostfwd=tcp::${PORT}-:22"
    -device "virtio-net-pci,netdev=n0"
    -display none -monitor none
    -serial "file:$serial_log"
    -pidfile "$QEMU_PID"
  )
  if [[ "$with_cdrom" == "yes" ]]; then
    args+=(-cdrom "$ISO")
  fi
  qemu-system-x86_64 "${args[@]}" &
  # Give it a moment to fail fast on a bad invocation before we start polling.
  sleep 5
  kill -0 "$(cat "$QEMU_PID")" 2>/dev/null || die "QEMU exited immediately; see $serial_log"
}

stop_qemu() {
  if [[ -f "$QEMU_PID" ]]; then
    kill "$(cat "$QEMU_PID")" 2>/dev/null || true
    for _ in $(seq 1 30); do
      kill -0 "$(cat "$QEMU_PID")" 2>/dev/null || break
      sleep 1
    done
    kill -9 "$(cat "$QEMU_PID")" 2>/dev/null || true
    rm -f "$QEMU_PID"
  fi
}

# --- Boot 1: the live ISO, driven by install.sh ------------------------------

log "boot 1: live ISO with a blank $DISK_SIZE disk"
start_qemu "$LOG_INSTALL" yes

if ! wait_for_ssh "$BOOT_TIMEOUT" "live ISO"; then
  log "--- last 60 lines of serial output ---"
  tail -n 60 "$LOG_INSTALL" || true
  die "the live ISO never came up on SSH within ${BOOT_TIMEOUT}s"
fi

log "running install.sh ($FLAKE_ATTR, disk $VM_DISK)"
# install.sh reads three lines from stdin: the disk-path confirmation, then the
# password twice. It is not TTY-gated, so piping satisfies it.
set +e
ssh_vm "printf '%s\n%s\n%s\n' '$VM_DISK' '$PW' '$PW' | HOST=inspironTest DISK=$VM_DISK /etc/dreadheadnix/install.sh"
install_rc=$?
set -e

if [[ $install_rc -ne 0 ]]; then
  log "install.sh exited $install_rc"
  log "--- last 80 lines of serial output ---"
  tail -n 80 "$LOG_INSTALL" || true
  die "install.sh failed"
fi
log "install.sh completed"

stop_qemu

# --- Boot 2: the installed system, no ISO attached ---------------------------

log "boot 2: installed system, ISO detached"
start_qemu "$LOG_BOOT" no

if ! wait_for_ssh "$BOOT_TIMEOUT" "installed system"; then
  log "--- last 60 lines of serial output ---"
  tail -n 60 "$LOG_BOOT" || true
  die "the installed system never came up on SSH — it does not boot"
fi

hostname="$(ssh_vm hostname)"
log "installed system hostname: $hostname"
[[ "$hostname" == "dreadheadnix-test" ]] || die "unexpected hostname '$hostname'"

# Prove it is a real booted system rather than a shell that merely accepted us:
# the ESP mounted at /boot means the bootloader installed, and the subvolumes
# mounted means disko's labels came out right.
for check in "/boot:ESP" "/:root" "/nix:nix" "/home:home"; do
  mountpoint="${check%%:*}"
  label="${check##*:}"
  if ! ssh_vm "mountpoint -q '$mountpoint'"; then
    die "$mountpoint is not a mountpoint — the $label subvolume did not mount"
  fi
  log "  $mountpoint mounted ok ($label)"
done

# disko mounts by partlabel, so this is the check that would have caught a
# missing label before it became an unbootable machine.
ssh_vm "ls /dev/disk/by-partlabel/" | tee "$WORK/partlabels.txt"
ssh_vm "grep -q 'disk-main-ESP' /proc/mounts" || die "root/ESP not mounted by partlabel"

log "rehearsal passed: install.sh wiped the disk, installed, and the system boots"

stop_qemu

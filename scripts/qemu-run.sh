#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/qemu-run.sh <disk-image.qcow2> [--ram 8192] [--smp 4] [--display gtk|none]
  ./scripts/qemu-run.sh --cdrom ./installer.iso --disk ./vm.qcow2 [--ram 8192] [--smp 4]
  ./scripts/qemu-run.sh --cdrom ./installer.iso --disk ./vm.qcow2 --display none

Quickly launch a QEMU/KVM VM using either a bootable disk image or an installer ISO.

Examples:
  ./scripts/qemu-run.sh ~/images/linux.qcow2
  ./scripts/qemu-run.sh ~/images/win11.qcow2 --ram 16384 --smp 8 --display none
  ./scripts/qemu-run.sh --cdrom ~/Downloads/nixos.iso --disk ~/images/nixos-install.qcow2
EOF
}

IMAGE=""
CDROM=""
RAM="${QEMU_RAM:-8192}"
SMP="${QEMU_SMP:-4}"
DISPLAY="${QEMU_DISPLAY:-gtk}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --disk)
      IMAGE="$2"
      shift 2
      ;;
    --cdrom)
      CDROM="$2"
      shift 2
      ;;
    --ram)
      RAM="$2"
      shift 2
      ;;
    --smp)
      SMP="$2"
      shift 2
      ;;
    --display)
      DISPLAY="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$IMAGE" && -z "$CDROM" ]]; then
        IMAGE="$1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$IMAGE" && -z "$CDROM" ]]; then
  usage
  exit 1
fi

if [[ -n "$IMAGE" && ! -f "$IMAGE" ]]; then
  echo "Disk image not found: $IMAGE" >&2
  exit 1
fi

if [[ -n "$CDROM" && ! -f "$CDROM" ]]; then
  echo "ISO image not found: $CDROM" >&2
  exit 1
fi

COMMON_ARGS=(
  -enable-kvm
  -m "$RAM"
  -cpu host
  -smp "$SMP"
  -netdev "user,id=net0"
  -device "virtio-net-pci,netdev=net0"
  -display "$DISPLAY"
)

if [[ -n "$CDROM" ]]; then
  if [[ -z "$IMAGE" ]]; then
    echo "A target disk image is required when using --cdrom. Use --disk /path/to/target.qcow2" >&2
    exit 1
  fi

  if [[ ! -f "$IMAGE" ]]; then
    qemu-img create -f qcow2 "$IMAGE" 64G
  fi

  COMMON_ARGS+=(
    -boot d
    -cdrom "$CDROM"
    -drive "file=$IMAGE,format=qcow2,if=virtio"
  )
else
  COMMON_ARGS+=(
    -drive "file=$IMAGE,format=qcow2,if=virtio"
  )
fi

exec qemu-system-x86_64 "${COMMON_ARGS[@]}"

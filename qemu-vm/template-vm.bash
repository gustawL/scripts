#!/usr/bin/env bash
set -euo pipefail

vm_name="vm-template"

drive_file="${1:-}"
iso_file="${2:-}"
boot_mode="${3:-bootdisk}"

if [[ -z "$drive_file" ]]; then
  echo "Usage: $0 <drive_file> [iso_file] [bootdisk|bootiso]" >&2
  exit 1
fi

if [[ ! -f "$drive_file" ]]; then
  echo "Error: drive file does not exist: $drive_file" >&2
  exit 1
fi

if [[ "${2:-}" == "bootdisk" ]]; then
  iso_file=""
  boot_mode="$2"
fi

disk_bootindex=1
iso_bootindex=2

case "$boot_mode" in
  bootiso)
    disk_bootindex=2
    iso_bootindex=1
    ;;
  bootdisk)
    disk_bootindex=1
    iso_bootindex=2
    ;;
  *)
    echo "Error: 3rd arg must be equal: bootdisk albo bootiso" >&2
    exit 1
    ;;
esac

# Zamiast: mac_addr="$("/home/$USER/scripts/qemu-mac-hasher.py" "$vm_name")"
# mac_addr="${MAC_ADDR:-XX:XX:XX:XX:XX:XX}"
mac_addr="$("/home/$USER/scripts/qemu-mac-hasher.py" "$vm_name")"

qemu_args=(
  -enable-kvm
  -machine q35,accel=kvm
  -sandbox on,obsolete=deny,elevateprivileges=deny,spawn=deny,resourcecontrol=deny
  -name "$vm_name"
  -no-user-config
  -nodefaults
  -display none
  -monitor stdio
  -serial none
  -bios /usr/share/edk2-ovmf/OVMF_CODE.fd
  -cpu host
  -smp 10
  -m 16G
  -boot menu=on
  -device qemu-xhci,id=xhci0
  -blockdev driver=file,filename="$drive_file",node-name=osfile
  -blockdev driver=qcow2,file=osfile,node-name=osdisk
  -device virtio-blk-pci,drive=osdisk,bootindex="$disk_bootindex"
  -device virtio-rng-pci
  -nic user,ipv6=off,model=e1000,mac="$mac_addr"
  -device vfio-pci,host=01:00.0,multifunction=on
  -device vfio-pci,host=01:00.1
  -device usb-host,bus=xhci0.0,vendorid=0xXXXX,productid=0xYYYY # mice/keyboard pass
  -device usb-host,bus=xhci0.0,vendorid=0xZZZZ,productid=0xWWWW # yubikey placeholder
  -device u2f-passthru # yubikey
)

if [[ -n "$iso_file" ]]; then
  qemu_args+=(
    -blockdev driver=file,filename="$iso_file",node-name=cdfile,read-only=on
    -blockdev driver=raw,file=cdfile,node-name=cdraw
    -device ide-cd,drive=cdraw,bootindex="$iso_bootindex"
  )
fi

exec qemu-system-x86_64 "${qemu_args[@]}"

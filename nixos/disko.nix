# Disk layout: single NVMe, UEFI, Btrfs with subvolumes. No dual boot — disko
# is whole-disk destructive and would discard any other OS on this drive.
#
# The disk is a specialArg so the QEMU rehearsal can point it at /dev/vda:
#   nixos-rebuild ... --flake .#inspiron --override-input ... (or specialArgs)
# Overriding it here is a one-line change at the call site in flake.nix.
{ disk, ... }:

{
  disko.devices.disk.main = {
    type = "disk";
    device = disk;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          name = "ESP";
          start = "1MiB";
          end = "1GiB";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            # efivars and the ESP are root-only; systemd-boot does not need more.
            mountOptions = [ "umask=0077" ];
          };
        };

        root = {
          name = "root";
          # `size` is the documented disko form and is what every example in the
          # disko repo uses. `end = "100%"` is not validated by lib/types/gpt.nix
          # and only appears to work; stick to `size`.
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "@root" = {
                mountpoint = "/";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "@log" = {
                mountpoint = "/var/log";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}

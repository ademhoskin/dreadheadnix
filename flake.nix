{
  description = "dreadheadnix — NixOS + Hyprland for the Dell Inspiron 16 7630 2-in-1";

  inputs = {
    # 26.05 stable, not unstable: the 7630 is 2023 hardware that 26.05 supports
    # fully, this matches system.stateVersion below, and it keeps Hyprland on a
    # version closer to what dotfiles/hypr/hyprland.conf was written against.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, disko, ... } @ inputs:
    let
      system = "x86_64-linux";
    in {
      # The laptop.
      #   nixos-install --flake /etc/dreadheadnix#inspiron
      #   nixos-rebuild switch --flake /etc/dreadheadnix#inspiron
      nixosConfigurations.inspiron = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          # The single NVMe in the 7630. Override this (e.g. to /dev/vda) when
          # rehearsing the install against a throwaway QEMU disk.
          disk = "/dev/nvme0n1";
        };
        modules = [
          disko.nixosModules.disko
          ./nixos/configuration.nix
        ];
      };

      # CI-only variant of the installer, used by the install rehearsal job.
      #
      # It differs from `installer` in one respect. installation-device.nix
      # leaves root with an empty password, which sshd refuses, so this gives
      # root a throwaway one — and that is what lets the rehearsal drive
      # install.sh over SSH instead of scraping the serial console. The real
      # `installer` keeps root passwordless and sshd refusing empty passwords.
      #
      # Everything under test — the disk layout, install.sh, nixos-install, the
      # bootloader — is identical between the two. This ISO is uploaded only as
      # a short-lived rehearsal artifact, never as the thing you flash.
      nixosConfigurations.installerTest = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ./nixos/installer.nix
          ({ lib, ... }: {
            # installation-device.nix gives root an empty password, which sshd
            # refuses. Give it a real one for the rehearsal instead of enabling
            # PermitEmptyPasswords — a throwaway password on a CI-only image is
            # the smaller concession.
            users.users.root = {
              initialHashedPassword = lib.mkForce null;
              initialPassword = "ci-rehearsal";
            };
          })
        ];
      };

      # CI-only variant of the laptop config, used for the rehearsal's second
      # boot, so it can confirm the installed system actually comes up. It
      # differs from `inspiron` only in SSH policy and hostname. The disk
      # layout, device path, bootloader, services and home-manager config are
      # identical — the rehearsal attaches its disk as NVMe precisely so this
      # stays /dev/nvme0n1 rather than a virtio stand-in.
      nixosConfigurations.inspironTest = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; disk = "/dev/nvme0n1"; };
        modules = [
          disko.nixosModules.disko
          ./nixos/configuration.nix
          ({ lib, ... }: {
            # mkForce, not a plain assignment: nixos/configuration.nix already
            # sets networking.hostName, and two same-priority definitions of a
            # str option is a hard evaluation error — which would take down the
            # CI eval step and install.sh's pre-flight check.
            networking.hostName = lib.mkForce "dreadheadnix-test";
            services.openssh.settings = {
              PasswordAuthentication = lib.mkForce true;
              PermitRootLogin = lib.mkForce "yes";
            };
            users.users.root.initialPassword = "ci-rehearsal";
          })
        ];
      };

      # The custom installer ISO, with this repo baked in at /etc/dreadheadnix.
      # Built by .github/workflows/iso.yml, not locally.
      #
      # Note it deliberately does NOT import ./nixos/configuration.nix or
      # ./nixos/disko.nix: installation-cd-base.nix sets
      # `fileSystems = lib.mkImageMediaOverride config.lib.isoFileSystems` and
      # `swapDevices = lib.mkImageMediaOverride []`, so pulling the laptop's disk
      # layout in here would be silently discarded rather than reported.
      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ./nixos/installer.nix
        ];
      };
    };
}

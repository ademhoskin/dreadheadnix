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

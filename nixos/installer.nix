# The custom installer ISO.
#
# Built on installation-cd-minimal.nix, which already brings NetworkManager and
# nmtui (via nixos/modules/profiles/installation-device.nix), passwordless sudo
# for the `nixos` user, and sshd. So Wi-Fi on the laptop works out of the box
# and nothing here needs to add it.
#
# What this module adds on top:
#   * the repo itself, baked in at /etc/dreadheadnix
#   * the disko CLI at the exact revision this flake locks
{ lib, pkgs, inputs, ... }:

{
  # The repo, as this flake sees it. `environment.etc` symlinks rather than
  # copies, so /etc/dreadheadnix points into the store.
  #
  # This copy is for the live environment only — `installer` and `installerTest`
  # do not import nixos/configuration.nix. The installed system gets its own
  # copy, from the matching entry in configuration.nix; that one is what makes
  # `nixos-rebuild switch --flake /etc/dreadheadnix#inspiron` work after install.
  #
  # It does not make the install offline: nixos-install still runs
  # `nix flake metadata` and fetches the github: inputs, then realises the
  # closure into the target store from cache.nixos.org. The ISO needs working
  # network.
  environment.etc."dreadheadnix".source = inputs.self.outPath;

  # The live image does not enable the experimental CLI on its own. install.sh's
  # pre-flight `nix eval` needs nix-command, and `nixos-install --flake` needs
  # flakes; without this the very first check fails with
  # "experimental Nix feature 'nix-command' is disabled".
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # disko's CLI refuses to run when its version differs from the one the flake
  # locked, so take it from the flake input rather than from pkgs.
  environment.systemPackages = [
    inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko
  ];

  # installation-cd-minimal.nix sets this to "minimal"; make the image name
  # reflect what it actually is.
  isoImage.edition = lib.mkForce "dreadheadnix";

  # nixpkgs defaults to `zstd -Xcompression-level 19`, which is near-maximum and
  # dominates the ISO build time in CI. Level 6 is the example the option's own
  # docs give: a modestly larger image for a substantially faster squashfs pass.
  #
  # The ISO is compressed once per CI run but downloaded once per flash, so if
  # download size ever matters more than build time, raise this; if CI time
  # matters more, drop it to 3 or 1.
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";

  # The live environment is a rescue shell, not a machine to be preserved.
  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
}

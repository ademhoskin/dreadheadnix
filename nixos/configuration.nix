# dreadheadnix — the laptop.
#   nixos-install  --flake /etc/dreadheadnix#inspiron
#   nixos-rebuild switch --flake /etc/dreadheadnix#inspiron
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ./disko.nix
    ./tablet.nix

    inputs.home-manager.nixosModules.home-manager
  ];

  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    # The flake is the source of truth; a channel profile would just go stale.
    channel.enable = false;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  boot.loader.systemd-boot = {
    enable = true;
    # A 1 GiB ESP will not hold many generations; prune rather than fill /boot.
    configurationLimit = 10;
    editor = false;
  };
  boot.loader.efi = {
    # Needed for a real NVRAM boot entry (without it Dell firmware may not list
    # NixOS in the boot order) and for fwupd capsule updates.
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # RAM-backed /tmp. Capped so a runaway build cannot eat all memory.
  boot.tmp.useTmpfs = true;
  boot.tmp.tmpfsSize = "4G";

  networking = {
    hostName = "inspiron";
    networkmanager.enable = true;
  };

  # --- User ---
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ bash zsh ];
  users.defaultUserShell = pkgs.zsh;

  users.users.dreadheadcoder = {
    isNormalUser = true;
    description = "Adem Hoskin";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "docker"
      "libvirtd"
      "kvm"
      "input"
      "render"
    ];
    # The hash is generated at install time by ./install.sh and written outside
    # the repo. This repo is public — a plaintext or default password here would
    # hand out a working wheel-group credential to anyone who reads it.
    hashedPasswordFile = "/var/lib/nixos-secrets/passwd";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPHyO66WwXWsIQi4Tn4Dy/XlO7m3jkfrsv+og2IqXd2L ademjhoskin@gmail.com"
    ];
  };

  # --- Desktop ---
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  # SDDM appends ".desktop" to this; nothing sets it for us, and without it
  # SDDM picks its own default session.
  services.displayManager.defaultSession = "hyprland";
  programs.hyprland.enable = true;

  security.polkit.enable = true;
  security.rtkit.enable = true;

  # --- Audio ---
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # --- Peripherals and services ---
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    # nssmdns was renamed; nssmdns4 is the current spelling.
    nssmdns4 = true;
    openFirewall = true;
  };

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.podman.enable = true;

  # Lets prebuilt/FHS binaries (rustup, bun, LSP servers fetched by Mason) run.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [ zlib stdenv.cc.cc.lib openssl ncurses ];
  };

  fonts = {
    fontconfig.enable = true;
    fontconfig.defaultFonts.monospace = [ "JetBrainsMono Nerd Font" ];
    packages = with pkgs; [ nerd-fonts.jetbrains-mono ];
  };

  # Needed by the Hyprland session (autostart and binds) before the user
  # environment exists, so these live on the system PATH rather than in
  # home-manager.
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    jq

    alacritty
    kdePackages.dolphin
    hyprpaper
    waybar
    wofi
    cliphist
    wl-clipboard
    hyprshot
    brightnessctl
    qt6Packages.qt6ct

    # Browser. qutebrowser renders with QtWebEngine — Chromium's Blink/V8 — but
    # ships only a minimal keyboard-driven shell on top, which makes it the
    # lightest Chromium available in nixpkgs. It is also vim-keybound by
    # default, matching the evil-mode workflow everywhere else here.
    #
    # Worth knowing: the engine is the bulk of the closure, so this is lighter
    # at runtime, not on disk. Every Chromium variant is roughly the same size.
    qutebrowser

    kdePackages.kate
    kdePackages.konsole

    qemu
    qemu-utils
    virt-viewer

    zip
    p7zip
    unzip
    unrar
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # --- Home Manager ---
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    users.dreadheadcoder = import ../home-manager/home.nix;
  };

  system.stateVersion = "26.05";
}

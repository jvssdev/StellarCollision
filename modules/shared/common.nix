{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;
  hardware.enableRedistributableFirmware = lib.mkDefault true;
  hardware.enableAllFirmware = true;
  time.timeZone = config.cfg.vars.timezone;

  environment.systemPackages = [
    pkgs.wget
    pkgs.curl
    pkgs.git
    pkgs.gh
    pkgs.jq
    pkgs.neovim-unwrapped
    pkgs.unzip
    pkgs.nix-index
    pkgs.dnsutils
    pkgs.nmap
    pkgs.mpc
    pkgs.ffmpeg
    pkgs.playerctl
    pkgs.pamixer
    pkgs.pavucontrol
    pkgs.networkmanagerapplet
    pkgs.anydesk
    pkgs.glib
    pkgs.p7zip
    pkgs.appimage-run
    pkgs.nh
    pkgs.mpv
    pkgs.imv
    pkgs.grim
    pkgs.slurp
    pkgs.wl-clip-persist
    pkgs.cliphist
    pkgs.wl-clipboard
    pkgs.qbittorrent
    pkgs.libgcc
    pkgs.libnotify
    pkgs.procps
    pkgs.wireplumber
    pkgs.bluez
    pkgs.blueman
    pkgs.wlopm
    pkgs.dbus
    pkgs.xdg-utils
    pkgs.wf-recorder
    pkgs.fcitx5

    pkgs.kdePackages.qt5compat
    pkgs.kdePackages.qtbase
    pkgs.kdePackages.qtdeclarative

    pkgs.lxqt.lxqt-policykit

    pkgs.xorg.xrdb
  ];

  security = {
    sudo = {
      enable = true;
      extraConfig = ''
        Defaults lecture = never

                Defaults timestamp_timeout=30

                Defaults env_keep += "EDITOR VISUAL TERM"
      '';
    };
  };

  services = {
    gvfs.enable = config.cfg.vars.withGui;
    tumbler.enable = config.cfg.vars.withGui;
    dbus.implementation = "dbus";

    angrr = {
      enable = true;
      enableNixGcIntegration = true;
      settings = {
        profile-policies = {
          system = {
            keep-booted-system = true;
            keep-current-system = true;
            keep-latest-n = 5;
            keep-since = "7d";
            profile-paths = [ "/nix/var/nix/profiles/system" ];
          };
          user = {
            enable = false;
            keep-booted-system = false;
            keep-current-system = false;
            keep-latest-n = 1;
            keep-since = "1d";
            profile-paths = [
              "~/.local/state/nix/profiles/profile"
              "/nix/var/nix/profiles/per-user/root/profile"
            ];
          };
        };
        temporary-root-policies = {
          direnv = {
            path-regex = "/\\.direnv/";
            period = "14d";
          };
          result = {
            path-regex = "/result[^/]*$";
            period = "3d";
          };
        };
      };
    };
    playerctld.enable = config.cfg.vars.withGui;
  };

  system = {
    activationScripts.diff = {
      supportsDryActivation = true;
      text = ''
        ${lib.getExe pkgs.nvd} --nix-bin-dir=${pkgs.nix}/bin diff /run/current-system "$systemConfig"
      '';
    };
  };

  systemd.services.nix-daemon = lib.mkIf config.boot.tmp.useTmpfs {
    environment.TMPDIR = "/var/tmp";
  };

  nix = {
    gc.automatic = true;
    registry = {
      system.flake = inputs.nixpkgs;
      default.flake = inputs.nixpkgs;
      nixpkgs.flake = inputs.nixpkgs;
    };

    settings = {
      trusted-users = [ "@wheel" ];
      allowed-users = [ "@wheel" ];
      log-lines = 30;
      accept-flake-config = false;
      auto-optimise-store = true;
      use-xdg-base-directories = true;
      keep-derivations = true;
      keep-outputs = true;
      warn-dirty = false;
      http-connections = 128;
      max-substitution-jobs = 128;
      narinfo-cache-positive-ttl = 3600;
      commit-lockfile-summary = "chore: Update flake.lock";
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      extra-substituters = [
        "https://nix-community.cachix.org"
        "https://cache.garnix.io"
        "https://wezterm.cachix.org"
      ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        "wezterm.cachix.org-1:kAbhjYUC9qvblTE+s7S+kl5XM1zVa4skO+E/1IDWdH0="
      ];
    };
  };
}

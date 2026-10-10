{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  libreofficeSeedLocale = pkgs.writeShellScript "libreoffice-seed-locale" ''
    f="''${XDG_CONFIG_HOME:-$HOME/.config}/libreoffice/4/user/registrymodifications.xcu"
    mkdir -p "$(dirname "$f")"
    if [ ! -f "$f" ]; then
      printf '%s\n' \
        '<?xml version="1.0" encoding="UTF-8"?>' \
        '<oor:items xmlns:oor="http://openoffice.org/2001/registry" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' \
        '</oor:items>' > "$f"
    fi
    if ! grep -q 'oor:name="DefaultLocale"' "$f"; then
      sed -i 's|</oor:items>|<item oor:path="/org.openoffice.Office.Linguistic/General"><prop oor:name="DefaultLocale" oor:op="fuse"><value>pt-BR</value></prop></item>\n</oor:items>|' "$f"
    fi
  '';
in
{
  nixpkgs.config.allowUnfree = true;
  hardware.enableRedistributableFirmware = lib.mkDefault true;
  hardware.enableAllFirmware = true;
  time.timeZone = config.cfg.vars.timezone;

  environment.systemPackages = [

    pkgs.ente-auth
    pkgs.wget
    pkgs.curl
    pkgs.git
    pkgs.gh
    pkgs.jq
    pkgs.tealdeer
    pkgs.neovim-unwrapped
    pkgs.unzip
    pkgs.p7zip
    pkgs.rar
    pkgs.nix-index
    pkgs.wf-recorder
    pkgs.mpc
    pkgs.ffmpeg
    pkgs.playerctl
    pkgs.pamixer
    pkgs.pavucontrol
    pkgs.wireplumber

    pkgs.appimage-run
    pkgs.nh

    pkgs.wl-clip-persist
    pkgs.cliphist
    pkgs.wl-clipboard

    pkgs.glib
    pkgs.libgcc
    pkgs.libnotify
    pkgs.procps
    pkgs.bluez
    pkgs.wlopm
    pkgs.dbus
    pkgs.xdg-utils
    pkgs.fcitx5

    pkgs.kdePackages.qt5compat
    pkgs.kdePackages.qtbase
    pkgs.kdePackages.qtdeclarative
    pkgs.lxqt.lxqt-policykit

    pkgs.networkmanagerapplet
    pkgs.qbittorrent
    pkgs.imv
    pkgs.rustdesk-flutter
    pkgs.haruna

    (pkgs.symlinkJoin {
      name = "libreoffice-pt-br";
      paths = [ pkgs.libreoffice ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        for bin in libreoffice soffice; do
          wrapProgram $out/bin/$bin --run ${libreofficeSeedLocale}
        done
      '';
    })

    (pkgs.hunspell.withDicts (dicts: [
      dicts.en_US
      dicts.en_GB-ize
      dicts.pt_BR
    ]))

    pkgs.azahar
    pkgs.melonds
    pkgs.ntfs3g
    pkgs.thunderbird
    pkgs.rufin
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
    dbus.implementation = "broker";

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
        # "https://nix-community.cachix.org"
        # "https://cache.garnix.io"
        # "https://niri.cachix.org"
      ];
      extra-trusted-public-keys = [
        # "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        # "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        # "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      ];
    };
  };
}

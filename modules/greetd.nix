{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    mkIf
    mkEnableOption
    ;
  cfg = config.cfg.sddm;

  sceneQml = pkgs.replaceVars ./stellar-theme/LoginScene.qml {
    fontFamily = cfg.font.name;
  };

  themeMetadata = pkgs.writeText "metadata.desktop" ''
    [SddmGreeterTheme]
    Name=Stellar Winter
    Description=Winter-inspired theme with a custom wallpaper, derived from the qylock Winter theme
    Author=StellarCollision
    Version=1.0
    Type=sddm-theme
    MainScript=Main.qml
    ConfigFile=theme.conf
    QtVersion=6
  '';

  themeConf = pkgs.writeText "theme.conf" ''
    [General]
  '';

  sddmTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "stellar-sddm-theme";
    version = "1.0";
    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      dir=$out/share/sddm/themes/${cfg.theme}
      mkdir -p $dir
      cp ${sceneQml} $dir/LoginScene.qml
      cp ${./stellar-theme/Main.qml} $dir/Main.qml
      cp ${./stellar-theme/NOTICE} $dir/NOTICE
      cp ${cfg.background} $dir/background.png
      cp ${themeMetadata} $dir/metadata.desktop
      cp ${themeConf} $dir/theme.conf

      runHook postInstall
    '';
  };

  lockShell = pkgs.stdenvNoCC.mkDerivation {
    pname = "stellar-lock-shell";
    version = "1.0";
    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      dir=$out/share/stellar-lock
      mkdir -p $dir
      cp ${sceneQml} $dir/LoginScene.qml
      cp ${./stellar-theme/lock.qml} $dir/lock.qml
      cp ${./stellar-theme/NOTICE} $dir/NOTICE
      cp ${cfg.background} $dir/background.png

      runHook postInstall
    '';
  };

  stellarLock = pkgs.writeShellScriptBin "stellar-lock" ''
    set -eu

    entry=${lockShell}/share/stellar-lock/lock.qml

    export PATH=${
      lib.makeBinPath [
        pkgs.quickshell
        pkgs.procps
        pkgs.coreutils
      ]
    }:$PATH

    if [ "''${1:-}" = "--test" ]; then
      export STELLAR_LOCK_TEST=1
    fi

    if [ "''${STELLAR_LOCK_TEST:-0}" != 1 ] && pgrep -f "$entry" >/dev/null 2>&1; then
      exit 0
    fi

    exec quickshell -p "$entry"
  '';
in
{
  options.cfg.sddm = {
    enable = mkEnableOption "Enable SDDM with the Stellar Winter theme and lockscreen.";
    wayland.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Wayland for SDDM.";
    };
    theme = mkOption {
      type = types.str;
      default = "stellar-winter";
      description = "Name of the SDDM theme directory installed by this module.";
    };
    background = mkOption {
      type = types.path;
      default = inputs.self + "/assets/Wallpapers/a6116535-4a72-453e-83c9-ea97b8597d8c.png";
      description = "Wallpaper used by the SDDM theme and by the lockscreen.";
    };
    font = {
      name = mkOption {
        type = types.str;
        default = "Orbitron";
        description = "Font family used by the theme.";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.orbitron;
        description = "Package providing the theme font.";
      };
    };
  };

  config = mkIf cfg.enable {
    security.pam.services.stellar-lock = { };

    fonts.packages = [ cfg.font.package ];

    environment = {
      systemPackages = with pkgs; [
        stellarLock
        sddmTheme
        kdePackages.qt6ct
        kdePackages.qtwayland
        qt6.qtwayland
        config.cfg.gtk.cursorTheme.package
      ];

      etc."sddm.conf.d/cursor.conf".text = ''
        [Theme]
        CursorTheme=${config.cfg.gtk.cursorTheme.name}
        CursorSize=${toString config.cfg.gtk.cursorTheme.size}
      '';

      etc."sddm.conf.d/virtualkeyboard.conf".text = ''
        [General]
        InputMethod=
      '';
    };

    qt.enable = true;

    systemd.tmpfiles.rules =
      let
        cursorPkg = config.cfg.gtk.cursorTheme.package;
        cursorName = config.cfg.gtk.cursorTheme.name;
        themePath = "${cursorPkg}/share/icons/${cursorName}";
      in
      [
        "L+ /usr/share/icons/default - - - - ${themePath}"
        "L+ /var/lib/sddm/.icons/default - - - - ${themePath}"
        "d /var/lib/sddm/.icons 0755 sddm sddm -"
      ];

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = cfg.wayland.enable;
      package = pkgs.kdePackages.sddm;
      theme = lib.mkForce cfg.theme;
      extraPackages = [
        config.cfg.gtk.cursorTheme.package
        sddmTheme
      ];
      settings = {
        Theme = {
          Current = cfg.theme;
          CursorTheme = config.cfg.gtk.cursorTheme.name;
          CursorSize = config.cfg.gtk.cursorTheme.size;
        };
        General = {
          InputMethod = "";
        };
      };
    };
  };
}

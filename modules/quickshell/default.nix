{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.cfg.quickshell;
  quickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  c = config.cfg.theme.colors;
  inherit (lib)
    mkOption
    mkIf
    types
    ;
  inherit (builtins) substring;

  isNiri = config.cfg.niri.enable or false;
  isMango = config.cfg.mango.enable or false;

  componentsDir = ./_components;
  NotificationPopups = import (componentsDir + "/NotificationPopups.nix") { inherit pkgs lib; };
  NotificationCenter = import (componentsDir + "/NotificationCenter.nix") { inherit isNiri isMango; };
  ControlCenter = import (componentsDir + "/ControlCenter.nix") {
    inherit
      isNiri
      isMango
      pkgs
      lib
      config
      ;
  };
  PowerButton = import (componentsDir + "/PowerButton.nix") { inherit pkgs lib; };
  PowerMenu = import (componentsDir + "/PowerMenu.nix") {
    backgroundColor = "#80${substring 1 6 c.base00}";
    inherit (c) base07;
  };
  WorkspaceModule = import (componentsDir + "/WorkspaceModule.nix") {
    inherit isNiri isMango;
    fontFamily = config.cfg.fonts.monospace.name;
  };
  IdleMonitors = import (componentsDir + "/IdleMonitors.nix") {
    inherit pkgs lib isNiri;
    quickshellPackage = cfg.package;
  };
  LockContext = import (componentsDir + "/LockContext.nix") { };
  LockSurface = import (componentsDir + "/LockSurface.nix") { };
  BluetoothService = import (componentsDir + "/BluetoothService.nix") { };
  BatteryMonitor = import (componentsDir + "/BatteryMonitor.nix") { inherit pkgs lib; };
  Shell = import (componentsDir + "/shell.nix") {
    inherit pkgs lib config;
    quickshellPackage = cfg.package;
    fontFamily = config.cfg.fonts.monospace.name;
    colors = c;
  };

  wallpapersDir = ../../assets/Wallpapers;
  wallpapersFiles = lib.filterAttrs (
    name: type:
    type == "regular"
    && (lib.hasSuffix ".png" name || lib.hasSuffix ".jpg" name || lib.hasSuffix ".jpeg" name)
  ) (builtins.readDir wallpapersDir);
  wallpapersList = lib.mapAttrsToList (name: _: toString wallpapersDir + "/" + name) wallpapersFiles;

  Wallpaper = import (componentsDir + "/Wallpaper.nix") {
    inherit pkgs lib wallpapersList;
  };

  WallpaperPicker = import (componentsDir + "/WallpaperPicker.nix") {
    inherit pkgs lib wallpapersList;
  };

  OverviewWallpaper = import (componentsDir + "/OverviewWallpaper.nix") {
    inherit pkgs lib wallpapersList;
  };

  Launcher = import (componentsDir + "/Launcher.nix") {
    inherit pkgs lib;
    fontFamily = config.cfg.fonts.monospace.name;
    colors = c;
    inherit (cfg) iconResolverPath;
  };
in
{
  options.cfg.quickshell = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Quickshell configuration";
    };
    package = mkOption {
      type = types.package;
      default = quickshell;
      description = "The Quickshell package to use";
    };
    iconResolverPath = mkOption {
      type = types.str;
      default = "icon-resolver";
      description = "Absolute path to the icon-resolver binary";
    };
  };

  config = mkIf cfg.enable {
    hj.packages = [
      cfg.package
      pkgs.gammastep
      pkgs.brightnessctl
      pkgs.libnotify
      pkgs.cliphist
      pkgs.wl-clipboard
    ];
    environment.sessionVariables = {
      QML_IMPORT_PATH = lib.concatStringsSep ":" [
        "$HOME/.config/quickshell"
        "${pkgs.quickshell}/share/qml"
        (lib.makeSearchPath "lib/qt-6/qml" [
          pkgs.kdePackages.qtdeclarative
          pkgs.kdePackages.qtbase
        ])
      ];
    };
    hj.xdg.config.files = {
      "quickshell/icons".source = ../../assets/icons;
      "quickshell/BatteryMonitor.qml".text = BatteryMonitor;
      "quickshell/NotificationPopups.qml".text = NotificationPopups;
      "quickshell/NotificationCenter.qml".text = NotificationCenter;
      "quickshell/ControlCenter.qml".text = ControlCenter;
      "quickshell/PowerButton.qml".text = PowerButton;
      "quickshell/PowerMenu.qml".text = PowerMenu;
      "quickshell/WorkspaceModule.qml".text = WorkspaceModule;
      "quickshell/IdleMonitors.qml".text = IdleMonitors;
      "quickshell/shell.qml".text = Shell;
      "quickshell/Wallpaper.qml".text = Wallpaper;
      "quickshell/WallpaperPicker.qml".text = WallpaperPicker;
      "quickshell/OverviewWallpaper.qml".text = OverviewWallpaper;
      "quickshell/wallpaper.png".source =
        ../../assets/Wallpapers/a6116535-4a72-453e-83c9-ea97b8597d8c.png;
      "quickshell/pam/password.conf".text = ''
        auth required pam_unix.so
      '';
      "quickshell/LockSurface.qml".text = LockSurface;
      "quickshell/LockContext.qml".text = LockContext;
      "quickshell/BluetoothService.qml".text = BluetoothService;
      "quickshell/Launcher.qml".text = Launcher;
    };
  };
}

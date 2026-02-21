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
    getExe
    getExe'
    ;
  inherit (builtins) substring;

  # Detect which compositor is enabled
  isNiri = config.cfg.niri.enable or false;
  isMango = config.cfg.mango.enable or false;

  # Import component files
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
    base07 = c.base07;
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
  Shell = import (componentsDir + "/shell.nix") {
    inherit pkgs lib config;
    quickshellPackage = cfg.package;
    fontFamily = config.cfg.fonts.monospace.name;
    colors = c;
  };

  # Listar todos os wallpapers disponíveis
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

  OverviewWallpaper = import (componentsDir + "/OverviewWallpaper.nix") {
    inherit pkgs lib wallpapersList;
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
  };

  config = mkIf cfg.enable {
    hj.packages = [
      cfg.package
      pkgs.gammastep
      pkgs.brightnessctl
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
      "quickshell/NotificationPopups.qml".text = NotificationPopups;
      "quickshell/NotificationCenter.qml".text = NotificationCenter;
      "quickshell/ControlCenter.qml".text = ControlCenter;
      "quickshell/PowerButton.qml".text = PowerButton;
      "quickshell/PowerMenu.qml".text = PowerMenu;
      "quickshell/WorkspaceModule.qml".text = WorkspaceModule;
      "quickshell/IdleMonitors.qml".text = IdleMonitors;
      "quickshell/shell.qml".text = Shell;
      "quickshell/Wallpaper.qml".text = Wallpaper;
      "quickshell/OverviewWallpaper.qml".text = OverviewWallpaper;
      "quickshell/wallpaper.png".source =
        ../../assets/Wallpapers/a6116535-4a72-453e-83c9-ea97b8597d8c.png;
      "quickshell/pam/password.conf".text = ''
        auth required pam_unix.so
      '';
      "quickshell/LockContext.qml".text = LockContext;
      "quickshell/LockSurface.qml".text = LockSurface;
    };
  };
}

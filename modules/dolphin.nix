{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption mkIf types;
  cfg = config.cfg.dolphin;
in
{
  options.cfg.dolphin = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Dolphin configuration.";
    };
    package = mkOption {
      type = types.package;
      default = pkgs.kdePackages.dolphin;
      description = "The Dolphin package to install.";
    };
  };

  config = mkIf cfg.enable {
    hj = {
      packages = [
        cfg.package
        pkgs.kdePackages.dolphin-plugins
        pkgs.kdePackages.ffmpegthumbs
        pkgs.kdePackages.ark
        pkgs.kdePackages.kservice
        pkgs.kdePackages.filelight
        pkgs.ghostty
      ];

      xdg.config.files."kdeglobals".text = ''
        [General]
        TerminalApplication=ghostty
        TerminalService=com.mitchellh.ghostty.desktop
      '';

      xdg.data.files."kio/servicemenus/ghostty-open-here.desktop".text = ''
        [Desktop Entry]
        Type=Service
        ServiceTypes=KonqPopupMenu/Plugin
        MimeType=inode/directory;
        Actions=openGhosttyHere;
        X-KDE-Priority=TopLevel

        [Desktop Action openGhosttyHere]
        Name=Open Ghostty Here
        Icon=com.mitchellh.ghostty
        Exec=${pkgs.ghostty}/bin/ghostty --gtk-single-instance=false --working-directory=%f
      '';
    };

  };
}

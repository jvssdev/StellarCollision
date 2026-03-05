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
    hj.packages = [
      cfg.package
      pkgs.kdePackages.dolphin-plugins
      pkgs.kdePackages.ffmpegthumbs
      pkgs.kdePackages.ark
      pkgs.kdePackages.kservice
      pkgs.gparted
    ];

    hj.xdg.data.files."kio/servicemenus/wezterm-open-here.desktop".text = ''
      [Desktop Entry]
      Type=Service
      ServiceTypes=KonqPopupMenu/Plugin
      MimeType=inode/directory;
      Actions=openWeztermHere;
      X-KDE-Priority=TopLevel

      [Desktop Action openWeztermHere]
      Name=Open Terminal Here
      Icon=org.wezfurlong.wezterm
      Exec=${pkgs.wezterm}/bin/wezterm start --cwd %f
    '';
  };
}

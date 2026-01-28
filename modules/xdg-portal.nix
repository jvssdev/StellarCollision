{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.cfg.portals;
in
{
  options.cfg.portals = {
    enable = mkEnableOption "XDG Desktop Portals configuration";
  };
  config = mkIf cfg.enable {
    xdg = {
      portal = {
        enable = true;
        wlr.enable = true;
        xdgOpenUsePortal = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-wlr
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-termfilechooser
        ];
        config = {
          common = {
            default = [ "gtk" ];
            "org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
          };
          mango = {
            default = [ "gtk" ];
            "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
            "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
            "org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
            "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
            "org.freedesktop.impl.portal.Inhibit" = [ ];
          };
        };
      };
    };
    hj.xdg.config.files."xdg-desktop-portal-termfilechooser/config" = {
      text = ''
        [filechooser]
        cmd=${
          config.hjem.users.${config.cfg.vars.username}.directory
        }/.config/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
        default_dir=${config.hjem.users.${config.cfg.vars.username}.directory}
        open_mode=suggested
        save_mode=last  
      '';
    };
    hj.xdg.config.files."xdg-desktop-portal-termfilechooser/yazi-wrapper.sh" = {
      executable = true;
      text = ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail

        multiple="$1"
        directory="$2"
        save="$3"
        path="$4"
        out="$5"

        ${pkgs.wezterm}/bin/wezterm start \
          --always-new-process \
          --class filechooser \
          -- ${pkgs.yazi}/bin/yazi \
          --chooser-file="$out" \
          "$path"
      '';
    };
  };
}

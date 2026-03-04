{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf optionals;
  cfg = config.cfg.portals;
in
{
  options.cfg.portals = {
    enable = mkEnableOption "XDG Desktop Portals configuration";
  };

  config = mkIf cfg.enable {
    systemd.user.services.xdg-desktop-portal = {
      serviceConfig = {
        Environment = [
          "NIX_XDG_DESKTOP_PORTAL_DIR=/run/current-system/sw/share/xdg-desktop-portal/portals"
          "XDG_DATA_DIRS=/run/current-system/sw/share:/etc/profiles/per-user/%u/share"
        ];
      };
    };

    systemd.user.services.xdg-desktop-portal-gnome = {
      serviceConfig = {
        Environment = [
          "XDG_DATA_DIRS=/run/current-system/sw/share:/etc/profiles/per-user/%u/share"
        ];
      };
    };

    xdg.portal = {
      enable = true;
      wlr.enable = config.cfg.mango.enable;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ]
      ++ optionals config.cfg.niri.enable [ pkgs.xdg-desktop-portal-gnome ]
      ++ optionals config.cfg.mango.enable [ pkgs.xdg-desktop-portal-wlr ];

      config = {
        common = {
          default = [ "gtk" ];
          "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
          "org.freedesktop.impl.portal.AppChooser" = "gtk";
        };
        niri = {
          "org.freedesktop.impl.portal.Access" = "gtk";
          "org.freedesktop.impl.portal.AppChooser" = "gtk";
          "org.freedesktop.impl.portal.FileChooser" = "gtk";
          "org.freedesktop.impl.portal.Notification" = "gtk";
          "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
        };
        mango = {
          "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
          "org.freedesktop.impl.portal.ScreenCast" = "wlr";
          "org.freedesktop.impl.portal.FileChooser" = "gtk";
          "org.freedesktop.impl.portal.Screenshot" = "wlr";
          "org.freedesktop.impl.portal.Inhibit" = [ ];
        };
      };
    };
  };
}

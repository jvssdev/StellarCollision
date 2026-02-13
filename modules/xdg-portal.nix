{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    optional
    ;

  homeDir = config.cfg.vars.homeDirectory;
  inherit (config.cfg.vars) username;
  cfg = config.cfg.portals;

  yazi-wrapper = pkgs.writeShellScript "yazi-filechooser-wrapper" ''
    #!/usr/bin/env bash
    set -e

    out="$5"
    path="$4"
    USER_ID=$(${pkgs.coreutils}/bin/id -u)

    if [ ! -d "$path" ]; then
      path="${homeDir}"
    fi

    cd "$path"

    export HOME="${homeDir}"
    export USER="${username}"
    export XDG_CONFIG_HOME="${homeDir}/.config"
    export XDG_DATA_HOME="${homeDir}/.local/share"
    export XDG_CACHE_HOME="${homeDir}/.cache"
    export YAZI_CONFIG_HOME="${homeDir}/.config/yazi"
    export XDG_RUNTIME_DIR="/run/user/$USER_ID"
    export WAYLAND_DISPLAY="wayland-0"

    export PATH="${pkgs.coreutils}/bin:${pkgs.bash}/bin:${pkgs.wezterm}/bin:${pkgs.yazi}/bin:/run/current-system/sw/bin:$PATH"

    exec ${pkgs.wezterm}/bin/wezterm start \
      --always-new-process \
      --class filechooser \
      -- ${pkgs.yazi}/bin/yazi --chooser-file="$out" "$path" 2>&1
  '';
in
{
  options.cfg.portals = {
    enable = mkEnableOption "XDG Desktop Portals configuration";
  };

  config = mkIf cfg.enable {
    systemd.user.services.xdg-desktop-portal.environment = {
      NIX_XDG_DESKTOP_PORTAL_DIR = "/run/current-system/sw/share/xdg-desktop-portal/portals";
    };

    systemd.user.services.xdg-desktop-portal-termfilechooser.environment = {
      WAYLAND_DISPLAY = "wayland-0";
      XDG_RUNTIME_DIR = "/run/user/%U";
    };

    xdg = {
      portal = {
        enable = true;
        wlr.enable = true;
        xdgOpenUsePortal = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-termfilechooser
        ]
        ++ (optional (config.niri.enable or false) pkgs.xdg-desktop-portal-gnome)
        ++ (optional (config.mango.enable or false) pkgs.xdg-desktop-portal-wlr);

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
          niri = {
            default = [ "gtk" ];
            "org.freedesktop.impl.portal.Access" = "gtk";
            "org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
            "org.freedesktop.impl.portal.Notification" = "gtk";
            "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
          };
        };
      };
    };

    hj.xdg.config.files."xdg-desktop-portal-termfilechooser/config".text = ''
      [filechooser]
      cmd=${yazi-wrapper}
      default_dir=${homeDir}
    '';
  };
}

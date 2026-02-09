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
    ;

  homeDir = config.cfg.vars.homeDirectory;
  inherit (config.cfg.vars) username;
  cfg = config.cfg.portals;

  xdg-desktop-portal-termfilechooser-mango =
    pkgs.xdg-desktop-portal-termfilechooser.overrideAttrs
      (oldAttrs: {
        postInstall = ''
          ${oldAttrs.postInstall or ""}
          sed -i 's/UseIn=/UseIn=mango;/' $out/share/xdg-desktop-portal/portals/termfilechooser.portal
        '';
      });

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

    # PATH completo para garantir que tudo seja encontrado
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
          xdg-desktop-portal-termfilechooser-mango
          pkgs.xdg-desktop-portal-wlr
          pkgs.xdg-desktop-portal-gtk
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

    hj.xdg.config.files."xdg-desktop-portal-termfilechooser/config".text = ''
      [filechooser]
      cmd=${yazi-wrapper}
      default_dir=${homeDir}
    '';
  };
}

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
    getExe
    getExe'
    ;
  homeDir = config.cfg.vars.homeDirectory;
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
        cmd=${getExe pkgs.bash} ${homeDir}/.config/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
        default_dir=${homeDir}
      '';
    };

    hj.xdg.config.files."xdg-desktop-portal-termfilechooser/yazi-wrapper.sh" = {
      executable = true;
      text = ''
        #!${getExe pkgs.bash}
        set -e

        out="$5"
        path="$4"

        export PATH="${
          lib.makeBinPath [
            pkgs.wezterm
            pkgs.yazi
            pkgs.coreutils
          ]
        }:$PATH"

        USER_ID=$(${getExe' pkgs.coreutils "id"} -u)
        export USER=$(${getExe' pkgs.coreutils "id"} -un)
        export HOME="${homeDir}"
        export XDG_RUNTIME_DIR="/run/user/$USER_ID"

        export DISPLAY=":11"
        unset WAYLAND_DISPLAY

        export XMODIFIERS="@im=fcitx"
        export GTK_IM_MODULE="fcitx"
        export QT_IM_MODULE="fcitx"
        export SDL_IM_MODULE="fcitx"
        export GLFW_IM_MODULE="ibus"

        export XKB_CONFIG_ROOT="${pkgs.xkeyboard_config}/share/X11/xkb"
        export XKB_DEFAULT_LAYOUT="br"

        if [ ! -d "$path" ]; then
          path="$HOME"
        fi

        exec ${getExe pkgs.wezterm} start \
          --always-new-process \
          --class filechooser \
          -- ${getExe pkgs.yazi} \
          --chooser-file="$out" \
          "$path" >> /tmp/portal-debug.log 2>&1
      '';
    };
  };
}

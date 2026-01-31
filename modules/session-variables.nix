{
  config,
  lib,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.cfg.sessionVariables;
in
{
  options.cfg.sessionVariables.enable = mkEnableOption "Centralized session variables";

  config = mkIf cfg.enable {
    environment.sessionVariables = {
      XCURSOR_THEME = config.cfg.gtk.cursorTheme.name;
      XCURSOR_SIZE = toString config.cfg.gtk.cursorTheme.size;

      GTK_THEME = config.cfg.gtk.theme.name;

      QT_QPA_PLATFORMTHEME = "qt5ct";

      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_FORCE_DPI = "140";

      QT_IM_MODULE = "fcitx";
      SDL_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      GLFW_IM_MODULE = "ibus";

      XDG_SESSION_TYPE = "wayland";
      SDL_VIDEODRIVER = "wayland";
      GDK_BACKEND = "wayland";
      CLUTTER_BACKEND = "wayland";
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      NIXOS_OZONE_WL = "1";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      GTK_USE_PORTAL = "1";

      GDK_DPI_SCALE = "1.45";

      EDITOR = "nvim";
      VISUAL = "nvim";
      SUDO_EDITOR = "nvim";
    };
  };
}

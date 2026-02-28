{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types mkIf;
  cfg = config.cfg.gtk;

  font = {
    inherit (config.cfg.fonts.monospace) name;
    inherit (config.cfg.fonts) size;
  };

  fairywrenWithFallback = pkgs.fairywren.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      theme_dir="$out/share/icons/FairyWren_Dark"
      if [ -f "$theme_dir/index.theme" ]; then
        sed -i '/^Inherits=/d' "$theme_dir/index.theme"
        sed -i '/^\[Icon Theme\]/a Inherits=Adwaita,hicolor' "$theme_dir/index.theme"
      fi
    '';
  });
in
{
  options.cfg.gtk = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable GTK Theme configuration.";
    };

    theme = mkOption {
      type = types.attrs;
      default = {
        name = "Colloid-Dark-Compact";
        package = pkgs.colloid-gtk-theme.override {
          colorVariants = [ "dark" ];
          themeVariants = [ "default" ];
          sizeVariants = [ "compact" ];
          tweaks = [
            "rimless"
            "black"
          ];
        };
      };
      description = "GTK theme configuration";
    };

    iconTheme = mkOption {
      type = types.attrs;
      default = {
        name = "FairyWren_Dark";
        package = fairywrenWithFallback;
      };
      description = "Icon theme configuration";
    };

    cursorTheme = mkOption {
      type = types.attrs;
      default = {
        name = "Bibata-Modern-Ice";
        package = pkgs.bibata-cursors;
        size = 24;
      };
      description = "Cursor theme configuration";
    };

    font = mkOption {
      type = types.attrs;
      default = font;
      description = "Font configuration";
    };
  };

  config = mkIf cfg.enable {
    hj = {
      packages = [
        cfg.theme.package
        cfg.iconTheme.package
        cfg.cursorTheme.package
        pkgs.adwaita-icon-theme
      ];

      xdg.config.files = {
        "gtk-3.0/settings.ini".text = ''
          [Settings]
          gtk-theme-name=${cfg.theme.name}
          gtk-icon-theme-name=${cfg.iconTheme.name}
          gtk-font-name=${cfg.font.name} ${toString cfg.font.size}
          gtk-cursor-theme-name=${cfg.cursorTheme.name}
          gtk-cursor-theme-size=${toString cfg.cursorTheme.size}
          gtk-application-prefer-dark-theme=1
          gtk-xft-antialias=1
          gtk-xft-hinting=1
          gtk-xft-hintstyle=hintslight
          gtk-xft-rgba=rgb
        '';

        "gtk-4.0/settings.ini".text = ''
          [Settings]
          gtk-theme-name=${cfg.theme.name}
          gtk-icon-theme-name=${cfg.iconTheme.name}
          gtk-font-name=${cfg.font.name} ${toString cfg.font.size}
          gtk-cursor-theme-name=${cfg.cursorTheme.name}
          gtk-cursor-theme-size=${toString cfg.cursorTheme.size}
          gtk-application-prefer-dark-theme=1
        '';
      };

      files.".gtkrc-2.0".text = ''
        gtk-theme-name="${cfg.theme.name}"
        gtk-icon-theme-name="${cfg.iconTheme.name}"
        gtk-font-name="${cfg.font.name} ${toString cfg.font.size}"
        gtk-cursor-theme-name="${cfg.cursorTheme.name}"
        gtk-cursor-theme-size=${toString cfg.cursorTheme.size}
        gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
        gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
        gtk-button-images=1
        gtk-menu-images=1
        gtk-enable-event-sounds=1
        gtk-enable-input-feedback-sounds=1
        gtk-xft-antialias=1
        gtk-xft-hinting=1
        gtk-xft-hintstyle=hintslight
        gtk-xft-rgba=rgb
      '';
    };
  };
}

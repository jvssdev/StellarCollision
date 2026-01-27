{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    mkIf
    ;
  cfg = config.cfg.fuzzel;
  c = config.cfg.theme.colors;
  inherit (config.cfg.fonts.monospace) name;

in
{
  options.cfg.fuzzel = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Fuzzel configuration.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.fuzzel;
      description = "The Fuzzel package to install.";
    };
  };

  config = mkIf cfg.enable {
    hj = {
      packages = [
        cfg.package
      ];
      xdg.config = {
        files = {
          "fuzzel/fuzzel.ini".text = ''
            [border]
            radius=10
            width=2

            [colors]
            background="${c.base00}f0"
            border="${c.base05}ff"
            selection="${c.base0D}ff"
            selection-text="${c.base00}ff"
            text="${c.base05}ff"

            [dmenu]
            lines=25
            width=70

            [main]
            dpi-aware=no
            font="${name}:size=13"
            icon-theme="${config.cfg.gtk.iconTheme.name}"
            lines=15
            prompt="󰍉  "
            monospace="${name}"
            width=40
          '';
        };
      };
    };
  };
}

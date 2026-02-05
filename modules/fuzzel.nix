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
    strip
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
            [main]
            dpi-aware=no
            font=${name}:size=13
            icons-enabled=yes
            icon-theme=${config.cfg.gtk.iconTheme.name}
            lines=15
            prompt=󰍉
            width=40
            terminal=${config.cfg.vars.terminal}

            [border]
            radius=10
            width=2

            [colors]
            background=${strip c.base00}f0
            border=${strip c.base0D}ff
            selection=${strip c.base0D}ff
            selection-text=${strip c.base00}ff
            text=${strip c.base05}ff
          '';
        };
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.cfg.fonts;
in
{
  options.cfg.fonts = {
    enable = mkEnableOption "Fonts configuration";

    sansSerif = {
      name = mkOption {
        type = types.str;
        default = "Roboto";
        description = "The name of the sans-serif font.";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.roboto;
        description = "The package providing the sans-serif font.";
      };
    };

    serif = {
      name = mkOption {
        type = types.str;
        default = "DejaVu Serif";
        description = "The name of the serif font.";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.dejavu_fonts;
        description = "The package providing the serif font.";
      };
    };

    cjk = {
      name = mkOption {
        type = types.str;
        default = "Noto Sans CJK JP";
        description = "The name of the CJK font.";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.noto-fonts-cjk-sans;
        description = "The package providing the CJK font.";
      };
    };

    emoji = {
      name = mkOption {
        type = types.str;
        default = "Noto Color Emoji";
        description = "The name of the emoji font.";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.noto-fonts-color-emoji;
        description = "The package providing the emoji font.";
      };
    };

    monospace = {
      name = mkOption {
        type = types.str;
        default = "JetBrainsMono Nerd Font";
        description = "The name of the monospace font.";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.nerd-fonts.jetbrains-mono;
        description = "The package providing the monospace font.";
      };
    };

    size = mkOption {
      type = types.int;
      default = 14;
      description = "Default font size (note: this is not automatically applied system-wide; use in applications as needed).";
    };
  };

  config = mkIf cfg.enable {
    environment.sessionVariables = {
      FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0 cff:hinting-engine=adobe";
    };

    fonts = {
      fontDir.enable = true;

      packages = [
        cfg.sansSerif.package
        cfg.serif.package
        cfg.cjk.package
        cfg.emoji.package
        cfg.monospace.package
        pkgs.symbola
      ];

      enableDefaultPackages = false;

      fontconfig = {
        enable = true;
        cache32Bit = true;

        defaultFonts = {
          serif = [
            cfg.serif.name
            cfg.cjk.name
            cfg.emoji.name
            "Symbola"
          ];
          sansSerif = [
            cfg.sansSerif.name
            cfg.cjk.name
            cfg.emoji.name
            "Symbola"
          ];
          monospace = [
            cfg.monospace.name
            cfg.cjk.name
            cfg.emoji.name
            "Symbola"
          ];
          emoji = [
            cfg.emoji.name
            "Symbola"
          ];
        };
      };
    };
  };
}

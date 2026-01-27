{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkIf
    types
    ;
  cfg = config.cfg.gammastep;
in
{
  options.cfg.gammastep = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable gammastep with tray and manual provider.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.gammastep;
    };

    temperature = {
      day = mkOption {
        type = types.int;
        default = 5500;
      };
      night = mkOption {
        type = types.int;
        default = 3500;
      };
    };

    dawnTime = mkOption {
      type = types.str;
      default = "6:00-7:45";
    };

    duskTime = mkOption {
      type = types.str;
      default = "18:35-20:45";
    };

    tray = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    hj = {
      packages = [
        cfg.package
        pkgs.brightnessctl
      ];

      xdg.config.files."gammastep/config.ini".text = ''
        [general]
        temp-day=${toString cfg.temperature.day}
        temp-night=${toString cfg.temperature.night}
        dawn-time=${cfg.dawnTime}
        dusk-time=${cfg.duskTime}
        fade=1
      '';
    };
  };
}

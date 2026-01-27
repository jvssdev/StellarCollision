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
      description = "Enable gammastep as a user service with tray.";
    };
    package = mkOption {
      type = types.package;
      default = pkgs.gammastep;
      description = "The gammastep package to use.";
    };
    temperatureDay = mkOption {
      type = types.int;
      default = 5500;
      description = "Daytime color temperature.";
    };
    temperatureNight = mkOption {
      type = types.int;
      default = 3500;
      description = "Nighttime color temperature.";
    };
    dawnTime = mkOption {
      type = types.str;
      default = "6:00-7:45";
      description = "Dawn transition time (manual mode).";
    };
    duskTime = mkOption {
      type = types.str;
      default = "18:35-20:45";
      description = "Dusk transition time (manual mode).";
    };
    tray = mkOption {
      type = types.bool;
      default = true;
      description = "Show tray icon (uses gammastep-indicator).";
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
        temp-day = ${toString cfg.temperatureDay}
        temp-night = ${toString cfg.temperatureNight}
        dawn-time = ${cfg.dawnTime}
        dusk-time = ${cfg.duskTime}
      '';
    };
  };
}

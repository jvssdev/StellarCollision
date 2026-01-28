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
    getExe
    ;
  cfg = config.cfg.gammastep;
in
{
  options.cfg.gammastep = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    package = mkOption {
      type = types.package;
      default = pkgs.gammastep;
    };
    temperature.day = mkOption {
      type = types.int;
      default = 5500;
    };
    temperature.night = mkOption {
      type = types.int;
      default = 3500;
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

      systemd.enable = true;

      systemd.services.gammastep = {
        description = "Gammastep color temperature adjuster";
        wantedBy = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];

        serviceConfig = {
          ExecStart = "${getExe cfg.package} ${if cfg.tray then "-indicator" else ""}";
          Restart = "always";
          RestartSec = 3;
        };

        restartTriggers = [ config.hj.xdg.config.files."gammastep/config.ini".source ];
        restartIfChanged = true;
      };
    };
  };
}

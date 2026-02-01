{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf strings;
  cfg = config.cfg.regreet;
  c = config.cfg.theme.colors;

  hexToInt =
    hex:
    {
      "0" = 0;
      "1" = 1;
      "2" = 2;
      "3" = 3;
      "4" = 4;
      "5" = 5;
      "6" = 6;
      "7" = 7;
      "8" = 8;
      "9" = 9;
      "a" = 10;
      "b" = 11;
      "c" = 12;
      "d" = 13;
      "e" = 14;
      "f" = 15;
      "A" = 10;
      "B" = 11;
      "C" = 12;
      "D" = 13;
      "E" = 14;
      "F" = 15;
    }
    .${hex};

  parseHex =
    hex:
    let
      s = strings.removePrefix "#" hex;
      d = n: hexToInt (builtins.substring n 1 s);
      p = n: d n * 16 + d (n + 1);
    in
    {
      r = p 0;
      g = p 2;
      b = p 4;
    };

  base00_rgb = parseHex c.base00;
in
{
  options.cfg.regreet.enable = mkEnableOption "ReGreet config";

  config = mkIf cfg.enable {
    programs.regreet = {
      enable = true;

      theme = {
        inherit (config.cfg.gtk.theme) name package;
      };

      iconTheme = {
        inherit (config.cfg.gtk.iconTheme) name package;
      };

      cursorTheme = {
        inherit (config.cfg.gtk.cursorTheme) name package;
      };

      font = {
        inherit (config.cfg.fonts.monospace) name package;
        inherit (config.cfg.fonts) size;
      };

      settings = {
        background = {
          path = ../assets/Wallpapers/a6116535-4a72-453e-83c9-ea97b8597d8c.png;
          sizing = "fill";
        };

        GTK = {
          application_prefer_dark = true;
          cursor_size = config.cfg.gtk.cursorTheme.size;
          cursor_theme_name = config.cfg.gtk.cursorTheme.name;
        };
        commands = {
          reboot = [
            "${pkgs.systemd}/bin/systemctl"
            "reboot"
          ];
          shutdown = [
            "${pkgs.systemd}/bin/systemctl"
            "poweroff"
          ];
        };
      };

      extraCss = ''
        window {
          background-color: rgba(${toString base00_rgb.r}, ${toString base00_rgb.g}, ${toString base00_rgb.b}, 0.85);
          border: 2px solid ${c.base0D};
          border-radius: 20px;
        }

        entry {
          background-color: ${c.base01};
          border: 2px solid ${c.base03};
          border-radius: 10px;
          padding: 12px;
          font-size: 18px;
        }

        entry:focus {
          border-color: ${c.base0D};
        }

        button {
          background-color: ${c.base0D};
          color: ${c.base00};
          border-radius: 10px;
          padding: 12px;
          font-size: 20px;
          font-weight: bold;
        }

        button:hover {
          background-color: ${c.base0B};
        }

        button:active {
          background-color: ${c.base0C};
        }

        label#clock {
          font-size: 80px;
          color: ${c.base06};
        }

        label#date {
          font-size: 28px;
          color: ${c.base05};
        }

        label#greeting {
          font-size: 36px;
          color: ${c.base06};
        }
      '';
    };

    services.greetd = {
      enable = true;
      settings = {
        # initial_session = {
        #   command = "${inputs.mango.packages.${pkgs.stdenv.hostPlatform.system}.mango}/bin/mango";
        #   user = "${config.cfg.vars.username}";
        # };
      };
    };
  };
}

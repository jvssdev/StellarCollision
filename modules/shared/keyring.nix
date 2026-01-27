{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.cfg.keyring;
in
{
  options.cfg.keyring = {
    enable = mkEnableOption "keyring";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = [ pkgs.libsecret ];
    };
    services = {
      gnome = {
        at-spi2-core.enable = true;
        gnome-keyring.enable = true;
      };
      dbus = {
        packages = [
          pkgs.gcr
          pkgs.seahorse
        ];
      };
    };

    security = {
      polkit.enable = true;
      pam = {
        services = {
          login = {
            enableGnomeKeyring = true;
          };
          greetd = {
            enableGnomeKeyring = true;
          };
        };
      };
    };

    systemd = {
      user.services.polkit-gnome-authentication-agent-1 = {
        description = "polkit-gnome-authentication-agent-1";
        wantedBy = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
    };
  };
}

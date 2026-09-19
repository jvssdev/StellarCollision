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
          pkgs.gcr_4
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
  };
}

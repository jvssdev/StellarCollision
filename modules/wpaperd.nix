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
  cfg = config.cfg.wpaperd;
in
{
  options.cfg.wpaperd = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable wpaperd as a user service.";
    };
    package = mkOption {
      type = types.package;
      default = pkgs.wpaperd;
      description = "The wpaperd package to use.";
    };
  };

  config = mkIf cfg.enable {
    hj = {
      packages = [ cfg.package ];

      xdg.config.files."wpaperd/config.toml".text = ''
        [any]
        path = "${../assets/Wallpapers}"
        sorting = "random"
        duration = "10m"
      '';

      systemd.enable = true;

      systemd.services.wpaperd = {
        description = "wpaperd wallpaper daemon";
        wantedBy = [ "default.target" ];
        after = [ "graphical-session.target" ];

        serviceConfig = {
          ExecStart = "${getExe cfg.package}";
          Restart = "always";
          RestartSec = 3;
        };
      };
    };
  };
}

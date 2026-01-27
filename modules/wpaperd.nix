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
    enable = lib.mkEnableOption "wpaperd";
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

        path = [ cfg.package ];

        serviceConfig = {
          ExecStart = "${getExe cfg.package}";
          Type = "simple";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };
  };
}

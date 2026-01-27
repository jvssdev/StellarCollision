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
  wallpapers = builtins.path {
    path = ../assets/Wallpapers;
    name = "wallpapers";
    filter = _: _: true;
  };
in
{
  options.cfg.wpaperd = {
    enable = lib.mkEnableOption "wpaperd";
    package = mkOption {
      type = types.package;
      default = pkgs.wpaperd;
    };
  };

  config = mkIf cfg.enable {
    hj = {
      packages = [ cfg.package ];

      xdg.config.files."wpaperd/config.toml".text = ''
        [any]
        path = "${wallpapers}"
        duration = "10m"
      '';

      systemd.enable = true;

      systemd.services.wpaperd = {
        description = "wpaperd wallpaper daemon";

        wantedBy = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];

        path = [ cfg.package ];

        serviceConfig = {
          ExecStart = "${getExe cfg.package}";
          Restart = "on-failure";
          RestartSec = 5;
          PassEnvironment = [
            "WAYLAND_DISPLAY"
            "XDG_RUNTIME_DIR"
            "DISPLAY"
          ];
        };
      };
    };
  };
}

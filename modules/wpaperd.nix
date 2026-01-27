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
        path = "${../assests/Wallpapers}"
        sorting = "random"
        duration = "10m"
      '';

      xdg.config.files."systemd/user/wpaperd.service".text = ''
        [Unit]
        Description=wpaperd wallpaper daemon
        PartOf=graphical-session.target

        [Service]
        ExecStart=${getExe cfg.package}
        Restart=always
        RestartSec=3

        [Install]
        WantedBy=graphical-session.target
      '';
    };
  };
}

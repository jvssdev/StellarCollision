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
        namespace = "wallpaper"
      '';
    };
  };
}

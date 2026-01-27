{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.cfg.drivers.intel;
in
{
  options.cfg.drivers.intel = {
    enable = mkEnableOption "Enable Intel Graphics Drivers";
  };

  config = mkIf cfg.enable {
    nixpkgs.config.packageOverrides = pkgs: {
      vaapiIntel = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
    };

    hardware.graphics = {
      extraPackages = [
        pkgs.intel-media-driver
        pkgs.intel-vaapi-driver
        pkgs.libva-vdpau-driver
        pkgs.libvdpau-va-gl
      ];
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.cfg.lutris;
in
{
  options.cfg.lutris = {
    enable = mkEnableOption "Lutris configuration";

    package = mkOption {
      type = types.package;
      default = pkgs.lutris.override {
        extraLibraries = _: [ pkgs.wineWow64Packages.staging ];
      };
      description = "The Lutris package to use.";
    };
  };

  config = mkIf cfg.enable {
    hj = {
      packages = [
        cfg.package
        pkgs.winetricks
      ];

      xdg.config.files = {
        "lutris/system.yml".text = ''
          system:
            env:
              DOTNET_ROOT: /dev/null
              DOTNET_BUNDLE_EXTRACT_BASE_DIR: /dev/null
        '';

        "lutris/runners/wine.yml".text = ''
          wine:
            system_winetricks: true
        '';
      };
    };
  };
}

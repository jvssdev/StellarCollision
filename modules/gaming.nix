{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    mkIf
    ;
  cfg = config.cfg.gaming;

  edenFixed = pkgs.symlinkJoin {
    name = "eden-fixed";
    paths = [ pkgs.eden ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/eden \
        --set GSETTINGS_SCHEMA_DIR "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas" \
        --set QT_QPA_PLATFORM xcb \
        --add-flags "-platform xcb"
    '';
  };

  lutrisPackage = pkgs.lutris.override {
    extraLibraries = _: [ pkgs.wineWow64Packages.staging ];
  };
in
{
  options.cfg.gaming = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable gaming configuration.";
    };
  };

  config = mkIf cfg.enable {
    hj = {
      packages = [
        edenFixed
        pkgs.azahar
        pkgs.melonds
        lutrisPackage
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

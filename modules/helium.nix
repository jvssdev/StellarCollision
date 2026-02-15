{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.cfg.helium;

  pname = "helium-browser";
  version = "0.9.1.1";

  src = pkgs.fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
    hash = "sha256-0Kw8Ko41Gdz4xLn62riYAny99Hd0s7/75h8bz4LUuCE=";
  };

  appimageContents = pkgs.appimageTools.extractType2 {
    inherit pname version src;
  };

  helium-browser = pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/helium.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/helium.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=${pname}'
      install -Dm444 ${appimageContents}/helium.png $out/share/pixmaps/helium.png
    '';

    passthru.updateScript = pkgs.nix-update-script {
      attrPath = "packages.${pkgs.system}.helium-browser";
    };

    meta = {
      description = "Helium web browser";
      homepage = "https://github.com/imputnet/helium-linux";
      platforms = [ "x86_64-linux" ];
      mainProgram = pname;
    };
  };
in
{
  options.cfg.helium = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Helium browser configuration.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = helium-browser;
      description = "The Helium browser package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    hj.packages = [ cfg.package ];
  };
}

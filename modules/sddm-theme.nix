{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    mkIf
    mkEnableOption
    ;
  cfg = config.cfg.sddm;
  c = config.cfg.theme.colors;

  inherit (inputs) silentSDDM;

  wallpaper = ../assests/Wallpapers/nord_valley.png;

  background-derivation = pkgs.runCommand "bg.jpg" { } ''
    cp ${wallpaper} $out
  '';

  silentTheme = silentSDDM.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
    extraBackgrounds = [ background-derivation ];
    theme-overrides = {
      "General" = {
        enable-animations = true;
      };
      "LoginScreen" = {
        background = "${background-derivation.name}";
        blur = 0;
      };
      "LoginScreen.LoginArea" = {
        position = "center";
        margin = -1;
      };
      "LoginScreen.LoginArea.Avatar" = {
        shape = "circle";
        active-size = 140;
        border-radius = 1;
        active-border-size = 2;
        active-border-color = "${c.base0D}";
      };
      "LoginScreen.LoginArea.LoginButton" = {
        font-size = 22;
        icon-size = 30;
        content-color = "${c.base05}";
        active-content-color = "${c.base06}";
        background-color = "${c.base01}";
      };
    };
  };
in
{
  options.cfg.sddm = {
    enable = mkEnableOption "Enable SDDM configuration.";
    wayland.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Wayland for SDDM.";
    };
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        silentTheme
        silentTheme.test
        bibata-cursors
        kdePackages.qt6ct
        libsForQt5.qtstyleplugin-kvantum
        kdePackages.qtstyleplugin-kvantum
        kdePackages.qtwayland
        qt6.qtwayland
      ];

      etc."sddm.conf.d/cursor.conf".text = ''
        [Theme]
        CursorTheme=Bibata-Modern-Ice
        CursorSize=24
      '';

      sessionVariables = {
        XCURSOR_THEME = "Bibata-Modern-Ice";
        XCURSOR_SIZE = "24";
        QT_QPA_PLATFORMTHEME = "qt5ct";
      };
    };

    qt.enable = true;

    systemd.tmpfiles.rules = [
      "L+ /var/lib/sddm/.icons/default - - - - ${pkgs.bibata-cursors}/share/icons/Bibata-Modern-Ice"
      "d /var/lib/sddm/.icons 0755 sddm sddm"
    ];

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = cfg.wayland.enable;
      package = pkgs.kdePackages.sddm;

      theme = silentTheme.pname;

      extraPackages = silentTheme.propagatedBuildInputs;

      settings = {
        General = {
          GreeterEnvironment = "QML2_IMPORT_PATH=${silentTheme}/share/sddm/themes/${silentTheme.pname}/components/,QT_QUICK_CONTROLS_STYLE=org.kde.desktop";
        };
      };
    };
  };
}

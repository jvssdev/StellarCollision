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
      General = {
        enable-animations = true;
      };
      LoginScreen = {
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
        active-border-color = c.base0D;
      };
      "LoginScreen.LoginArea.LoginButton" = {
        font-size = 22;
        icon-size = 30;
        content-color = c.base05;
        active-content-color = c.base06;
        background-color = c.base00;
        background-opacity = 0.7;
        active-background-color = c.base0D;
        active-background-opacity = 0.7;
        border-size = 2;
        border-color = c.base0D;
      };
      "LoginScreen.LoginArea.PasswordInput" = {
        width = 460;
        height = 60;
        font-size = 22;
        display-icon = true;
        icon-size = 30;
        content-color = c.base05;
        background-color = c.base00;
        background-opacity = 0.7;
        border-size = 2;
        border-color = c.base0D;
        margin-top = 20;
      };
      "LoginScreen.LoginArea.Spinner" = {
        text = "Logging in";
        font-size = 36;
        icon-size = 72;
        color = c.base06;
        spacing = 1;
      };
      "LoginScreen.LoginArea.Username" = {
        font-size = 40;
        color = c.base00;
        margin = 5;
      };
      "LoginScreen.LoginArea.WarningMessage" = {
        font-size = 22;
        normal-color = c.base06;
        warning-color = c.base0A;
        error-color = c.base08;
      };
      "LoginScreen.MenuArea.Buttons" = {
        size = 60;
      };
      "LoginScreen.MenuArea.Keyboard" = {
        display = true;
      };
      "LoginScreen.MenuArea.Layout" = {
        index = 2;
        position = "bottom-center";
        font-size = 20;
        icon-size = 32;
        content-color = c.base05;
        active-content-color = c.base06;
        background-color = c.base00;
        background-opacity = 0.7;
        border-size = 2;
        border-color = c.base0D;
      };
      "LoginScreen.MenuArea.Popups" = {
        max-height = 600;
        item-height = 60;
        item-spacing = 1;
        padding = 2;
        font-size = 22;
        icon-size = 24;
        content-color = c.base05;
        active-content-color = c.base06;
        background-color = c.base00;
        background-opacity = 0.7;
        active-option-background-color = c.base02;
        active-option-background-opacity = 0.7;
        border-size = 2;
        border-color = c.base0D;
        display-scrollbar = true;
      };
      "LoginScreen.MenuArea.Power" = {
        index = 0;
        popup-width = 200;
        position = "bottom-center";
        icon-size = 32;
        content-color = c.base05;
        active-content-color = c.base06;
        background-color = c.base00;
        background-opacity = 0.7;
        border-size = 2;
        border-color = c.base0D;
      };
      "LoginScreen.MenuArea.Session" = {
        index = 1;
        position = "bottom-center";
        button-width = 300;
        popup-width = 300;
        font-size = 25;
        icon-size = 32;
        content-color = c.base05;
        active-content-color = c.base06;
        background-color = c.base00;
        background-opacity = 0.7;
        active-background-opacity = 0.7;
        border-size = 2;
        border-color = c.base0D;
      };
      LockScreen = {
        background = "${background-derivation.name}";
        blur = 50;
      };
      "LockScreen.Clock" = {
        position = "center";
        align = "center";
        format = "hh:mm:ss";
        color = c.base01;
        font-size = 92;
      };
      "LockScreen.Date" = {
        margin-top = 1;
        format = "dd/MM/yyyy";
        locale = "pt_BR";
        color = c.base0D;
        font-size = 32;
      };
      "LockScreen.Message" = {
        text = "Press any key";
        font-size = 32;
        color = c.base0D;
        icon-size = 44;
        paint-icon = true;
      };
      Tooltips = {
        enable = false;
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
          GreeterEnvironment = "QML2_IMPORT_PATH=${silentTheme}/share/sddm/themes/${silentTheme.pname}/components/,QT_IM_MODULE=qtvirtualkeyboard,XCURSOR_THEME=Bibata-Modern-Ice,XCURSOR_SIZE=24,XCURSOR_PATH=/usr/share/icons:${pkgs.bibata-cursors}/share/icons";
          InputMethod = "qtvirtualkeyboard";
        };
        Theme = {
          CursorTheme = "Bibata-Modern-Ice";
          CursorSize = 24;
        };
      };
    };
  };
}

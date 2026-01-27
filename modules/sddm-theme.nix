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
in
{
  imports = [
    inputs.silentSDDM.nixosModules.default
  ];

  options.cfg.sddm = {
    enable = mkEnableOption "Enable SDDM configuration.";

    wayland.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Wayland for SDDM.";
    };
  };

  config = mkIf cfg.enable {
    programs.silentSDDM = {
      enable = true;

      settings = {
        General = {
          enable-animations = true;
          animation-speed = 1.0;
        };

        LoginScreen = {
          background = "${../assests/Wallpapers/nord_valley.png}";
          blur = 0;
          background-mode = "fill";
          background-color = c.base00;
        };

        "LoginScreen.LoginArea" = {
          position = "center";
          margin = -1;
          spacing = 20;
          background-color = "transparent";
        };

        "LoginScreen.LoginArea.Avatar" = {
          shape = "circle";
          active-size = 140;
          inactive-size = 120;
          border-radius = 1;
          active-border-size = 2;
          inactive-border-size = 0;
          active-border-color = c.base0D;
          inactive-border-color = c.base03;
        };

        "LoginScreen.LoginArea.UserName" = {
          font-size = 24;
          font-family = "Inter";
          color = c.base05;
          bold = false;
        };

        "LoginScreen.LoginArea.PasswordField" = {
          font-size = 18;
          placeholder = "Password";
          background-color = c.base01;
          text-color = c.base05;
          placeholder-color = c.base04;
          border-radius = 8;
          border-size = 2;
          border-color = c.base03;
          active-border-color = c.base0D;
        };

        "LoginScreen.LoginArea.LoginButton" = {
          font-size = 22;
          icon-size = 30;
          text = "Login";
          content-color = c.base05;
          active-content-color = c.base06;
          hover-content-color = c.base0D;
          background-color = c.base01;
          active-background-color = c.base02;
          hover-background-color = c.base02;
          border-radius = 8;
          border-size = 2;
          border-color = c.base03;
          active-border-color = c.base0D;
        };

        "LoginScreen.MenuArea" = {
          position = "bottom-right";
          margin = 20;
          spacing = 15;
        };

        "LoginScreen.MenuArea.PowerButton" = {
          display = true;
          icon-size = 32;
          icon-color = c.base08;
          hover-icon-color = c.base0F;
          background-color = "transparent";
          hover-background-color = c.base01;
          border-radius = 8;
        };

        "LoginScreen.MenuArea.SessionButton" = {
          display = true;
          icon-size = 32;
          icon-color = c.base0D;
          hover-icon-color = c.base0C;
          background-color = "transparent";
          hover-background-color = c.base01;
          border-radius = 8;
        };

        "LoginScreen.MenuArea.Keyboard" = {
          display = true;
          icon-size = 32;
          icon-color = c.base0A;
          hover-icon-color = c.base0C;
          background-color = "transparent";
          hover-background-color = c.base01;
          border-radius = 8;
        };

        Clock = {
          display = true;
          position = "top-center";
          margin = 40;
          time-format = "HH:mm";
          date-format = "dddd, MMMM d";
          time-font-size = 72;
          date-font-size = 24;
          time-color = c.base05;
          date-color = c.base04;
          time-font-family = "Inter";
          date-font-family = "Inter";
        };

        VirtualKeyboard = {
          display-on-focus = true;
          background-color = c.base01;
          key-background-color = c.base02;
          key-hover-background-color = c.base03;
          key-active-background-color = c.base0D;
          key-text-color = c.base05;
          key-hover-text-color = c.base06;
          key-active-text-color = c.base00;
          border-radius = 8;
        };
      };
    };

    services.displayManager.sddm = {
      wayland.enable = cfg.wayland.enable;
    };

    environment = {
      systemPackages = with pkgs; [
        bibata-cursors
        kdePackages.qt6ct
        libsForQt5.qtstyleplugin-kvantum
        kdePackages.qtstyleplugin-kvantum
        kdePackages.qtwayland
        qt6.qtwayland
        inter
      ];

      etc = {
        "sddm.conf.d/cursor.conf".text = ''
          [Theme]
          CursorTheme=Bibata-Modern-Ice
          CursorSize=24
        '';
      };

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
  };
}

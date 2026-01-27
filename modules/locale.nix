{
  lib,
  config,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.cfg.locale;

  fontName = config.cfg.fonts.monospace.name;
  fontSize = toString config.cfg.fonts.size;

  c = config.cfg.theme.colors;
in
{
  options.cfg.locale = {
    enable = mkEnableOption "Locale configuration";
  };

  config = mkIf cfg.enable {
    i18n = {
      supportedLocales = [
        "en_US.UTF-8/UTF-8"
        "pt_BR.UTF-8/UTF-8"
      ];
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "pt_BR.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "pt_BR.UTF-8";
        LC_MONETARY = "pt_BR.UTF-8";
        LC_NAME = "pt_BR.UTF-8";
        LC_NUMERIC = "pt_BR.UTF-8";
        LC_PAPER = "pt_BR.UTF-8";
        LC_TELEPHONE = "pt_BR.UTF-8";
        LC_TIME = "pt_BR.UTF-8";
      };
      inputMethod = {
        enable = true;
        type = "fcitx5";

        fcitx5 = {
          waylandFrontend = true;
          addons = [
            pkgs.fcitx5-gtk
            pkgs.libsForQt5.fcitx5-qt
          ];
        };
      };
    };

    environment.sessionVariables = {
      XMODIFIERS = "@im=fcitx";
      QT_IM_MODULE = "fcitx";
      SDL_IM_MODULE = "fcitx";
    };

    hj.xdg.config.files = {
      "fcitx5/conf/classicui.conf".text = ''
        Vertical Candidate List=False
        PerScreenDPI=True
        WheelForPaging=True
        Font="${fontName} ${fontSize}"
        MenuFont="${fontName} ${fontSize}"
        TrayFont="${fontName} ${fontSize}"
        TrayOutlineColor=#000000
        TrayTextColor=#ffffff
        PreferTextIcon=True
        ShowLayoutNameInIcon=True
        UseInputMethodLangaugeToDisplayText=True
        Theme=tsuki
      '';

      "fcitx5/config".text = ''
        [Hotkey]
        EnumerateWithTriggerKeys=True
        EnumerateSkipFirst=False

        [Hotkey/TriggerKeys]
        0=Control+Shift+space

        [Hotkey/EnumerateForwardKeys]
        0=Control+Shift_L

        [Hotkey/EnumerateBackwardKeys]
        0=Control+Shift_R

        [Behavior]
        ActiveByDefault=False
        ShareInputState=No
        PreeditEnabledByDefault=True
        ShowInputMethodInformation=True
        CompactInputMethodInformation=True
        ShowFirstInputMethodInformation=True
        DefaultPageSize=5
      '';

      "fcitx5/profile".text = ''
        [Groups/0]
        Name=Default
        Default Layout=br
        DefaultIM=keyboard-br

        [Groups/0/Items/0]
        Name=keyboard-br
        Layout=

        [GroupOrder]
        0=Default
      '';
    };

    hj.xdg.data.files = {
      "fcitx5/themes/tsuki/theme.conf".text = ''
        Name=tsuki
        Description=Tsuki theme
        InputPanel=panel.svg
        Highlight=highlight.svg
      '';

      "fcitx5/themes/tsuki/panel.svg".text = ''
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" preserveAspectRatio="none">
          <defs>
            <filter id="dropShadow" x="-50%" y="-50%" width="200%" height="200%">
              <feGaussianBlur stdDeviation="3" result="blur"/>
              <feOffset dx="0" dy="4" result="offsetBlur"/>
              <feFlood flood-color="#000000" flood-opacity="0.4"/>
              <feComposite in="offsetBlur" in2="SourceAlpha" operator="in"/>
              <feMerge>
                <feMergeNode/>
                <feMergeNode in="SourceGraphic"/>
              </feMerge>
            </filter>
          </defs>
          <rect width="100" height="100" rx="10" ry="10" fill="${c.base01}" filter="url(#dropShadow)"/>
          <rect width="100" height="100" rx="10" ry="10" fill="none" stroke="${c.base03}" stroke-width="1.5"/>
        </svg>
      '';

      "fcitx5/themes/tsuki/highlight.svg".text = ''
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" preserveAspectRatio="none">
          <rect width="100" height="100" fill="${c.base0D}" opacity="0.3"/>
        </svg>
      '';
    };
  };
}

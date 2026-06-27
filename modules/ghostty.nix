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
  cfg = config.cfg.ghostty;
  c = config.cfg.theme.colors;

  strip = color: lib.substring 1 6 color;
in
{
  options.cfg.ghostty = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Ghostty configuration.";
    };
    package = mkOption {
      type = types.package;
      default = pkgs.ghostty;
      description = "The Ghostty package to install.";
    };
  };

  config = mkIf cfg.enable {
    hj.packages = [ cfg.package ];
    systemd.user.services."app-com.mitchellh.ghostty" = {
      enable = true;
      enableDefaultPath = false;
      wantedBy = [ "graphical-session.target" ];
    };
    hj.xdg.config.files."ghostty/config".text = ''
      background = "${c.base00}"
      confirm-close-surface = false
      copy-on-select = false
      cursor-color = "${c.base05}"
      cursor-style = bar
      cursor-style-blink = false
      quit-after-last-window-closed = false
      gtk-single-instance = true
      quick-terminal-animation-duration = 0
      font-family = "${config.cfg.fonts.monospace.name}"
      font-size = 15
      foreground = "${c.base05}"
      keybind = ctrl+plus=increase_font_size:1
      keybind = ctrl+minus=decrease_font_size:1
      keybind = ctrl+zero=reset_font_size
      keybind = ctrl+w=close_tab
      keybind = alt+left=unbind
      keybind = alt+right=unbind
      keybind = alt+h=previous_tab
      keybind = alt+l=next_tab
      keybind = ctrl+t=new_tab
      keybind = shift+enter=text:
      mouse-hide-while-typing = true
      palette = 0=${strip c.base00}
      palette = 1=${strip c.base08}
      palette = 2=${strip c.base0B}
      palette = 3=${strip c.base0A}
      palette = 4=${strip c.base0D}
      palette = 5=${strip c.base0E}
      palette = 6=${strip c.base0C}
      palette = 7=${strip c.base05}
      palette = 8=${strip c.base04}
      palette = 9=${strip c.base08}
      palette = 10=${strip c.base0B}
      palette = 11=${strip c.base0A}
      palette = 12=${strip c.base0D}
      palette = 13=${strip c.base0E}
      palette = 14=${strip c.base0C}
      palette = 15=${strip c.base06}
      shell-integration = zsh
      shell-integration-features = sudo,title,no-cursor
      window-decoration = false
    '';
  };
}

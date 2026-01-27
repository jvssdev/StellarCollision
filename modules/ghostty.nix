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

    hj.xdg.config.files."ghostty/config".text = ''
      background = "${c.base00}"
      confirm-close-surface = false
      copy-on-select = false
      cursor-color = "${c.base05}"
      cursor-style = bar
      cursor-style-blink = false
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
      palette = 0="${c.base00}"
      palette = 1="${c.base08}"
      palette = 2="${c.base0B}"
      palette = 3="${c.base0A}"
      palette = 4="${c.base0D}"
      palette = 5="${c.base0E}"
      palette = 6="${c.base0C}"
      palette = 7="${c.base05}"
      palette = 8="${c.base04}"
      palette = 9="${c.base08}"
      palette = 10="${c.base0B}"
      palette = 11="${c.base0A}"
      palette = 12="${c.base0D}"
      palette = 13="${c.base0E}"
      palette = 14="${c.base0C}"
      palette = 15="${c.base06}"
      shell-integration = zsh
      shell-integration-features = sudo,title,no-cursor
      window-decoration = false
    '';
  };
}

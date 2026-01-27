{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    types
    mkOption
    mkIf
    ;
  inherit (config.cfg.fonts.monospace) name;
  cfg = config.cfg.dunst;
  c = config.cfg.theme.colors;
in
{
  options.cfg.dunst = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Dunst configuration.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.dunst;
      description = "The Dunst package to install.";
    };
  };

  config = mkIf cfg.enable {
    hj = {
      packages = [ cfg.package ];

      xdg.config.files."dunst/dunstrc" = {
        generator = lib.generators.toINI { };
        value = {
          global = {
            monitor = 0;
            follow = "mouse";
            width = 400;
            height = 300;
            origin = "top-right";
            offset = "8x8";
            notification_limit = 0;
            progress_bar = true;
            progress_bar_height = 10;
            progress_bar_frame_width = 1;
            progress_bar_min_width = 150;
            progress_bar_max_width = 400;
            indicate_hidden = true;
            separator_height = 2;
            padding = 10;
            horizontal_padding = 10;
            text_icon_padding = 0;
            frame_width = 2;
            frame_color = "${c.base01}";
            separator_color = "frame";
            sort = true;

            font = "${name} 12";

            line_height = 0;
            markup = "full";
            format = "<b>%s</b>\\n%b";
            alignment = "left";
            vertical_alignment = "center";
            show_age_threshold = 60;
            ellipsize = "middle";
            ignore_newline = false;
            stack_duplicates = true;
            hide_duplicate_count = false;
            show_indicators = true;
            icon_position = "left";
            min_icon_size = 0;
            max_icon_size = 64;
            sticky_history = true;
            history_length = 100;
            browser = "brave";
            always_run_script = true;
            title = "Dunst";
            class = "Dunst";
            corner_radius = 0;
            ignore_dbusclose = false;
            force_xwayland = false;
            mouse_left_click = "close_current";
            mouse_middle_click = "do_action, close_current";
            mouse_right_click = "close_all";
          };
          urgency_low = {
            background = "${c.base00}";
            foreground = "${c.base04}";
            frame_color = "${c.base01}";
            timeout = 5;
          };
          urgency_normal = {
            background = "${c.base00}";
            foreground = "${c.base04}";
            frame_color = "${c.base01}";
            timeout = 5;
          };
          urgency_critical = {
            background = "${c.base0F}";
            foreground = "${c.base05}";
            frame_color = "${c.base08}";
            timeout = 0;
          };
          screenshot = {
            appname = "screenshot";
            max_icon_size = 192;
            timeout = 3;
          };
          audio = {
            appname = "audio";
            timeout = 2;
          };
          brightness = {
            appname = "brightness";
            timeout = 2;
          };
          mpd = {
            appname = "mpd";
            max_icon_size = 96;
            word_wrap = false;
            timeout = 3;
          };
        };
      };
    };
  };
}

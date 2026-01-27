{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption mkIf types;
  cfg = config.cfg.zed;
  c = config.cfg.theme.colors;
  inherit (config.cfg) vars;
  font = config.cfg.fonts.monospace.name;
in
{
  options.cfg.zed = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Zed editor configuration.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.zed-editor;
      description = "The Zed package to install.";
    };
  };

  config = mkIf cfg.enable {
    hj.packages = [ cfg.package ];

    hj.xdg.config.files = {
      "zed/settings.json".text = builtins.toJSON {
        vim_mode = true;
        theme = "Base16";
        icon_theme = "Symbols Icon Theme";
        diagnostics = {
          inline = {
            enabled = true;
          };
        };
        vim = {
          toggle_relative_line_numbers = true;
          use_system_clipboard = "always";
        };
        cursor_blink = false;
        autosave = "on_focus_change";
        use_autoclose = true;
        use_auto_surround = true;
        formatter = {
          language_server = {
            name = "biome";
          };
        };
        features = {
          edit_prediction_provider = "none";
        };
        terminal = {
          alternate_scroll = "off";
          blinking = "terminal_controlled";
          copy_on_select = false;
          dock = "bottom";
          default_width = 640;
          default_height = 320;
          detect_venv = {
            on = {
              directories = [
                ".env"
                "env"
                ".venv"
                "venv"
              ];
              activate_script = "default";
            };
          };
          env = {
            TERM = vars.terminal;
          };
          line_height = "comfortable";
          button = true;
          shell = {
            program = "zsh";
          };
          toolbar = {
            breadcrumbs = false;
            title = true;
          };
          working_directory = "current_project_directory";
          scrollbar = {
            show = null;
          };
        };
        hide_mouse = "on_typing_and_movement";
        code_actions_on_format = {
          "source.fixAll.biome" = true;
          "source.organizeImports.biome" = true;
        };
        inlay_hints = {
          enabled = true;
        };
        indent_guides = {
          coloring = "fixed";
        };
        buffer_font_weight = 300;
        buffer_line_height = "comfortable";
        current_line_highlight = "all";
        selection_highlight = true;
        buffer_font_family = font;
        ui_font_family = font;
        ui_font_size = 15;
        ui_font_weight = 400;
        telemetry = {
          diagnostics = false;
          metrics = false;
        };
      };

      "zed/keymap.json".text = builtins.toJSON [
        {
          context = "Workspace";
          bindings = {
            "space e" = "workspace::ToggleLeftDock";
            "alt-h" = "workspace::ToggleBottomDock";
            "space b d" = [
              "pane::CloseActiveItem"
              { close_pinned = false; }
            ];
            "space s f" = "file_finder::Toggle";
            "space s g" = "pane::DeploySearch";
          };
        }
        {
          context = "ProjectSearchBar";
          bindings = {
            "space s g" = "search::FocusSearch";
          };
        }
        {
          context = "Pane";
          bindings = {
            "space s g" = "project_search::ToggleFocus";
          };
        }
        {
          context = "Editor";
          bindings = {
            "gc" = [
              "editor::ToggleComments"
              { advance_downwards = false; }
            ];
          };
        }
      ];

      "zed/themes/base16.json".text = builtins.toJSON {
        name = "Base16";
        author = "João";
        themes = [
          {
            name = "Base16";
            appearance = "dark";
            style = {
              border = "${c.base03}ff";
              "border.variant" = "${c.base01}ff";
              "border.focused" = null;
              "border.selected" = null;
              "border.transparent" = null;
              "border.disabled" = null;
              "elevated_surface.background" = "${c.base01}";
              "surface.background" = "${c.base00}";
              background = "${c.base00}";
              "element.background" = "${c.base00}";
              "element.hover" = "${c.base01}ff";
              "element.active" = "${c.base02}ff";
              "element.selected" = "${c.base02}ff";
              "element.disabled" = "${c.base03}d3";
              "ghost_element.background" = "${c.base00}";
              "ghost_element.hover" = "${c.base01}ff";
              "ghost_element.active" = "${c.base02}ff";
              "ghost_element.selected" = "${c.base02}ff";
              "ghost_element.disabled" = "${c.base03}d3";
              "drop_target.background" = "${c.base03}d3";
              text = "${c.base05}";
              "text.muted" = "${c.base04}";
              "text.placeholder" = "${c.base03}";
              "text.disabled" = "${c.base03}";
              "text.accent" = "${c.base0D}";
              icon = "${c.base05}";
              "icon.muted" = "${c.base03}";
              "icon.disabled" = "${c.base03}";
              "icon.placeholder" = "${c.base03}";
              "icon.accent" = "${c.base0D}";
              "status_bar.background" = "${c.base00}";
              "title_bar.background" = "${c.base00}";
              "title_bar.inactive_background" = "${c.base00}";
              "toolbar.background" = "${c.base00}";
              "tab_bar.background" = "${c.base00}";
              "tab.inactive_background" = "${c.base00}";
              "tab.active_background" = "${c.base01}";
              "search.match_background" = "${c.base02}";
              "panel.background" = "${c.base00}";
              "panel.focused_border" = null;
              "pane.focused_border" = "${c.base00}";
              "scrollbar.thumb.background" = "${c.base01}d3";
              "scrollbar.thumb.hover_background" = "${c.base02}";
              "scrollbar.thumb.border" = "00000000";
              "scrollbar.track.background" = "00000000";
              "scrollbar.track.border" = "00000000";
              "editor.foreground" = "${c.base05}";
              "editor.background" = "${c.base00}";
              "editor.gutter.background" = "${c.base00}";
              "editor.subheader.background" = "${c.base00}";
              "editor.active_line.background" = "${c.base01}";
              "editor.highlighted_line.background" = "${c.base02}";
              "editor.line_number" = "${c.base03}";
              "editor.active_line_number" = "${c.base05}";
              "editor.invisible" = "${c.base03}";
              "editor.wrap_guide" = "${c.base03}";
              "editor.active_wrap_guide" = "${c.base03}d3";
              "editor.document_highlight.read_background" = "${c.base02}d3";
              "editor.document_highlight.write_background" = "${c.base03}d3";
              "link_text.hover" = "${c.base0D}";

              conflict = "${c.base0B}";
              "conflict.background" = "${c.base0B}d3";
              "conflict.border" = "${c.base03}";

              created = "${c.base0B}";
              "created.background" = "${c.base0B}d3";
              "created.border" = "${c.base03}";

              deleted = "${c.base08}";
              "deleted.background" = "${c.base08}d3";
              "deleted.border" = "${c.base03}";

              error = "${c.base08}";
              "error.background" = "${c.base08}d3";
              "error.border" = "${c.base03}";

              hidden = "${c.base03}";
              "hidden.background" = "${c.base00}";
              "hidden.border" = "${c.base03}";

              hint = "${c.base0D}";
              "hint.background" = "${c.base0D}d3";
              "hint.border" = "${c.base03}";

              ignored = "${c.base03}";
              "ignored.background" = "${c.base00}";
              "ignored.border" = "${c.base03}";

              info = "${c.base0D}";
              "info.background" = "${c.base0D}d3";
              "info.border" = "${c.base03}";

              modified = "${c.base0A}";
              "modified.background" = "${c.base0A}d3";
              "modified.border" = "${c.base03}";

              predictive = "${c.base0E}";
              "predictive.background" = "${c.base0E}d3";
              "predictive.border" = "${c.base03}";

              renamed = "${c.base0D}";
              "renamed.background" = "${c.base0D}d3";
              "renamed.border" = "${c.base03}";

              success = "${c.base0B}";
              "success.background" = "${c.base0B}d3";
              "success.border" = "${c.base03}";

              unreachable = "${c.base03}";
              "unreachable.background" = "${c.base00}";
              "unreachable.border" = "${c.base03}";

              warning = "${c.base0A}";
              "warning.background" = "${c.base0A}d3";
              "warning.border" = "${c.base03}";

              players = [
                {
                  cursor = "${c.base0D}";
                  background = "${c.base0D}20";
                  selection = "${c.base0D}30";
                }
                {
                  cursor = "${c.base0E}";
                  background = "${c.base0E}20";
                  selection = "${c.base0E}30";
                }
                {
                  cursor = "${c.base0E}";
                  background = "${c.base0E}20";
                  selection = "${c.base0E}30";
                }
                {
                  cursor = "${c.base09}";
                  background = "${c.base09}20";
                  selection = "${c.base09}30";
                }
                {
                  cursor = "${c.base0B}";
                  background = "${c.base0B}20";
                  selection = "${c.base0B}30";
                }
                {
                  cursor = "${c.base08}";
                  background = "${c.base08}20";
                  selection = "${c.base08}30";
                }
                {
                  cursor = "${c.base0A}";
                  background = "${c.base0A}20";
                  selection = "${c.base0A}30";
                }
                {
                  cursor = "${c.base0B}";
                  background = "${c.base0B}20";
                  selection = "${c.base0B}30";
                }
              ];

              syntax = {
                attribute = {
                  color = "${c.base0D}";
                };
                boolean = {
                  color = "${c.base0E}";
                };
                comment = {
                  color = "${c.base03}";
                  font_style = "italic";
                };
                "comment.doc" = {
                  color = "${c.base03}";
                  font_style = "italic";
                  font_weight = 700;
                };
                constant = {
                  color = "${c.base0E}";
                };
                constructor = {
                  color = "${c.base0B}";
                };
                directive = {
                  color = "${c.base0E}";
                };
                escape = {
                  color = "${c.base0D}";
                  font_style = "italic";
                };
                function = {
                  color = "${c.base0D}";
                  font_style = "italic";
                };
                "function.decorator" = {
                  color = "${c.base0D}";
                  font_style = "italic";
                };
                "function.magic" = {
                  color = "${c.base0D}";
                  font_style = "italic";
                };
                keyword = {
                  color = "${c.base0E}";
                  font_style = "italic";
                };
                label = {
                  color = "${c.base05}";
                };
                local = {
                  color = "${c.base08}";
                };
                markup = {
                  color = "${c.base09}";
                };
                meta = {
                  color = "${c.base05}";
                };
                modifier = {
                  color = "${c.base05}";
                };
                namespace = {
                  color = "${c.base08}";
                };
                number = {
                  color = "${c.base0A}";
                };
                operator = {
                  color = "${c.base0E}";
                };
                parameter = {
                  color = "${c.base05}";
                };
                punctuation = {
                  color = "${c.base05}";
                };
                regexp = {
                  color = "${c.base0C}";
                };
                self = {
                  color = "${c.base05}";
                  font_weight = 700;
                };
                string = {
                  color = "${c.base0B}";
                };
                strong = {
                  color = "${c.base0D}";
                  font_weight = 700;
                };
                support = {
                  color = "${c.base0E}";
                };
                symbol = {
                  color = "${c.base0A}";
                };
                tag = {
                  color = "${c.base0D}";
                };
                text = {
                  color = "${c.base05}";
                };
                type = {
                  color = "${c.base0B}";
                };
                variable = {
                  color = "${c.base05}";
                };
              };

              "terminal.background" = "${c.base00}ff";
              "terminal.foreground" = "${c.base05}ff";
              "terminal.ansi.black" = "${c.base00}ff";
              "terminal.ansi.red" = "${c.base08}ff";
              "terminal.ansi.green" = "${c.base0B}ff";
              "terminal.ansi.yellow" = "${c.base0A}ff";
              "terminal.ansi.blue" = "${c.base0D}ff";
              "terminal.ansi.magenta" = "${c.base0E}ff";
              "terminal.ansi.cyan" = "${c.base0C}ff";
              "terminal.ansi.white" = "${c.base05}ff";
              "terminal.ansi.bright_black" = "${c.base03}ff";
              "terminal.ansi.bright_red" = "${c.base08}ff";
              "terminal.ansi.bright_green" = "${c.base0B}ff";
              "terminal.ansi.bright_yellow" = "${c.base0A}ff";
              "terminal.ansi.bright_blue" = "${c.base0D}ff";
              "terminal.ansi.bright_magenta" = "${c.base0E}ff";
              "terminal.ansi.bright_cyan" = "${c.base0C}ff";
              "terminal.ansi.bright_white" = "${c.base05}ff";
            };
          }
        ];
      };
    };
  };
}

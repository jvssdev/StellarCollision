{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption mkIf types;
  wezterm = inputs.wezterm.packages.${pkgs.stdenv.hostPlatform.system}.default;
  cfg = config.cfg.wezterm;
  c = config.cfg.theme.colors;
  font = config.cfg.fonts.monospace.name;
in
{
  options.cfg.wezterm = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable WezTerm configuration.";
    };
    package = mkOption {
      type = types.package;
      default = wezterm;
      description = "The WezTerm package to install.";
    };
  };
  config = mkIf cfg.enable {
    hj.packages = [ cfg.package ];
    hj.xdg.config.files."wezterm/wezterm.lua".text = ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()
      config.font = wezterm.font '${font}'
      config.default_cursor_style = 'SteadyBar'
      config.font_size = 15
      config.enable_wayland = true
      config.check_for_updates = false
      config.colors = {
        foreground = '${c.base05}',
        background = '${c.base00}',
        cursor_border = '${c.base05}',
        cursor_bg = '${c.base05}',
        cursor_fg = '${c.base00}',
        ansi = {
          '${c.base00}',
          '${c.base08}',
          '${c.base0B}',
          '${c.base0A}',
          '${c.base0D}',
          '${c.base0E}',
          '${c.base0C}',
          '${c.base05}',
        },
        brights = {
          '${c.base03}',
          '${c.base08}',
          '${c.base0B}',
          '${c.base0A}',
          '${c.base0D}',
          '${c.base0E}',
          '${c.base0C}',
          '${c.base07}',
        },
      }
      config.keys = {
         {
           key = 'h',
           mods = 'SHIFT|CTRL',
           action = wezterm.action.DisableDefaultAssignment,
         },
         {
           key = 'l',
           mods = 'SHIFT|CTRL',
           action = wezterm.action.DisableDefaultAssignment,
         },
         { key = "t", mods = "CTRL", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
         { key = "w", mods = "CTRL", action = wezterm.action.CloseCurrentTab({ confirm = false }) },
         { key = "l", mods = "ALT", action = wezterm.action.ActivateTabRelative(1) },
         { key = "h", mods = "ALT", action = wezterm.action.ActivateTabRelative(-1) },
         { key = "v", mods = "ALT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
         { key = "s", mods = "ALT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
         { key = "q", mods = "ALT", action = wezterm.action.CloseCurrentPane({ confirm = false }) },
         { key = "LeftArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Left") },
         { key = "RightArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Right") },
         { key = "UpArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Up") },
         { key = "DownArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Down") },
       }
      config.hide_tab_bar_if_only_one_tab = true
      config.window_frame = {
        active_titlebar_bg = '${c.base00}',
        inactive_titlebar_bg = '${c.base00}',
      }
      config.tab_bar_at_bottom = false
      return config
    '';
  };
}

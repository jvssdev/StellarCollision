{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption mkIf types;
  cfg = config.cfg.zathura;
  c = config.cfg.theme.colors;
in
{
  options.cfg.zathura = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Zathura configuration.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.zathura;
      description = "The Zathura package to install.";
    };
  };

  config = mkIf cfg.enable {
    hj.packages = [ cfg.package ];

    hj.xdg.config.files."zathura/zathurarc".text = ''
      set default-fg               "${c.base05}"
      set default-bg               "${c.base00}"

      set completion-bg            "${c.base02}"
      set completion-fg            "${c.base05}"
      set completion-highlight-bg  "${c.base04}"
      set completion-highlight-fg  "${c.base05}"
      set completion-group-bg      "${c.base02}"
      set completion-group-fg      "${c.base0E}"

      set statusbar-fg             "${c.base05}"
      set statusbar-bg             "${c.base02}"

      set notification-bg          "${c.base02}"
      set notification-fg          "${c.base05}"
      set notification-error-bg    "${c.base02}"
      set notification-error-fg    "${c.base08}"
      set notification-warning-bg  "${c.base02}"
      set notification-warning-fg  "${c.base09}"

      set inputbar-fg              "${c.base05}"
      set inputbar-bg              "${c.base02}"

      set index-fg                 "${c.base05}"
      set index-bg                 "${c.base00}"
      set index-active-fg          "${c.base05}"
      set index-active-bg          "${c.base02}"

      set render-loading-bg        "${c.base00}"
      set render-loading-fg        "${c.base05}"

      set recolor-lightcolor       "${c.base00}"
      set recolor-darkcolor        "${c.base05}"
      set recolor                   true
    '';
  };
}

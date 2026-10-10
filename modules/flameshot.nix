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
  cfg = config.cfg.flameshot;

  c = config.cfg.theme.colors;

  isMango = config.cfg.mango.enable or false;
in
{
  options.cfg.flameshot = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Flameshot configuration.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.flameshot.override { enableWlrSupport = isMango; };
      description = "The Flameshot package to install.";
    };
  };

  config = mkIf cfg.enable {
    hj = {
      packages = [ cfg.package ];

      xdg.config.files."flameshot/flameshot.ini" = {
        generator = lib.generators.toINI { };
        value = {
          General = {
            showStartupLaunchMessage = false;
            showAbortNotification = false;
            uiColor = "${c.base0D}";
            contrastUiColor = "${c.base02}";
            drawColor = "${c.base08}";
            contrastOpacity = 188;
            userColors = "picker, ${c.base08}, ${c.base09}, ${c.base0A}, ${c.base0B}, ${c.base0D}, ${c.base0E}";
            savePath = "${config.cfg.vars.homeDirectory}/Pictures/Screenshots";
            savePathFixed = true;
          };
        };
      };
    };
  };
}

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
in
{
  options.cfg.flameshot = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Flameshot configuration.";
    };
  };

  config = mkIf cfg.enable {
    hj = {
      services.flameshot = {
        enable = true;
        package = pkgs.flameshot.override { enableWlrSupport = true; };
        settings = {
          General = {
            showStartupLaunchMessage = false;
            showAbortNotification = false;
            uiColor = "${c.base0D}";
            contrastUiColor = "${c.base02}";
            drawColor = "${c.base08}";
            contrastOpacity = 188;
            userColors = "picker, ${c.base08}, ${c.base09}, ${c.base0A}, ${c.base0B}, ${c.base0D}, ${c.base0E}";
          };
        };
      };
    };
  };
}

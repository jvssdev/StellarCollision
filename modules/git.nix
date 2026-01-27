{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (config.cfg) vars;
  cfg = config.cfg.git;
in
{
  options.cfg.git = {
    enable = mkEnableOption "Git configuration";
  };

  config = mkIf cfg.enable {
    hj = {
      xdg.config.files."git/config".text = ''
        [user]
            name = ${vars.name}
            email = ${vars.email}

        [color]
            ui = auto

        [init]
            defaultBranch = main

        [format]
            signOff = true

        [pull]
            rebase = true

        [core]
            excludesFile = ~/.config/git/ignore
      '';

      xdg.config.files."git/ignore".text = ''
        cached_layouts
      '';
    };
  };
}

{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkOption
    mkIf
    types
    optionals
    optionalAttrs
    getExe
    mkEnableOption
    ;
  cfg = config.cfg.jujutsu;
  toml = pkgs.formats.toml { };
in
{
  options.cfg.jujutsu = {
    enable = mkEnableOption "Jujutsu";
    package = mkOption {
      type = types.package;
      default = pkgs.jujutsu;
      description = "The Jujutsu package to install.";
    };
    name = mkOption {
      type = types.str;
      default = config.cfg.vars.name or "";
      description = "Username for Jujutsu.";
    };
    email = mkOption {
      type = types.str;
      default = config.cfg.vars.email or "";
      description = "Email for Jujutsu.";
    };
    integrations = {
      difftastic.enable = mkEnableOption "difftastic integration";
    };
  };

  config = mkIf cfg.enable {
    hj = {
      packages = [
        cfg.package
        pkgs.jjui
      ]
      ++ optionals cfg.integrations.difftastic.enable [ pkgs.difftastic ];

      xdg.config.files."jj/config.toml".source = toml.generate "jj-config" (
        {
          user = {
            inherit (cfg) name email;
          };
        }
        // optionalAttrs cfg.integrations.difftastic.enable {
          ui.diff-formatter = [
            (getExe pkgs.difftastic)
            "--display=side-by-side"
            "--color=always"
            "$left"
            "$right"
          ];
        }
      );
    };
  };
}

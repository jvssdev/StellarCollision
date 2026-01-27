{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types mkIf;
  cfg = config.cfg.brave;

  preferencesContent = import ./_preferences.nix;
  policiesContent = import ./_policies.nix;

in
{
  options.cfg.brave = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Brave Browser configuration.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.brave;
      description = "The Brave package to install.";
    };

    extensions = mkOption {
      type = types.listOf types.str;
      default = [
        "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"
        "dbepggeogbaibhgnhhndojpepiihcmeb"
        "dhdgffkkebhmkfjojejmpbldmpobfkfo"
        "ammjkodgmmoknidbanneddgankgfejfh"
        "eimadpbcbfnmbkopoojfekhnkhdbieeh"
        "mnjggcdmjocbbbhaepdhchncahnbgone"
      ];
      description = "List of extension IDs to install.";
    };
  };

  config = mkIf cfg.enable {
    hj.packages = [ cfg.package ];

    programs.chromium = {
      enable = true;
      inherit (cfg) extensions;
      extraOpts = policiesContent.policies;
    };

    hj.xdg.config = {
      files = {
        "BraveSoftware/Brave-Browser/Default/Preferences" = {
          text = builtins.toJSON preferencesContent;
        };
      };
    };

    environment.sessionVariables = {
      BROWSER = "brave";
      DEFAULT_BROWSER = "brave";
    };
  };
}

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

  forcedExtensions = map (id: "${id};https://clients2.google.com/service/update2/crx") cfg.extensions;

  fullPolicies = policiesContent.policies // {
    ExtensionInstallForcelist = forcedExtensions;
  };

  braveFixed = pkgs.brave.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      rm -f $out/share/applications/com.brave.Browser.desktop
    '';
  });
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
      default = braveFixed;
      description = "The Brave package to install.";
    };

    extensions = mkOption {
      type = types.listOf types.str;
      default = [
        "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # uBlock Origin Lite
        "dbepggeogbaibhgnhhndojpepiihcmeb" # Tampermonkey
        "dhdgffkkebhmkfjojejmpbldmpobfkfo" # Bitwarden
        "ammjkodgmmoknidbanneddgankgfejfh" # Dark Reader
        "eimadpbcbfnmbkopoojfekhnkhdbieeh" # DuckDuckGo Privacy Essentials
        "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
      ];
      description = "List of extension IDs to install.";
    };
  };

  config = mkIf cfg.enable {
    hj.packages = [ cfg.package ];

    environment.etc."opt/chrome/policies/managed/brave-policies.json".text =
      builtins.toJSON fullPolicies;

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

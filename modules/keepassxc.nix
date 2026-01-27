{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption mkIf types;
  cfg = config.cfg.keepassxc;
in
{
  options.cfg.keepassxc = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable KeePassXC configuration.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.keepassxc;
      description = "The KeePassXC package to install.";
    };
  };

  config = mkIf cfg.enable {
    hj.packages = [
      cfg.package
    ];
    hj.xdg.config.files."keepassxc/keepassxc.ini".text = ''
      [General]
      ConfigVersion=2
      UseAtomicSaves=true

      [Browser]
      AlwaysAllowAccess=true
      Enabled=true
      SearchInAllDatabases=true

      [GUI]
      ApplicationTheme=classic
      CompactMode=true

      [PasswordGenerator]
      Length=24
    '';
  };
}

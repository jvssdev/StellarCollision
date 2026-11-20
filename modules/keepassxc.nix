{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption mkIf types;

  cfg = config.cfg.keepassxc;

  nativeHost = {
    name = "org.keepassxc.keepassxc_browser";
    description = "KeePassXC integration with native messaging support";
    path = "${cfg.package}/bin/keepassxc-proxy";
    type = "stdio";
  };

  firefoxManifest = nativeHost // {
    allowed_extensions = [
      "keepassxc-browser@keepassxc.org"
    ];
  };

  chromiumManifest = nativeHost // {
    allowed_origins = [
      "chrome-extension://oboonakemofpalcgghocfoadofidjkkk/"
    ];
  };

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
    hj = {
      packages = [
        cfg.package
      ];

      xdg.config.files."keepassxc/keepassxc.ini" = {
        text = /* ini */ ''
          [General]
          ConfigVersion=2
          UseAtomicSaves=true
          MinimizeOnClose=true
          MinimizeToTray=true

          [Browser]
          AlwaysAllowAccess=true
          Enabled=true
          SearchInAllDatabases=true

          [GUI]
          ApplicationTheme=classic
          CompactMode=false

          [PasswordGenerator]
          Length=24

          [Security]
          LockDatabaseIdleSeconds=10800
        '';

        type = "copy";
        permissions = "0644";
        clobber = true;
      };

      files = {
        ".mozilla/native-messaging-hosts/org.keepassxc.keepassxc_browser.json" = {
          text = builtins.toJSON firefoxManifest;
          type = "copy";
          permissions = "0644";
          clobber = true;
        };

        ".config/google-chrome/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json" = {
          text = builtins.toJSON chromiumManifest;
          type = "copy";
          permissions = "0644";
          clobber = true;
        };

        ".config/chromium/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json" = {
          text = builtins.toJSON chromiumManifest;
          type = "copy";
          permissions = "0644";
          clobber = true;
        };
      };
    };
  };
}

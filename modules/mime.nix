{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkOption types mkIf;
  cfg = config.cfg.mime;
in
{
  options.cfg.mime = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable mime config";
    };
  };

  config = mkIf cfg.enable {
    xdg.mime = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/chrome" = "firefox.desktop";
        "text/html" = "firefox.desktop";
        "application/x-extension-htm" = "firefox.desktop";
        "application/x-extension-html" = "firefox.desktop";
        "application/x-extension-shtml" = "firefox.desktop";
        "application/xhtml+xml" = "firefox.desktop";
        "application/x-extension-xhtml" = "firefox.desktop";
        "application/x-extension-xht" = "firefox.desktop";

        "text/markdown" = "nvim.desktop";
        "text/x-nix" = "nvim.desktop";
        "text/x-log" = "nvim.desktop";
        "application/x-shellscript" = "nvim.desktop";
        "application/xml" = "nvim.desktop";
        "text/plain" = "nvim.desktop";
        "text/txt" = "nvim.desktop";

        "image/png" = "imv.desktop";
        "image/jpeg" = "imv.desktop";
        "image/gif" = "imv.desktop";
        "image/webp" = "imv.desktop";
        "image/svg+xml" = "imv.desktop";

        "application/pdf" = "org.pwmt.zathura.desktop";

        "video/mp4" = "org.kde.haruna.desktop";
        "video/x-matroska" = "org.kde.haruna.desktop";
        "audio/mpeg" = "org.kde.haruna.desktop";

        "application/x-bittorrent" = "org.qbittorrent.qBittorrent.desktop";
        "x-scheme-handler/magnet" = "org.qbittorrent.qBittorrent.desktop";

        "x-scheme-handler/terminal" = "com.mitchellh.ghostty.desktop";
        "x-terminal-emulator" = "com.mitchellh.ghostty.desktop";
      };
    };
  };
}

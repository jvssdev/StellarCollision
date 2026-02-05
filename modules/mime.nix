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
        "x-scheme-handler/http" = "zen-browser.desktop";
        "x-scheme-handler/https" = "zen-browser.desktop";
        "x-scheme-handler/chrome" = "zen-browser.desktop";
        "text/html" = "zen-browser.desktop";
        "application/x-extension-htm" = "zen-browser.desktop";
        "application/x-extension-html" = "zen-browser.desktop";
        "application/x-extension-shtml" = "zen-browser.desktop";
        "application/xhtml+xml" = "zen-browser.desktop";
        "application/x-extension-xhtml" = "zen-browser.desktop";
        "application/x-extension-xht" = "zen-browser.desktop";

        "inode/directory" = "yazi-open.desktop";

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
      };
    };
  };
}

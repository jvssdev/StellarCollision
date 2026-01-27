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
        "x-scheme-handler/http" = "brave-browser.desktop";
        "x-scheme-handler/https" = "brave-browser.desktop";
        "x-scheme-handler/chrome" = "brave-browser.desktop";
        "text/html" = "brave-browser.desktop";
        "application/x-extension-htm" = "brave-browser.desktop";
        "application/x-extension-html" = "brave-browser.desktop";
        "application/x-extension-shtml" = "brave-browser.desktop";
        "application/xhtml+xml" = "brave-browser.desktop";
        "application/x-extension-xhtml" = "brave-browser.desktop";
        "application/x-extension-xht" = "brave-browser.desktop";

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

        "video/mp4" = "mpv.desktop";
        "video/x-matroska" = "mpv.desktop";
        "audio/mpeg" = "mpv.desktop";
      };
    };
  };
}

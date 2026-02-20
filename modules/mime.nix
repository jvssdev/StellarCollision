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
        "x-scheme-handler/http" = "helium.desktop";
        "x-scheme-handler/https" = "helium.desktop";
        "x-scheme-handler/chrome" = "helium.desktop";
        "text/html" = "helium.desktop";
        "application/x-extension-htm" = "helium.desktop";
        "application/x-extension-html" = "helium.desktop";
        "application/x-extension-shtml" = "helium.desktop";
        "application/xhtml+xml" = "helium.desktop";
        "application/x-extension-xhtml" = "helium.desktop";
        "application/x-extension-xht" = "helium.desktop";

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

{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types mkIf;

  cfg = config.cfg.qt;

  colloid-kde = pkgs.fetchFromGitHub {
    owner = "vinceliuice";
    repo = "Colloid-kde";
    rev = "main";
    sha256 = "sha256-CWa6HnMP042jh573/x7WxYyRScN/l+jjCasiaBODljA=";
  };
in
{
  options.cfg.qt.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Qt/Kvantum theme";
  };

  config = mkIf cfg.enable {
    qt = {
      enable = true;
      platformTheme = "qt5ct";
      style = "kvantum";
    };

    hj = {
      packages = [ colloid-kde ];

      xdg.data.files."Kvantum".source = "${colloid-kde}/Kvantum";

      xdg.config.files = {
        "Kvantum/kvantum.kvconfig".text = ''
          [General]
          theme=ColloidDark
        '';

        "qt5ct/qt5ct.conf".text = ''
          [Appearance]
          color_scheme_path=${colloid-kde}/color-schemes/ColloidDark.colors
          custom_palette=true
          style=kvantum
          icon_theme=${config.cfg.gtk.iconTheme.name}

          [Fonts]
          fixed="${config.cfg.fonts.monospace.name},11"
          general="${config.cfg.fonts.monospace.name},11"
        '';

        "qt6ct/qt6ct.conf".text = ''
          [Appearance]
          color_scheme_path=${colloid-kde}/color-schemes/ColloidDark.colors
          custom_palette=true
          style=kvantum
          icon_theme=${config.cfg.gtk.iconTheme.name}

          [Fonts]
          fixed="${config.cfg.fonts.monospace.name},11"
          general="${config.cfg.fonts.monospace.name},11"
        '';
      };
    };
  };
}

{ lib, ... }:
let
  inherit (lib) mkOption types;

  mkColor =
    default:
    mkOption {
      type = types.str;
      inherit default;
      description = "Base16 color hex code";
    };
in
{
  options.cfg.theme = {
    name = mkOption {
      type = types.str;
      default = "tsuki";
      description = "Name of the current theme";
    };

    colors = {
      base00 = mkColor "#000000";
      base01 = mkColor "#002147";
      base02 = mkColor "#2D3D60";
      base03 = mkColor "#485A82";
      base04 = mkColor "#BADEFC";
      base05 = mkColor "#485A82";
      base06 = mkColor "#E0DEF4";
      base07 = mkColor "#A7AAE7";

      base08 = mkColor "#CC1512";
      base09 = mkColor "#F29A8A";
      base0A = mkColor "#FCE570";
      base0B = mkColor "#23CFBD";
      base0C = mkColor "#089B96";
      base0D = mkColor "#246BCE";
      base0E = mkColor "#9D91F8";
      base0F = mkColor "#6699CC";
    };
  };
}

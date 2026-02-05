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
      base01 = mkColor "#04080F";
      base02 = mkColor "#485A82";
      base03 = mkColor "#6578B2";
      base04 = mkColor "#C3DDF9";
      base05 = mkColor "#63789D";
      base06 = mkColor "#284189";
      base07 = mkColor "#5A5293";

      base08 = mkColor "#CC1512";
      base09 = mkColor "#F29A8A";
      base0A = mkColor "#FCE570";
      base0B = mkColor "#0EA2AB";
      base0C = mkColor "#405D73";
      base0D = mkColor "#2B6BBA";
      base0E = mkColor "#6B59C0";
      base0F = mkColor "#6699CC";
    };
  };
}

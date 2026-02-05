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
      base01 = mkColor "#060914";
      base02 = mkColor "#0C0F1A";
      base03 = mkColor "#1D202B";
      base04 = mkColor "#656771";
      base05 = mkColor "#A7A9B5";
      base06 = mkColor "#BDBFCB";
      base07 = mkColor "#C6DFEC";

      base08 = mkColor "#C65E53";
      base09 = mkColor "#C97E4F";
      base0A = mkColor "#E1C084";
      base0B = mkColor "#0EA2AB";
      base0C = mkColor "#9FF7FF";
      base0D = mkColor "#597BC0";
      base0E = mkColor "#8666B2";
      base0F = mkColor "#81A1C1";
    };
  };
}

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
      base01 = mkColor "#0D182E";
      base02 = mkColor "#485A82";
      base03 = mkColor "#64718D";
      base04 = mkColor "#BDCAE6";
      base05 = mkColor "#A7A9B5";
      base06 = mkColor "#BDBFCB";
      base07 = mkColor "#C6DFEC";

      base08 = mkColor "#C65E53";
      base09 = mkColor "#C97E4F";
      base0A = mkColor "#E1C084";
      base0B = mkColor "#0EA2AB";
      base0C = mkColor "#9FF7FF";
      base0D = mkColor "#597BC0";
      base0E = mkColor "#6B59C0";
      base0F = mkColor "#6699CC";
    };
  };
}

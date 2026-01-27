{ pkgs, lib }:
let
  inherit (lib)
    getExe
    getExe'
    ;
in
pkgs.writeShellScriptBin "screenshot" ''
  dir="$HOME/Pictures/Screenshots"
  mkdir -p "$dir"
  file="$dir/$(date +'%Y-%m-%d_%H-%M-%S').png"
  ${getExe pkgs.grim} -g "$(${lib.getExe pkgs.slurp})" "$file"
  ${getExe' pkgs.wl-clipboard "wl-copy"} < "$file"
  ${getExe' pkgs.libnotify "notify-send"} "Screenshot saved" -i "$file" -t 3000
''

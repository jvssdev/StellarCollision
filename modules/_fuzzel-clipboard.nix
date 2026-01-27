{ pkgs, lib, ... }:

let
  fuzzel-clipboard = pkgs.writeShellScriptBin "fuzzel-clipboard" ''
    #!/usr/bin/env bash

    ${lib.getExe pkgs.cliphist} list | ${lib.getExe pkgs.fuzzel} --dmenu \
      --prompt "󱉥  " \
      -l 25 -w 70 \
      --border-width=2 --border-radius=10 \
      | ${lib.getExe pkgs.cliphist} decode | ${lib.getExe' pkgs.wl-clipboard "wl-copy"}
  '';

  fuzzel-clipboard-clear = pkgs.writeShellScriptBin "fuzzel-clipboard-clear" ''
    #!/usr/bin/env bash

    ${lib.getExe pkgs.cliphist} wipe && \
    ${lib.getExe' pkgs.libnotify "notify-send"} "󰩺 Clipboard cleaned" -t 1500
  '';
in
{
  inherit fuzzel-clipboard fuzzel-clipboard-clear;
}

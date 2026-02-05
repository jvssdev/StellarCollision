{ pkgs, lib, ... }:

let
  inherit (lib) getExe getExe';

  fuzzel-clipboard = pkgs.writeShellScriptBin "fuzzel-clipboard" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Debug: log para arquivo
    exec 2> >(tee -a /tmp/fuzzel-clipboard.log >&2)
    set -x

    CLIPHIST="${getExe pkgs.cliphist}"
    FUZZEL="${getExe pkgs.fuzzel}"
    WL_COPY="${getExe' pkgs.wl-clipboard "wl-copy"}"

    echo "=== $(date) ===" >&2
    echo "CLIPBOARD_LIST:" >&2
    "$CLIPHIST" list >&2 || echo "cliphist list falhou" >&2

    selected=$("$CLIPHIST" list | "$FUZZEL" --dmenu \
      --prompt "󱉥  " \
      --lines 25 \
      --width 70) || {
        echo "Fuzzel cancelado ou falhou" >&2
        exit 0
      }

    echo "SELECIONADO: '$selected'" >&2

    if [ -z "$selected" ]; then
      echo "Nada selecionado" >&2
      exit 0
    fi

    echo "$selected" | "$CLIPHIST" decode | "$WL_COPY"
    echo "Copiado com sucesso" >&2
  '';

  fuzzel-clipboard-clear = pkgs.writeShellScriptBin "fuzzel-clipboard-clear" ''
    #!/usr/bin/env bash
    "${getExe pkgs.cliphist}" wipe && \
    "${getExe' pkgs.libnotify "notify-send"}" "󰩺 Clipboard cleaned" -t 1500
  '';
in
{
  inherit fuzzel-clipboard fuzzel-clipboard-clear;
}

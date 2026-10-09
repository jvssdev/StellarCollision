{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    mkIf
    mkEnableOption
    ;
  cfg = config.cfg.sddm;

  qmlPath = lib.makeSearchPath "lib/qt-6/qml" [
    pkgs.qt6.qt5compat
    pkgs.qt6.qtdeclarative
    pkgs.qt6.qtmultimedia
    pkgs.qt6.qtsvg
  ];

  pluginPath = lib.makeSearchPath "lib/qt-6/plugins" [
    pkgs.qt6.qtmultimedia
    pkgs.qt6.qtbase
  ];

  qylockShare = pkgs.stdenvNoCC.mkDerivation {
    pname = "qylock-quickshell-share";
    version = "unstable";
    src = inputs.qylock;
    nativeBuildInputs = [ pkgs.python3 ];
    dontBuild = true;

    installPhase = ''
            runHook preInstall

            mkdir -p $out/share/qylock
            cp -r quickshell-lockscreen/. $out/share/qylock/
            cp -r themes $out/share/qylock/themes

            python3 - "$out/share/qylock" <<'ENDOFPY'
      import os
      import re
      import sys

      root = sys.argv[1]
      shim_path = os.path.join(root, "shim", "SddmShim.qml")
      shell_path = os.path.join(root, "lock_shell.qml")
      themes_root = os.path.join(root, "themes")

      text = open(shim_path).read()

      marker = 'property string themePath: ""'
      if marker in text and "property var keyboard:" not in text:
          text = text.replace(
              marker,
              marker
              + """
                property var keyboard: QtObject {
                    property bool numLock: false
                    property bool capsLock: false
                    property bool scrollLock: false
                }""",
              1,
          )

      needle = "property var sddm: QtObject {"
      idx = text.find(needle)
      if idx >= 0 and "property string hostName" not in text:
          insert_at = text.find("signal loginFailed()", idx)
          if insert_at < 0:
              raise SystemExit("loginFailed not found")
          extra = """
                property string hostName: {
                    var xhr = new XMLHttpRequest();
                    try {
                        xhr.open("GET", "file:///etc/hostname", false);
                        xhr.send();
                        if (xhr.status === 200 || xhr.status === 0)
                            return (xhr.responseText || "").trim() || "localhost";
                    } catch (e) {}
                    return "localhost";
                }
                function suspend() { Quickshell.execDetached(["systemctl", "suspend"]); }
                function hibernate() { Quickshell.execDetached(["systemctl", "hibernate"]); }
            """
          text = text[:insert_at] + extra + text[insert_at:]

      open(shim_path, "w").write(text)

      shell = open(shell_path).read()
      hook = 'console.error("FAILED to load theme:", source)'
      if hook not in shell:
          raise SystemExit("theme error hook not found")
      shell = shell.replace(
          hook,
          hook + "\n                    shellRoot.sessionLocked = false\n                    Qt.quit()",
          1,
      )

      old_loaded = """onLoaded: {
                item.forceActiveFocus()
            }"""
      new_loaded = """onLoaded: {
                if (item && item.parent) {
                    item.anchors.fill = item.parent
                    item.width = item.parent.width
                    item.height = item.parent.height
                    item.forceActiveFocus()
                } else if (item) {
                    item.forceActiveFocus()
                }
            }"""
      if old_loaded in shell:
          shell = shell.replace(old_loaded, new_loaded, 1)
      else:
          shell = shell.replace(
              "item.forceActiveFocus()",
              """if (item && item.parent) {
                        item.anchors.fill = item.parent
                        item.width = item.parent.width
                        item.height = item.parent.height
                        item.forceActiveFocus()
                    } else if (item) {
                        item.forceActiveFocus()
                    }""",
              1,
          )

      open(shell_path, "w").write(shell)
      print("qylock shim/shell patched")

      PASS_IDS = re.compile(
          r"\bid\s*:\s*(passInput|pwd|password|passwordBox|passwordField|passField|pass)\b"
      )
      FOCUS_TRUE = re.compile(r"\bfocus\s*:\s*true\b")
      TIMER_FOCUS = re.compile(
          r"(Timer\s*\{[^}]*?interval\s*:\s*\d+[^}]*?onTriggered\s*:\s*)"
          r"((?:passInput|pwd|password|passwordBox|passwordField|passField|pass)\.forceActiveFocus\(\))",
          re.DOTALL,
      )
      TIMER_FOCUS_BLOCK = re.compile(
          r"(Timer\s*\{[^}]*?interval\s*:\s*\d+[^}]*?onTriggered\s*:\s*\{\s*)"
          r"((?:passInput|pwd|password|passwordBox|passwordField|passField|pass)\.forceActiveFocus\(\)\s*;?\s*)",
          re.DOTALL,
      )

      def demote_focus(m):
          block = m.group(0)
          if re.search(
              r"echoMode\s*:\s*TextInput\.Password|passwordCharacter|Password",
              block,
          ):
              return FOCUS_TRUE.sub("focus: false", block)
          return block

      def clear_then_focus(m):
          prefix, call = m.group(1), m.group(2)
          id_name = call.split(".", 1)[0]
          return prefix + "{ " + id_name + '.text = ""; ' + call + " }"

      def clear_then_focus_block(m):
          prefix, call = m.group(1), m.group(2)
          id_name = call.split(".", 1)[0]
          return prefix + id_name + '.text = ""; ' + call

      patched = 0
      for dirpath, _, files in os.walk(themes_root):
          if "Main.qml" not in files:
              continue
          path = os.path.join(dirpath, "Main.qml")
          src = open(path).read()
          orig = src

          src = re.sub(
              r"(TextInput|TextField)\s*\{(?:[^{}]|\{[^{}]*\}){0,40}\}",
              demote_focus,
              src,
              flags=re.DOTALL,
          )
          src = TIMER_FOCUS.sub(clear_then_focus, src)
          src = TIMER_FOCUS_BLOCK.sub(clear_then_focus_block, src)

          ids = PASS_IDS.findall(src)
          if ids and "passwordClearDelay" not in src:
              pid = ids[0]
              inject = (
                  "\n"
                  "    Timer {\n"
                  "        id: passwordClearDelay\n"
                  "        interval: 700\n"
                  "        running: true\n"
                  "        onTriggered: {\n"
                  "            if (typeof " + pid + ' !== "undefined") {\n'
                  "                " + pid + '.text = ""\n'
                  "                " + pid + ".forceActiveFocus()\n"
                  "            }\n"
                  "        }\n"
                  "    }\n"
              )
              if "Component.onCompleted:" in src:
                  src = src.replace(
                      "Component.onCompleted:",
                      inject + "\n    Component.onCompleted:",
                      1,
                  )
              else:
                  src = re.sub(
                      r"(id\s*:\s*root\b[^\n]*\n)",
                      r"\1" + inject,
                      src,
                      count=1,
                  )

          if "MediaPlayer" in src and "bg.mp4" in src:
              src = src.replace(
                  'source: "bg.mp4"',
                  'source: Qt.resolvedUrl("bg.mp4")',
              )
              if "onErrorOccurred" not in src:
                  src = src.replace(
                      "Component.onCompleted: player.play()",
                      """Component.onCompleted: player.play()
        onErrorOccurred: Qt.callLater(function() { player.play() })
        onPlaybackStateChanged: {
            if (playbackState === MediaPlayer.StoppedState)
                Qt.callLater(function() { player.play() })
        }""",
                  )

          if src != orig:
              open(path, "w").write(src)
              patched += 1
              print("password-focus fixed:", path)

      print("password leak fix applied to %d themes" % patched)
      ENDOFPY

            find $out/share/qylock/themes -name 'Main.qml' -print0 | xargs -0 -r sed -i \
              -e 's/Component\.onCompleted:[[:space:]]*keyboard\.numLock[[:space:]]*=[[:space:]]*true/Component.onCompleted: { if (typeof keyboard !== "undefined") keyboard.numLock = true }/g' \
              -e 's/keyboard\.numLock[[:space:]]*=[[:space:]]*true/if (typeof keyboard !== "undefined") keyboard.numLock = true/g'

            test -f $out/share/qylock/imports/SddmComponents/qmldir
            test -f $out/share/qylock/lock_shell.qml

            runHook postInstall
    '';
  };

  qylockLock = pkgs.writeShellScriptBin "qylock-lock" ''
    set -eu

    share=${qylockShare}/share/qylock
    theme="''${1:-''${QS_THEME:-${cfg.theme}}}"
    testMode="''${QYLOCK_TEST:-0}"

    if [ ! -f "$share/themes/$theme/Main.qml" ]; then
      echo "qylock-lock: theme not found: $theme" >&2
      exit 1
    fi

    export PATH=${
      lib.makeBinPath [
        pkgs.quickshell
        pkgs.systemd
        pkgs.coreutils
        pkgs.bash
        pkgs.procps
      ]
    }:$PATH

    if [ "$testMode" != 1 ] && pgrep -f "$share/lock_shell.qml" >/dev/null 2>&1; then
      exit 0
    fi

    if [ -z "''${XDG_SESSION_TYPE:-}" ]; then
      if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
        export XDG_SESSION_TYPE=wayland
      else
        export XDG_SESSION_TYPE=x11
      fi
    fi

    if [ "$testMode" = 1 ]; then
      export XDG_SESSION_TYPE=x11
      export QS_TESTING=1
    fi

    export QS_THEME="$theme"
    export QYLOCK_THEMES_ROOT="$share/themes"
    export QS_THEME_PATH="$share/themes/$theme"
    export QML_XHR_ALLOW_FILE_READ=1

    export QML2_IMPORT_PATH="$share/imports:${qmlPath}"
    export QML_IMPORT_PATH="$QML2_IMPORT_PATH"
    export QT_PLUGIN_PATH="${pluginPath}"

    exec quickshell -p "$share/lock_shell.qml"
  '';
in
{
  imports = [ inputs.qylock.nixosModules.default ];

  options.cfg.sddm = {
    enable = mkEnableOption "Enable SDDM with qylock themes.";
    wayland.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Wayland for SDDM.";
    };
    theme = mkOption {
      type = types.str;
      default = "winter";
      description = "qylock theme folder name (flat Main.qml themes for SDDM).";
    };
  };

  config = mkIf cfg.enable {
    programs.qylock = {
      enable = true;
      inherit (cfg) theme;
      sddm.enable = true;
      quickshell.enable = false;
    };
    environment = {
      systemPackages = with pkgs; [
        qylockLock
        qt6.qtmultimedia
        kdePackages.qt6ct
        kdePackages.qtwayland
        qt6.qtwayland
        config.cfg.gtk.cursorTheme.package
      ];

      etc."sddm.conf.d/cursor.conf".text = ''
        [Theme]
        CursorTheme=${config.cfg.gtk.cursorTheme.name}
        CursorSize=${toString config.cfg.gtk.cursorTheme.size}
      '';

      etc."sddm.conf.d/virtualkeyboard.conf".text = ''
        [General]
        InputMethod=
      '';
    };

    qt.enable = true;

    systemd.tmpfiles.rules =
      let
        cursorPkg = config.cfg.gtk.cursorTheme.package;
        cursorName = config.cfg.gtk.cursorTheme.name;
        themePath = "${cursorPkg}/share/icons/${cursorName}";
      in
      [
        "L+ /usr/share/icons/default - - - - ${themePath}"
        "L+ /var/lib/sddm/.icons/default - - - - ${themePath}"
        "d /var/lib/sddm/.icons 0755 sddm sddm -"
      ];

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = cfg.wayland.enable;
      package = pkgs.kdePackages.sddm;
      theme = lib.mkForce cfg.theme;
      extraPackages = [
        config.cfg.gtk.cursorTheme.package
        pkgs.qt6.qtmultimedia
        pkgs.qt6.qt5compat
        pkgs.qt6.qtsvg
      ];
      settings = {
        Theme = {
          Current = cfg.theme;
          CursorTheme = config.cfg.gtk.cursorTheme.name;
          CursorSize = config.cfg.gtk.cursorTheme.size;
        };
        General = {
          InputMethod = "";
        };
      };
    };
  };
}

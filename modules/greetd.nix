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

  gst = pkgs.gst_all_1;

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

  gstPath = lib.makeSearchPath "lib/gstreamer-1.0" [
    gst.gstreamer
    gst.gst-plugins-base
    gst.gst-plugins-good
    gst.gst-plugins-bad
    gst.gst-plugins-ugly
    gst.gst-libav
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

      python3 - "$out/share/qylock/shim/SddmShim.qml" "$out/share/qylock/lock_shell.qml" <<'PY'
      import sys

      shim_path = sys.argv[1]
      shell_path = sys.argv[2]

      text = open(shim_path).read()

      marker = 'property string themePath: ""'
      if marker in text and "property var keyboard:" not in text:
          text = text.replace(
              marker,
              marker + """
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
      open(shell_path, "w").write(shell)
      print("qylock patched")
      PY

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
    export QT_MEDIA_BACKEND=gstreamer
    export QML_XHR_ALLOW_FILE_READ=1
    export QML2_IMPORT_PATH="$share/imports:${qmlPath}''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
    export QML_IMPORT_PATH="$QML2_IMPORT_PATH"
    export QT_PLUGIN_PATH="${pluginPath}''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
    export GST_PLUGIN_SYSTEM_PATH_1_0="${gstPath}''${GST_PLUGIN_SYSTEM_PATH_1_0:+:$GST_PLUGIN_SYSTEM_PATH_1_0}"

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
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-bad
        gst_all_1.gst-plugins-ugly
        gst_all_1.gst-libav
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

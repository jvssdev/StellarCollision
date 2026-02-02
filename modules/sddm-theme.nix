{
  config,
  lib,
  pkgs,
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
  c = config.cfg.theme.colors;

  wallpaper = ../assets/Wallpapers/a6116535-4a72-453e-83c9-ea97b8597d8c.png;
  themeName = "quickshell-sddm";

  mainQml = pkgs.writeText "Main.qml" ''
    import QtQuick 2.15
    import QtQuick.Layouts 1.15
    import QtQuick.Controls 2.15

    Rectangle {
        id: root
        color: "${c.base00}"

        Image {
            anchors.fill: parent
            source: "wallpaper.png"
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 30

            Text {
                id: clockLabel
                text: Qt.formatTime(new Date(), "HH:mm")
                color: "${c.base06}"
                font.pixelSize: 72
                font.family: "${config.cfg.fonts.monospace.name}"
                font.bold: true
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.8)
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                id: dateLabel
                text: Qt.formatDate(new Date(), "dd/MM/yyyy")
                color: "${c.base04}"
                font.pixelSize: 24
                font.family: "${config.cfg.fonts.monospace.name}"
                Layout.alignment: Qt.AlignHCenter
            }

            TextField {
                id: usernameField
                implicitWidth: 300
                padding: 15
                text: sddm.greeterEnvironment.lastUser || ""
                placeholderText: "Username"
                color: "${c.base05}"
                background: Rectangle {
                    color: Qt.rgba(46/255, 52/255, 64/255, 0.85)
                    border.color: "${c.base0D}"
                    border.width: 2
                    radius: 10
                }
                Layout.alignment: Qt.AlignHCenter
            }

            TextField {
                id: passwordField
                implicitWidth: 300
                padding: 15
                focus: true
                echoMode: TextInput.Password
                placeholderText: "Password"
                inputMethodHints: Qt.ImhSensitiveData
                color: "${c.base05}"
                background: Rectangle {
                    color: Qt.rgba(46/255, 52/255, 64/255, 0.85)
                    border.color: "${c.base0D}"
                    border.width: 2
                    radius: 10
                }
                onAccepted: if (loginButton.enabled) loginButton.clicked()
                Layout.alignment: Qt.AlignHCenter
            }

            ComboBox {
                id: sessionCombo
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex
                implicitWidth: 300
                Layout.alignment: Qt.AlignHCenter
                contentItem: Text {
                    text: currentText
                    color: "${c.base05}"
                    font.family: "${config.cfg.fonts.monospace.name}"
                    horizontalAlignment: Text.AlignHCenter
                    leftPadding: 10
                    rightPadding: 10
                }
                background: Rectangle {
                    color: Qt.rgba(46/255, 52/255, 64/255, 0.85)
                    border.color: "${c.base0D}"
                    border.width: 2
                    radius: 10
                }
            }

            Button {
                id: loginButton
                text: "Login"
                enabled: usernameField.text.length > 0 && passwordField.text.length > 0
                padding: 12
                Layout.alignment: Qt.AlignHCenter
                onClicked: {
                    errorText.visible = false
                    sddm.login(usernameField.text, passwordField.text, sessionCombo.currentIndex)
                }
                contentItem: Text {
                    text: parent.text
                    color: "${c.base00}"
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "${config.cfg.fonts.monospace.name}"
                }
                background: Rectangle {
                    color: parent.down ? "${c.base0B}" : (parent.hovered ? "${c.base0C}" : "${c.base0D}")
                    radius: 8
                }
            }

            Text {
                id: errorText
                visible: false
                text: "Login failed"
                color: "${c.base08}"
                font.pixelSize: 14
                font.family: "${config.cfg.fonts.monospace.name}"
                Layout.alignment: Qt.AlignHCenter
            }
        }

        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 60
            spacing: 80

            Button {
                visible: sddm.canPowerOff
                text: ""
                font.pixelSize: 48
                onClicked: sddm.powerOff()
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: parent.text
                    color: parent.hovered ? "${c.base08}" : "${c.base05}"
                    font: parent.font
                }
            }

            Button {
                visible: sddm.canReboot
                text: ""
                font.pixelSize: 48
                onClicked: sddm.reboot()
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: parent.text
                    color: parent.hovered ? "${c.base0A}" : "${c.base05}"
                    font: parent.font
                }
            }

            Button {
                visible: sddm.canSuspend
                text: ""
                font.pixelSize: 48
                onClicked: sddm.suspend()
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: parent.text
                    color: parent.hovered ? "${c.base0E}" : "${c.base05}"
                    font: parent.font
                }
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: clockLabel.text = Qt.formatTime(new Date(), "HH:mm")
        }

        Timer {
            interval: 60000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: dateLabel.text = Qt.formatDate(new Date(), "dd/MM/yyyy")
        }

        Connections {
            target: sddm
            function onLoginFailed() {
                passwordField.text = ""
                errorText.visible = true
                passwordField.forceActiveFocus()
            }
        }
    }
  '';

  customTheme = pkgs.stdenv.mkDerivation {
    pname = themeName;
    version = "1.0";

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/share/sddm/themes/${themeName}
      cp ${wallpaper} $out/share/sddm/themes/${themeName}/wallpaper.png
      cp ${mainQml} $out/share/sddm/themes/${themeName}/Main.qml

      cat > $out/share/sddm/themes/${themeName}/theme.conf <<EOF
      [General]
      type=qtquick
      EOF
    '';
  };
in
{
  options.cfg.sddm = {
    enable = mkEnableOption "Enable SDDM configuration.";
    wayland.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Wayland for SDDM.";
    };
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        customTheme
        kdePackages.qt6ct
        libsForQt5.qtstyleplugin-kvantum
        kdePackages.qtstyleplugin-kvantum
        kdePackages.qtwayland
        qt6.qtwayland
        config.cfg.gtk.cursorTheme.package
      ];

      etc."sddm.conf.d/00-quickshell-theme.conf".text = ''
        [Theme]
        Current=${themeName}
        CursorTheme=${config.cfg.gtk.cursorTheme.name}
        CursorSize=${toString config.cfg.gtk.cursorTheme.size}
      '';

      etc."sddm.conf.d/cursor.conf".text = ''
        [Theme]
        CursorTheme=${config.cfg.gtk.cursorTheme.name}
        CursorSize=${toString config.cfg.gtk.cursorTheme.size}
      '';
    };

    qt.enable = true;

    systemd.tmpfiles.rules =
      let
        cursorPkg = config.cfg.gtk.cursorTheme.package;
        cursorName = config.cfg.gtk.cursorTheme.name;
      in
      [
        "L+ /var/lib/sddm/.icons/default - - - - ${cursorPkg}/share/icons/${cursorName}"

        "d /usr/share/icons/default 0755 root root -"

        "L+ /usr/share/icons/default/index.theme - - - - ${pkgs.writeText "default-index.theme" ''
          [Icon Theme]
          Inherits=${cursorName}
        ''}"

        "d /var/lib/sddm/.icons 0755 sddm sddm -"
      ];

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = cfg.wayland.enable;
      package = pkgs.kdePackages.sddm;
      theme = themeName;

      extraPackages = [ config.cfg.gtk.cursorTheme.package ];

      settings = {
        General = {
          InputMethod = "";
        };
      };
    };
  };
}

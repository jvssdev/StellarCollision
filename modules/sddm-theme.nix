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
    import SddmComponents 2.0

    Rectangle {
        id: root
        anchors.fill: parent
        color: "${c.base00}"

        Image {
            anchors.fill: parent
            source: "wallpaper.png"
            fillMode: Image.PreserveAspectCrop
            asynchronous: false
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 25

            Text {
                id: clockLabel
                text: Qt.formatTime(new Date(), "HH:mm")
                color: "${c.base06}"
                font.pixelSize: 64
                font.family: "${config.cfg.fonts.monospace.name}"
                font.bold: true
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.8)
                Layout.alignment: Qt.AlignHCenter
                renderType: Text.NativeRendering
            }

            Text {
                id: dateLabel
                text: Qt.formatDate(new Date(), "dd/MM/yyyy")
                color: "${c.base04}"
                font.pixelSize: 22
                font.family: "${config.cfg.fonts.monospace.name}"
                Layout.alignment: Qt.AlignHCenter
                renderType: Text.NativeRendering
            }

            Item { height: 20 }

            TextField {
                id: usernameField
                implicitWidth: 320
                padding: 12
                text: sddm.lastUser || ""
                placeholderText: "Username"
                color: "${c.base05}"
                font.family: "${config.cfg.fonts.monospace.name}"
                background: Rectangle {
                    color: Qt.rgba(0.11, 0.13, 0.18, 0.9)
                    border.color: "${c.base0D}"
                    border.width: 2
                    radius: 8
                }
                Layout.alignment: Qt.AlignHCenter
            }

            TextField {
                id: passwordField
                implicitWidth: 320
                padding: 12
                focus: true
                echoMode: TextInput.Password
                placeholderText: "Password"
                inputMethodHints: Qt.ImhSensitiveData
                color: "${c.base05}"
                font.family: "${config.cfg.fonts.monospace.name}"
                background: Rectangle {
                    color: Qt.rgba(0.11, 0.13, 0.18, 0.9)
                    border.color: "${c.base0D}"
                    border.width: 2
                    radius: 8
                }
                onAccepted: if (loginButton.enabled) loginButton.clicked()
                Layout.alignment: Qt.AlignHCenter
            }

            ComboBox {
                id: sessionCombo
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex
                implicitWidth: 320
                Layout.alignment: Qt.AlignHCenter
                contentItem: Text {
                    text: sessionCombo.displayText || sessionCombo.currentText
                    color: "${c.base05}"
                    font.family: "${config.cfg.fonts.monospace.name}"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 10
                    rightPadding: 10
                }
                background: Rectangle {
                    color: Qt.rgba(0.11, 0.13, 0.18, 0.9)
                    border.color: "${c.base0D}"
                    border.width: 2
                    radius: 8
                }
            }

            Button {
                id: loginButton
                text: "Login"
                enabled: usernameField.text.length > 0 && passwordField.text.length > 0
                padding: 12
                implicitWidth: 320
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
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
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
            anchors.bottomMargin: 40
            spacing: 60

            Button {
                visible: sddm.canPowerOff
                text: "⏻"
                font.pixelSize: 32
                padding: 20
                onClicked: sddm.powerOff()
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: parent.text
                    color: parent.hovered ? "${c.base08}" : "${c.base05}"
                    font: parent.font
                    renderType: Text.NativeRendering
                }
            }

            Button {
                visible: sddm.canReboot
                text: "↻"
                font.pixelSize: 32
                padding: 20
                onClicked: sddm.reboot()
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: parent.text
                    color: parent.hovered ? "${c.base0A}" : "${c.base05}"
                    font: parent.font
                    renderType: Text.NativeRendering
                }
            }

            Button {
                visible: sddm.canSuspend
                text: "⏾"
                font.pixelSize: 32
                padding: 20
                onClicked: sddm.suspend()
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: parent.text
                    color: parent.hovered ? "${c.base0E}" : "${c.base05}"
                    font: parent.font
                    renderType: Text.NativeRendering
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

  customTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = themeName;
    version = "1.0.0";
    src = pkgs.runCommand "theme-src" { } ''
      mkdir -p $out
    '';
    installPhase = ''
      mkdir -p $out/share/sddm/themes/${themeName}
      cp ${wallpaper} $out/share/sddm/themes/${themeName}/wallpaper.png
      cp ${mainQml} $out/share/sddm/themes/${themeName}/Main.qml

      cat > $out/share/sddm/themes/${themeName}/theme.conf <<EOF
      [General]
      type=qml
      EOF

      cat > $out/share/sddm/themes/${themeName}/metadata.desktop <<EOF
      [Desktop Entry]
      Name=Quickshell SDDM
      Comment=Minimal clean theme matching Quickshell lock screen
      Type=theme
      X-Plasma-API=declarativeappletscript
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
      systemPackages = [
        customTheme
      ];

      etc."sddm.conf.d/theme.conf".text = lib.mkForce ''
        [Theme]
        Current=${themeName}
        CursorTheme=${config.cfg.gtk.cursorTheme.name}
        CursorSize=${toString config.cfg.gtk.cursorTheme.size}
      '';
    };

    qt.enable = true;

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = cfg.wayland.enable;
      package = pkgs.kdePackages.sddm;
      theme = themeName;
      settings = {
        General = {
          InputMethod = "";
          DefaultSession = "";
        };
      };
    };
  };
}

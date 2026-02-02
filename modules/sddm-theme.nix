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

  mainQml = pkgs.writeTextFile {
    name = "Main.qml";
    text = ''
      import QtQuick 2.15
      import QtQuick.Layouts 1.15
      import QtQuick.Controls 2.15
      import SddmComponents 2.0

      Rectangle {
          id: root
          anchors.fill: parent
          color: "${c.base00}"

          Image {
              id: backgroundImage
              anchors.fill: parent
              source: "wallpaper.png"
              fillMode: Image.PreserveAspectCrop
              cache: false
              asynchronous: false
              z: 0
          }

          Rectangle {
              anchors.fill: parent
              color: Qt.rgba(0, 0, 0, 0.3)
              z: 1
          }

          ColumnLayout {
              z: 2
              anchors.centerIn: parent
              spacing: 20

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

              Item { 
                  Layout.preferredHeight: 30 
              }

              TextField {
                  id: usernameField
                  implicitWidth: 300
                  height: 45
                  padding: 12
                  text: sddm.lastUser || ""
                  placeholderText: "Username"
                  color: "${c.base05}"
                  font.family: "${config.cfg.fonts.monospace.name}"
                  font.pixelSize: 14
                  background: Rectangle {
                      color: Qt.rgba(0.11, 0.13, 0.18, 0.95)
                      border.color: "${c.base0D}"
                      border.width: 2
                      radius: 8
                  }
                  Layout.alignment: Qt.AlignHCenter
                  Keys.onReturnPressed: passwordField.forceActiveFocus()
                  Keys.onEnterPressed: passwordField.forceActiveFocus()
              }

              TextField {
                  id: passwordField
                  implicitWidth: 300
                  height: 45
                  padding: 12
                  focus: true
                  echoMode: TextInput.Password
                  placeholderText: "Password"
                  inputMethodHints: Qt.ImhSensitiveData
                  color: "${c.base05}"
                  font.family: "${config.cfg.fonts.monospace.name}"
                  font.pixelSize: 14
                  background: Rectangle {
                      color: Qt.rgba(0.11, 0.13, 0.18, 0.95)
                      border.color: "${c.base0D}"
                      border.width: 2
                      radius: 8
                  }
                  onAccepted: {
                      if (loginButton.enabled) 
                          sddm.login(usernameField.text, passwordField.text, sessionCombo.currentIndex)
                  }
                  Layout.alignment: Qt.AlignHCenter
              }

              ComboBox {
                  id: sessionCombo
                  model: sessionModel
                  textRole: "name"
                  currentIndex: sessionModel.lastIndex
                  implicitWidth: 300
                  height: 40
                  Layout.alignment: Qt.AlignHCenter
                  contentItem: Text {
                      text: sessionCombo.displayText
                      color: "${c.base05}"
                      font.family: "${config.cfg.fonts.monospace.name}"
                      font.pixelSize: 14
                      horizontalAlignment: Text.AlignHCenter
                      verticalAlignment: Text.AlignVCenter
                  }
                  background: Rectangle {
                      color: Qt.rgba(0.11, 0.13, 0.18, 0.95)
                      border.color: "${c.base0D}"
                      border.width: 2
                      radius: 8
                  }
              }

              Button {
                  id: loginButton
                  text: "Login"
                  enabled: usernameField.text.length > 0 && passwordField.text.length > 0
                  implicitWidth: 300
                  height: 45
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
                  text: "Authentication failed"
                  color: "${c.base08}"
                  font.pixelSize: 14
                  font.family: "${config.cfg.fonts.monospace.name}"
                  Layout.alignment: Qt.AlignHCenter
              }
          }

          Row {
              z: 2
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 50
              spacing: 40

              Button {
                  visible: sddm.canPowerOff
                  width: 60
                  height: 60
                  onClicked: sddm.powerOff()
                  background: Rectangle { 
                      color: parent.hovered ? Qt.rgba(1, 0, 0, 0.3) : "transparent"
                      radius: 30
                  }
                  contentItem: Text {
                      text: "⏻"
                      color: parent.hovered ? "${c.base08}" : "${c.base05}"
                      font.pixelSize: 28
                      horizontalAlignment: Text.AlignHCenter
                      verticalAlignment: Text.AlignVCenter
                  }
              }

              Button {
                  visible: sddm.canReboot
                  width: 60
                  height: 60
                  onClicked: sddm.reboot()
                  background: Rectangle { 
                      color: parent.hovered ? Qt.rgba(1, 0.5, 0, 0.3) : "transparent"
                      radius: 30
                  }
                  contentItem: Text {
                      text: "↻"
                      color: parent.hovered ? "${c.base0A}" : "${c.base05}"
                      font.pixelSize: 28
                      horizontalAlignment: Text.AlignHCenter
                      verticalAlignment: Text.AlignVCenter
                  }
              }

              Button {
                  visible: sddm.canSuspend
                  width: 60
                  height: 60
                  onClicked: sddm.suspend()
                  background: Rectangle { 
                      color: parent.hovered ? Qt.rgba(0, 0.5, 1, 0.3) : "transparent"
                      radius: 30
                  }
                  contentItem: Text {
                      text: "⏾"
                      color: parent.hovered ? "${c.base0E}" : "${c.base05}"
                      font.pixelSize: 28
                      horizontalAlignment: Text.AlignHCenter
                      verticalAlignment: Text.AlignVCenter
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
  };

  customTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = themeName;
    version = "1.0.0";

    dontUnpack = true;
    dontWrapQtApps = true;

    installPhase = ''
      runHook preInstall

      themeDir=$out/share/sddm/themes/${themeName}
      mkdir -p $themeDir

      cp ${wallpaper} $themeDir/wallpaper.png
      cp ${mainQml} $themeDir/Main.qml

      cat > $themeDir/theme.conf << 'EOF'
      [General]
      type=qml
      name=Quickshell SDDM
      description=Minimal SDDM theme matching Quickshell style
      version=1.0
      EOF

      cat > $themeDir/metadata.desktop << EOF
      [Desktop Entry]
      Name=Quickshell SDDM
      Comment=Minimal SDDM theme matching Quickshell lock screen
      Type=Service

      [X-SDDM-Theme]
      type=qml
      EOF

      runHook postInstall
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
    environment.systemPackages = [ customTheme ];

    services.displayManager.sddm = {
      enable = true;
      package = pkgs.kdePackages.sddm;
      theme = themeName;
      wayland.enable = cfg.wayland.enable;

      settings = {
        Theme = {
          Current = themeName;
          CursorTheme = config.cfg.gtk.cursorTheme.name;
          CursorSize = config.cfg.gtk.cursorTheme.size;
        };
        General = {
          DisplayServer = if cfg.wayland.enable then "wayland" else "x11";
          GreeterEnvironment = "QT_QPA_PLATFORM=wayland";
          InputMethod = "";
        };
      };
    };
  };
}

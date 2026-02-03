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

  sddmTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = themeName;
    version = "1.0.0";
    dontUnpack = true;
    dontWrapQtApps = true;

    buildInputs = [ pkgs.kdePackages.qtbase ];

    installPhase = ''
      themeDir=$out/share/sddm/themes/${themeName}
      mkdir -p $themeDir


      cp ${wallpaper} $themeDir/wallpaper.png


      cat > $themeDir/Main.qml << 'QML'
      import QtQuick 2.15
      import QtQuick.Layouts 1.15
      import QtQuick.Controls 2.15
      import SddmComponents 2.0

      Rectangle {
          id: root
          color: "${c.base00}"
          anchors.fill: parent
          
          Image {
              anchors.fill: parent
              source: "wallpaper.png"
              fillMode: Image.PreserveAspectCrop
              asynchronous: false
          }
          
          Rectangle {
              anchors.fill: parent
              color: Qt.rgba(0, 0, 0, 0.3)
          }
          
          ColumnLayout {
              anchors.centerIn: parent
              spacing: 20
              
              Text {
                  id: clockLabel
                  text: Qt.formatTime(new Date(), "HH:mm")
                  color: "${c.base06}"
                  font.pixelSize: 64
                  font.family: "${config.cfg.fonts.monospace.name}"
                  font.bold: true
                  Layout.alignment: Qt.AlignHCenter
                  
                  Timer {
                      interval: 1000
                      running: true
                      repeat: true
                      onTriggered: clockLabel.text = Qt.formatTime(new Date(), "HH:mm")
                  }
              }
              
              Text {
                  id: dateLabel
                  text: Qt.formatDate(new Date(), "dd/MM/yyyy")
                  color: "${c.base04}"
                  font.pixelSize: 20
                  font.family: "${config.cfg.fonts.monospace.name}"
                  Layout.alignment: Qt.AlignHCenter
                  
                  Timer {
                      interval: 60000
                      running: true
                      repeat: true
                      onTriggered: dateLabel.text = Qt.formatDate(new Date(), "dd/MM/yyyy")
                  }
              }
              
              Item { height: 30 }
              
              TextField {
                  id: usernameField
                  implicitWidth: 300
                  height: 45
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
                  
                  Keys.onReturnPressed: passwordField.forceActiveFocus()
              }
              
              TextField {
                  id: passwordField
                  implicitWidth: 300
                  height: 45
                  focus: true
                  echoMode: TextInput.Password
                  placeholderText: "Password"
                  color: "${c.base05}"
                  font.family: "${config.cfg.fonts.monospace.name}"
                  
                  background: Rectangle {
                      color: Qt.rgba(0.11, 0.13, 0.18, 0.9)
                      border.color: "${c.base0D}"
                      border.width: 2
                      radius: 8
                  }
                  
                  Layout.alignment: Qt.AlignHCenter
                  
                  onAccepted: {
                      sddm.login(usernameField.text, passwordField.text, sessionCombo.currentIndex)
                  }
              }
              
              ComboBox {
                  id: sessionCombo
                  model: sessionModel
                  textRole: "name"
                  currentIndex: sessionModel.lastIndex
                  implicitWidth: 300
                  height: 40
                  
                  contentItem: Text {
                      text: sessionCombo.displayText
                      color: "${c.base05}"
                      font.family: "${config.cfg.fonts.monospace.name}"
                      horizontalAlignment: Text.AlignHCenter
                      verticalAlignment: Text.AlignVCenter
                  }
                  
                  background: Rectangle {
                      color: Qt.rgba(0.11, 0.13, 0.18, 0.9)
                      border.color: "${c.base0D}"
                      border.width: 2
                      radius: 8
                  }
                  
                  Layout.alignment: Qt.AlignHCenter
              }
              
              Button {
                  id: loginButton
                  text: "Login"
                  implicitWidth: 300
                  height: 45
                  enabled: usernameField.text.length > 0 && passwordField.text.length > 0
                  
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
                  
                  onClicked: {
                      sddm.login(usernameField.text, passwordField.text, sessionCombo.currentIndex)
                  }
                  
                  Layout.alignment: Qt.AlignHCenter
              }
              
              Text {
                  id: errorText
                  visible: false
                  text: "Login failed"
                  color: "${c.base08}"
                  font.family: "${config.cfg.fonts.monospace.name}"
                  Layout.alignment: Qt.AlignHCenter
              }
          }
          
          Row {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 40
              spacing: 40
              
              Button {
                  visible: sddm.canPowerOff
                  text: "⏻"
                  flat: true
                  
                  contentItem: Text {
                      text: parent.text
                      color: parent.hovered ? "${c.base08}" : "${c.base05}"
                      font.pixelSize: 32
                  }
                  
                  onClicked: sddm.powerOff()
              }
              
              Button {
                  visible: sddm.canReboot
                  text: "↻"
                  flat: true
                  
                  contentItem: Text {
                      text: parent.text
                      color: parent.hovered ? "${c.base0A}" : "${c.base05}"
                      font.pixelSize: 32
                  }
                  
                  onClicked: sddm.reboot()
              }
              
              Button {
                  visible: sddm.canSuspend
                  text: "⏾"
                  flat: true
                  
                  contentItem: Text {
                      text: parent.text
                      color: parent.hovered ? "${c.base0E}" : "${c.base05}"
                      font.pixelSize: 32
                  }
                  
                  onClicked: sddm.suspend()
              }
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
      QML


      cat > $themeDir/metadata.desktop << EOF
      [Desktop Entry]
      Name=Quickshell SDDM
      Comment=Quickshell-styled SDDM theme
      Type=Service
      X-SDDM-Theme=qml
      EOF

      cat > $themeDir/theme.conf << EOF
      [General]
      type=qml
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
    environment.systemPackages = [ sddmTheme ];

    services.displayManager.sddm = {
      enable = true;
      package = pkgs.kdePackages.sddm;
      theme = themeName;
      wayland.enable = cfg.wayland.enable;

      settings = {
        Theme = {
          Current = themeName;
          ThemeDir = "/run/current-system/sw/share/sddm/themes";
          CursorTheme = config.cfg.gtk.cursorTheme.name;
          CursorSize = config.cfg.gtk.cursorTheme.size;
        };
        General = {
          DisplayServer = if cfg.wayland.enable then "wayland" else "x11";
          GreeterEnvironment = "QT_QPA_PLATFORM=wayland";
        };
        Wayland = lib.mkIf cfg.wayland.enable {
          CompositorCommand = "${pkgs.kdePackages.kwin}/bin/kwin_wayland --drm --no-lockscreen";
        };
      };
    };

    environment.etc."sddm/themes".source = "${sddmTheme}/share/sddm/themes";
  };
}

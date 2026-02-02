{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    getExe
    ;
  cfg = config.cfg.greetd;
  c = config.cfg.theme.colors;

  wallpaper = ../assets/Wallpapers/a6116535-4a72-453e-83c9-ea97b8597d8c.png;

  mangowc = inputs.mango.packages.${pkgs.stdenv.hostPlatform.system}.mango;
  quickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;

  greeterQml = pkgs.writeText "greeter.qml" ''
    import QtQuick
    import QtQuick.Layouts
    import QtQuick.Controls
    import Quickshell
    import Quickshell.Services.Greetd

    ShellRoot {
        id: root
        
        Greetd {
            id: greetd
        }
        
        property string username: "${config.cfg.vars.username}"
        
        PanelWindow {
            anchors.fill: true
            color: "${c.base00}"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            
            Image {
                anchors.fill: parent
                source: "file://${wallpaper}"
                fillMode: Image.PreserveAspectCrop
            }
            
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.4)
            }
        }
        
        PanelWindow {
            anchors.centerIn: true
            width: 420
            height: 520
            color: "transparent"
            exclusionMode: ExclusionMode.Normal
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0.04, 0.05, 0.08, 0.95)
                radius: 20
                border.color: "${c.base0D}"
                border.width: 2
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 20
                    width: parent.width - 80
                    
                    Text {
                        id: clockLabel
                        text: Qt.formatTime(new Date(), "HH:mm")
                        color: "${c.base06}"
                        font.pixelSize: 56
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
                        font.pixelSize: 18
                        font.family: "${config.cfg.fonts.monospace.name}"
                        Layout.alignment: Qt.AlignHCenter
                        
                        Timer {
                            interval: 60000
                            running: true
                            repeat: true
                            onTriggered: dateLabel.text = Qt.formatDate(new Date(), "dd/MM/yyyy")
                        }
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 2
                        color: "${c.base03}"
                        Layout.topMargin: 10
                        Layout.bottomMargin: 10
                    }
                    
                    Text {
                        text: "Welcome, " + root.username
                        color: "${c.base05}"
                        font.pixelSize: 16
                        font.family: "${config.cfg.fonts.monospace.name}"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    TextField {
                        id: passwordField
                        Layout.fillWidth: true
                        implicitHeight: 50
                        echoMode: TextInput.Password
                        placeholderText: "Password"
                        color: "${c.base05}"
                        font.family: "${config.cfg.fonts.monospace.name}"
                        font.pixelSize: 14
                        focus: true
                        
                        background: Rectangle {
                            color: Qt.rgba(0.11, 0.13, 0.18, 0.9)
                            border.color: parent.activeFocus ? "${c.base0D}" : "${c.base03}"
                            border.width: 2
                            radius: 8
                        }
                        
                        onAccepted: loginButton.clicked()
                    }
                    
                    Text {
                        id: errorText
                        visible: greetd.errorMessage !== ""
                        text: greetd.errorMessage
                        color: "${c.base08}"
                        font.pixelSize: 12
                        font.family: "${config.cfg.fonts.monospace.name}"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    Button {
                        id: loginButton
                        Layout.fillWidth: true
                        implicitHeight: 50
                        text: "Login"
                        enabled: passwordField.text.length > 0 && !greetd.inProgress
                        
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
                            greetd.login(root.username, passwordField.text, "mangowc")
                        }
                    }
                    
                    Item { Layout.preferredHeight: 20 }
                    
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 40
                        
                        Button {
                            flat: true
                            implicitWidth: 60
                            implicitHeight: 60
                            
                            contentItem: Text {
                                text: "⏻"
                                color: parent.hovered ? "${c.base08}" : "${c.base05}"
                                font.pixelSize: 28
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            background: Rectangle {
                                color: parent.hovered ? Qt.rgba(0.8, 0.2, 0.2, 0.3) : "transparent"
                                radius: 30
                            }
                            
                            onClicked: greetd.powerOff()
                        }
                        
                        Button {
                            flat: true
                            implicitWidth: 60
                            implicitHeight: 60
                            
                            contentItem: Text {
                                text: "↻"
                                color: parent.hovered ? "${c.base0A}" : "${c.base05}"
                                font.pixelSize: 28
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            background: Rectangle {
                                color: parent.hovered ? Qt.rgba(0.9, 0.6, 0.2, 0.3) : "transparent"
                                radius: 30
                            }
                            
                            onClicked: greetd.reboot()
                        }
                        
                        Button {
                            flat: true
                            implicitWidth: 60
                            implicitHeight: 60
                            
                            contentItem: Text {
                                text: "⏾"
                                color: parent.hovered ? "${c.base0E}" : "${c.base05}"
                                font.pixelSize: 28
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            background: Rectangle {
                                color: parent.hovered ? Qt.rgba(0.2, 0.5, 0.9, 0.3) : "transparent"
                                radius: 30
                            }
                            
                            onClicked: greetd.suspend()
                        }
                    }
                }
            }
        }
    }
  '';

  mangoConf = pkgs.writeText "mango-greeter.conf" ''
    monitorrule=eDP-1,0.60,1,tile,0,1,0,0,1920,1080,60
    borderpx=0
    rootcolor=0x000000ff
    exec-once=${quickshell}/bin/quickshell --config ${greeterQml}
  '';

  quickshellGreeter = pkgs.writeShellScriptBin "quickshell-greeter" ''
    export QT_QPA_PLATFORM=wayland
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=wlroots
    export XCURSOR_THEME=${config.cfg.gtk.cursorTheme.name}
    export XCURSOR_SIZE=${toString config.cfg.gtk.cursorTheme.size}

    ${getExe mangowc} -c ${mangoConf}
  '';
in
{
  options.cfg.greetd = {
    enable = mkEnableOption "Enable greetd display manager with Quickshell greeter.";
  };

  config = mkIf cfg.enable {

    users.users.greeter = {
      isSystemUser = true;
      group = "greeter";
      home = "/var/lib/greeter";
      createHome = true;
    };
    users.groups.greeter = { };
    services = {
      displayManager.sddm.enable = lib.mkForce false;

      greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${quickshellGreeter}/bin/quickshell-greeter";
            user = "greeter";
          };
        };
      };

      udev.extraRules = ''
        KERNEL=="tty[0-9]*", TAG+="uaccess", TAG+="seat"
        KERNEL=="drm/card[0-9]*", TAG+="uaccess", TAG+="seat"
      '';
    };

    environment.systemPackages = [
      quickshell
      mangowc
      quickshellGreeter
    ];
  };
}

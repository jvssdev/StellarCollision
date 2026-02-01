{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkIf
    mkEnableOption
    types
    getExe'
    strings
    ;
  cfg = config.cfg.quickshellGreeter;
  c = config.cfg.theme.colors;
  quickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  inherit (inputs.mango.packages.${pkgs.stdenv.hostPlatform.system}) mango;

  greeterUser = "greeter";
  greeterHome = "/var/lib/greeter";
in
{
  options.cfg.quickshellGreeter = {
    enable = mkEnableOption "Quickshell greeter";

    autologin = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      user = mkOption {
        type = types.str;
        default = "";
      };
    };
  };

  config = mkIf cfg.enable {
    services.greetd = {
      enable = true;
      restart = true;
      settings = {
        default_session = {
          command = "${quickshell}/bin/quickshell ${greeterHome}/.config/quickshell/greeter.qml";
          user = greeterUser;
        };
        initial_session = mkIf cfg.autologin.enable {
          command = "${mango}/bin/mango";
          inherit (cfg.autologin) user;
        };
      };
    };

    users.users.${greeterUser} = {
      isSystemUser = true;
      group = greeterUser;
      extraGroups = [
        "video"
        "render"
        "input"
      ];
      home = greeterHome;
      createHome = true;
    };

    users.groups.${greeterUser} = { };
    environment = {

      systemPackages = [
        quickshell
        pkgs.kdePackages.qtwayland
      ];

      etc."greetd/environments".text = ''
        Mango
        ${mango}/bin/mango
      '';

      etc."greetd/quickshell/greeter.qml".text = ''
        import QtQuick
        import QtQuick.Layouts
        import QtQuick.Controls
        import Quickshell
        import Quickshell.Wayland
        import Quickshell.Io
        import Quickshell.Services.Greetd

        ShellRoot {
            Greetd {
                id: greetd

                onLaunched: Quickshell.quit()

                onAuthMessage: (message, error, responseRequired, echoResponse) => {
                    if (responseRequired) {
                        greetd.respond(passwordField.text)
                    }
                }

                onAuthFailure: {
                    errorText.text = "Incorrect password. Try again."
                    errorText.visible = true
                    passwordField.text = ""
                    passwordField.focus = true
                }

                onAuthError: (error) => {
                    errorText.text = "Error: " + error
                    errorText.visible = true
                }
            }

            Variants {
                model: Quickshell.screens

                PanelWindow {
                    property var modelData
                    screen: modelData

                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                    anchors.fill: parent
                    color: "transparent"

                    Image {
                        anchors.fill: parent
                        source: "wallpaper.png"
                        fillMode: Image.PreserveAspectCrop
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(0, 0, 0, 0.55)
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 40

                        Text {
                            text: Qt.formatTime(new Date(), "HH:mm")
                            color: "${c.base06}"
                            font.pixelSize: 100
                            font.family: "${config.cfg.fonts.monospace.name}"
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                            style: Text.Outline
                            styleColor: Qt.rgba(0, 0, 0, 0.6)

                            Timer {
                                interval: 1000
                                running: true
                                repeat: true
                                onTriggered: parent.text = Qt.formatTime(new Date(), "HH:mm")
                            }
                        }

                        Text {
                            text: Qt.formatDate(new Date(), "dddd, MMMM d, yyyy")
                            color: "${c.base05}"
                            font.pixelSize: 28
                            font.family: "${config.cfg.fonts.monospace.name}"
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Rectangle {
                            Layout.preferredWidth: 420
                            Layout.preferredHeight: 380
                            color: "#e6${strings.removePrefix "#" c.base00}"
                            radius: 20
                            border.color: "${c.base0D}"
                            border.width: 2

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 40
                                spacing: 20

                                Text {
                                    text: "Welcome"
                                    color: "${c.base06}"
                                    font.pixelSize: 36
                                    font.family: "${config.cfg.fonts.monospace.name}"
                                    font.bold: true
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                ComboBox {
                                    id: userSelector
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 50

                                    model: ListModel {
                                        id: usersModel
                                        Component.onCompleted: {
                                            ${lib.concatMapStringsSep
                                              "\n                                          "
                                              (user: ''append({ text: "${user}", value: "${user}" });'')
                                              (builtins.attrNames (lib.filterAttrs (_: user: user.isNormalUser) config.users.users))
                                            }
                                        }
                                    }

                                    textRole: "text"
                                    valueRole: "value"

                                    delegate: ItemDelegate {
                                        width: userSelector.width
                                        contentItem: Text {
                                            text: model.text
                                            color: "${c.base05}"
                                            font.pixelSize: 18
                                            font.family: "${config.cfg.fonts.monospace.name}"
                                        }
                                        background: Rectangle {
                                            color: highlighted ? "${c.base02}" : "transparent"
                                        }
                                    }

                                    contentItem: Text {
                                        text: userSelector.displayText
                                        color: "${c.base05}"
                                        font.pixelSize: 18
                                        font.family: "${config.cfg.fonts.monospace.name}"
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 16
                                    }

                                    background: Rectangle {
                                        color: "${c.base01}"
                                        border.color: "${c.base03}"
                                        border.width: 1
                                        radius: 10
                                    }
                                }

                                TextField {
                                    id: passwordField
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 50
                                    placeholderText: "Password"
                                    echoMode: TextInput.Password
                                    focus: true
                                    color: "${c.base05}"
                                    font.pixelSize: 18
                                    font.family: "${config.cfg.fonts.monospace.name}"

                                    background: Rectangle {
                                        color: "${c.base01}"
                                        border.color: activeFocus ? "${c.base0D}" : "${c.base03}"
                                        border.width: 2
                                        radius: 10
                                    }

                                    onAccepted: loginButton.clicked()
                                }

                                Text {
                                    id: errorText
                                    visible: false
                                    text: ""
                                    color: "${c.base08}"
                                    font.pixelSize: 14
                                    font.family: "${config.cfg.fonts.monospace.name}"
                                    Layout.fillWidth: true
                                    wrapMode: Text.Wrap
                                }

                                Button {
                                    id: loginButton
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 50
                                    text: "Login"

                                    contentItem: Text {
                                        text: parent.text
                                        color: "${c.base00}"
                                        font.pixelSize: 20
                                        font.family: "${config.cfg.fonts.monospace.name}"
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    background: Rectangle {
                                        color: down ? "${c.base0C}" : (hovered ? "${c.base0B}" : "${c.base0D}")
                                        radius: 10
                                    }

                                    onClicked: {
                                        errorText.visible = false
                                        greetd.createSession(userSelector.currentValue)
                                        greetd.launch("${mango}/bin/mango", true)
                                    }
                                }
                            }
                        }

                        RowLayout {
                            spacing: 20
                            Layout.alignment: Qt.AlignHCenter

                            Button {
                                text: "Shutdown"
                                padding: 12
                                background: Rectangle {
                                    color: down ? "${c.base02}" : (hovered ? "${c.base01}" : "transparent")
                                    border.color: "${c.base03}"
                                    border.width: 2
                                    radius: 10
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "${c.base05}"
                                    font.pixelSize: 16
                                    font.family: "${config.cfg.fonts.monospace.name}"
                                }
                                onClicked: Process.exec("${getExe' pkgs.systemd "systemctl"}", ["poweroff"])
                            }

                            Button {
                                text: "Reboot"
                                padding: 12
                                background: Rectangle {
                                    color: down ? "${c.base02}" : (hovered ? "${c.base01}" : "transparent")
                                    border.color: "${c.base03}"
                                    border.width: 2
                                    radius: 10
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "${c.base05}"
                                    font.pixelSize: 16
                                    font.family: "${config.cfg.fonts.monospace.name}"
                                }
                                onClicked: Process.exec("${getExe' pkgs.systemd "systemctl"}", ["reboot"])
                            }
                        }
                    }
                }
            }
        }
      '';
    };

    systemd.tmpfiles.rules =
      let
        cursorPkg = config.cfg.gtk.cursorTheme.package;
        cursorName = config.cfg.gtk.cursorTheme.name;
      in
      [
        "d ${greeterHome}/.config 0755 ${greeterUser} ${greeterUser} -"
        "d ${greeterHome}/.config/quickshell 0755 ${greeterUser} ${greeterUser} -"
        "d ${greeterHome}/.icons 0755 ${greeterUser} ${greeterUser} -"
        "L+ ${greeterHome}/.icons/default - - - - ${cursorPkg}/share/icons/${cursorName}"
        "C ${greeterHome}/.config/quickshell/wallpaper.png - - - - ${../assets/Wallpapers/a6116535-4a72-453e-83c9-ea97b8597d8c.png}"
      ];

    systemd.services.greetd = {
      serviceConfig = {
        Type = "idle";
        StandardInput = "tty";
        StandardOutput = "tty";
        StandardError = "journal";
        TTYReset = true;
        TTYVHangup = true;
        TTYVTDisallocate = true;

        Restart = lib.mkForce "on-failure";
      };

      unitConfig.After = [
        "systemd-user-sessions.service"
        "plymouth-quit-wait.service"
      ];
    };
  };
}

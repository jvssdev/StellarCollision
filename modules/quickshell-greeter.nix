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

  greeterScript = pkgs.writeShellScript "quickshell-greeter-wrapper" ''
    set -x

    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=cage
    export XDG_RUNTIME_DIR=/run/user/$(id -u)
    export WAYLAND_DISPLAY=wayland-0

    export QT_QPA_PLATFORM=wayland
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

    export QML_IMPORT_PATH="${quickshell}/share/qml:${pkgs.kdePackages.qtdeclarative}/lib/qt-6/qml:${pkgs.kdePackages.qtbase}/lib/qt-6/qml:${pkgs.kdePackages.qt5compat}/lib/qt-6/qml"

    mkdir -p "$XDG_RUNTIME_DIR"
    chmod 0700 "$XDG_RUNTIME_DIR"

    echo "Starting cage with quickshell..." >&2
    echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR" >&2
    echo "QML_IMPORT_PATH=$QML_IMPORT_PATH" >&2

    exec ${pkgs.dbus}/bin/dbus-run-session ${pkgs.cage}/bin/cage -s -d -- ${quickshell}/bin/quickshell ${greeterHome}/.config/quickshell/greeter.qml
  '';
in
{
  options.cfg.quickshellGreeter = {
    enable = mkEnableOption "Quickshell greeter";

    autologin = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable autologin";
      };
      user = mkOption {
        type = types.str;
        default = "";
        description = "User to autologin";
      };
    };
  };

  config = mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${greeterScript}";
          user = greeterUser;
        };
      };
    };

    security.pam.services.greetd = {
      enableGnomeKeyring = lib.mkForce false;
      gnupg.enable = lib.mkForce false;
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

    environment.systemPackages = [
      quickshell
      pkgs.cage
      pkgs.kdePackages.qtwayland
      pkgs.kdePackages.qtdeclarative
      pkgs.kdePackages.qtbase
      pkgs.kdePackages.qt5compat
    ];

    systemd.tmpfiles.rules =
      let
        cursorPkg = config.cfg.gtk.cursorTheme.package;
        cursorName = config.cfg.gtk.cursorTheme.name;
      in
      [
        "d ${greeterHome}/.config 0755 ${greeterUser} ${greeterUser} -"
        "d ${greeterHome}/.config/quickshell 0755 ${greeterUser} ${greeterUser} -"
        "d ${greeterHome}/.icons 0755 ${greeterUser} ${greeterUser} -"
        "d /run/user/995 0700 ${greeterUser} ${greeterUser} -"
        "L+ ${greeterHome}/.icons/default - - - - ${cursorPkg}/share/icons/${cursorName}"
        "C ${greeterHome}/.config/quickshell/wallpaper.png - - - - ${../assets/Wallpapers/a6116535-4a72-453e-83c9-ea97b8597d8c.png}"
        "L+ ${greeterHome}/.config/quickshell/greeter.qml - - - - /etc/greetd/quickshell/greeter.qml"
      ];

    environment.etc = {
      "greetd/environments".text = ''
        Mango
        ${mango}/bin/mango
      '';

      "greetd/quickshell/greeter.qml".text = ''
        import QtQuick
        import QtQuick.Layouts
        import QtQuick.Controls
        import Qt5Compat.GraphicalEffects
        import Quickshell
        import Quickshell.Wayland
        import Quickshell.Io
        import Quickshell.Greetd

        ShellRoot {
            Component.onCompleted: {
                console.log("ShellRoot initialized")
                console.log("Screens available:", Quickshell.screens.length)
            }
            
            GreetdServer {
                id: greetd
                
                Component.onCompleted: {
                    console.log("GreetdServer initialized")
                }
                
                onLoginSucceeded: {
                    console.log("Login succeeded, quitting")
                    Quickshell.quit()
                }
                
                onLoginFailed: function(reason) {
                    console.error("Login failed:", reason)
                    errorText.text = reason
                    errorText.visible = true
                    passwordField.text = ""
                    passwordField.forceActiveFocus()
                }
            }

            Variants {
                model: Quickshell.screens

                PanelWindow {
                    property var modelData
                    screen: modelData

                    Component.onCompleted: {
                        console.log("PanelWindow created for screen:", modelData.name)
                    }

                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                    anchors.fill: true
                    color: "transparent"
                    visible: true

                    Image {
                        id: wallpaper
                        anchors.fill: parent
                        source: "file://${greeterHome}/.config/quickshell/wallpaper.png"
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        
                        onStatusChanged: {
                            if (status == Image.Error) {
                                console.error("Failed to load wallpaper")
                            }
                        }
                    }

                    FastBlur {
                        anchors.fill: wallpaper
                        source: wallpaper
                        radius: 64
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(0, 0, 0, 0.45)
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 40

                        Text {
                            id: clockText
                            property var currentTime: new Date()
                            text: Qt.formatTime(currentTime, "HH:mm")
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
                                onTriggered: clockText.currentTime = new Date()
                            }
                        }

                        Text {
                            property var currentDate: new Date()
                            text: Qt.formatDate(currentDate, "dddd, MMMM d, yyyy")
                            color: "${c.base05}"
                            font.pixelSize: 28
                            font.family: "${config.cfg.fonts.monospace.name}"
                            Layout.alignment: Qt.AlignHCenter
                            
                            Timer {
                                interval: 60000
                                running: true
                                repeat: true
                                onTriggered: parent.currentDate = new Date()
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 420
                            Layout.preferredHeight: 400
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
                                        Component.onCompleted: {
                                            ${lib.concatMapStringsSep
                                              "\n                                            "
                                              (user: ''append({ text: "${user}", value: "${user}" });'')
                                              (builtins.attrNames (lib.filterAttrs (_: user: user.isNormalUser) config.users.users))
                                            }
                                            console.log("Users loaded:", count)
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
                                            verticalAlignment: Text.AlignVCenter
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
                                    color: "${c.base05}"
                                    font.pixelSize: 18
                                    font.family: "${config.cfg.fonts.monospace.name}"
                                    selectByMouse: true
                                    
                                    Component.onCompleted: {
                                        forceActiveFocus()
                                        console.log("Password field ready")
                                    }

                                    background: Rectangle {
                                        color: "${c.base01}"
                                        border.color: passwordField.activeFocus ? "${c.base0D}" : "${c.base03}"
                                        border.width: 2
                                        radius: 10
                                    }

                                    onAccepted: {
                                        if (text.length > 0 && !greetd.loginActive) {
                                            doLogin()
                                        }
                                    }
                                    
                                    Keys.onEscapePressed: text = ""
                                    
                                    function doLogin() {
                                        console.log("Attempting login for:", userSelector.currentValue)
                                        errorText.visible = false
                                        greetd.login(userSelector.currentValue, passwordField.text, "${mango}/bin/mango")
                                    }
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
                                    Layout.preferredHeight: visible ? implicitHeight : 0
                                }

                                Button {
                                    id: loginButton
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 50
                                    enabled: !greetd.loginActive && passwordField.text.length > 0

                                    contentItem: Text {
                                        text: greetd.loginActive ? "Logging in..." : "Login"
                                        color: parent.enabled ? "${c.base00}" : "${c.base04}"
                                        font.pixelSize: 20
                                        font.family: "${config.cfg.fonts.monospace.name}"
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    background: Rectangle {
                                        color: parent.enabled ? 
                                            (parent.down ? "${c.base0C}" : (parent.hovered ? "${c.base0B}" : "${c.base0D}")) : 
                                            "${c.base03}"
                                        radius: 10
                                    }

                                    onClicked: passwordField.doLogin()
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
                                    color: parent.down ? "${c.base02}" : (parent.hovered ? "${c.base01}" : "transparent")
                                    border.color: "${c.base03}"
                                    border.width: 2
                                    radius: 10
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "${c.base05}"
                                    font.pixelSize: 16
                                    font.family: "${config.cfg.fonts.monospace.name}"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: Process.exec("${getExe' pkgs.systemd "systemctl"}", ["poweroff"])
                            }

                            Button {
                                text: "Reboot"
                                padding: 12
                                background: Rectangle {
                                    color: parent.down ? "${c.base02}" : (parent.hovered ? "${c.base01}" : "transparent")
                                    border.color: "${c.base03}"
                                    border.width: 2
                                    radius: 10
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "${c.base05}"
                                    font.pixelSize: 16
                                    font.family: "${config.cfg.fonts.monospace.name}"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
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

    systemd.services.greetd = {
      serviceConfig = {
        Type = "idle";
        StandardInput = "tty";
        StandardOutput = "journal";
        StandardError = "journal";
        TTYReset = true;
        TTYVHangup = true;
        TTYVTDisallocate = true;
      };

      unitConfig = {
        After = [
          "systemd-user-sessions.service"
          "plymouth-quit-wait.service"
        ];
      };
    };

    systemd.services."user-runtime-dir@995" = {
      enable = true;
    };
  };
}

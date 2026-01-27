{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.cfg.quickshell;
  quickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  c = config.cfg.theme.colors;
  inherit (lib)
    mkOption
    mkIf
    types
    getExe
    getExe'
    ;
  inherit (builtins) substring;
in
{
  options.cfg.quickshell = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Quickshell configuration";
    };
    package = mkOption {
      type = types.package;
      default = quickshell;
      description = "The Quickshell package to use";
    };
  };

  config = mkIf cfg.enable {
    hj.packages = [ cfg.package ];
    environment.sessionVariables = {
      QML_IMPORT_PATH = lib.concatStringsSep ":" [
        "$HOME/.config/quickshell"
        "${pkgs.quickshell}/share/qml"
        (lib.makeSearchPath "lib/qt-6/qml" [
          pkgs.kdePackages.qtdeclarative
          pkgs.kdePackages.qtbase
        ])
      ];
    };
    hj.xdg.config.files = {
      "quickshell/icons".source = ../assests/icons;

      "quickshell/PowerButton.qml".text = ''
        import QtQuick
        import Quickshell.Io
        QtObject {
            required property string command
            required property string text
            required property string icon
            id: button
            readonly property var process: Process {
                command: ["${getExe pkgs.bash}", "-c", button.command]
            }
            function exec() {
                process.startDetached();
            }
        }
      '';

      "quickshell/PowerMenu.qml".text = ''
        import QtQuick
        import QtQuick.Layouts
        import Quickshell
        import Quickshell.Io
        import Quickshell.Wayland
        Variants {
            id: root
            property bool shown: false
            property int focusedIndex: -1
            property color backgroundColor: "#80${substring 1 6 c.base00}"
            property color buttonColor: "transparent"
            property color buttonHoverColor: "${c.base0D}"
            default property list<PowerButton> buttons
            model: Quickshell.screens
            onShownChanged: if (shown) focusedIndex = 0; else focusedIndex = -1;
            PanelWindow {
                id: w
                visible: root.shown
                property var modelData
                screen: modelData
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                color: "transparent"
                contentItem {
                    focus: true
                    Keys.onPressed: event => {
                        if (event.key == Qt.Key_Escape) {
                            root.shown = false;
                            event.accepted = true;
                        }
                        else if (event.key == Qt.Key_Left || event.key == Qt.Key_H) {
                            if (root.focusedIndex > 0) root.focusedIndex--;
                            event.accepted = true;
                        }
                        else if (event.key == Qt.Key_Right || event.key == Qt.Key_L) {
                            if (root.focusedIndex + 1 < buttons.length) root.focusedIndex++;
                            event.accepted = true;
                        }
                        else if (event.key == Qt.Key_Up || event.key == Qt.Key_K) {
                            if (root.focusedIndex > 0) root.focusedIndex--;
                            event.accepted = true;
                        }
                        else if (event.key == Qt.Key_Down || event.key == Qt.Key_J) {
                            if (root.focusedIndex + 1 < buttons.length) root.focusedIndex++;
                            event.accepted = true;
                        }
                        else if (event.key == Qt.Key_Return || event.key == Qt.Key_Space) {
                            if (root.focusedIndex >= 0 && root.focusedIndex < buttons.length) {
                                buttons[root.focusedIndex].exec();
                                root.shown = false;
                            }
                            event.accepted = true;
                        }
                    }
                }
                anchors {
                    top: true
                    left: true
                    bottom: true
                    right: true
                }
                Rectangle {
                    color: backgroundColor
                    anchors.fill: parent
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.shown = false
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 20
                            Repeater {
                                model: buttons
                                delegate: Rectangle {
                                    required property PowerButton modelData;
                                    required property int index;
                                    Layout.preferredWidth: 180
                                    Layout.preferredHeight: 180
                                    color: ma.containsMouse || (index == root.focusedIndex) ? root.buttonHoverColor : root.buttonColor
                                    radius: 10
                                    border.color: "${c.base03}"
                                    border.width: 2
                                    MouseArea {
                                        id: ma
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            modelData.exec();
                                            root.shown = false;
                                        }
                                    }
                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 10
                                        Image {
                                            source: ma.containsMouse || (index == root.focusedIndex) ? "icons/" + modelData.icon + "-hover.png" : "icons/" + modelData.icon + ".png"
                                            Layout.preferredWidth: 114
                                            Layout.preferredHeight: 114
                                            fillMode: Image.PreserveAspectFit
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                        Text {
                                            text: modelData.text
                                            font.pixelSize: 12
                                            color: "${c.base07}"
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
      '';

      "quickshell/WorkspaceModule.qml".text = ''
        import QtQuick
        import QtQuick.Layouts
        import Quickshell
        import Quickshell.Io
        RowLayout {
            id: workspaceModule
            spacing: 4
            RowLayout {
                      spacing: 12
                      Row {
                          spacing: 2
                          Repeater {
                              model: ListModel {
                                  id: dwlTagsModel
                                  Component.onCompleted: {
                                      for (let i = 1; i <= 9; i++) {
                                          append({ tagId: i.toString(), isActive: false, isOccupied: false, isUrgent: false });
                                      }
                                  }
                              }
                              Rectangle {
                                  visible: model.isActive || model.isOccupied || model.isUrgent
                                  width: visible ? 20 : 0
                                  height: 20
                                  color: "transparent"
                                  Rectangle {
                                      anchors.fill: parent
                                      anchors.margins: 2
                                      color: model.isUrgent ? "${c.base0D}" : (model.isActive ? "${c.base0D}" : (model.isOccupied ? "${c.base02}" : "transparent"))
                                      radius: 10
                                      Text {
                                          text: model.tagId
                                          color: (model.isActive || model.isUrgent) ? "${c.base00}" : "${c.base05}"
                                          font.pixelSize: 11
                                          font.family: "${config.cfg.fonts.monospace.name}"
                                          font.bold: model.isActive
                                          anchors.centerIn: parent
                                      }
                                  }
                              }
                          }
                      }
                      Text {
                          id: dwlLayoutText
                          text: ""
                          color: "${c.base0C}"
                          font.pixelSize: 11
                          font.family: "${config.cfg.fonts.monospace.name}"
                          font.bold: true
                      }
                  }
                  Process {
                      id: dwlUpdateProc
                      command: ["mmsg", "-g"]
                      stdout: SplitParser {
                          onRead: data => {
                              if (!data) return;
                              const parts = data.trim().split(/\s+/);

                              const tagIndex = parts.indexOf("tag");
                              if (tagIndex !== -1 && parts.length > tagIndex + 4) {
                                  const id = parseInt(parts[tagIndex + 1]);
                                  if (id >= 1 && id <= 9) {
                                      const state = parts[tagIndex + 2];
                                      const active = state === "1";
                                      const urgent = state === "2";
                                      const occupied = parseInt(parts[tagIndex + 3]) > 0;

                                      dwlTagsModel.setProperty(id - 1, "isActive", active);
                                      dwlTagsModel.setProperty(id - 1, "isOccupied", occupied);
                                      dwlTagsModel.setProperty(id - 1, "isUrgent", urgent);
                                  }
                              }

                              const layoutIndex = parts.indexOf("layout");
                              if (layoutIndex !== -1 && parts.length > layoutIndex + 1) {
                                  const symbol = parts[layoutIndex + 1] || "";
                                  dwlLayoutText.text = symbol ? "[" + symbol.replace(/[\[\]]/g, "") + "]" : "";
                              }
                          }
                      }
                  }
                  Process {
                      id: dwlWatchProc
                      command: ["mmsg", "-w"]
                      running: true
                      stdout: SplitParser {
                          onRead: data => {
                              if (data.trim()) {
                                  dwlUpdateProc.running = true;
                              }
                          }
                      }
                  }
                  Timer {
                      interval: 250
                      running: true
                      repeat: true
                      triggeredOnStart: true
                      onTriggered: {
                          if (!dwlUpdateProc.running) {
                              dwlUpdateProc.running = true;
                          }
                      }
                  }
                  Component.onCompleted: dwlUpdateProc.running = true
        }
      '';

      "quickshell/IdleMonitors.qml".text = ''
        import QtQuick
        import Quickshell
        import Quickshell.Wayland
        import Quickshell.Io
        Scope {
            id: idleScope
            property bool manualInhibit: false
            QtObject { id: audioPlaying; property bool isPlaying: false }
            Process {
                id: audioCheckProc
                command: ["${getExe pkgs.bash}", "-c", "${getExe pkgs.playerctl} -a status 2>/dev/null | grep Playing > /dev/null && echo yes || echo no"]
                stdout: SplitParser {
                    onRead: data => {
                        if (data) {
                            audioPlaying.isPlaying = data.trim() === "yes"
                        }
                    }
                }
            }
            Timer {
                interval: 2000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: audioCheckProc.running = true
            }
            IdleInhibitor {
                enabled: manualInhibit || audioPlaying.isPlaying
            }
            function handleIdleAction(action, isIdle) {
                if (!action) return;
                if (action === "lock" && isIdle) lockProc.running = true;
                if (action === "suspend" && isIdle) suspendProc.running = true;
                if (action === "dpms off" && isIdle) wlopmOffProc.running = true;
                if (action === "dpms on" && !isIdle) wlopmOnProc.running = true;
            }
            Process { id: wlopmOffProc; command: ["${getExe pkgs.wlopm}", "--off", "*"] }
            Process { id: wlopmOnProc; command: ["${getExe pkgs.wlopm}", "--on", "*"] }
            Process { id: lockProc; command: ["${getExe pkgs.quickshell}", "ipc", "call", "lockScreen", "toggle"] }
            Process { id: suspendProc; command: ["${getExe' pkgs.systemd "systemctl"}", "suspend"] }
            Process {
                id: logindMonitor
                command: ["${lib.getExe' pkgs.dbus "dbus-monitor"}", "--system", "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"]
                running: true
                stdout: SplitParser {
                    onRead: data => {
                        if (data.includes("boolean true")) {
                            lockProc.running = true
                        }
                    }
                }
            }
            Variants {
                model: [
                    { timeout: 240, idleAction: "dpms off", returnAction: "dpms on" },
                    { timeout: 300, idleAction: "lock" },
                    { timeout: 600, idleAction: "suspend" }
                ]
                IdleMonitor {
                    required property var modelData
                    enabled: !audioPlaying.isPlaying && !manualInhibit
                    respectInhibitors: true
                    timeout: modelData.timeout
                    onIsIdleChanged: idleScope.handleIdleAction(isIdle ? modelData.idleAction : modelData.returnAction, isIdle)
                }
            }
        }
      '';

      "quickshell/shell.qml".text = ''
        import QtQuick
        import QtQuick.Layouts
        import Quickshell
        import Quickshell.Io
        import Quickshell.Wayland
        import Quickshell.Bluetooth
        import Quickshell.Services.Pam
        ShellRoot {
            id: root
            IpcHandler {
                target: "powerMenu"
                function toggle(): void {
                    powerMenu.shown = !powerMenu.shown
                }
            }
            IpcHandler {
                target: "lockScreen"
                function toggle(): void {
                    sessionLocked = true
                }
            }
            property bool sessionLocked: false
            LockContext {
                id: lockContext
                onUnlocked: {
                    sessionLocked = false
                }
                onFailed: {
                }
            }
            WlSessionLock {
                id: sessionLock
                locked: sessionLocked
                WlSessionLockSurface {
                    LockSurface {
                        anchors.fill: parent
                        context: lockContext
                    }
                }
            }
            QtObject {
                id: theme
                readonly property color bg: "${c.base00}"
                readonly property color bgAlt: "${c.base01}"
                readonly property color bgLighter: "${c.base02}"
                readonly property color fg: "${c.base05}"
                readonly property color fgMuted: "${c.base04}"
                readonly property color fgSubtle: "${c.base03}"
                readonly property color red: "${c.base08}"
                readonly property color green: "${c.base0B}"
                readonly property color yellow: "${c.base0A}"
                readonly property color blue: "${c.base0D}"
                readonly property color darkBlue: "${c.base0D}"
                readonly property color magenta: "${c.base0E}"
                readonly property color cyan: "${c.base0C}"
                readonly property color orange: "${c.base09}"
                readonly property int radius: 10
                readonly property int borderWidth: 2
                readonly property int padding: 14
                readonly property int spacing: 10
                readonly property string fontFamily: "${config.cfg.fonts.monospace.name}"
                readonly property int fontPixelSize: 12
            }
            QtObject {
                id: idleInhibitorState
                property bool enabled: false
            }
            QtObject { id: dunstDnd; property bool isDnd: false }
            QtObject {
                id: volume
                property int level: 0
                property bool muted: false
            }
            QtObject {
                id: battery
                property int percentage: 0
                property string icon: "󰂎"
                property bool charging: false
                onPercentageChanged: {
                    if (percentage === 0) icon = "󰁹"
                    else if (percentage <= 10) icon = "󰂎"
                    else if (percentage <= 30) icon = "󰁻"
                    else if (percentage <= 50) icon = "󰁽"
                    else if (percentage <= 70) icon = "󰁾"
                    else if (percentage <= 90) icon = "󰂀"
                    else icon = "󰂂"
                }
            }
            QtObject { id: cpu; property int usage: 0 }
            QtObject { id: mem; property int percent: 0 }
            QtObject { id: network; property string icon: "" }
            property var lastCpuIdle: 0
            property var lastCpuTotal: 0
            Process {
                id: dunstProc
                command: ["${getExe' pkgs.dunst "dunstctl"}", "is-paused"]
                stdout: SplitParser {
                    onRead: data => {
                        if (data) dunstDnd.isDnd = data.trim() === "true"
                    }
                }
            }
            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: dunstProc.running = true
            }
            Process {
                id: volumeProc
                command: ["${getExe' pkgs.wireplumber "wpctl"}", "get-volume", "@DEFAULT_AUDIO_SINK@"]
                stdout: SplitParser {
                    onRead: data => {
                        if (!data) return
                        const out = data.trim()
                        volume.muted = out.includes("[MUTED]")
                        const match = out.match(/Volume: ([0-9.]+)/)
                        if (match) volume.level = Math.round(parseFloat(match[1]) * 100)
                    }
                }
            }
            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: volumeProc.running = true
            }
            Timer {
                interval: 10000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    batCapacityProc.running = true
                    batStatusProc.running = true
                }
            }
            Process {
                id: batCapacityProc
                command: ["${getExe pkgs.bash}", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo 0"]
                stdout: SplitParser {
                    onRead: data => {
                        if (data) battery.percentage = parseInt(data.trim()) || 0
                    }
                }
            }
            Process {
                id: batStatusProc
                command: ["${getExe pkgs.bash}", "-c", "cat /sys/class/power_supply/BAT*/status 2>/dev/null || echo Discharging"]
                stdout: SplitParser {
                    onRead: data => {
                        if (data) battery.charging = data.trim() === "Charging"
                    }
                }
            }
            Process {
                id: cpuProc
                command: ["${getExe pkgs.bash}", "-c", "head -1 /proc/stat"]
                stdout: SplitParser {
                    onRead: data => {
                        if (!data) return
                        var parts = data.trim().split(/\s+/)
                        var user = parseInt(parts[1]) || 0
                        var nice = parseInt(parts[2]) || 0
                        var system = parseInt(parts[3]) || 0
                        var idle = parseInt(parts[4]) || 0
                        var iowait = parseInt(parts[5]) || 0
                        var irq = parseInt(parts[6]) || 0
                        var softirq = parseInt(parts[7]) || 0
                        var total = user + nice + system + idle + iowait + irq + softirq
                        var idleTime = idle + iowait
                        if (lastCpuTotal > 0) {
                            var totalDiff = total - lastCpuTotal
                            var idleDiff = idleTime - lastCpuIdle
                            if (totalDiff > 0) {
                                cpu.usage = Math.round(100 * (totalDiff - idleDiff) / totalDiff)
                            }
                        }
                        lastCpuTotal = total
                        lastCpuIdle = idleTime
                    }
                }
            }
            Timer {
                interval: 2000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: cpuProc.running = true
            }
            Process {
                id: memProc
                command: ["${getExe pkgs.bash}", "-c", "${getExe' pkgs.procps "free"} | grep Mem"]
                stdout: SplitParser {
                    onRead: data => {
                        if (!data) return
                        var parts = data.trim().split(/\s+/)
                        var total = parseInt(parts[1]) || 1
                        var used = parseInt(parts[2]) || 0
                        mem.percent = Math.round(100 * used / total)
                    }
                }
            }
            Timer {
                interval: 2000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: memProc.running = true
            }
            Process {
                id: networkProc
                command: ["${getExe pkgs.bash}", "-c", 'if nmcli device status | grep -q "wifi .*connected"; then echo ""; elif nmcli device status | grep -q "ethernet .*connected"; then echo "󰲝"; else echo ""; fi']
                stdout: SplitParser {
                    onRead: data => {
                        if (data) network.icon = data.trim()
                    }
                }
            }
            Timer {
                interval: 5000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: networkProc.running = true
            }
            IdleMonitors {
                manualInhibit: idleInhibitorState.enabled
            }
            PanelWindow {
                anchors {
                    top: true
                    left: true
                    right: true
                }
                implicitHeight: 20
                color: "transparent"
                Process { id: pavuProcess; command: ["${getExe pkgs.pavucontrol}"] }
                Process { id: bluemanProcess; command: ["${getExe' pkgs.blueman "blueman-manager"}"] }
                Process { id: dunstDndProcess; command: ["${getExe' pkgs.dunst "dunstctl"}", "set-paused", "toggle"] }
                Process { id: networkManagerProcess; command: ["${getExe' pkgs.networkmanagerapplet "nm-connection-editor"}"] }
                Rectangle {
                    anchors.fill: parent
                    color: theme.bg
                    RowLayout {
                        anchors.fill: parent
                        spacing: theme.spacing / 2
                        Item { width: theme.padding / 2 }
                        WorkspaceModule {}
                        Item { Layout.fillWidth: true }
                        Text {
                            text: idleInhibitorState.enabled ? "󰛊" : "󰾆"
                            color: idleInhibitorState.enabled ? theme.orange : theme.fgMuted
                            font {
                                family: theme.fontFamily
                                pixelSize: theme.fontPixelSize
                                bold: true
                            }
                            Layout.rightMargin: theme.spacing / 2
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: idleInhibitorState.enabled = !idleInhibitorState.enabled
                            }
                        }
                        Text {
                            id: clockText
                            text: Qt.formatDateTime(new Date(), "HH:mm dd/MM")
                            color: theme.cyan
                            font {
                                family: theme.fontFamily
                                pixelSize: theme.fontPixelSize
                                bold: true
                            }
                            Layout.rightMargin: theme.spacing / 2
                            Timer {
                                interval: 1000
                                running: true
                                repeat: true
                                onTriggered: clockText.text = Qt.formatDateTime(new Date(), "HH:mm dd/MM")
                            }
                        }
                        Rectangle {
                            Layout.preferredWidth: theme.borderWidth
                            Layout.preferredHeight: 16
                            Layout.alignment: Qt.AlignVCenter
                            Layout.leftMargin: 0
                            Layout.rightMargin: theme.spacing / 2
                            color: theme.fgSubtle
                        }
                        Text {
                            text: " " + cpu.usage + "%"
                            color: cpu.usage > 85 ? theme.red : theme.green
                            font {
                                family: theme.fontFamily
                                pixelSize: theme.fontPixelSize
                                bold: true
                            }
                            Layout.rightMargin: theme.spacing / 2
                        }
                        Text {
                            text: " " + mem.percent + "%"
                            color: mem.percent > 85 ? theme.red : theme.cyan
                            font {
                                family: theme.fontFamily
                                pixelSize: theme.fontPixelSize
                                bold: true
                            }
                            Layout.rightMargin: theme.spacing / 2
                        }
                        Rectangle {
                            Layout.preferredWidth: theme.borderWidth
                            Layout.preferredHeight: 16
                            Layout.alignment: Qt.AlignVCenter
                            Layout.leftMargin: 0
                            Layout.rightMargin: theme.spacing / 2
                            color: theme.fgSubtle
                        }
                        Text {
                            text: volume.muted ? " Muted " : " " + " " + volume.level + "%"
                            color: volume.muted ? theme.fgSubtle : theme.darkBlue
                            font {
                                family: theme.fontFamily
                                pixelSize: theme.fontPixelSize
                                bold: true
                            }
                            Layout.rightMargin: theme.spacing / 2
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: pavuProcess.running = true
                            }
                        }
                        Text {
                            text: {
                                if (!Bluetooth.defaultAdapter) return "󰂲";
                                if (!Bluetooth.defaultAdapter.enabled) return "󰂲";
                                let connectedCount = 0;
                                for (let i = 0; i < Bluetooth.devices.count; i++) {
                                    let device = Bluetooth.devices.get(i);
                                    if (device.connected) connectedCount++;
                                }
                                if (connectedCount > 0) return "󰂯 " + connectedCount;
                                return "󰂯";
                            }
                            color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? theme.cyan : theme.fgMuted
                            font {
                                family: theme.fontFamily
                                pixelSize: theme.fontPixelSize
                                bold: true
                            }
                            Layout.rightMargin: theme.spacing / 2
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: bluemanProcess.running = true
                            }
                        }
                        Text {
                            text: network.icon
                            color: network.icon === "󰤬" ? theme.red : theme.blue
                            font {
                                family: theme.fontFamily
                                pixelSize: theme.fontPixelSize
                                bold: true
                            }
                            Layout.rightMargin: theme.spacing / 2
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: networkManagerProcess.running = true
                            }
                        }
                        Text {
                            text: dunstDnd.isDnd ? "󰂛" : "󰂚"
                            color: dunstDnd.isDnd ? theme.red : theme.yellow
                            font {
                                family: theme.fontFamily
                                pixelSize: theme.fontPixelSize
                                bold: dunstDnd.isDnd
                            }
                            Layout.rightMargin: theme.spacing / 2
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: dunstDndProcess.running = true
                            }
                        }
                        Text {
                            visible: battery.percentage > 0
                            text: battery.icon + " " + battery.percentage + "%" + (battery.charging ? " 󰂄" : "")
                            color: battery.percentage <= 15 ? theme.red : battery.percentage <= 30 ? theme.yellow : theme.green
                            font {
                                family: theme.fontFamily
                                pixelSize: theme.fontPixelSize
                            }
                            Layout.rightMargin: theme.spacing / 2
                        }
                        Text {
                            text: "⏻"
                            color: theme.fg
                            font {
                                family: theme.fontFamily
                                pixelSize: theme.fontPixelSize
                            }
                            Layout.rightMargin: theme.spacing / 2
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: powerMenu.shown = true
                            }
                        }
                        Item { width: theme.padding / 2 }
                    }
                }
            }
            PowerMenu {
                id: powerMenu
                PowerButton {
                    command: "${getExe pkgs.quickshell} ipc call lockScreen toggle"
                    text: "Lock"
                    icon: "lock"
                }
                PowerButton {
                    command: "loginctl kill-session $XDG_SESSION_ID"
                    text: "Exit"
                    icon: "logout"
                }
                PowerButton {
                    command: "${getExe' pkgs.systemd "systemctl"} poweroff"
                    text: "Shutdown"
                    icon: "shutdown"
                }
                PowerButton {
                    command: "${getExe' pkgs.systemd "systemctl"} suspend"
                    text: "Suspend"
                    icon: "suspend"
                }
                PowerButton {
                    command: "${getExe' pkgs.systemd "systemctl"} reboot"
                    text: "Reboot"
                    icon: "reboot"
                }
            }
        }
      '';

      "quickshell/wallpaper.png".source = ../assests/Wallpapers/a6116535-4a72-453e-83c9-ea97b8597d8c.png;

      "quickshell/pam/password.conf".text = ''
        auth required pam_unix.so
      '';

      "quickshell/LockContext.qml".text = ''
        import QtQuick
        import Quickshell
        import Quickshell.Services.Pam

        Scope {
            id: root
            signal unlocked()
            signal failed()

            property string currentText: ""
            property bool unlockInProgress: false
            property bool showFailure: false

            onCurrentTextChanged: showFailure = false;

            function tryUnlock() {
                if (currentText === "") ;
                root.unlockInProgress = true;
                pam.start();
            }

            PamContext {
                id: pam

                configDirectory: "pam"
                config: "password.conf"

                onPamMessage: {
                    if (this.responseRequired) {
                        this.respond(root.currentText);
                    }
                }

                onCompleted: result => {
                    if (result == PamResult.Success) {
                        root.unlocked();
                    } else {
                        root.currentText = "";
                        root.showFailure = true;
                        root.failed();
                    }
                    root.unlockInProgress = false;
                }
            }
        }
      '';

      "quickshell/LockSurface.qml".text = ''
        import QtQuick
        import QtQuick.Layouts
        import QtQuick.Controls
        import Quickshell.Wayland

        Rectangle {
            id: root
            required property LockContext context

            color: "${c.base00}"
            Image {
                anchors.fill: parent
                source: "wallpaper.png"
                fillMode: Image.PreserveAspectFit
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    id: clockLabel
                    property var currentDate: new Date()
                    text: Qt.formatTime(currentDate, "HH:mm")
                    color: "${c.base06}"
                    font.pixelSize: 72
                    font.family: "${config.cfg.fonts.monospace.name}"
                    font.bold: true
                    style: Text.Outline
                    styleColor: Qt.rgba(0, 0, 0, 0.8)
                    Layout.alignment: Qt.AlignHCenter

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: clockLabel.currentDate = new Date()
                    }
                }

                Text {
                    id: dateLabel
                    property var currentDate: new Date()
                    text: Qt.formatDate(currentDate, "dd/MM/yyyy")
                    color: "${c.base04}"
                    font.pixelSize: 24
                    font.family: "${config.cfg.fonts.monospace.name}"
                    Layout.alignment: Qt.AlignHCenter

                    Timer {
                        interval: 60000
                        running: true
                        repeat: true
                        onTriggered: dateLabel.currentDate = new Date()
                    }
                }

                Text {
                    text: "Enter Password"
                    color: "${c.base05}"
                    font.pixelSize: 18
                    font.family: "${config.cfg.fonts.monospace.name}"
                    Layout.alignment: Qt.AlignHCenter
                }

                RowLayout {
                    spacing: 10
                    Layout.alignment: Qt.AlignHCenter

                    TextField {
                        id: passwordBox
                        implicitWidth: 300
                        padding: 15
                        focus: true
                        enabled: !root.context.unlockInProgress
                        echoMode: TextInput.Password
                        inputMethodHints: Qt.ImhSensitiveData
                        color: "${c.base05}"
                        background: Rectangle {
                            color: Qt.rgba(46/255, 52/255, 64/255, 0.85)
                            border.color: "${c.base0D}"
                            border.width: 2
                            radius: 10
                        }
                        onTextChanged: root.context.currentText = this.text;
                        onAccepted: root.context.tryUnlock();

                        Connections {
                            target: root.context
                            function onCurrentTextChanged() {
                                passwordBox.text = root.context.currentText;
                            }
                        }
                    }

                    Button {
                        text: "Unlock"
                        padding: 12
                        focusPolicy: Qt.NoFocus
                        enabled: !root.context.unlockInProgress && root.context.currentText !== ""
                        onClicked: root.context.tryUnlock();
                        contentItem: Text {
                            text: parent.text
                            color: "${c.base00}"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 16
                            font.bold: true
                            font.family: "${config.cfg.fonts.monospace.name}"
                        }
                        background: Rectangle {
                            color: parent.down ? "${c.base0B}" : (parent.hovered ? "${c.base0C}" : "${c.base0D}")
                            radius: 8
                        }
                    }
                }

                Text {
                    visible: root.context.showFailure
                    text: "Incorrect password"
                    color: "${c.base08}"
                    font.pixelSize: 14
                    font.family: "${config.cfg.fonts.monospace.name}"
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
      '';
    };
  };
}

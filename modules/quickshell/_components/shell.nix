{
  pkgs,
  lib,
  fontFamily,
  colors,
  ...
}:
let
  inherit (lib) getExe getExe';
  c = colors;
in
''
  import QtQuick
  import QtQuick.Layouts
  import QtQuick.Effects
  import Quickshell
  import Quickshell.Io
  import Quickshell.Wayland
  import Quickshell.Bluetooth
  import Quickshell.Services.Pam
  import Quickshell.Services.Notifications
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
      NotificationServer {
          id: notificationServer
          actionsSupported: true
          bodySupported: true
          bodyMarkupSupported: true
          imageSupported: true
          persistenceSupported: true
          keepOnReload: true

          onNotification: notification => {
              notification.tracked = true
          }
      }

      NotificationPopups {
          id: notificationPopups
      }

      NotificationCenter {
          id: notificationCenter
          notifServer: notificationServer
          theme: theme
      }

      ControlCenter {
          id: controlCenter
          theme: theme
          volumeObj: volume
          batteryObj: battery
      }

      IpcHandler {
          target: "notificationCenter"
          function toggle(): void {
              notificationCenter.toggle()
          }
      }

      IpcHandler {
          target: "controlCenter"
          function toggle(): void {
              controlCenter.toggle()
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
          readonly property color blue: "${c.base0F}"
          readonly property color darkBlue: "${c.base0D}"
          readonly property color magenta: "${c.base0E}"
          readonly property color cyan: "${c.base04}"
          readonly property color orange: "${c.base09}"
          readonly property int radius: 12
          readonly property int borderWidth: 2
          readonly property int padding: 14
          readonly property int spacing: 10
          readonly property string fontFamily: "${fontFamily}"
          readonly property int fontPixelSize: 12
      }
      QtObject {
          id: idleInhibitorState
          property bool enabled: false
      }
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
          id: barWindow
          anchors {
              top: true
              left: true
              right: true
          }
          implicitHeight: 20
          color: "transparent"
          Process { id: pavuProcess; command: ["${getExe pkgs.pavucontrol}"] }
          Process { id: bluemanProcess; command: ["${getExe' pkgs.blueman "blueman-manager"}"] }
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
                      color: theme.darkBlue
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
                      color: mem.percent > 85 ? theme.red : theme.green
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
                      color: volume.muted ? theme.fgSubtle : theme.blue
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
                      color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? theme.darkBlue : theme.blue
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
                      color: network.icon === "󰤬" ? theme.red : theme.darkBlue
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
                      text: notificationServer.trackedNotifications.count > 0 ? "󰂛" : "󰂚"
                      color: notificationServer.trackedNotifications.count > 0 ? theme.yellow : theme.fgMuted
                      font {
                          family: theme.fontFamily
                          pixelSize: theme.fontPixelSize
                          bold: notificationServer.trackedNotifications.count > 0
                      }
                      Layout.rightMargin: theme.spacing / 2
                      MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: notificationCenter.shown = !notificationCenter.shown
                      }
                  }
                  Text {
                      text: "󰜎"
                      color: controlCenter.shown ? theme.darkBlue : theme.fgMuted
                      font {
                          family: theme.fontFamily
                          pixelSize: theme.fontPixelSize
                          bold: controlCenter.shown
                      }
                      Layout.rightMargin: theme.spacing / 2
                      MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: controlCenter.toggle()
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
                      color: theme.cyan
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

      Loader {
          id: wallpaperLoader
          source: "Wallpaper.qml"
      }

      Loader {
          id: overviewWallpaperLoader
          source: "OverviewWallpaper.qml"
      }
  }
''

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
/* qml */ ''
  //@ pragma ShellId stellar
  //@ pragma IconTheme FairyWren_Dark
  import QtQuick
  import QtQuick.Layouts
  import QtQuick.Effects
  import Quickshell
  import Quickshell.Io
  import Quickshell.Wayland
  import Quickshell.Bluetooth
  import Quickshell.Services.Pam
  import Quickshell.Services.Notifications
  import Quickshell.Networking
  import Quickshell.Services.Pipewire
  import Quickshell.Services.Polkit
  import "BatteryMonitor.qml"
  import "Clipboard.qml"

  ShellRoot {
      id: root
      IpcHandler {
          target: "powerMenu"
          function toggle(): void {
              powerMenu.shown = !powerMenu.shown
          }
      }
      property var notificationHistory: []

      function resolveIcon(name) {
          if (!name) return ""
          var ic = String(name)
          if (ic.startsWith("file://")) return ic
          if (ic.startsWith("/")) {
              if (ic.indexOf("/nix/store/") === 0) {
                  var base = ic.split("/").pop().replace(/\.[^.]+$/, "")
                  return Quickshell.iconPath(base, true)
              }
              return "file://" + ic
          }
          return Quickshell.iconPath(ic, true)
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
              var entry = {
                  id: notification.id,
                  appName: notification.appName || "",
                  summary: notification.summary || "",
                  body: notification.body || "",
                  urgency: notification.urgency !== undefined ? notification.urgency : 1,
                  appIcon: root.resolveIcon(notification.appIcon || ""),
                  image: notification.image || "",
                  time: Date.now()
              }
              // keep a reasonable history limit (inspired by Caelestia)
              var h = [entry].concat(root.notificationHistory)
              if (h.length > 80) h = h.slice(0, 80)
              root.notificationHistory = h
          }
      }

      NotificationPopups {
          id: notificationPopups
          dndEnabled: controlCenter.dndEnabled
      }

      NotificationCenter {
          id: notificationCenter
          notifServer: notificationServer
          theme: theme
          history: root.notificationHistory
          onClearHistory: root.notificationHistory = []
          onRemoveEntry: index => {
              var h = root.notificationHistory.slice()
              h.splice(index, 1)
              root.notificationHistory = h
          }
      }

      ControlCenter {
          id: controlCenter
          theme: theme
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
      IpcHandler {
          target: "launcher"
          function toggle(): void {
              if (launcherLoader.item) {
                  launcherLoader.item.toggle()
              }
          }
          function openClipboard(): void {
              clipboard.open()
          }
          function clearClipboard(): void {
              clipboard.clear()
          }
      }
      IpcHandler {
          target: "clipboard"
          function toggle(): void {
              clipboard.toggle()
          }
          function open(): void {
              clipboard.open()
          }
          function clear(): void {
              clipboard.clear()
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
      PwObjectTracker {
          objects: [Pipewire.defaultAudioSink]
      }
      QtObject {
          id: volume
          readonly property int level: Math.round((Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100)
          readonly property bool muted: Pipewire.defaultAudioSink?.audio?.muted ?? false
      }

      QtObject {
          id: battery
          property int percentage: BatteryMonitor.percentage
          property string icon: BatteryMonitor.getBatteryIcon()
          property bool charging: BatteryMonitor.isCharging
          property bool hasBattery: BatteryMonitor.hasBattery
      }
      QtObject { id: cpu; property int usage: 0 }
      QtObject { id: mem; property int percent: 0 }
      QtObject {
          id: network
          readonly property var wiredDevice: {
              for (const d of Networking.devices.values) {
                  if (d.type === DeviceType.Wired) return d
              }
              return null
          }
          readonly property var wifiDevice: {
              for (const d of Networking.devices.values) {
                  if (d.type === DeviceType.Wifi) return d
              }
              return null
          }
          readonly property var activeWifiNetwork: {
              if (!wifiDevice) return null
              for (const n of wifiDevice.networks.values) {
                  if (n.connected) return n
              }
              return null
          }
          readonly property bool connected: (wiredDevice?.connected ?? false) || (wifiDevice?.connected ?? false)
          readonly property string type: {
              if (wiredDevice?.connected) return "ethernet"
              if (wifiDevice?.connected) return "wifi"
              if (connected) return "other"
              return "none"
          }
          readonly property int strength: activeWifiNetwork ? Math.round(activeWifiNetwork.signalStrength * 100) : 0
          readonly property string ssid: activeWifiNetwork?.name ?? ""
          readonly property string icon: {
              if (!Networking.wifiEnabled) return "󰤮"
              if (type === "ethernet") return "󰈀"
              if (type === "wifi") {
                  if (strength < 25) return "󰤟"
                  if (strength < 50) return "󰤢"
                  if (strength < 75) return "󰤥"
                  return "󰤨"
              }
              return "󰤭"
          }
      }
      property var lastCpuIdle: 0
      property var lastCpuTotal: 0
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
      IdleMonitors {
          inhibit: idleInhibitorState.enabled
          window: barWindow
      }
      PolkitDialog { }
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
          Process { id: calendarProcess; command: ["${getExe pkgs.thunderbird}", "-calendar"] }
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
                      text: network.icon
                      color: !network.connected ? theme.fgMuted : (network.type === "ethernet" ? theme.darkBlue : theme.blue)
                      font {
                          family: theme.fontFamily
                          pixelSize: theme.fontPixelSize
                          bold: true
                      }
                      Layout.rightMargin: theme.spacing / 2
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
                      color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? theme.darkBlue : theme.fgSubtle
                      font {
                          family: theme.fontFamily
                          pixelSize: theme.fontPixelSize
                          bold: true
                      }
                      Layout.rightMargin: theme.spacing / 2
                  }
                  Text {
                      text: volume.muted ? " " : (volume.level === 0 ? " " : " ")
                      color: (volume.muted || volume.level === 0) ? theme.fgSubtle : theme.blue
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
                      text: controlCenter.dndEnabled ? "󰂛" : "󰂚"
                      color: {
                          const hasNotifs = root.notificationHistory.length > 0
                          const dnd = controlCenter.dndEnabled
                          if (hasNotifs && dnd) return theme.red
                          if (hasNotifs)        return theme.yellow
                          return theme.fgMuted
                      }
                      font {
                          family: theme.fontFamily
                          pixelSize: theme.fontPixelSize
                          bold: root.notificationHistory.length > 0
                      }
                      Layout.rightMargin: theme.spacing / 2
                      MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: notificationCenter.shown = !notificationCenter.shown
                      }
                  }
                  Text {
                      text: ""
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
                      visible: battery.hasBattery
                      text: battery.icon + " " + battery.percentage + "%"
                      color: battery.percentage <= 20 ? theme.red : battery.percentage <= 35 ? theme.yellow : theme.green
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
              }
              Text {
                  id: clockText
                  anchors.centerIn: parent
                  text: Qt.formatDateTime(new Date(), "ddd HH:mm dd/MM")
                  color: theme.darkBlue
                  font {
                      family: theme.fontFamily
                      pixelSize: theme.fontPixelSize
                      bold: true
                  }
                  Timer {
                      interval: 1000
                      running: true
                      repeat: true
                      onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd HH:mm dd/MM")
                  }
                  MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: calendarProcess.running = true
                  }
              }
          }
      }
      PowerMenu {
          id: powerMenu
          PowerButton {
              command: "qylock-lock"
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
          id: wallpaperPickerLoader
          source: "WallpaperPicker.qml"

          onLoaded: {
              if (item) {
                  item.wallpaperLoader = wallpaperLoader
                  item.overviewWallpaperLoader = overviewWallpaperLoader
              }
          }
      }

      IpcHandler {
          target: "wallpaperPicker"
          function toggle(): void {
              if (wallpaperPickerLoader.item) {
                  wallpaperPickerLoader.item.shown = !wallpaperPickerLoader.item.shown
              }
          }
      }

      Loader {
          id: overviewWallpaperLoader
          source: "OverviewWallpaper.qml"
      }

      Loader {
          id: launcherLoader
          source: "Launcher.qml"
          property var theme: theme
      }

      Clipboard {
          id: clipboard
      }
  }
''

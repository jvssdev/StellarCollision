{
  pkgs,
  lib,
  ...
}:

/* qml */ ''
  pragma Singleton
  pragma ComponentBehavior: Bound

  import QtQuick
  import Quickshell
  import Quickshell.Services.UPower
  import Quickshell.Io

  Singleton {
    id: root

    property var mainBattery: null

    readonly property bool hasBattery: mainBattery !== null
    readonly property int percentage: mainBattery ? Math.round(mainBattery.percentage * 100) : 0
    readonly property int state: mainBattery ? mainBattery.state : UPowerDeviceState.Unknown
    readonly property bool isCharging: state === UPowerDeviceState.Charging
    property bool lowBatteryNotified: false
    property bool fullBatteryNotified: false

    Component.onCompleted: {
        console.log("BatteryMonitor loaded, hasBattery=" + root.hasBattery + " percentage=" + root.percentage)
        Qt.callLater(root.checkBatteryLevel)
    }

    Instantiator {
      model: UPower.devices
      delegate: QtObject {
        required property var modelData
        Component.onCompleted: checkDevice()
        function checkDevice() {
          console.log("UPower device found: isLaptopBattery=" + modelData.isLaptopBattery)
          if (modelData && modelData.isLaptopBattery) {
            root.mainBattery = modelData
            console.log("Battery set, percentage=" + root.percentage)
          }
        }
      }
    }

    function getBatteryIcon() {
      if (root.isCharging) return "󰂄"
      const p = root.percentage
      if (p >= 90) return "󰁹"
      if (p >= 60) return "󰂀"
      if (p >= 40) return "󰁾"
      if (p >= 10) return "󰁼"
      return "󰁺"
    }

    Timer {
      interval: 5000
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        console.log("BatteryMonitor timer triggered, hasBattery=" + root.hasBattery + " percentage=" + root.percentage)
        if (root.hasBattery) {
          root.checkBatteryLevel();
        }
      }
    }

    function checkBatteryLevel() {
      if (!root.mainBattery) return;
      
      const percentage = root.percentage;
      const charging = root.isCharging;

      console.log("Battery check: " + percentage + "% charging=" + charging);

      if (percentage <= 60 && !charging && !root.lowBatteryNotified) {
        root.sendLowBatteryNotification(percentage);
        root.lowBatteryNotified = true;
      } else if (percentage > 60 || charging) {
        root.lowBatteryNotified = false;
      }

      if (percentage >= 100 && !charging && !root.fullBatteryNotified) {
        root.sendFullBatteryNotification();
        root.fullBatteryNotified = true;
      } else if (percentage < 100) {
        root.fullBatteryNotified = false;
      }
    }

    function sendLowBatteryNotification(percentage) {
      var title = "Low Battery";
      var message = "Battery is at " + percentage + "%. Please plug in your charger.";
      var urgency = "critical";

      Quickshell.execDetached(["notify-send", "-u", urgency, "-i", "battery-low", title, message]);
    }

    function sendFullBatteryNotification() {
      var title = "Battery Full";
      var message = "Battery is fully charged. You can unplug the charger.";
      var urgency = "normal";

      Quickshell.execDetached(["notify-send", "-u", urgency, "-i", "battery-full", title, message]);
    }
  }
''

_:

/* qml */ ''
  pragma Singleton
  pragma ComponentBehavior: Bound

  import QtQuick
  import Quickshell
  import Quickshell.Services.UPower
  import Quickshell.Io

  Singleton {
    id: batteryMonitor

    property var mainBattery: null

    readonly property bool hasBattery: mainBattery !== null
    readonly property int percentage: mainBattery ? Math.round(mainBattery.percentage * 100) : 0
    readonly property int state: mainBattery ? mainBattery.state : UPowerDeviceState.Unknown
    readonly property bool isCharging: state === UPowerDeviceState.Charging
    property bool lowBatteryNotified: false
    property bool fullBatteryNotified: false

    Component.onCompleted: {
        Qt.callLater(batteryMonitor.checkBatteryLevel)
    }

    Instantiator {
      model: UPower.devices
      delegate: QtObject {
        required property var modelData
        Component.onCompleted: checkDevice()
        function checkDevice() {
          if (modelData && modelData.isLaptopBattery) {
            batteryMonitor.mainBattery = modelData
          }
        }
      }
    }

    function getBatteryIcon() {
      if (batteryMonitor.isCharging) return "󰂄"
      const p = batteryMonitor.percentage
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
        if (batteryMonitor.hasBattery) {
          batteryMonitor.checkBatteryLevel();
        }
      }
    }

    function checkBatteryLevel() {
      if (!batteryMonitor.mainBattery) return;

      const percentage = batteryMonitor.percentage;
      const charging = batteryMonitor.isCharging;

      if (percentage <= 20 && !charging && !batteryMonitor.lowBatteryNotified) {
        batteryMonitor.sendLowBatteryNotification(percentage);
        batteryMonitor.lowBatteryNotified = true;
      } else if (percentage > 20 || charging) {
        batteryMonitor.lowBatteryNotified = false;
      }

      // if (percentage >= 100 && !charging && !batteryMonitor.fullBatteryNotified) {
      //   batteryMonitor.sendFullBatteryNotification();
      //   batteryMonitor.fullBatteryNotified = true;
      // } else if (percentage < 100) {
      //   batteryMonitor.fullBatteryNotified = false;
      // }
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

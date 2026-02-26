_:

/* qml */ ''
  pragma Singleton

  import QtQuick
  import Quickshell
  import Quickshell.Bluetooth
  import Quickshell.Io

  Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter

    readonly property bool available: root.adapter !== null
    readonly property bool enabled: root.adapter ? root.adapter.enabled : false
    readonly property bool discovering: root.adapter ? root.adapter.discovering : false

    readonly property var devices: {
      if (!root.adapter || !root.adapter.devices) {
        return [];
      }
      return root.adapter.devices.values || [];
    }

    readonly property var pairedDevices: {
      return root.devices.filter(dev => dev && (dev.paired || dev.trusted));
    }

    readonly property int activeDeviceCount: {
      var count = 0;
      var devs = root.devices;
      for (var i = 0; i < devs.length; i++) {
        if (devs[i] && devs[i].connected) count++;
      }
      return count;
    }

    readonly property string firstDeviceName: {
      var devs = root.devices;
      for (var i = 0; i < devs.length; i++) {
        if (devs[i] && devs[i].connected) {
          return devs[i].name || devs[i].alias || "Device";
        }
      }
      return "";
    }

    function setBluetoothEnabled(state) {
      if (!root.adapter) return;
      try {
        root.adapter.enabled = state;
      } catch (e) {}
    }

    function setScanActive(active) {
      if (!root.adapter) return;

      if (active) {
        try {
          root.adapter.enabled = true;
        } catch (e) {}

        scanDelayTimer.start();
      } else {
        try {
          root.adapter.discovering = false;
          root.adapter.discoverable = false;
        } catch (e) {}
        scanDelayTimer.stop();
      }
    }

    Timer {
      id: scanDelayTimer
      interval: 1000
      repeat: false
      onTriggered: {
        if (!root.adapter || !root.adapter.enabled) return;
        try {
          root.adapter.discoverable = true;
          root.adapter.discovering = true;
        } catch (e) {}
      }
    }

    function toggle() {
      if (root.adapter) {
        root.adapter.enabled = !root.adapter.enabled;
      }
    }

    function getDeviceIcon(device) {
      if (!device) return "bluetooth";
      var name = (device.name || device.alias || "").toLowerCase();
      var icon = (device.icon || "").toLowerCase();

      if (icon.indexOf("headset") !== -1 || name.indexOf("headset") !== -1 ||
          icon.indexOf("airpod") !== -1 || name.indexOf("airpod") !== -1 ||
          icon.indexOf("headphone") !== -1 || name.indexOf("headphone") !== -1) {
        return "headset";
      }
      if (icon.indexOf("mouse") !== -1 || name.indexOf("mouse") !== -1) return "mouse";
      if (icon.indexOf("keyboard") !== -1 || name.indexOf("keyboard") !== -1) return "keyboard";
      if (icon.indexOf("phone") !== -1 || name.indexOf("iphone") !== -1) return "phone";
      if (icon.indexOf("watch") !== -1 || name.indexOf("watch") !== -1) return "watch";
      if (icon.indexOf("speaker") !== -1 || name.indexOf("speaker") !== -1) return "speaker";
      if (icon.indexOf("display") !== -1 || icon.indexOf("tv") !== -1) return "tv";

      return "bluetooth";
    }

    function canConnect(device) {
      if (!device) return false;
      return !device.connected && (device.paired || device.trusted) && !device.pairing && !device.blocked;
    }

    function canDisconnect(device) {
      if (!device) return false;
      return device.connected && !device.pairing && !device.blocked;
    }

    function canPair(device) {
      if (!device) return false;
      return !device.connected && !device.paired && !device.trusted && !device.pairing && !device.blocked;
    }

    function isDeviceBusy(device) {
      if (!device) return false;
      return device.pairing || device.state === 2 || device.state === 3;
    }

    function connectDevice(device) {
      if (!device) return;
      console.log("DEBUG: connectDevice, device=" + (device.name || device.address));

      try {
        device.connect();
      } catch (e) {
        console.log("connectDevice error: " + e);
      }
    }

    function disconnectDevice(device) {
      if (!device) return;
      try {
        device.disconnect();
      } catch (e) {}
    }

    function connectDeviceWithTrust(device) {
      if (!device) return;
      console.log("connectDeviceWithTrust: " + (device.name || device.address));

      try {
        device.trusted = true;
        device.connect();
      } catch (e) {
        console.log("connectDeviceWithTrust error: " + e);
      }
    }

    function forgetDevice(device) {
      if (!device) return;
      try {
        device.forget();
      } catch (e) {}
    }

    function pairDevice(device) {
      if (!device) return;
      console.log("pairDevice: " + (device.name || device.address));

      try {
        device.pair();
      } catch (e) {
        console.log("pairDevice error: " + e);
      }
    }

    property int pairWaitSeconds: 45
    property int connectAttempts: 3
    property int connectRetryIntervalMs: 2000

    Process {
      id: pairingProcess
      running: false
      command: []
      stdout: SplitParser {
        onRead: function(data) {
          console.log("Pair output: " + data);
        }
      }
      onExited: function() {
        console.log("Pairing process finished");
      }
    }

    property int _refreshCounter: 0

    function refreshDevices() {
      root._refreshCounter = root._refreshCounter + 1;
    }

    Timer {
      id: autoRefreshTimer
      interval: 5000
      running: true
      repeat: true
      onTriggered: {
        root.refreshDevices();
      }
    }
  }
''

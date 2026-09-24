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

    // Like awesome-setup: always show paired/connected; during scan show everything else too
    readonly property var visibleDevices: {
      var all = root.devices;
      if (!all || all.length === 0) return [];
      if (root.discovering) return all;
      return all.filter(function(dev) {
        if (!dev) return false;
        return dev.connected || dev.paired || dev.trusted;
      });
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
      if (!device) return "󰂯";
      var name = (device.name || device.alias || device.deviceName || "").toLowerCase();
      var icon = (device.icon || "").toLowerCase();

      // Prefer Nerd Font icons (same style as awesome-setup)
      if (icon.indexOf("headset") !== -1 || name.indexOf("headset") !== -1 ||
          icon.indexOf("airpod") !== -1 || name.indexOf("airpod") !== -1 ||
          name.indexOf("buds") !== -1 || name.indexOf("xm") !== -1 ||
          icon.indexOf("headphone") !== -1 || name.indexOf("headp") !== -1) {
        return "󰋋";
      }
      if (icon.indexOf("mouse") !== -1 || name.indexOf("mouse") !== -1 ||
          name.indexOf("master") !== -1 || name.indexOf("trackpad") !== -1) return "󰍽";
      if (icon.indexOf("keyboard") !== -1 || name.indexOf("key") !== -1) return "󰌌";
      if (icon.indexOf("phone") !== -1 || name.indexOf("iphone") !== -1) return "󰄜";
      if (icon.indexOf("watch") !== -1 || name.indexOf("watch") !== -1) return "󰢐";
      if (icon.indexOf("speaker") !== -1 || name.indexOf("speaker") !== -1) return "󰓃";
      if (icon.indexOf("display") !== -1 || icon.indexOf("tv") !== -1) return "󰟴";

      return "󰂯";
    }

    function getBatteryPercent(device) {
      if (!device || !device.batteryAvailable) return -1;
      return Math.round(device.battery * 100);
    }

    function getBatteryText(device) {
      var pct = root.getBatteryPercent(device);
      return pct >= 0 ? (pct + "%") : "";
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

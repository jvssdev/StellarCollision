{ lib, pkgs, ... }:
let
  inherit (lib) ;
in
''
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
      id: stateCheckTimer
      interval: 500
      repeat: true
      running: true
      onTriggered: {
        if (root.adapter && root.adapter.enabled && !root.adapter.discovering) {
          scanDelayTimer.start();
        }
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
      return !device.paired && !device.pairing && !device.blocked;
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
      var address = device.address || device.addresses;
      if (!address) return;
      
      console.log("DEBUG: connectDevice, address=" + address);
      
      var logFile = "/tmp/bluetooth-pair-" + address.replace(/:/g, "-") + ".log";
      var scriptPath = "/run/current-system/sw/bin/bluetooth-pair";
      
      Quickshell.execDetached(["bash", "-c", 
        "bluetoothctl remove " + address + " 2>/dev/null; " +
        "sleep 0.5; " +
        "python3 " + scriptPath + " " + address + " 45 3 2 > " + logFile + " 2>&1 &"]);
    }

    function disconnectDevice(device) {
      if (!device) return;
      var address = device.address || device.addresses;
      if (address) {
        Quickshell.execDetached(["bluetoothctl", "disconnect", address]);
      }
    }

    function forgetDevice(device) {
      if (!device) return;
      var address = device.address || device.addresses;
      if (address) {
        Quickshell.execDetached(["bluetoothctl", "remove", address]);
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

    function pairDevice(device) {
      if (!device) return;
      var address = device.address || device.addresses;
      if (!address) {
        address = device.name;
      }
      console.log("DEBUG: pairDevice called, address=" + address);
      
      var scriptPath = "/run/current-system/sw/bin/bluetooth-pair";
      var logFile = "/tmp/bluetooth-pair-" + address.replace(/:/g, "-") + ".log";
      
      var cmd = "python3 " + scriptPath + " " + address + " 45 3 2 > " + logFile + " 2>&1 &";
      console.log("DEBUG: Running: " + cmd);
      
      Quickshell.execDetached(["bash", "-c", cmd]);
    }
  }
''

{ lib, ... }:
let
  inherit (lib) getExe getExe';
in
''
  pragma Singleton

  import QtQuick
  import Quickshell
  import Quickshell.Bluetooth
  import Quickshell.Io

  Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter

    property bool ctlAvailable: false
    readonly property bool bluetoothAvailable: !!adapter || root.ctlAvailable
    readonly property bool enabled: adapter ? adapter.enabled : root.ctlPowered
    property bool ctlPowered: false
    property bool ctlDiscovering: false
    property bool ctlDiscoverable: false

    readonly property bool scanningActive: adapter ? (adapter.discovering || root.ctlDiscovering) : root.ctlDiscovering
    readonly property bool discoverable: adapter ? adapter.discoverable : root.ctlDiscoverable

    property var discoveredDevices: []

    readonly property var devices: {
      if (adapter && adapter.devices && adapter.devices.count > 0) {
        var result = [];
        for (var i = 0; i < adapter.devices.count; i++) {
          result.push(adapter.devices.get(i));
        }
        return result;
      }
      return root.discoveredDevices;
    }

    readonly property var connectedDevices: {
      if (!adapter || !adapter.devices) {
        return [];
      }
      var result = [];
      for (var i = 0; i < adapter.devices.count; i++) {
        var dev = adapter.devices.get(i);
        if (dev && dev.connected) {
          result.push(dev);
        }
      }
      return result;
    }

    Timer {
      id: initDelayTimer
      interval: 3000
      running: true
      repeat: false
      onTriggered: pollCtlState()
    }

    Timer {
      id: pollTimer
      interval: 5000
      repeat: true
      running: true
      onTriggered: pollCtlState()
    }

    Component.onCompleted: {
      pollCtlState();
    }

    function pollCtlState() {
      if (!adapter && !ctlAvailable) {
        ctlShowProcess.running = true;
        return;
      }
      ctlShowProcess.running = true;
    }

    Process {
      id: ctlShowProcess
      command: ["bluetoothctl", "show"]
      running: false
      stdout: StdioCollector {
        id: ctlStdout
      }
      onExited: function() {
        try {
          var text = ctlStdout.text || "";
          var lines = text.split('\n');
          var foundController = false;
          var powered = false;
          var discoverable = false;
          var discovering = false;

          for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line.indexOf("Controller") === 0) {
              foundController = true;
            }
            var mp = line.match(/\bPowered:\s*(yes|no)\b/i);
            if (mp) powered = (mp[1].toLowerCase() === "yes");
            var md = line.match(/\bDiscoverable:\s*(yes|no)\b/i);
            if (md) discoverable = (md[1].toLowerCase() === "yes");
            var ms = line.match(/\bDiscovering:\s*(yes|no)\b/i);
            if (ms) discovering = (ms[1].toLowerCase() === "yes");
          }

          root.ctlAvailable = foundController;
          root.ctlPowered = powered;
          root.ctlDiscoverable = discoverable;
          root.ctlDiscovering = discovering;
        } catch (e) {}
      }
    }

    Process {
      id: btPowerOnProcess
      command: ["bluetoothctl", "power", "on"]
    }

    Process {
      id: bluetoothctlScanProcess
      command: ["bluetoothctl", "scan", "on"]
    }

    Process {
      id: devicesListProcess
      command: ["bluetoothctl", "devices"]
      running: false
      stdout: StdioCollector {
        id: devicesStdout
      }
      onExited: function() {
        try {
          var text = devicesStdout.text || "";
          var lines = text.split('\n');
          var devicesArray = [];
          for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line.indexOf("Device ") === 0) {
              var parts = line.slice(7).split(" ");
              if (parts.length >= 2) {
                var addr = parts[0];
                var name = parts.slice(1).join(" ");
                devicesArray.push({ address: addr, name: name, alias: name, paired: true, connected: false });
              }
            }
          }
          root.discoveredDevices = devicesArray;
        } catch (e) {}
      }
    }

    Timer {
      id: devicesPollTimer
      interval: 3000
      repeat: true
      running: false
      onTriggered: devicesListProcess.running = true
    }

    function setScanActive(active) {
      if (active) {
        if (adapter) {
          try {
            adapter.enabled = true;
          } catch (e) {}
        }
        btPowerOnProcess.running = true;
        bluetoothctlScanProcess.running = true;
        devicesListProcess.running = true;
        devicesPollTimer.running = true;
      } else {
        Quickshell.execDetached(["bluetoothctl", "scan", "off"]);
        devicesPollTimer.running = false;
      }
    }

    function setBluetoothEnabled(state) {
      if (adapter) {
        try {
          adapter.enabled = state;
        } catch (e) {}
      }
      Quickshell.execDetached(["bluetoothctl", "power", state ? "on" : "off"]);
      root.ctlPowered = state;
    }

    function getDeviceIcon(device) {
      if (!device) return "󰂯";
      var n = (device.name || device.alias || "").toLowerCase();
      if (n.indexOf("bud") !== -1 || n.indexOf("airpod") !== -1 || n.indexOf("head") !== -1) return "󰒘";
      if (n.indexOf("mouse") !== -1) return "󰍽";
      if (n.indexOf("keyboard") !== -1) return "󰌌";
      return "󰂯";
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

    function connectDevice(device) {
      if (!device) return;
      try {
        device.trusted = true;
        if (device.paired) {
          device.connect();
        } else {
          device.pair();
        }
      } catch (e) {}
    }

    function disconnectDevice(device) {
      if (!device) return;
      try {
        device.disconnect();
      } catch (e) {}
    }

    function forgetDevice(device) {
      if (!device) return;
      try {
        device.trusted = false;
        device.forget();
      } catch (e) {}
    }

    function pairDevice(device) {
      if (!device) return;
      try {
        device.pair();
      } catch (e) {}
    }
  }
''

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

    readonly property bool available: adapter !== null
    readonly property bool enabled: (adapter && adapter.enabled) ?? false
    readonly property bool discovering: (adapter && adapter.discovering) ?? false

    property var _devicesList: []

    readonly property var devices: {
      if (!adapter || !adapter.devices) {
        return root._devicesList;
      }
      try {
        var result = [];
        var count = adapter.devices.count || 0;
        for (var i = 0; i < count; i++) {
          var dev = adapter.devices.get(i);
          if (dev) result.push(dev);
        }
        return result.length > 0 ? result : root._devicesList;
      } catch (e) {
        return root._devicesList;
      }
    }

    property bool _wasEnabled: false

    Component.onCompleted: {
      _wasEnabled = root.enabled;
    }

    onEnabledChanged: {
      if (root.enabled && !_wasEnabled) {
        root.setScanActive(true);
      }
      _wasEnabled = root.enabled;
    }

    readonly property var pairedDevices: {
      if (!adapter || !adapter.devices) {
        return [];
      }
      var result = [];
      for (var i = 0; i < adapter.devices.count; i++) {
        var dev = adapter.devices.get(i);
        if (dev && (dev.paired || dev.trusted)) {
          result.push(dev);
        }
      }
      return result;
    }

    function sortDevices(devices) {
      return devices.sort((a, b) => {
        const aName = a.name || a.deviceName || "";
        const bName = b.name || b.deviceName || "";
        const aAddr = a.address || "";
        const bAddr = b.address || "";

        const aHasRealName = aName.indexOf(" ") !== -1 && aName.length > 3;
        const bHasRealName = bName.indexOf(" ") !== -1 && bName.length > 3;

        if (aHasRealName && !bHasRealName) return -1;
        if (!aHasRealName && bHasRealName) return 1;

        if (aHasRealName && bHasRealName) {
          return aName.localeCompare(bName);
        }

        return aAddr.localeCompare(bAddr);
      });
    }

    function getDeviceIcon(device) {
      if (!device) return "bluetooth";
      const name = (device.name || device.deviceName || "").toLowerCase();
      const icon = (device.icon || "").toLowerCase();

      if (icon.indexOf("headset") !== -1 || name.indexOf("headset") !== -1 ||
          icon.indexOf("airpod") !== -1 || name.indexOf("airpod") !== -1 ||
          icon.indexOf("headphone") !== -1 || name.indexOf("headphone") !== -1) {
        return "headset";
      }

      if (icon.indexOf("mouse") !== -1 || name.indexOf("mouse") !== -1) {
        return "mouse";
      }

      if (icon.indexOf("keyboard") !== -1 || name.indexOf("keyboard") !== -1) {
        return "keyboard";
      }

      if (icon.indexOf("phone") !== -1 || name.indexOf("iphone") !== -1 ||
          icon.indexOf("android") !== -1 || name.indexOf("samsung") !== -1) {
        return "phone";
      }

      if (icon.indexOf("watch") !== -1 || name.indexOf("watch") !== -1) {
        return "watch";
      }

      if (icon.indexOf("speaker") !== -1 || name.indexOf("speaker") !== -1) {
        return "speaker";
      }

      if (icon.indexOf("display") !== -1 || icon.indexOf("tv") !== -1 || name.indexOf("tv") !== -1) {
        return "tv";
      }

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

    function setBluetoothEnabled(state) {
      if (!adapter) return;
      try {
        adapter.enabled = state;
      } catch (e) {}
    }

    function setScanActive(active) {
      if (!adapter) return;
      
      if (active) {
        if (!adapter.enabled) {
          try {
            adapter.enabled = true;
          } catch (e) {}
        }
        scanTimer.start();
      } else {
        try {
          adapter.discovering = false;
          adapter.discoverable = false;
        } catch (e) {}
      }
    }

    Timer {
      id: scanTimer
      interval: 500
      repeat: false
      onTriggered: {
        if (adapter && adapter.enabled) {
          try {
            adapter.discovering = true;
            adapter.discoverable = true;
          } catch (e) {}
        }
        refreshDevicesTimer.start();
      }
    }

    Timer {
      id: refreshDevicesTimer
      interval: 2000
      repeat: true
      running: root.enabled
      onTriggered: {
        refreshDevicesProcess.running = true;
      }
    }

    Process {
      id: refreshDevicesProcess
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
          if (devicesArray.length > 0) {
            root._devicesList = devicesArray;
          }
        } catch (e) {}
      }
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

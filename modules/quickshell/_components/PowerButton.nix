{ pkgs, lib, ... }:
let
  inherit (lib) getExe;
in
''
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
''

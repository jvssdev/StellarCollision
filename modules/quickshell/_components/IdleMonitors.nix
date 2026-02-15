{
  pkgs,
  lib,
  quickshellPackage,
  isNiri,
  ...
}:
let
  inherit (lib) getExe getExe';
  useNiriDPMS = isNiri;
in
''
  import QtQuick
  import Quickshell
  import Quickshell.Wayland
  import Quickshell.Io
  Scope {
      id: idleScope
      property bool manualInhibit: false
      QtObject { id: audioPlaying; property bool isPlaying: false }
      Process {
          id: audioCheckProc
          command: ["${getExe pkgs.bash}", "-c", "${getExe pkgs.playerctl} -a status 2>/dev/null | grep Playing > /dev/null && echo yes || echo no"]
          stdout: SplitParser {
              onRead: data => {
                  if (data) {
                      audioPlaying.isPlaying = data.trim() === "yes"
                  }
              }
          }
      }
      Timer {
          interval: 2000
          running: true
          repeat: true
          triggeredOnStart: true
          onTriggered: audioCheckProc.running = true
      }
      IdleInhibitor {
          enabled: manualInhibit || audioPlaying.isPlaying
      }
      function handleIdleAction(action, isIdle) {
          if (!action) return;
          if (action === "lock" && isIdle) lockProc.running = true;
          if (action === "suspend" && isIdle) suspendProc.running = true;
          if (action === "dpms off" && isIdle) dpmsOffProc.running = true;
          if (action === "dpms on" && !isIdle) dpmsOnProc.running = true;
      }
      Process { 
          id: dpmsOffProc; 
          command: ${
            if useNiriDPMS then
              ''["niri", "msg", "action", "power-off-monitors"]''
            else
              ''["${getExe pkgs.wlopm}", "--off", "*"]''
          }
          stderr: SplitParser {
              onRead: data => console.log("[dpms off] stderr:", data)
          }
          onRunningChanged: running => {
              if (!running) console.log("[dpms off] exited with code:", dpmsOffProc.exitCode, "exitStatus:", dpmsOffProc.exitStatus)
          }
      }
      Process { 
          id: dpmsOnProc; 
          command: ${
            if useNiriDPMS then
              ''["niri", "msg", "action", "power-on-monitors"]''
            else
              ''["${getExe pkgs.wlopm}", "--on", "*"]''
          }
          stderr: SplitParser {
              onRead: data => console.log("[dpms on] stderr:", data)
          }
      }
      Process { id: lockProc; command: ["${quickshellPackage}/bin/quickshell", "ipc", "call", "lockScreen", "toggle"] }
      Process { id: suspendProc; command: ["${getExe' pkgs.systemd "systemctl"}", "suspend"] }
      Process {
          id: logindMonitor
          command: ["${getExe' pkgs.dbus "dbus-monitor"}", "--system", "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"]
          running: true
          stdout: SplitParser {
              onRead: data => {
                  if (data.includes("boolean true")) {
                      lockProc.running = true
                  }
              }
          }
      }
      Variants {
          model: [
              { timeout: 240, idleAction: "dpms off", returnAction: "dpms on" },
              { timeout: 300, idleAction: "lock" },
              { timeout: 600, idleAction: "suspend" }
          ]
          IdleMonitor {
              required property var modelData
              enabled: !manualInhibit
              respectInhibitors: true
              timeout: modelData.timeout
              onIsIdleChanged: idleScope.handleIdleAction(isIdle ? modelData.idleAction : modelData.returnAction, isIdle)
          }
      }
  }
''

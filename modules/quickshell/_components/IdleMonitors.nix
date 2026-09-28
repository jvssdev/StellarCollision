{
  pkgs,
  lib,
  isNiri,
  ...
}:
let
  inherit (lib) getExe getExe';
  useNiriDPMS = isNiri;
in
/* qml */ ''
  import QtQuick
  import Quickshell
  import Quickshell.Wayland
  import Quickshell.Io
  import Quickshell.Services.Mpris

  Scope {
      id: idleScope

      property bool inhibit: false
      property var window: null

      property bool lockGrace: false
      property bool lockRequested: false
      property bool outputsOn: true

      IdleInhibitor {
          window: idleScope.window
          enabled: idleScope.inhibit || audioPlaying.isPlaying
      }

      QtObject {
          id: audioPlaying
          readonly property bool isPlaying: {
              for (const p of Mpris.players.values) {
                  if (p.playbackState === MprisPlaybackState.Playing) return true
              }
              return false
          }
      }

      Timer {
          id: lockGraceTimer
          interval: 4000
          repeat: false
          onTriggered: {
              idleScope.lockGrace = false
              idleScope.lockRequested = false
          }
      }

      IdleMonitor {
          timeout: 1
          onIsIdleChanged: {
              if (!lockProc.running) return
              if (!isIdle) {
                  dpmsOnProc.running = true
                  idleScope.outputsOn = true
              }
          }
      }

      function requestLock(reason) {
          if (lockProc.running || idleScope.lockGrace || idleScope.lockRequested)
              return

          idleScope.lockRequested = true
          lockProc.running = true
      }

      function handleIdleAction(action, isIdle) {
          if (!action) return
          if (action === "lock" && isIdle) {
              idleScope.requestLock("idle")
              return
          }
          if (action === "suspend" && isIdle) suspendProc.running = true
          if (action === "dpms off" && isIdle) {
              dpmsOffProc.running = true
              idleScope.outputsOn = false
          }
          if (action === "dpms on" && !isIdle) {
              dpmsOnProc.running = true
              idleScope.outputsOn = true
          }
      }

      Process {
          id: dpmsOffProc
          command: ${
            if useNiriDPMS then
              ''["niri", "msg", "action", "power-off-monitors"]''
            else
              ''["${getExe pkgs.wlopm}", "--off", "*"]''
          }
      }

      Process {
          id: dpmsOnProc
          command: ${
            if useNiriDPMS then
              ''["niri", "msg", "action", "power-on-monitors"]''
            else
              ''["${getExe pkgs.wlopm}", "--on", "*"]''
          }
      }

      Process {
          id: lockProc
          clearEnvironment: false
          workingDirectory: Quickshell.env("HOME") || "/tmp"
          environment: ({
              QML_IMPORT_PATH: null,
              QML2_IMPORT_PATH: null
          })
          command: ["/run/current-system/sw/bin/qylock-lock"]
          stderr: StdioCollector {
              onStreamFinished: {
                  if (text && text.length > 0)
                      console.warn("[qylock-lock stderr]", text)
              }
          }
          onExited: (exitCode, exitStatus) => {
              idleScope.lockRequested = false
              idleScope.lockGrace = true
              lockGraceTimer.restart()
          }
      }

      Process {
          id: suspendProc
          command: ["${getExe' pkgs.systemd "systemctl"}", "suspend"]
      }

      Process {
          id: logindMonitor
          command: ["${getExe' pkgs.dbus "dbus-monitor"}", "--system", "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"]
          running: true
          stdout: SplitParser {
              onRead: data => {
                  if (data.includes("boolean true")) {
                      idleScope.requestLock("prepare-for-sleep")
                  }
              }
          }
      }

      Variants {
          model: [
              { timeout: 100, idleAction: "dpms off", returnAction: "dpms on" },
              { timeout: 160, idleAction: "lock" },
              { timeout: 600, idleAction: "suspend" }
          ]
          IdleMonitor {
              required property var modelData
              timeout: modelData.timeout
              onIsIdleChanged: idleScope.handleIdleAction(
                  isIdle ? modelData.idleAction : modelData.returnAction,
                  isIdle
              )
          }
      }
  }
''

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
      property int lockDimTimeout: 30000
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

      Timer {
          id: lockDimTimer
          interval: idleScope.lockDimTimeout
          repeat: false
          onTriggered: {
              if (lockProc.running) {
                  dpmsOffProc.running = true
                  idleScope.outputsOn = false
              }
          }
      }

      IdleMonitor {
          timeout: 1
          onIsIdleChanged: {
              if (!lockProc.running) return
              if (!isIdle) {
                  dpmsOnProc.running = true
                  idleScope.outputsOn = true
                  lockDimTimer.restart()
              }
          }
      }

      function requestLock(reason) {
          if (lockProc.running || idleScope.lockGrace || idleScope.lockRequested)
              return

          idleScope.lockRequested = true
          lockProc.running = true
          if (idleScope.outputsOn) lockDimTimer.restart()
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
              if (lockProc.running) lockDimTimer.restart()
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
          command: ["/run/current-system/sw/bin/qylock-lock"]
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
              { timeout: 240, idleAction: "dpms off", returnAction: "dpms on" },
              { timeout: 300, idleAction: "lock" },
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

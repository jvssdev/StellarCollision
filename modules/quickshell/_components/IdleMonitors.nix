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

      // After a successful unlock, ignore new lock requests for a short window.
      // Prevents the classic "unlock → lock again immediately" when IdleMonitor
      // still reports isIdle=true (lock-screen input often does not fully reset
      // ext-idle-notify) or when two lock starts race.
      property bool lockGrace: false
      property bool lockRequested: false

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

      function requestLock(reason) {
          // Already showing a lock, or just unlocked — do nothing
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
          if (action === "dpms off" && isIdle) dpmsOffProc.running = true
          if (action === "dpms on" && !isIdle) dpmsOnProc.running = true
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
          // When the lock exits (unlock or crash), start a grace period so the
          // still-idle IdleMonitor cannot immediately spawn another lock.
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
              // Keep monitors always enabled so returnAction (dpms on) still works.
              // Lock re-entry is gated inside requestLock().
              onIsIdleChanged: idleScope.handleIdleAction(
                  isIdle ? modelData.idleAction : modelData.returnAction,
                  isIdle
              )
          }
      }
  }
''

{
  isNiri,
  isMango,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) getExe getExe';
in
if isNiri then
  /* qml */ ''
    import QtQuick
    import QtQuick.Layouts
    import QtQuick.Controls
    import Quickshell
    import Quickshell.Wayland
    import Quickshell.Io
    import QtCore
    import Quickshell.Services.Mpris
    import Quickshell.Services.Pipewire
    import Quickshell.Networking

    import "BluetoothService.qml"

    Scope {
        id: root
        property bool shown: false
        property var theme: null
        property var batteryObj: null
        property int brightnessLevel: 50
        property bool bluetoothPageVisible: false
        property bool wifiPageVisible: false

        onBluetoothPageVisibleChanged: {
            if (bluetoothPageVisible) {
                BluetoothService.setScanActive(true);
            }
        }

        readonly property var wifiDevice: {
            for (const d of Networking.devices.values) {
                if (d.type === DeviceType.Wifi) return d
            }
            return null
        }
        property bool wifiEnabled: Networking.wifiEnabled
        property bool wifiScanning: wifiDevice?.scannerEnabled ?? false
        readonly property var wifiNetworks: {
            if (!wifiDevice) return []
            const nets = wifiDevice.networks.values.map(n => ({
                ssid: n.name,
                signal: Math.round(n.signalStrength * 100),
                secure: n.security !== WifiSecurityType.Open,
                active: n.connected,
                saved: n.known,
                connecting: n.stateChanging
            }))
            nets.sort((a, b) => {
                if (a.active) return -1
                if (b.active) return 1
                return b.signal - a.signal
            })
            return nets
        }
        property string pendingWifiSsid: ""
        readonly property var pendingWifiNetwork: root.findWifiNetwork(root.pendingWifiSsid)
        property bool wifiPasswordPageVisible: false
        property bool airplaneMode: false
        property bool dndEnabled: false

        // ── Session persistence (Dank-style FileView JSON) ─────────────────
        // Survives pkill / logout / QS restart
        property bool _sessionReady: false
        property bool _sessionApplying: false

        readonly property string sessionStateDir: {
            let base = StandardPaths.writableLocation(StandardPaths.GenericStateLocation).toString()
            if (base.startsWith("file://"))
                base = base.substring(7)
            return base + "/stellar"
        }
        readonly property string sessionStatePath: root.sessionStateDir + "/session.json"

        FileView {
            id: sessionFile
            path: root.sessionStatePath
            blockLoading: true
            blockWrites: true
            atomicWrites: true
            watchChanges: false
            printErrors: false
            onLoaded: root._loadSessionState()
            Component.onCompleted: sessionMkdirProc.running = true
        }

        Process {
            id: sessionMkdirProc
            running: false
            command: ["${getExe' pkgs.coreutils "mkdir"}", "-p", root.sessionStateDir]
            onExited: code => {
                sessionFile.reload()
                // If file still missing, onLoaded may not fire — force ready + write defaults
                sessionReadyFallback.restart()
            }
        }

        Timer {
            id: sessionReadyFallback
            interval: 800
            repeat: false
            onTriggered: {
                // Only mark ready — never write here (avoids clobbering airplaneMode
                // before FileView finishes loading session.json)
                if (!root._sessionReady)
                    root._sessionReady = true
            }
        }

        function _loadSessionState() {
            root._sessionApplying = true
            try {
                const raw = sessionFile.text()
                if (raw && raw.trim().length > 0) {
                    const obj = JSON.parse(raw)
                    if (typeof obj.brightnessLevel === "number") {
                        const pct = Math.max(0, Math.min(100, Math.round(obj.brightnessLevel)))
                        root.brightnessLevel = pct
                        brightnessSetProc.running = false
                        brightnessSetProc.command = ["${getExe pkgs.brightnessctl}", "-n2", "set", pct + "%"]
                        brightnessSetProc.running = true
                    }
                    // Airplane first so UI binding is correct before side effects
                    if (typeof obj.airplaneMode === "boolean") {
                        root.airplaneMode = !!obj.airplaneMode
                        console.warn("session: loaded airplaneMode =", root.airplaneMode)
                        if (root.airplaneMode)
                            sessionAirplaneRestoreTimer.restart()
                    }
                    // BT only if not in airplane (airplane restore will force off)
                    if (typeof obj.bluetoothEnabled === "boolean" && !root.airplaneMode) {
                        BluetoothService.setBluetoothEnabled(obj.bluetoothEnabled)
                    }
                    if (typeof obj.nightLightTemperature === "number") {
                        root.nightLightTemperature = Math.max(2500, Math.min(6500, Math.round(obj.nightLightTemperature)))
                    }
                    if (obj.nightLightEnabled === true) {
                        sessionNightRestoreTimer.restart()
                    } else if (obj.nightLightEnabled === false) {
                        root.nightLightEnabled = false
                    }
                    if (typeof obj.dndEnabled === "boolean")
                        root.dndEnabled = obj.dndEnabled
                }
            } catch (e) {
                console.warn("session.json parse failed:", e)
            }
            root._sessionApplying = false
            root._sessionReady = true
            // Re-assert airplane UI after bindings settle (Control Center may mount later)
            if (root.airplaneMode)
                sessionAirplaneUiTimer.restart()
        }

        Timer {
            id: sessionAirplaneUiTimer
            interval: 1000
            repeat: false
            onTriggered: {
                if (!root.airplaneMode)
                    return
                // force property notification for QuickToggle binding
                root.airplaneMode = false
                root.airplaneMode = true
                Networking.wifiEnabled = false
                BluetoothService.setBluetoothEnabled(false)
                console.warn("session: airplaneMode restored ON")
            }
        }

        Timer {
            id: sessionNightRestoreTimer
            interval: 400
            repeat: false
            onTriggered: root.startNightLight(root.nightLightTemperature)
        }

        // Apply radio kill after Networking/BT services are up; re-assert UI flag
        Timer {
            id: sessionAirplaneRestoreTimer
            interval: 600
            repeat: false
            onTriggered: {
                if (!root.airplaneMode)
                    return
                root.airplaneMode = true
                Networking.wifiEnabled = false
                BluetoothService.setBluetoothEnabled(false)
            }
        }

        function flushSessionState() {
            if (root._sessionApplying)
                return
            // mark ready so first Airplane toggle still persists
            root._sessionReady = true
            sessionSaveTimer.stop()
            const obj = {
                brightnessLevel: root.brightnessLevel,
                bluetoothEnabled: root.airplaneMode ? false : BluetoothService.enabled,
                nightLightEnabled: root.nightLightEnabled,
                nightLightTemperature: root.nightLightTemperature,
                dndEnabled: root.dndEnabled,
                airplaneMode: root.airplaneMode
            }
            try {
                sessionFile.setText(JSON.stringify(obj, null, 2) + "\n")
            } catch (e) {
                console.warn("session.json save failed:", e)
            }
        }

        function saveSessionState() {
            if (!root._sessionReady || root._sessionApplying)
                return
            sessionSaveTimer.restart()
        }

        Timer {
            id: sessionSaveTimer
            interval: 300
            repeat: false
            onTriggered: {
                if (!root._sessionReady || root._sessionApplying)
                    return
                const obj = {
                    brightnessLevel: root.brightnessLevel,
                    bluetoothEnabled: BluetoothService.enabled,
                    nightLightEnabled: root.nightLightEnabled,
                    nightLightTemperature: root.nightLightTemperature,
                    dndEnabled: root.dndEnabled,
                    airplaneMode: root.airplaneMode
                }
                try {
                    sessionFile.setText(JSON.stringify(obj, null, 2) + "\n")
                } catch (e) {
                    console.warn("session.json save failed:", e)
                }
            }
        }

        // Debounced persist on relevant changes
        onBrightnessLevelChanged: root.saveSessionState()
        onNightLightEnabledChanged: root.saveSessionState()
        onNightLightTemperatureChanged: root.saveSessionState()
        onDndEnabledChanged: root.saveSessionState()
        onAirplaneModeChanged: root.flushSessionState()

        Connections {
            target: BluetoothService
            function onEnabledChanged() { root.saveSessionState() }
        }


        onWifiPageVisibleChanged: {
            if (wifiDevice) wifiDevice.scannerEnabled = wifiPageVisible
        }

        PwObjectTracker {
            objects: [Pipewire.defaultAudioSink]
        }

        // Sync with system default output (same source as the bar / pavucontrol)
        readonly property real sinkVolume: {
            const sink = Pipewire.defaultAudioSink
            if (!sink || !sink.audio)
                return -1
            return sink.audio.volume ?? -1
        }

        property int volumeLevel: {
            if (sinkVolume < 0)
                return 0
            return Math.round(Math.min(sinkVolume, 1.0) * 100)
        }

        property bool isMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false

        function findWifiNetwork(ssid) {
            if (!wifiDevice) return null
            for (const n of wifiDevice.networks.values) {
                if (n.name === ssid) return n
            }
            return null
        }

        function forgetWifi(ssid) {
            const net = findWifiNetwork(ssid)
            if (net) net.forget()
        }

        function scanWifi() {
            if (wifiDevice) wifiDevice.scannerEnabled = true
        }

        function toggleWifi() {
            if (root.airplaneMode) return
            Networking.wifiEnabled = !Networking.wifiEnabled
        }

        function toggleAirplaneMode() {
            root.airplaneMode = !root.airplaneMode
            Networking.wifiEnabled = !root.airplaneMode
            BluetoothService.setBluetoothEnabled(!root.airplaneMode)
            root.flushSessionState()
        }

        property string wifiError: ""

        Timer {
            id: wifiErrorTimer
            interval: 4000
            onTriggered: root.wifiError = ""
        }

        Connections {
            target: root.pendingWifiNetwork
            enabled: root.pendingWifiNetwork !== null
            function onConnectionFailed(reason) {
                if (reason === ConnectionFailReason.NoSecrets) {
                    root.wifiPasswordPageVisible = true
                } else {
                    root.wifiError = ConnectionFailReason.toString(reason)
                    wifiErrorTimer.restart()
                }
            }
        }

        function connectWifi(ssid, password) {
            root.wifiPasswordPageVisible = false
            const net = findWifiNetwork(ssid)
            if (!net) return
            if (password) net.connectWithPsk(password)
            else net.connect()
        }

        function disconnectWifi() {
            if (wifiDevice) wifiDevice.disconnect()
        }

        function getWifiIcon(signal) {
            if (signal >= 75) return "󰤨"
            if (signal >= 50) return "󰤥"
            if (signal >= 25) return "󰤢"
            return "󰤟"
        }

        function setVolume(newVal) {
            const sink = Pipewire.defaultAudioSink
            if (sink && sink.audio) {
                sink.audio.muted = false
                sink.audio.volume = Math.max(0, Math.min(1.0, newVal / 100))
            } else {
                volumeSetProc.command = ["${getExe' pkgs.wireplumber "wpctl"}", "set-volume", "@DEFAULT_AUDIO_SINK@", (newVal / 100).toString()]
                volumeSetProc.running = true
            }
        }

        function toggleMute() {
            const sink = Pipewire.defaultAudioSink
            if (sink && sink.audio) {
                sink.audio.muted = !sink.audio.muted
            } else {
                volumeMuteProc.running = true
            }
        }

        function toggle() {
            shown = !shown
        }

        property bool nightLightEnabled: false
        property int nightLightTemperature: 4500
        property bool _nightLightUserAdjust: false
        property int _pendingNightTemp: -1

        // Same invocation that used to work on this niri setup:
        //   gammastep -P -O <temp>
        // Do NOT force -m wayland/drm — that broke gamma on this machine.
        Process {
            id: nightLightDaemon
            running: false
            command: ["${getExe pkgs.gammastep}", "-P", "-O", "4500"]
            stderr: SplitParser {
                onRead: data => console.warn("gammastep:", data)
            }
            onRunningChanged: {
                if (!running && root.nightLightEnabled && !root._nightLightUserAdjust)
                    root.nightLightEnabled = false
            }
        }

        Process {
            id: nightLightKillProc
            running: false
            command: ["${getExe' pkgs.procps "pkill"}", "-9", "-x", "gammastep"]
        }

        function startNightLight(temp) {
            temp = Math.max(2500, Math.min(6500, Math.round(temp || root.nightLightTemperature)))
            root._nightLightUserAdjust = true
            root.nightLightTemperature = temp
            root.nightLightEnabled = true

            // stop previous instance, then start with new temp
            nightLightDaemon.running = false
            nightLightKillProc.running = false
            nightLightKillProc.running = true

            nightLightDaemon.command = [
                "${getExe pkgs.gammastep}",
                "-P",
                "-O", "" + temp
            ]
            // small delay so pkill finishes
            nightLightStartTimer.restart()
        }

        Timer {
            id: nightLightStartTimer
            interval: 250
            repeat: false
            onTriggered: {
                nightLightDaemon.running = true
                nightLightUnlockTimer.restart()
            }
        }

        Timer {
            id: nightLightUnlockTimer
            interval: 600
            repeat: false
            onTriggered: root._nightLightUserAdjust = false
        }

        function stopNightLight() {
            root._nightLightUserAdjust = true
            root.nightLightEnabled = false
            nightLightDaemon.running = false
            nightLightKillProc.running = false
            nightLightKillProc.running = true
            // avoid hanging `gammastep -x` — pkill is enough to drop the ramp on many setups
            nightLightUnlockTimer.restart()
        }

        function toggleNightLight() {
            if (root.nightLightEnabled || nightLightDaemon.running)
                root.stopNightLight()
            else
                root.startNightLight(root.nightLightTemperature)
        }

        function setNightLightTemp(temp) {
            temp = Math.max(2500, Math.min(6500, Math.round(temp)))
            root.nightLightTemperature = temp
            root._pendingNightTemp = temp
            root.nightLightEnabled = true
            nightLightApplyTimer.restart()
        }

        Timer {
            id: nightLightApplyTimer
            interval: 200
            repeat: false
            onTriggered: {
                if (root._pendingNightTemp >= 0)
                    root.startNightLight(root._pendingNightTemp)
                root._pendingNightTemp = -1
            }
        }

        // Re-detect external/orphan gammastep after QS restart
        Process {
            id: checkNightLightProc
            running: false
            command: ["${getExe pkgs.bash}", "-c",
                "pid=$(${getExe' pkgs.procps "pgrep"} -x gammastep 2>/dev/null | head -n1); "
                + "if [ -z \"$pid\" ]; then echo '0:'; exit 0; fi; "
                + "cmd=$(tr '\\0' ' ' < /proc/$pid/cmdline 2>/dev/null || true); "
                + "temp=$(printf '%s' \"$cmd\" | ${getExe pkgs.gnugrep} -oE -- '-O[[:space:]]*[0-9]+' | ${getExe pkgs.gnugrep} -oE '[0-9]+' | head -n1); "
                + "echo \"1:''${temp:-}\""
            ]
            stdout: SplitParser {
                onRead: data => {
                    if (root._nightLightUserAdjust || nightLightDaemon.running)
                        return
                    const s = data.trim()
                    const idx = s.indexOf(":")
                    if (idx < 0) return
                    if (s.substring(0, idx) === "1") {
                        root.nightLightEnabled = true
                        const t = parseInt(s.substring(idx + 1), 10)
                        if (!isNaN(t) && t >= 2500 && t <= 6500)
                            root.nightLightTemperature = t
                    }
                }
            }
        }

        Timer {
            interval: 4000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                if (!root._nightLightUserAdjust && !nightLightDaemon.running) {
                    checkNightLightProc.running = false
                    checkNightLightProc.running = true
                }
            }
        }

        property var mprisPlayers: Mpris.players.values
        property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
        property bool hasMediaPlayer: activePlayer !== null
        property string mediaTitle: activePlayer?.trackTitle || "No media playing"
        property string mediaArtist: activePlayer?.trackArtist || ""
        property string mediaAlbum: activePlayer?.trackAlbum || ""
        property string mediaArtUrl: activePlayer?.trackArtUrl || ""
        property bool mediaPlaying: activePlayer?.isPlaying || false

        function getActivePlayer() {
            var players = Mpris.players.values
            if (players.length === 0) return null
            for (var i = 0; i < players.length; i++) {
                if (players[i].isPlaying) return players[i]
            }
            return players[0]
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: root.activePlayer = root.getActivePlayer()
        }

        component QuickToggle: Rectangle {
            id: toggle
            property string icon: "󰛨"
            property string iconOff: icon
            property string label: "Toggle"
            property bool isOn: false
            property color accentColor: controlTheme.green
            property var controlTheme: null
            property var onClick: null

            Layout.fillWidth: true
            height: 60
            radius: 8
            color: isOn ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : (controlTheme.bgAlt)
            border.width: isOn ? 2 : 0
            border.color: accentColor

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.width { NumberAnimation { duration: 150 } }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: toggle.isOn ? toggle.icon : toggle.iconOff
                    font.family: toggle.controlTheme.fontFamily
                    font.pixelSize: 18
                    color: toggle.isOn ? toggle.accentColor : (toggle.controlTheme.fgMuted)
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: toggle.label
                    font.family: toggle.controlTheme.fontFamily
                    font.pixelSize: 10
                    color: toggle.isOn ? (toggle.controlTheme.fg) : (toggle.controlTheme.fgMuted)
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (toggle.onClick) toggle.onClick()
                    else toggle.isOn = !toggle.isOn
                }
            }
        }

        component SliderCard: Rectangle {
            id: sliderCard
            property string icon: "󰕾"
            property string label: "Slider"
            property int value: 50
            property color accentColor: controlTheme.blue
            property bool isMuted: false
            property var controlTheme: null
            property var valueChangedHandler: null
            property bool liveValue: false

            height: 70
            radius: 8
            color: controlTheme.bgAlt

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: sliderCard.icon
                        font.family: sliderCard.controlTheme.fontFamily
                        font.pixelSize: 16
                        color: sliderCard.isMuted ? (sliderCard.controlTheme.fgMuted) : sliderCard.accentColor
                    }

                    Text {
                        text: sliderCard.label
                        font.family: sliderCard.controlTheme.fontFamily
                        font.pixelSize: 12
                        color: sliderCard.controlTheme.fg
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: sliderCard.value + "%"
                        font.family: sliderCard.controlTheme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        color: sliderCard.controlTheme.fgMuted
                    }
                }

                Item {
                    Layout.fillWidth: true
                    height: 20

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 6
                        radius: 3
                        color: controlTheme.bg

                        Rectangle {
                            width: (sliderCard.value / 100) * parent.width
                            height: parent.height
                            radius: parent.radius
                            color: sliderCard.isMuted ? (sliderCard.controlTheme.fgMuted) : sliderCard.accentColor
                        }
                    }

                    Rectangle {
                        x: (sliderCard.value / 100) * (parent.width - width)
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14
                        height: 14
                        radius: 7
                        color: sliderCard.isMuted ? (sliderCard.controlTheme.fgMuted) : sliderCard.accentColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                var newVal = Math.max(0, Math.min(100, (mouse.x / width) * 100))
                                if (!sliderCard.liveValue) sliderCard.value = Math.round(newVal)
                                if (sliderCard.valueChangedHandler) sliderCard.valueChangedHandler(newVal)
                            }
                        }
                        onClicked: (mouse) => {
                            var newVal = Math.max(0, Math.min(100, (mouse.x / width) * 100))
                            if (!sliderCard.liveValue) sliderCard.value = Math.round(newVal)
                            if (sliderCard.valueChangedHandler) sliderCard.valueChangedHandler(newVal)
                        }
                    }
                }
            }
        }

        component MediaCard: Rectangle {
            id: mediaCard
            property string title: root.mediaTitle
            property string artist: root.mediaArtist
            property string album: root.mediaAlbum
            property string artUrl: root.mediaArtUrl
            property bool isPlaying: root.mediaPlaying
            property bool hasPlayer: root.hasMediaPlayer
            property var controlTheme: null

            visible: hasPlayer
            height: 90
            radius: 8
            color: controlTheme.bgAlt

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Rectangle {
                    width: 56
                    height: 56
                    radius: 6
                    color: controlTheme.bg

                    Image {
                        anchors.fill: parent
                        source: mediaCard.artUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: mediaCard.artUrl !== ""
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰝚"
                        font.family: mediaCard.controlTheme.fontFamily
                        font.pixelSize: 24
                        color: mediaCard.controlTheme.fgMuted
                        visible: mediaCard.artUrl === ""
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: mediaCard.title
                        font.family: mediaCard.controlTheme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        color: mediaCard.controlTheme.fg
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: mediaCard.artist || "Unknown artist"
                        font.family: mediaCard.controlTheme.fontFamily
                        font.pixelSize: 10
                        color: mediaCard.controlTheme.fgMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: mediaCard.album || ""
                        font.family: mediaCard.controlTheme.fontFamily
                        font.pixelSize: 9
                        color: mediaCard.controlTheme.fgMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        visible: mediaCard.album !== ""
                    }
                }

                RowLayout {
                    spacing: 4

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: prevMouse.containsMouse ? (mediaCard.controlTheme.bg) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰒮"
                            font.family: mediaCard.controlTheme.fontFamily
                            font.pixelSize: 14
                            color: mediaCard.controlTheme.fg
                        }

                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activePlayer?.previous()
                        }
                    }

                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: mediaCard.controlTheme.darkBlue

                        Text {
                            anchors.centerIn: parent
                            text: mediaCard.isPlaying ? "󰏤" : "󰐊"
                            font.family: mediaCard.controlTheme.fontFamily
                            font.pixelSize: 16
                            color: mediaCard.controlTheme.bg
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (mediaCard.isPlaying) root.activePlayer?.pause()
                                else root.activePlayer?.play()
                            }
                        }
                    }

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: nextMouse.containsMouse ? (mediaCard.controlTheme.bg) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰒭"
                            font.family: mediaCard.controlTheme.fontFamily
                            font.pixelSize: 14
                            color: mediaCard.controlTheme.fg
                        }

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activePlayer?.next()
                        }
                    }
                }
            }
        }

        component WifiNetworkCard: Rectangle {
            id: wifiCard
            property string ssid: ""
            property int signal: 0
            property bool secure: false
            property bool active: false
            property bool connecting: false
            property bool saved: false
            property var controlTheme: null

            height: 50
            radius: 8
            color: controlTheme.bg

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Text {
                    text: root.getWifiIcon(wifiCard.signal)
                    font.family: wifiCard.controlTheme.fontFamily
                    font.pixelSize: 18
                    color: wifiCard.active ? (wifiCard.controlTheme.green) : (wifiCard.controlTheme.fgMuted)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: wifiCard.ssid
                        font.family: wifiCard.controlTheme.fontFamily
                        font.pixelSize: 12
                        font.bold: wifiCard.active
                        color: wifiCard.controlTheme.fg
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: {
                            if (wifiCard.connecting) return "Connecting..."
                            if (wifiCard.active) return "Connected"
                            if (wifiCard.saved) return "Saved"
                            if (wifiCard.secure) return "Secured"
                            return "Open"
                        }
                        font.family: wifiCard.controlTheme.fontFamily
                        font.pixelSize: 10
                        color: wifiCard.active ? (wifiCard.controlTheme.green) : (wifiCard.controlTheme.fgMuted)
                    }
                }

                Text {
                    text: wifiCard.signal + "%"
                    font.family: wifiCard.controlTheme.fontFamily
                    font.pixelSize: 10
                    color: wifiCard.controlTheme.fgMuted
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (wifiCard.active) {
                        root.disconnectWifi()
                    } else if (wifiCard.saved) {
                        root.connectWifi(wifiCard.ssid, "")
                    } else if (wifiCard.secure) {
                        root.pendingWifiSsid = wifiCard.ssid
                        root.wifiPasswordPageVisible = true
                    } else {
                        root.connectWifi(wifiCard.ssid, "")
                    }
                }
                onPressAndHold: {
                    if (wifiCard.active || wifiCard.saved) {
                        contextMenu.wifiSsid = wifiCard.ssid
                        contextMenu.visible = true
                    }
                }
            }

            Rectangle {
                id: contextMenu
                property string wifiSsid: ""
                visible: false
                width: 140
                height: 36
                radius: 8
                color: controlTheme.bg
                z: 1000

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: 6
                    color: menuMouse.containsMouse ? (controlTheme.bgAlt) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Forget Network"
                        font.family: controlTheme.fontFamily
                        font.pixelSize: 11
                        color: controlTheme.red
                    }

                    MouseArea {
                        id: menuMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.forgetWifi(contextMenu.wifiSsid)
                            contextMenu.visible = false
                        }
                    }
                }
            }
        }

        component WifiEmptyState: Rectangle {
            property var controlTheme: null

            Layout.fillWidth: true
            Layout.fillHeight: true
            color: controlTheme.bgAlt

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                Rectangle {
                    width: 64
                    height: 64
                    radius: 32
                    color: controlTheme.bg
                    Layout.alignment: Qt.AlignHCenter

                    Text {
                        anchors.centerIn: parent
                        text: root.wifiScanning ? "󰤩" : (root.wifiEnabled ? "󰤫" : "󰤮")
                        font.family: controlTheme.fontFamily
                        font.pixelSize: 28
                        color: controlTheme.fgMuted
                        opacity: 0.5
                    }
                }

                Text {
                    text: {
                        if (!root.wifiEnabled) return "Wi-Fi Off"
                        if (root.wifiScanning) return "Scanning..."
                        return "No networks found"
                    }
                    font.family: controlTheme.fontFamily
                    font.pixelSize: 12
                    color: controlTheme.fgMuted
                    opacity: 0.7
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        component WifiPasswordPage: Rectangle {
            id: passPage
            property string targetSsid: ""
            property var controlTheme: null

            color: controlTheme.bgAlt
            radius: 12

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width * 0.85
                spacing: 20

                Text {
                    text: "󰤁"
                    font.family: controlTheme.fontFamily
                    font.pixelSize: 48
                    color: controlTheme.blue
                    Layout.alignment: Qt.AlignHCenter
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 5

                    Text {
                        text: "Password Required"
                        color: controlTheme.fgMuted
                        font.pixelSize: 12
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: passPage.targetSsid
                        color: controlTheme.fg
                        font.bold: true
                        font.pixelSize: 14
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: parent.width
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 45
                    radius: 8
                    color: controlTheme.bg

                    TextInput {
                        id: passTextInput
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        leftPadding: 15
                        rightPadding: 40
                        echoMode: showPassToggle.checked ? TextInput.Normal : TextInput.Password
                        color: controlTheme.fg
                        font.family: controlTheme.fontFamily
                        font.pixelSize: 12

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: showPassToggle.checked ? "󰤁" : "󰤂"
                            font.family: controlTheme.fontFamily
                            font.pixelSize: 16
                            color: controlTheme.fgMuted

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: showPassToggle.checked = !showPassToggle.checked
                            }
                        }
                    }

                    Item {
                        id: showPassToggle
                        property bool checked: false
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    spacing: 15

                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: 8
                        color: controlTheme.bg

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.family: controlTheme.fontFamily
                            font.pixelSize: 12
                            color: controlTheme.fg
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                passTextInput.text = ""
                                showPassToggle.checked = false
                                root.wifiPasswordPageVisible = false
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: 8
                        color: controlTheme.blue

                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            font.family: controlTheme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            color: controlTheme.bg
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (passTextInput.text.length > 0) {
                                    root.connectWifi(passPage.targetSsid, passTextInput.text)
                                    passTextInput.text = ""
                                    showPassToggle.checked = false
                                }
                            }
                        }
                    }
                }
            }
        }

        function refreshBrightness() {
            brightnessGetProc.running = false
            brightnessGetProc.running = true
        }

        Process {
            id: brightnessGetProc
            running: false
            // machine-readable: device,class,current,percent%,max
            command: ["${getExe pkgs.brightnessctl}", "-m", "info"]
            stdout: SplitParser {
                onRead: data => {
                    if (!data)
                        return
                    const line = data.trim().split(/\n/)[0]
                    const parts = line.split(",")
                    // Prefer the percentage field (e.g. "40%") — same scale as `set N%` without -e
                    if (parts.length >= 4) {
                        const pct = parseInt(parts[3], 10)
                        if (!isNaN(pct) && pct >= 0 && pct <= 100) {
                            root.brightnessLevel = pct
                            return
                        }
                    }
                    // Fallback: current/max
                    if (parts.length >= 5) {
                        const current = parseInt(parts[2], 10)
                        const max = parseInt(parts[4], 10)
                        if (max > 0 && !isNaN(current))
                            root.brightnessLevel = Math.round((current / max) * 100)
                    }
                }
            }
        }

        Process {
            id: brightnessSetProc
            running: false
            // linear % (no -e) so set matches the percentage we read from -m info
            command: ["${getExe pkgs.brightnessctl}", "-n2", "set", "50%"]
        }

        Timer {
            interval: root.shown ? 1500 : 5000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: root.refreshBrightness()
        }

        onShownChanged: {
            if (shown) {
                root.refreshBrightness()
            }
        }

        Process {
            id: volumeSetProc
            running: false
        }

        Process {
            id: volumeMuteProc
            command: ["${getExe' pkgs.wireplumber "wpctl"}", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        }

        PanelWindow {
            id: ccWindow
            visible: root.shown
            screen: Quickshell.screens[0]
            color: "transparent"

            implicitWidth: 380
            implicitHeight: 600

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                right: true
            }

            margins {
                top: 22
                right: 5
            }

            contentItem {
                focus: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        if (root.wifiPasswordPageVisible) {
                            root.wifiPasswordPageVisible = false
                        } else if (root.wifiPageVisible) {
                            root.wifiPageVisible = false
                        } else if (root.bluetoothPageVisible) {
                            root.bluetoothPageVisible = false
                        } else {
                            root.shown = false
                        }
                        event.accepted = true
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: root.theme.bg
                border.color: root.theme.darkBlue
                border.width: 2
                radius: 12

                ColumnLayout {
                    id: contentColumn
                    anchors.fill: parent
                    anchors.topMargin: 10
                    anchors.bottomMargin: 18
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: root.wifiPasswordPageVisible ? "Password" : (root.wifiPageVisible ? "Wi-Fi" : (root.bluetoothPageVisible ? "Bluetooth" : "Control Center"))
                            color: root.theme.darkBlue
                            font.pixelSize: 16
                            font.bold: true
                            font.family: root.theme.fontFamily
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            visible: root.bluetoothPageVisible && !root.wifiPageVisible && !root.wifiPasswordPageVisible
                            text: "Power"
                            color: root.theme.fgMuted
                            font.pixelSize: 10
                        }

                        Rectangle {
                            visible: root.bluetoothPageVisible && !root.wifiPageVisible && !root.wifiPasswordPageVisible
                            width: 44
                            height: 24
                            radius: 12
                            color: BluetoothService.enabled ? (root.theme.green) : (root.theme.fgMuted)

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: BluetoothService.setBluetoothEnabled(!BluetoothService.enabled)
                            }

                            Rectangle {
                                x: BluetoothService.enabled ? 22 : 2
                                y: 2
                                width: 20
                                height: 20
                                radius: 10
                                color: "#FFFFFF"
                            }
                        }

                        Text {
                            visible: root.wifiPageVisible && !root.wifiPasswordPageVisible
                            text: "Wi-Fi"
                            color: root.theme.fgMuted
                            font.pixelSize: 10
                        }

                        Rectangle {
                            visible: root.wifiPageVisible && !root.wifiPasswordPageVisible
                            width: 44
                            height: 24
                            radius: 12
                            color: root.wifiEnabled ? (root.theme.green) : (root.theme.bg)

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleWifi()
                            }

                            Rectangle {
                                x: root.wifiEnabled ? 22 : 2
                                y: 2
                                width: 20
                                height: 20
                                radius: 10
                                color: root.wifiEnabled ? "#FFFFFF" : (root.theme.fgMuted)
                            }
                        }

                        Text {
                            visible: root.wifiPageVisible && !root.wifiPasswordPageVisible
                            text: "Scan"
                            color: root.theme.fgMuted
                            font.pixelSize: 10

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.scanWifi()
                            }
                        }

                        Text {
                            text: "x"
                            color: closeMa.containsMouse ? root.theme.darkBlue : root.theme.fg
                            font.pixelSize: 20

                            MouseArea {
                                id: closeMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (root.wifiPasswordPageVisible) {
                                        root.wifiPasswordPageVisible = false
                                    } else if (root.wifiPageVisible) {
                                        root.wifiPageVisible = false
                                    } else if (root.bluetoothPageVisible) {
                                        root.bluetoothPageVisible = false
                                    } else {
                                        root.shown = false
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: root.theme.fgSubtle
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 520
                        radius: 8
                        color: root.theme.bgAlt
                        visible: root.bluetoothPageVisible

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            RowLayout {
                                Text {
                                    text: "Bluetooth"
                                    color: root.theme.darkBlue
                                    font.pixelSize: 16
                                    font.bold: true
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: BluetoothService.enabled ? "󰂯" : "󰂲"
                                    color: BluetoothService.enabled ? root.theme.green : root.theme.fgMuted
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: BluetoothService.setBluetoothEnabled(!BluetoothService.enabled)
                                    }
                                }
                                Text {
                                    text: "Scan"
                                    color: BluetoothService.discovering ? root.theme.yellow : root.theme.fgMuted
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: BluetoothService.setScanActive(!BluetoothService.discovering)
                                    }
                                }
                                Text {
                                    text: "⟳"
                                    color: root.theme.fgMuted
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            BluetoothService._refreshCounter = BluetoothService._refreshCounter + 1;
                                            BluetoothService.refreshDevices();
                                        }
                                    }
                                }
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 6
                                model: BluetoothService.devices

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 56
                                    radius: 8
                                    color: modelData.connected ? Qt.rgba(0.4, 0.8, 0.4, 0.15) : root.theme.bg

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.connected) {
                                                BluetoothService.disconnectDevice(modelData);
                                            } else if (BluetoothService.canConnect(modelData)) {
                                                BluetoothService.connectDeviceWithTrust(modelData);
                                            } else {
                                                BluetoothService.pairDevice(modelData);
                                            }
                                        }
                                        onPressAndHold: {
                                            BluetoothService.forgetDevice(modelData);
                                        }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 12

                                        Text {
                                            text: BluetoothService.getDeviceIcon(modelData)
                                            font.pixelSize: 20
                                        }

                                        ColumnLayout {
                                            Text {
                                                text: modelData.deviceName || modelData.alias || modelData.name || "Unknown"
                                                font.pixelSize: 13
                                                font.bold: modelData.connected
                                                color: root.theme.fg
                                            }
                                            Text {
                                                text: modelData.connected ? "Connected" : "Tap to connect"
                                                font.pixelSize: 10
                                                color: modelData.connected ? root.theme.green : root.theme.fgMuted
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        Text {
                                            text: modelData.connected ? "󰅙" : "󰂯"
                                            color: modelData.connected ? root.theme.red : root.theme.blue
                                            font.pixelSize: 18
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: BluetoothService.enabled && BluetoothService.available
                                text: BluetoothService.discovering ? "Searching for devices..." : "No devices found"
                                color: root.theme.fgMuted
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 520
                        radius: 8
                        color: root.theme.bgAlt
                        visible: root.wifiPageVisible

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                visible: root.wifiError !== ""
                                text: root.wifiError
                                font.family: root.theme.fontFamily
                                font.pixelSize: 11
                                color: root.theme.red
                                wrapMode: Text.WordWrap
                            }

                            ListView {
                                id: wifiListView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 5

                                model: root.wifiNetworks

                                delegate: WifiNetworkCard {
                                    width: ListView.view.width
                                    ssid: modelData.ssid || ""
                                    signal: modelData.signal || 0
                                    secure: modelData.secure || false
                                    active: modelData.active || false
                                    saved: modelData.saved || false
                                    connecting: modelData.connecting
                                    controlTheme: root.theme
                                }
                            }

                            WifiEmptyState {
                                visible: root.wifiPageVisible && (!root.wifiEnabled || root.wifiNetworks.length === 0) && !root.wifiScanning
                                controlTheme: root.theme
                            }
                        }
                    }

                    ColumnLayout {
                        visible: !root.bluetoothPageVisible && !root.wifiPageVisible && !root.wifiPasswordPageVisible
                        spacing: 12

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
                            rowSpacing: 10
                            columnSpacing: 10

                            QuickToggle {
                                icon: "󰤨"
                                iconOff: "󰤭"
                                label: "WiFi"
                                isOn: root.wifiEnabled
                                controlTheme: root.theme
                                onClick: () => { root.wifiPageVisible = !root.wifiPageVisible }
                            }

                            QuickToggle {
                                icon: "󰂯"
                                iconOff: "󰂲"
                                label: "Bluetooth"
                                isOn: BluetoothService.enabled
                                controlTheme: root.theme
                                onClick: () => { root.bluetoothPageVisible = !root.bluetoothPageVisible }
                            }

                            QuickToggle {
                                icon: "󰍶"
                                iconOff: "󰍷"
                                label: "DND"
                                isOn: root.dndEnabled
                                accentColor: root.theme.red
                                controlTheme: root.theme
                                onClick: () => { root.dndEnabled = !root.dndEnabled }
                            }

                            QuickToggle {
                                icon: "󰖨"
                                iconOff: "󱩌"
                                label: "Night"
                                isOn: root.nightLightEnabled
                                accentColor: root.theme.yellow
                                controlTheme: root.theme
                                onClick: () => root.toggleNightLight()
                            }

                            QuickToggle {
                                icon: "󰀝"
                                iconOff: "󰀞"
                                label: "Airplane"
                                isOn: root.airplaneMode
                                accentColor: root.theme.magenta
                                controlTheme: root.theme
                                onClick: () => root.toggleAirplaneMode()
                            }

                            QuickToggle {
                                icon: "󱐋"
                                iconOff: "󱐌"
                                label: "Power"
                                isOn: false
                                accentColor: root.theme.cyan
                                controlTheme: root.theme
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 60
                            radius: 8
                            color: root.theme.bgAlt
                            visible: root.nightLightEnabled

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    Text {
                                        text: "Night Light Temperature"
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 12
                                        color: root.theme.fg
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: root.nightLightTemperature + "K"
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.theme.yellow
                                    }
                                }

                                RowLayout {
                                    Text { text: "2500"; font.pixelSize: 9; color: root.theme.fgMuted }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 2500
                                        to: 6500
                                        value: root.nightLightTemperature
                                        // only apply when user moves — avoid restart loop when syncing from system
                                        onMoved: root.setNightLightTemp(Math.round(value))
                                    }
                                    Text { text: "6500"; font.pixelSize: 9; color: root.theme.fgMuted }
                                }
                            }
                        }

                        SliderCard {
                            Layout.fillWidth: true
                            icon: root.isMuted ? "󰖁" : "󰕾"
                            label: "Volume"
                            value: root.volumeLevel
                            accentColor: root.theme.blue
                            isMuted: root.isMuted
                            controlTheme: root.theme
                            liveValue: true
                            valueChangedHandler: (newVal) => root.setVolume(newVal)
                        }

                        SliderCard {
                            Layout.fillWidth: true
                            icon: "󰃟"
                            label: "Brightness"
                            value: root.brightnessLevel
                            accentColor: root.theme.yellow
                            controlTheme: root.theme
                            valueChangedHandler: (newVal) => {
                                const pct = Math.max(0, Math.min(100, Math.round(newVal)))
                                root.brightnessLevel = pct
                                brightnessSetProc.running = false
                                // linear percentage — same scale as brightnessGetProc
                                brightnessSetProc.command = ["${getExe pkgs.brightnessctl}", "-n2", "set", pct + "%"]
                                brightnessSetProc.running = true
                            }
                            liveValue: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: root.theme.fgSubtle
                        }

                        MediaCard {
                            Layout.fillWidth: true
                            controlTheme: root.theme
                        }
                    }
                }
            }

            Rectangle {
                id: passwordOverlay
                z: 100
                visible: root.wifiPasswordPageVisible
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.6)

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.wifiPasswordPageVisible = false
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width * 0.85
                    spacing: 20

                    Rectangle {
                        Layout.fillWidth: true
                        height: 250
                        radius: 12
                        color: root.theme.bgAlt

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 15

                            Text {
                                text: "󰤁"
                                font.family: root.theme.fontFamily
                                font.pixelSize: 36
                                color: root.theme.blue
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "Password Required"
                                font.family: root.theme.fontFamily
                                font.pixelSize: 12
                                color: root.theme.fgMuted
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: root.pendingWifiSsid
                                font.family: root.theme.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                                color: root.theme.fg
                                Layout.alignment: Qt.AlignHCenter
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 8
                                color: root.theme.bg

                                TextInput {
                                    id: passField
                                    anchors.fill: parent
                                    verticalAlignment: TextInput.AlignVCenter
                                    leftPadding: 15
                                    rightPadding: 40
                                    echoMode: passShow.checked ? TextInput.Normal : TextInput.Password
                                    color: root.theme.fg
                                    font.family: root.theme.fontFamily
                                    font.pixelSize: 12

                                    Text {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: passShow.checked ? "󰤁" : "󰤂"
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 14
                                        color: root.theme.fgMuted

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: passShow.checked = !passShow.checked
                                        }
                                    }
                                }

                                Item {
                                    id: passShow
                                    property bool checked: false
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 15

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 36
                                    radius: 8
                                    color: root.theme.bg

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Cancel"
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 12
                                        color: root.theme.fg
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            passField.text = ""
                                            root.wifiPasswordPageVisible = false
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 36
                                    radius: 8
                                    color: root.theme.blue

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Connect"
                                        font.family: root.theme.fontFamily
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.theme.bg
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.connectWifi(root.pendingWifiSsid, passField.text)
                                            passField.text = ""
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
  ''
else if isMango then
  /* qml */ ''
    import QtQuick
    import Quickshell
    Scope {
        id: root
        property bool shown: false
        property var theme: null

        function toggle() {
            shown = !shown
        }
    }
  ''
else
  /* qml */ ''
    import QtQuick
    import Quickshell
    Scope {
        id: root
        property bool shown: false
        property var theme: null

        function toggle() {
            shown = !shown
        }
    }
  ''

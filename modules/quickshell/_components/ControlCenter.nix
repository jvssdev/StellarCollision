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
  ''
    import QtQuick
    import QtQuick.Layouts
    import QtQuick.Controls
    import Quickshell
    import Quickshell.Wayland
    import Quickshell.Io
    import Quickshell.Services.Mpris
    import Quickshell.Services.Pipewire

    import "BluetoothService.qml"

    Scope {
        id: root
        property bool shown: false
        property var theme: null
        property var batteryObj: null
        property var networkObj: null
        property int brightnessLevel: 50
        property bool bluetoothPageVisible: false
        property bool wifiPageVisible: false

        onBluetoothPageVisibleChanged: {
            if (bluetoothPageVisible && !BluetoothService.enabled) {
                BluetoothService.setBluetoothEnabled(true);
            }
        }
        property bool wifiEnabled: false
        property bool wifiScanning: false
        property var wifiNetworks: []
        property string currentWifiSsid: ""
        property bool wifiConnecting: false
        property string pendingWifiSsid: ""
        property bool wifiPasswordPageVisible: false
        property bool airplaneMode: false

        onShownChanged: {
            if (shown && networkObj && !root.airplaneMode) {
                root.wifiEnabled = networkObj.type === "wifi"
                root.currentWifiSsid = networkObj.ssid || ""
            }
        }

        onWifiPageVisibleChanged: {
            if (wifiPageVisible && networkObj && !root.airplaneMode) {
                root.wifiEnabled = networkObj.type === "wifi"
                wifiListProc.running = true
            }
        }

        onNetworkObjChanged: {
            if (networkObj && !root.airplaneMode) {
                root.wifiEnabled = networkObj.type === "wifi"
                root.currentWifiSsid = networkObj.ssid || ""
            }
        }

        property var audioSink: Pipewire.defaultAudioSink
        property bool audioReady: audioSink !== null && audioSink.audio !== null && (audioSink.bound || false)
        property var audioObj: audioReady ? audioSink.audio : null
        property int volumeLevel: (audioObj !== null) ? Math.round((audioObj.volume || 0.5) * 100) : 50
        property bool isMuted: (audioObj !== null) ? (audioObj.muted || false) : false

        PwObjectTracker {
            objects: [audioSink]
        }

        Process {
            id: wifiListProc
            running: false
            command: ["${getExe pkgs.bash}", "-c", "nmcli -t -f SSID,SIGNAL,SECURITY,ACTIVE dev wifi list 2>/dev/null | head -20"]
            property string buffer: ""
            onRunningChanged: {
                if (running) {
                    root.wifiScanning = true
                }
                if (!running && buffer) {
                    var lines = buffer.trim().split("\n")
                    var uniqueSsids = {}
                    var networks = []
                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i].trim()
                        if (!line) continue
                        var parts = line.split(":")
                        if (parts.length < 4) continue
                        var active = parts[parts.length - 1] === "yes"
                        var security = parts[parts.length - 2]
                        var signal = parseInt(parts[parts.length - 3])
                        var ssid = parts.slice(0, parts.length - 3).join(":")
                        if (isNaN(signal)) signal = 0
                        if (ssid && !uniqueSsids[ssid]) {
                            uniqueSsids[ssid] = true
                            networks.push({
                                ssid: ssid,
                                signal: signal,
                                security: security,
                                active: active,
                                saved: false
                            })
                        }
                    }
                    networks.sort((a, b) => {
                        if (a.active) return -1
                        if (b.active) return 1
                        return b.signal - a.signal
                    })
                    root.wifiNetworks = networks
                    root.wifiScanning = false
                    buffer = ""
                }
            }
            stdout: SplitParser {
                onRead: data => {
                    wifiListProc.buffer += data + "\n"
                }
            }
        }

        Process {
            id: wifiRescanProc
            running: false
            command: ["${getExe pkgs.bash}", "-c", "nmcli device wifi rescan 2>/dev/null"]
            onRunningChanged: {
                if (!running) {
                    wifiListProc.running = true
                }
            }
        }

        Process {
            id: wifiToggleProc
            running: false
            command: ["${getExe pkgs.bash}", "-c", "true"]
            onRunningChanged: if (!running) {
                if (root.wifiEnabled) {
                    wifiListProc.running = true
                }
            }
        }

        Process {
            id: wifiConnectProc
            running: false
            command: ["${getExe pkgs.bash}", "-c", "true"]
            onRunningChanged: if (!running) {
                root.wifiConnecting = false
                root.wifiPasswordPageVisible = false
                wifiListProc.running = true
            }
        }

        Process {
            id: wifiDisconnectProc
            running: false
            command: ["${getExe pkgs.bash}", "-c", "nmcli dev disconnect iface wlan0"]
            onRunningChanged: if (!running) {
                wifiListProc.running = true
            }
        }

        Process {
            id: wifiForgetProc
            running: false
            command: ["${getExe pkgs.bash}", "-c", "true"]
            onRunningChanged: if (!running) {
                wifiListProc.running = true
            }
        }

        function forgetWifi(ssid) {
            wifiForgetProc.command = ["${getExe pkgs.bash}", "-c", "nmcli connection delete id '" + ssid + "'"]
            wifiForgetProc.running = true
        }

        function scanWifi() {
            wifiRescanProc.running = true
        }

        function toggleWifi() {
            if (root.airplaneMode) return
            var newState = !root.wifiEnabled
            root.wifiEnabled = newState
            wifiToggleProc.command = ["${getExe pkgs.bash}", "-c", "nmcli radio wifi " + (newState ? "on" : "off")]
            wifiToggleProc.running = true
        }

        function toggleAirplaneMode() {
            root.airplaneMode = !root.airplaneMode
            if (root.airplaneMode) {
                root.wifiEnabled = false
                wifiToggleProc.command = ["${getExe pkgs.bash}", "-c", "nmcli radio wifi off"]
                wifiToggleProc.running = true
            } else {
                root.wifiEnabled = false
                wifiToggleProc.command = ["${getExe pkgs.bash}", "-c", "nmcli radio wifi on"]
                wifiToggleProc.running = true
            }
        }

        function connectWifi(ssid, password) {
            root.wifiConnecting = true
            root.wifiPasswordPageVisible = false
            if (password) {
                wifiConnectProc.command = ["${getExe pkgs.bash}", "-c", "nmcli dev wifi connect '" + ssid + "' password '" + password + "'"]
            } else {
                wifiConnectProc.command = ["${getExe pkgs.bash}", "-c", "nmcli dev wifi connect '" + ssid + "'"]
            }
            wifiConnectProc.running = true
        }

        function disconnectWifi() {
            wifiDisconnectProc.running = true
        }

        function getWifiIcon(signal) {
            if (signal >= 75) return "󰤨"
            if (signal >= 50) return "󰤥"
            if (signal >= 25) return "󰤢"
            return "󰤟"
        }

        function setVolume(newVal) {
            if (audioReady && audioObj) {
                audioObj.muted = false
                audioObj.volume = newVal / 100
            } else {
                volumeSetProc.command = ["${getExe' pkgs.wireplumber "wpctl"}", "set-volume", "@DEFAULT_AUDIO_SINK@", (newVal / 100).toString()]
                volumeSetProc.running = true
            }
        }

        function toggleMute() {
            if (audioReady && audioObj) {
                audioObj.muted = !audioObj.muted
            } else {
                volumeMuteProc.running = true
            }
        }

        function toggle() {
            shown = !shown
        }

        property bool nightLightEnabled: false
        property int nightLightTemperature: 4500

        Process {
            id: nightLightProc
            running: false
            command: ["bash", "-c", "true"]
        }

        function toggleNightLight() {
            root.nightLightEnabled = !root.nightLightEnabled
            if (root.nightLightEnabled) {
                nightLightProc.command = ["bash", "-c", "pkill gammastep 2>/dev/null; gammastep -P -O " + root.nightLightTemperature + " &"]
                nightLightProc.startDetached()
            } else {
                nightLightProc.command = ["bash", "-c", "pkill gammastep 2>/dev/null; gammastep -x"]
                nightLightProc.running = true
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
            var players = Mpris.players.values;
            if (players.length === 0) return null;
            for (var i = 0; i < players.length; i++) {
                if (players[i].isPlaying) return players[i];
            }
            return players[0];
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                root.activePlayer = root.getActivePlayer()
            }
        }

        function setNightLightTemp(temp) {
            root.nightLightTemperature = temp
            nightLightProc.command = ["bash", "-c", "pkill gammastep 2>/dev/null; gammastep -P -O " + temp + " &"]
            if (!root.nightLightEnabled) {
                root.nightLightEnabled = true
            }
            nightLightProc.startDetached()
        }

        Process {
            id: checkNightLightProc
            running: true
            command: ["${getExe pkgs.bash}", "-c", "pgrep gammastep > /dev/null && echo 1 || echo 0"]
            stdout: SplitParser {
                onRead: data => {
                    root.nightLightEnabled = data.trim() === "1"
                }
            }
        }

        component QuickToggle: Rectangle {
            id: toggle
            property string icon: "󰛨"
            property string iconOff: icon
            property string label: "Toggle"
            property bool isOn: false
            property color accentColor: controlTheme?.green || "#A3BE8C"
            property var controlTheme: null
            property var onClick: null

            Layout.fillWidth: true
            height: 60
            radius: 8
            color: isOn ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : (controlTheme?.bgAlt || "#3B4252")
            border.width: isOn ? 2 : 0
            border.color: accentColor

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.width { NumberAnimation { duration: 150 } }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: toggle.isOn ? toggle.icon : toggle.iconOff
                    font.family: toggle.controlTheme?.fontFamily || "monospace"
                    font.pixelSize: 18
                    color: toggle.isOn ? toggle.accentColor : (toggle.controlTheme?.fgMuted || "#434C5E")
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: toggle.label
                    font.family: toggle.controlTheme?.fontFamily || "monospace"
                    font.pixelSize: 10
                    color: toggle.isOn ? (toggle.controlTheme?.fg || "#D8DEE9") : (toggle.controlTheme?.fgMuted || "#434C5E")
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
            property color accentColor: controlTheme?.blue || "#81A1C1"
            property bool isMuted: false
            property var controlTheme: null
            property var valueChangedHandler: null

            height: 70
            radius: 8
            color: controlTheme?.bgAlt || "#3B4252"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: sliderCard.icon
                        font.family: sliderCard.controlTheme?.fontFamily || "monospace"
                        font.pixelSize: 16
                        color: sliderCard.isMuted ? (sliderCard.controlTheme?.fgMuted || "#434C5E") : sliderCard.accentColor
                    }

                    Text {
                        text: sliderCard.label
                        font.family: sliderCard.controlTheme?.fontFamily || "monospace"
                        font.pixelSize: 12
                        color: sliderCard.controlTheme?.fg || "#D8DEE9"
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: sliderCard.value + "%"
                        font.family: sliderCard.controlTheme?.fontFamily || "monospace"
                        font.pixelSize: 12
                        font.bold: true
                        color: sliderCard.controlTheme?.fgMuted || "#434C5E"
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
                        color: controlTheme?.bg || "#2E3440"

                        Rectangle {
                            width: (sliderCard.value / 100) * parent.width
                            height: parent.height
                            radius: parent.radius
                            color: sliderCard.isMuted ? (sliderCard.controlTheme?.fgMuted || "#434C5E") : sliderCard.accentColor
                        }
                    }

                    Rectangle {
                        x: (sliderCard.value / 100) * (parent.width - width)
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14
                        height: 14
                        radius: 7
                        color: sliderCard.isMuted ? (sliderCard.controlTheme?.fgMuted || "#434C5E") : sliderCard.accentColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                var newVal = Math.max(0, Math.min(100, (mouse.x / width) * 100))
                                sliderCard.value = Math.round(newVal)
                                if (sliderCard.valueChangedHandler) sliderCard.valueChangedHandler(newVal)
                            }
                        }
                        onClicked: (mouse) => {
                            var newVal = Math.max(0, Math.min(100, (mouse.x / width) * 100))
                            sliderCard.value = Math.round(newVal)
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
            color: controlTheme?.bgAlt || "#3B4252"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Rectangle {
                    width: 56
                    height: 56
                    radius: 6
                    color: controlTheme?.bg || "#2E3440"

                    Image {
                        anchors.fill: parent
                        source: mediaCard.artUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: mediaCard.artUrl !== ""
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰝚"
                        font.family: mediaCard.controlTheme?.fontFamily || "monospace"
                        font.pixelSize: 24
                        color: mediaCard.controlTheme?.fgMuted || "#434C5E"
                        visible: mediaCard.artUrl === ""
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: mediaCard.title
                        font.family: mediaCard.controlTheme?.fontFamily || "monospace"
                        font.pixelSize: 12
                        font.bold: true
                        color: mediaCard.controlTheme?.fg || "#D8DEE9"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: mediaCard.artist || "Unknown artist"
                        font.family: mediaCard.controlTheme?.fontFamily || "monospace"
                        font.pixelSize: 10
                        color: mediaCard.controlTheme?.fgMuted || "#434C5E"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: mediaCard.album || ""
                        font.family: mediaCard.controlTheme?.fontFamily || "monospace"
                        font.pixelSize: 9
                        color: mediaCard.controlTheme?.fgMuted || "#434C5E"
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
                        color: prevMouse.containsMouse ? (mediaCard.controlTheme?.bg || "#2E3440") : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰒮"
                            font.family: mediaCard.controlTheme?.fontFamily || "monospace"
                            font.pixelSize: 14
                            color: mediaCard.controlTheme?.fg || "#D8DEE9"
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
                        color: mediaCard.controlTheme?.darkBlue || "#5E81AC"

                        Text {
                            anchors.centerIn: parent
                            text: mediaCard.isPlaying ? "󰏤" : "󰐊"
                            font.family: mediaCard.controlTheme?.fontFamily || "monospace"
                            font.pixelSize: 16
                            color: mediaCard.controlTheme?.bg || "#2E3440"
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
                        color: nextMouse.containsMouse ? (mediaCard.controlTheme?.bg || "#2E3440") : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰒭"
                            font.family: mediaCard.controlTheme?.fontFamily || "monospace"
                            font.pixelSize: 14
                            color: mediaCard.controlTheme?.fg || "#D8DEE9"
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
            color: controlTheme?.bg || "#2E3440"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Text {
                    text: root.getWifiIcon(wifiCard.signal)
                    font.family: wifiCard.controlTheme?.fontFamily || "monospace"
                    font.pixelSize: 18
                    color: wifiCard.active ? (wifiCard.controlTheme?.green || "#A3BE8C") : (wifiCard.controlTheme?.fgMuted || "#434C5E")
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: wifiCard.ssid
                        font.family: wifiCard.controlTheme?.fontFamily || "monospace"
                        font.pixelSize: 12
                        font.bold: wifiCard.active
                        color: wifiCard.controlTheme?.fg || "#D8DEE9"
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
                        font.family: wifiCard.controlTheme?.fontFamily || "monospace"
                        font.pixelSize: 10
                        color: wifiCard.active ? (wifiCard.controlTheme?.green || "#A3BE8C") : (wifiCard.controlTheme?.fgMuted || "#434C5E")
                    }
                }

                Text {
                    text: wifiCard.signal + "%"
                    font.family: wifiCard.controlTheme?.fontFamily || "monospace"
                    font.pixelSize: 10
                    color: wifiCard.controlTheme?.fgMuted || "#434C5E"
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
                color: controlTheme?.bg || "#2E3440"
                z: 1000

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: 6
                    color: menuMouse.containsMouse ? (controlTheme?.bgAlt || "#3B4252") : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Forget Network"
                        font.family: controlTheme?.fontFamily || "monospace"
                        font.pixelSize: 11
                        color: controlTheme?.red || "#BF616A"
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
            color: controlTheme?.bgAlt || "#3B4252"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                Rectangle {
                    width: 64
                    height: 64
                    radius: 32
                    color: controlTheme?.bg || "#2E3440"
                    Layout.alignment: Qt.AlignHCenter

                    Text {
                        anchors.centerIn: parent
                        text: root.wifiScanning ? "󰤩" : (root.wifiEnabled ? "󰤫" : "󰤮")
                        font.family: controlTheme?.fontFamily || "monospace"
                        font.pixelSize: 28
                        color: controlTheme?.fgMuted || "#434C5E"
                        opacity: 0.5
                    }
                }

                Text {
                    text: {
                        if (!root.wifiEnabled) return "Wi-Fi Off"
                        if (root.wifiScanning) return "Scanning..."
                        return "No networks found"
                    }
                    font.family: controlTheme?.fontFamily || "monospace"
                    font.pixelSize: 12
                    color: controlTheme?.fgMuted || "#434C5E"
                    opacity: 0.7
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        component WifiPasswordPage: Rectangle {
            id: passPage
            property string targetSsid: ""
            property var controlTheme: null

            color: controlTheme?.bgAlt || "#3B4252"
            radius: 12

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width * 0.85
                spacing: 20

                Text {
                    text: "󰤁"
                    font.family: controlTheme?.fontFamily || "monospace"
                    font.pixelSize: 48
                    color: controlTheme?.blue || "#81A1C1"
                    Layout.alignment: Qt.AlignHCenter
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 5

                    Text {
                        text: "Password Required"
                        color: controlTheme?.fgMuted || "#434C5E"
                        font.pixelSize: 12
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: passPage.targetSsid
                        color: controlTheme?.fg || "#D8DEE9"
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
                    color: controlTheme?.bg || "#2E3440"

                    TextInput {
                        id: passTextInput
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        leftPadding: 15
                        rightPadding: 40
                        echoMode: showPassToggle.checked ? TextInput.Normal : TextInput.Password
                        color: controlTheme?.fg || "#D8DEE9"
                        font.family: controlTheme?.fontFamily || "monospace"
                        font.pixelSize: 12

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: showPassToggle.checked ? "󰤁" : "󰤂"
                            font.family: controlTheme?.fontFamily || "monospace"
                            font.pixelSize: 16
                            color: controlTheme?.fgMuted || "#434C5E"

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
                        color: controlTheme?.bg || "#2E3440"

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.family: controlTheme?.fontFamily || "monospace"
                            font.pixelSize: 12
                            color: controlTheme?.fg || "#D8DEE9"
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
                        color: controlTheme?.blue || "#81A1C1"

                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            font.family: controlTheme?.fontFamily || "monospace"
                            font.pixelSize: 12
                            font.bold: true
                            color: controlTheme?.bg || "#2E3440"
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

        Process {
            id: brightnessGetProc
            command: ["${getExe pkgs.brightnessctl}", "-m", "get"]
            stdout: SplitParser {
                onRead: data => {
                    if (data) {
                        var parts = data.trim().split(",")
                        if (parts.length >= 4) {
                            var current = parseInt(parts[2])
                            var max = parseInt(parts[3])
                            if (max > 0) {
                                root.brightnessLevel = Math.round((current / max) * 100)
                            }
                        }
                    }
                }
            }
        }

        Process {
            id: brightnessSetProc
            command: ["${getExe pkgs.brightnessctl}", "-e4", "-n2", "set", "50%"]
        }

        Timer {
            interval: 5000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: brightnessGetProc.running = true
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
                top: 40
                right: 20
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
                color: root.theme?.bg || "#2E3440"
                border.color: root.theme?.fgSubtle || "#4C566A"
                border.width: 2
                radius: 12

                ColumnLayout {
                    id: contentColumn
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: root.wifiPasswordPageVisible ? "Password" : (root.wifiPageVisible ? "Wi-Fi" : (root.bluetoothPageVisible ? "Bluetooth" : "Control Center"))
                            color: root.theme?.darkBlue || "#5E81AC"
                            font.pixelSize: 16
                            font.bold: true
                            font.family: root.theme?.fontFamily || "monospace"
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            visible: root.bluetoothPageVisible && !root.wifiPageVisible && !root.wifiPasswordPageVisible
                            text: "Power"
                            color: root.theme?.fgMuted || "#434C5E"
                            font.pixelSize: 10
                        }

                        Rectangle {
                            visible: root.bluetoothPageVisible && !root.wifiPageVisible && !root.wifiPasswordPageVisible
                            width: 44
                            height: 24
                            radius: 12
                            color: BluetoothService.enabled ? (root.theme?.green || "#A3BE8C") : (root.theme?.fgMuted || "#434C5E")

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
                            color: root.theme?.fgMuted || "#434C5E"
                            font.pixelSize: 10
                        }

                        Rectangle {
                            visible: root.wifiPageVisible && !root.wifiPasswordPageVisible
                            width: 44
                            height: 24
                            radius: 12
                            color: root.wifiEnabled ? (root.theme?.green || "#A3BE8C") : (root.theme?.bg || "#2E3440")

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
                                color: root.wifiEnabled ? "#FFFFFF" : (root.theme?.fgMuted || "#434C5E")
                            }
                        }

                        Text {
                            visible: root.wifiPageVisible && !root.wifiPasswordPageVisible
                            text: "Scan"
                            color: root.theme?.fgMuted || "#434C5E"
                            font.pixelSize: 10

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.scanWifi()
                            }
                        }

                        Text {
                            text: "X"
                            color: closeMa.containsMouse ? root.theme?.darkBlue : root.theme?.fg
                            font.pixelSize: 14

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
                        color: root.theme?.fgSubtle || "#4C566A"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 520
                        radius: 8
                        color: root.theme?.bgAlt || "#3B4252"
                        visible: root.bluetoothPageVisible

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            RowLayout {
                                Text {
                                    text: "Bluetooth"
                                    color: root.theme?.darkBlue
                                    font.pixelSize: 16
                                    font.bold: true
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: BluetoothService.enabled ? "󰂯" : "󰂲"
                                    color: BluetoothService.enabled ? root.theme?.green : root.theme?.fgMuted
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: BluetoothService.setBluetoothEnabled(!BluetoothService.enabled)
                                    }
                                }
                                Text {
                                    text: "Scan"
                                    color: BluetoothService.discovering ? root.theme?.yellow : root.theme?.fgMuted
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: BluetoothService.setScanActive(!BluetoothService.discovering)
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
                                    color: modelData.connected ? Qt.rgba(0.4, 0.8, 0.4, 0.15) : root.theme?.bg || "#2E3440"

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
                                                text: modelData.alias || modelData.name || "Unknown"
                                                font.pixelSize: 13
                                                font.bold: modelData.connected
                                                color: root.theme?.fg
                                            }
                                            Text {
                                                text: modelData.connected ? "Connected" : (modelData.paired ? "Paired" : "")
                                                font.pixelSize: 10
                                                color: modelData.connected ? root.theme?.green : root.theme?.fgMuted
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        MouseArea {
                                            width: 40
                                            height: 40
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.connected) {
                                                    BluetoothService.disconnectDevice(modelData);
                                                } else {
                                                    if (modelData.paired || modelData.trusted) {
                                                        BluetoothService.connectDevice(modelData);
                                                    } else {
                                                        BluetoothService.pairDevice(modelData);
                                                    }
                                                }
                                            }
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.connected ? "󰅙" : "󰂯"
                                                color: modelData.connected ? root.theme?.red : root.theme?.blue
                                                font.pixelSize: 18
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onPressAndHold: BluetoothService.forgetDevice(modelData)
                                    }
                                }
                            }

                            Text {
                                visible: BluetoothService.enabled && BluetoothService.available
                                text: BluetoothService.discovering ? "Searching for devices..." : "No devices found"
                                color: root.theme?.fgMuted
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 520
                        radius: 8
                        color: root.theme?.bgAlt || "#3B4252"
                        visible: root.wifiPageVisible

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

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
                                    connecting: root.wifiConnecting && root.pendingWifiSsid === modelData.ssid
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
                                isOn: false
                                accentColor: root.theme?.red || "#BF616A"
                                controlTheme: root.theme
                            }

                            QuickToggle {
                                icon: "󰖨"
                                iconOff: "󱩌"
                                label: "Night"
                                isOn: root.nightLightEnabled
                                accentColor: root.theme?.yellow || "#EBCB8B"
                                controlTheme: root.theme
                                onClick: () => root.toggleNightLight()
                            }

                            QuickToggle {
                                icon: "󰀝"
                                iconOff: "󰀞"
                                label: "Airplane"
                                isOn: root.airplaneMode
                                accentColor: root.theme?.magenta || "#B48EAD"
                                controlTheme: root.theme
                                onClick: () => root.toggleAirplaneMode()
                            }

                            QuickToggle {
                                icon: "󱐋"
                                iconOff: "󱐌"
                                label: "Power"
                                isOn: false
                                accentColor: root.theme?.cyan || "#8FBCBB"
                                controlTheme: root.theme
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 60
                            radius: 8
                            color: root.theme?.bgAlt || "#3B4252"
                            visible: root.nightLightEnabled

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    Text {
                                        text: "Night Light Temperature"
                                        font.family: root.theme?.fontFamily || "monospace"
                                        font.pixelSize: 12
                                        color: root.theme?.fg || "#D8DEE9"
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: root.nightLightTemperature + "K"
                                        font.family: root.theme?.fontFamily || "monospace"
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.theme?.yellow || "#EBCB8B"
                                    }
                                }

                                RowLayout {
                                    Text { text: "2500"; font.pixelSize: 9; color: root.theme?.fgMuted }
                                    Slider {
                                        Layout.fillWidth: true
                                        from: 2500
                                        to: 6500
                                        value: root.nightLightTemperature
                                        onValueChanged: root.setNightLightTemp(Math.round(value))
                                    }
                                    Text { text: "6500"; font.pixelSize: 9; color: root.theme?.fgMuted }
                                }
                            }
                        }

                        SliderCard {
                            Layout.fillWidth: true
                            icon: root.isMuted ? "󰖁" : "󰕾"
                            label: "Volume"
                            value: root.volumeLevel
                            accentColor: root.theme?.blue || "#81A1C1"
                            isMuted: root.isMuted
                            controlTheme: root.theme
                            valueChangedHandler: (newVal) => root.setVolume(newVal)
                        }

                        SliderCard {
                            Layout.fillWidth: true
                            icon: "󰃟"
                            label: "Brightness"
                            value: root.brightnessLevel
                            accentColor: root.theme?.yellow || "#EBCB8B"
                            controlTheme: root.theme
                            valueChangedHandler: (newVal) => {
                                brightnessSetProc.command = ["${getExe pkgs.brightnessctl}", "-e4", "-n2", "set", newVal + "%"]
                                brightnessSetProc.running = true
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: root.theme?.fgSubtle || "#4C566A"
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
                        color: root.theme?.bgAlt || "#3B4252"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 15

                            Text {
                                text: "󰤁"
                                font.family: root.theme?.fontFamily || "monospace"
                                font.pixelSize: 36
                                color: root.theme?.blue || "#81A1C1"
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "Password Required"
                                font.family: root.theme?.fontFamily || "monospace"
                                font.pixelSize: 12
                                color: root.theme?.fgMuted || "#434C5E"
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: root.pendingWifiSsid
                                font.family: root.theme?.fontFamily || "monospace"
                                font.pixelSize: 14
                                font.bold: true
                                color: root.theme?.fg || "#D8DEE9"
                                Layout.alignment: Qt.AlignHCenter
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 8
                                color: root.theme?.bg || "#2E3440"

                                TextInput {
                                    id: passField
                                    anchors.fill: parent
                                    verticalAlignment: TextInput.AlignVCenter
                                    leftPadding: 15
                                    rightPadding: 40
                                    echoMode: passShow.checked ? TextInput.Normal : TextInput.Password
                                    color: root.theme?.fg || "#D8DEE9"
                                    font.family: root.theme?.fontFamily || "monospace"
                                    font.pixelSize: 12

                                    Text {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: passShow.checked ? "󰤁" : "󰤂"
                                        font.family: root.theme?.fontFamily || "monospace"
                                        font.pixelSize: 14
                                        color: root.theme?.fgMuted || "#434C5E"

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
                                    color: root.theme?.bg || "#2E3440"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Cancel"
                                        font.family: root.theme?.fontFamily || "monospace"
                                        font.pixelSize: 12
                                        color: root.theme?.fg || "#D8DEE9"
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
                                    color: root.theme?.blue || "#81A1C1"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Connect"
                                        font.family: root.theme?.fontFamily || "monospace"
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.theme?.bg || "#2E3440"
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
  ''
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
  ''
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

{
  isNiri,
  isMango,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) getExe;
in
if isNiri then
  ''
    import QtQuick
    import QtQuick.Layouts
    import QtQuick.Controls
    import Quickshell
    import Quickshell.Wayland
    import Quickshell.Io
    import Quickshell.Bluetooth
    import Quickshell.Services.Mpris

    Scope {
        id: root
        property bool shown: false
        property var theme: null
        property var volumeObj: null
        property var batteryObj: null
        property int brightnessLevel: 50
        property bool bluetoothPageVisible: false

        function toggle() {
            shown = !shown
        }

        // Night Light state
        property bool nightLightEnabled: false
        property int nightLightTemperature: 4500

        // Toggle Night Light
        function toggleNightLight() {
            console.log("Toggle night light called, current state:", root.nightLightEnabled)
            root.nightLightEnabled = !root.nightLightEnabled
            if (root.nightLightEnabled) {
                console.log("Starting gammastep at " + root.nightLightTemperature + "K...")
                nightLightOn.startDetached()
            } else {
                console.log("Stopping gammastep...")
                nightLightOff.running = true
            }
        }

        // Initial check disabled - only check on toggle
        Component.onCompleted: {
            checkNightLightProc.running = true
        }

        // MPRIS for media control
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

        // Update media properties when players change
        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                root.activePlayer = root.getActivePlayer()
            }
        }

        // Process to start night light (uses current temperature)
        Process {
            id: nightLightOn
            command: ["${getExe pkgs.bash}", "-c", "pkill gammastep 2>/dev/null; sleep 0.2; ${getExe pkgs.gammastep} -P -O " + root.nightLightTemperature + " &"]
        }

        // Process to set night light temperature
        Process {
            id: nightLightWarm
            command: ["${getExe pkgs.bash}", "-c", "pkill gammastep 2>/dev/null; sleep 0.2; ${getExe pkgs.gammastep} -P -O 3500 &"]
        }

        Process {
            id: nightLightNormal
            command: ["${getExe pkgs.bash}", "-c", "pkill gammastep 2>/dev/null; sleep 0.2; ${getExe pkgs.gammastep} -P -O 4500 &"]
        }

        Process {
            id: nightLightCool
            command: ["${getExe pkgs.bash}", "-c", "pkill gammastep 2>/dev/null; sleep 0.2; ${getExe pkgs.gammastep} -P -O 5500 &"]
        }

        // Process to stop night light
        Process {
            id: nightLightOff
            command: ["${getExe pkgs.bash}", "-c", "pkill gammastep 2>/dev/null; sleep 0.2; ${getExe pkgs.gammastep} -x 2>/dev/null"]
        }

        // Set temperature preset
        function setNightLightTemp(temp) {
            root.nightLightTemperature = temp
            if (!root.nightLightEnabled) {
                root.nightLightEnabled = true
            }
            if (temp === 3500) {
                nightLightWarm.startDetached()
            } else if (temp === 4500) {
                nightLightNormal.startDetached()
            } else if (temp === 5500) {
                nightLightCool.startDetached()
            }
        }

        // Process to check status
        Process {
            id: checkNightLightProc
            running: true
            command: ["${getExe pkgs.bash}", "-c", "pgrep gammastep > /dev/null && echo 1 || echo 0"]
            stdout: SplitParser {
                onRead: data => {
                    console.log("Night light check:", data.trim() === "1" ? "running" : "not found")
                    root.nightLightEnabled = data.trim() === "1"
                }
            }
        }

        // Timer to check status periodically (disabled for now)
        Timer {
            interval: 10000
            running: false
            repeat: true
            triggeredOnStart: false
            onTriggered: checkNightLightProc.running = true
        }

        // Quick Toggle Component
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

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Text {
                    text: toggle.label
                    font.family: toggle.controlTheme?.fontFamily || "monospace"
                    font.pixelSize: 10
                    color: toggle.isOn ? (toggle.controlTheme?.fg || "#D8DEE9") : (toggle.controlTheme?.fgMuted || "#434C5E")
                    Layout.alignment: Qt.AlignHCenter

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (toggle.onClick) {
                        toggle.onClick()
                    } else {
                        toggle.isOn = !toggle.isOn
                    }
                }
            }
        }

        // Slider Card Component
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

                            Behavior on width { NumberAnimation { duration: 50 } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    Rectangle {
                        x: (sliderCard.value / 100) * (parent.width - width)
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14
                        height: 14
                        radius: 7
                        color: sliderCard.isMuted ? (sliderCard.controlTheme?.fgMuted || "#434C5E") : sliderCard.accentColor

                        Behavior on x { NumberAnimation { duration: 50 } }
                        Behavior on color { ColorAnimation { duration: 150 } }
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

        // Media Card Component
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
                                if (mediaCard.isPlaying) {
                                    root.activePlayer?.pause()
                                } else {
                                    root.activePlayer?.play()
                                }
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

        // Action Button Component
        component ActionButton: Rectangle {
            id: actionBtn

            property string icon: "󰐥"
            property string label: "Action"
            property color accentColor: controlTheme?.darkBlue || "#5E81AC"
            property var controlTheme: null

            signal clicked()

            height: 44
            radius: 8
            color: btnMouse.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2) : (controlTheme?.bgAlt || "#3B4252")
            border.width: btnMouse.containsMouse ? 2 : 0
            border.color: accentColor

            Behavior on color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: actionBtn.icon
                    font.family: actionBtn.controlTheme?.fontFamily || "monospace"
                    font.pixelSize: 16
                    color: actionBtn.accentColor
                }

                Text {
                    text: actionBtn.label
                    font.family: actionBtn.controlTheme?.fontFamily || "monospace"
                    font.pixelSize: 12
                    color: actionBtn.controlTheme?.fg || "#D8DEE9"
                }
            }

            MouseArea {
                id: btnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: actionBtn.clicked()
            }
        }

        // Process to get current brightness
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

        // Process to set brightness
        Process {
            id: brightnessSetProc
            command: ["${getExe pkgs.brightnessctl}", "-e4", "-n2", "set", "50%"]
        }

        // Timer to update brightness periodically
        Timer {
            interval: 5000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: brightnessGetProc.running = true
        }

        PanelWindow {
            id: ccWindow
            visible: root.shown
            screen: Quickshell.screens[0]
            color: "transparent"

            implicitWidth: 380
            implicitHeight: 600

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
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
                        if (root.bluetoothPageVisible) {
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

                    // Fixed Header - shows Control Center or Bluetooth
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: root.bluetoothPageVisible ? "Bluetooth" : "Control Center"
                            color: root.theme?.darkBlue || "#5E81AC"
                            font.pixelSize: 16
                            font.bold: true
                            font.family: root.theme?.fontFamily || "monospace"
                        }

                        Item { Layout.fillWidth: true }

                        // Show Power toggle when Bluetooth page is visible
                        Text {
                            visible: root.bluetoothPageVisible
                            text: "Power"
                            color: root.theme?.fgMuted || "#434C5E"
                            font.pixelSize: 10
                        }

                        Rectangle {
                            visible: root.bluetoothPageVisible
                            width: 44
                            height: 24
                            radius: 12
                            color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? (root.theme?.green || "#A3BE8C") : (root.theme?.fgMuted || "#434C5E")

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (Bluetooth.defaultAdapter) {
                                        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                                    }
                                }
                            }

                            Rectangle {
                                x: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? 22 : 2
                                y: 2
                                width: 20
                                height: 20
                                radius: 10
                                color: "#FFFFFF"
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
                                    if (root.bluetoothPageVisible) {
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

                    // Show Bluetooth page as full content when visible
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

                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true

                                model: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? Bluetooth.defaultAdapter.devices : []

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 50
                                    radius: 8
                                    color: root.theme?.bg || "#2E3440"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10

                                        Text {
                                            text: modelData.icon || "󰂯"
                                            font.family: root.theme?.fontFamily || "monospace"
                                            font.pixelSize: 18
                                            color: modelData.connected ? (root.theme?.blue || "#81A1C1") : (root.theme?.fgMuted || "#434C5E")
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Text {
                                                text: modelData.name || modelData.address || "Unknown"
                                                font.family: root.theme?.fontFamily || "monospace"
                                                font.pixelSize: 12
                                                color: root.theme?.fg || "#D8DEE9"
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                text: {
                                                    if (modelData.state === 1) return "Connected"
                                                    if (modelData.state === 2) return "Connecting..."
                                                    if (modelData.state === 3) return "Disconnecting..."
                                                    return modelData.paired ? "Paired" : ""
                                                }
                                                font.family: root.theme?.fontFamily || "monospace"
                                                font.pixelSize: 10
                                                color: root.theme?.fgMuted || "#434C5E"
                                            }
                                        }

                                        Text {
                                            text: modelData.connected ? "󰤬" : "󰛲"
                                            font.family: root.theme?.fontFamily || "monospace"
                                            font.pixelSize: 16
                                            color: modelData.connected ? (root.theme?.green || "#A3BE8C") : (root.theme?.fgMuted || "#434C5E")
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.connected) {
                                                modelData.disconnect()
                                            } else {
                                                modelData.connect()
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: !Bluetooth.defaultAdapter || !Bluetooth.defaultAdapter.enabled
                                text: !Bluetooth.defaultAdapter ? "No adapter" : "Bluetooth is off"
                                font.family: root.theme?.fontFamily || "monospace"
                                font.pixelSize: 12
                                color: root.theme?.fgMuted || "#434C5E"
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    // Regular content (hidden when Bluetooth page is visible)
                    ColumnLayout {
                        visible: !root.bluetoothPageVisible
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
                            isOn: true
                            controlTheme: root.theme
                        }

                        QuickToggle {
                            icon: "󰂯"
                            iconOff: "󰂲"
                            label: "Bluetooth"
                            isOn: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
                            controlTheme: root.theme
                            onClick: () => {
                                root.bluetoothPageVisible = !root.bluetoothPageVisible
                            }
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
                            isOn: false
                            accentColor: root.theme?.magenta || "#B48EAD"
                            controlTheme: root.theme
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

                    // Night Light Temperature Card
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
                                Text {
                                    text: "2500"
                                    font.family: root.theme?.fontFamily || "monospace"
                                    font.pixelSize: 9
                                    color: root.theme?.fgMuted || "#434C5E"
                                }

                                Slider {
                                    id: nightTempSlider
                                    Layout.fillWidth: true
                                    from: 2500
                                    to: 6500
                                    value: root.nightLightTemperature
                                    onValueChanged: {
                                        root.nightLightTemperature = Math.round(value)
                                        nightLightSetProc.running = false
                                        nightLightSetProc.command = ["${getExe pkgs.bash}", "-c", "pkill gammastep 2>/dev/null; ${getExe pkgs.gammastep} -P -O " + root.nightLightTemperature + " &"]
                                        nightLightSetProc.running = true
                                    }
                                }

                                Process {
                                    id: nightLightSetProc
                                    running: false
                                }

                                Text {
                                    text: "6500"
                                    font.family: root.theme?.fontFamily || "monospace"
                                    font.pixelSize: 9
                                    color: root.theme?.fgMuted || "#434C5E"
                                }
                            }

                            // Temperature Presets
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 28
                                    radius: 6
                                    color: root.theme?.bg || "#2E3440"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Warm"
                                        font.family: root.theme?.fontFamily || "monospace"
                                        font.pixelSize: 10
                                        color: root.theme?.fg || "#D8DEE9"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setNightLightTemp(3500)
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 28
                                    radius: 6
                                    color: root.theme?.bg || "#2E3440"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Normal"
                                        font.family: root.theme?.fontFamily || "monospace"
                                        font.pixelSize: 10
                                        color: root.theme?.fg || "#D8DEE9"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setNightLightTemp(4500)
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 28
                                    radius: 6
                                    color: root.theme?.bg || "#2E3440"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Cool"
                                        font.family: root.theme?.fontFamily || "monospace"
                                        font.pixelSize: 10
                                        color: root.theme?.fg || "#D8DEE9"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setNightLightTemp(5500)
                                    }
                                }
                            }
                        }
                    }

                    SliderCard {
                        Layout.fillWidth: true
                        icon: root.volumeObj?.muted ? "󰖁" : "󰕾"
                        label: "Volume"
                        value: root.volumeObj?.level || 50
                        accentColor: root.theme?.blue || "#81A1C1"
                        isMuted: root.volumeObj?.muted || false
                        controlTheme: root.theme
                    }

                    SliderCard {
                        id: brightnessSlider
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

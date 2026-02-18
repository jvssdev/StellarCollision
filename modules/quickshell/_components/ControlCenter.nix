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

    Scope {
        id: root
        property bool shown: false
        property var theme: null
        property var volumeObj: null
        property var batteryObj: null
        property int brightnessLevel: 50

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

        // Process to start night light (default 4500K)
        Process {
            id: nightLightOn
            command: ["${getExe pkgs.bash}", "-c", "pkill gammastep 2>/dev/null; sleep 0.2; ${getExe pkgs.gammastep} -P -O 4500 &"]
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
            command: ["pidof", "gammastep"]
            stdout: SplitParser {
                onRead: data => {
                    console.log("Night light check:", data.length > 0 ? "running" : "not found")
                    root.nightLightEnabled = data.length > 0
                }
            }
        }

        // Timer to check status periodically
        Timer {
            interval: 5000
            running: true
            repeat: true
            triggeredOnStart: true
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

            property string title: "No media playing"
            property string artist: ""
            property bool isPlaying: false
            property var controlTheme: null

            height: 80
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

                    Text {
                        anchors.centerIn: parent
                        text: "󰝚"
                        font.family: mediaCard.controlTheme?.fontFamily || "monospace"
                        font.pixelSize: 24
                        color: mediaCard.controlTheme?.fgMuted || "#434C5E"
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
                            onClicked: mediaPrev.running = true
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
                                mediaCard.isPlaying = !mediaCard.isPlaying
                                mediaToggle.running = true
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
                            onClicked: mediaNext.running = true
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
            implicitHeight: contentColumn.implicitHeight + 60

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
                        root.shown = false
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
                            text: "Control Center"
                            color: root.theme?.darkBlue || "#5E81AC"
                            font.pixelSize: 16
                            font.bold: true
                            font.family: root.theme?.fontFamily || "monospace"
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "X"
                            color: closeMa.containsMouse ? root.theme?.darkBlue : root.theme?.fg
                            font.pixelSize: 14

                            MouseArea {
                                id: closeMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.shown = false
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: root.theme?.fgSubtle || "#4C566A"
                    }

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
                            isOn: false
                            controlTheme: root.theme
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
                                    onValueChanged: root.nightLightTemperature = value
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

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: root.theme?.fgSubtle || "#4C566A"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ActionButton {
                            Layout.fillWidth: true
                            icon: "󰌾"
                            label: "Lock"
                            onClicked: lockProcess.running = true
                            controlTheme: root.theme
                        }

                        ActionButton {
                            Layout.fillWidth: true
                            icon: "󰐥"
                            label: "Power"
                            accentColor: root.theme?.red || "#BF616A"
                            onClicked: powerProcess.running = true
                            controlTheme: root.theme
                        }
                    }
                }
            }
        }

        Process {
            id: lockProcess
            command: ["hyprlock"]
        }

        Process {
            id: powerProcess
            command: ["wlogout"]
        }

        Process {
            id: mediaToggle
            command: ["playerctl", "play-pause"]
        }

        Process {
            id: mediaPrev
            command: ["playerctl", "previous"]
        }

        Process {
            id: mediaNext
            command: ["playerctl", "next"]
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

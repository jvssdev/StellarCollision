{ isNiri, isMango, ... }:
if isNiri then
  ''
    import QtQuick
    import QtQuick.Layouts
    import Quickshell
    import Quickshell.Wayland
    import Quickshell.Services.Notifications

    PanelWindow {
        id: root
        property bool shown: false
        property var notifServer: null
        property var theme: null

        visible: shown
        screen: Quickshell.screens[0]
        color: "transparent"
        implicitWidth: 400
        implicitHeight: Math.min(600, Quickshell.screens[0]?.height * 0.8 || 600)

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
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

        property var urgencyIcons: ({
            [NotificationUrgency.Low]: "󰂚",
            [NotificationUrgency.Normal]: "󰂚",
            [NotificationUrgency.Critical]: "󰂛"
        })
        property var urgencyColors: ({
            [NotificationUrgency.Low]: theme.fgMuted,
            [NotificationUrgency.Normal]: theme.darkBlue,
            [NotificationUrgency.Critical]: theme.red
        })

        Rectangle {
            anchors.fill: parent
            color: theme.bg
            border.color: theme.fgSubtle
            border.width: theme.borderWidth
            radius: theme.radius

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: theme.padding
                spacing: theme.spacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: theme.spacing

                    Text {
                        text: "Notifications"
                        color: theme.darkBlue
                        font.pixelSize: 16
                        font.bold: true
                        font.family: theme.fontFamily
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        color: clearMa.containsMouse ? theme.red : "transparent"
                        radius: theme.radius / 2
                        visible: notificationList.count > 0

                        Text {
                            anchors.centerIn: parent
                            text: "Clear"
                            color: clearMa.containsMouse ? theme.bg : theme.red
                            font.pixelSize: 10
                            font.family: theme.fontFamily
                        }

                        MouseArea {
                            id: clearMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                let count = root.notifServer?.trackedNotifications?.count ?? 0
                                for (let i = count - 1; i >= 0; i--) {
                                    let notif = root.notifServer?.trackedNotifications?.get(i)
                                    if (notif) notif.dismiss()
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        color: closeMa.containsMouse ? theme.darkBlue : "transparent"
                        radius: theme.radius / 2

                        Text {
                            anchors.centerIn: parent
                            text: "X"
                            color: closeMa.containsMouse ? theme.bg : theme.fg
                            font.pixelSize: 12
                            font.family: theme.fontFamily
                        }

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
                    color: theme.fgSubtle
                }

                ListView {
                    id: notificationList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: theme.spacing
                    clip: true
                    model: root.notifServer?.trackedNotifications

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: notificationList.width
                        height: notificationColumn.implicitHeight + theme.padding * 2
                        color: index % 2 === 0 ? theme.bgAlt : theme.bg
                        border.color: modelData ? (root.urgencyColors[modelData.urgency] || theme.darkBlue) : theme.darkBlue
                        border.width: 1
                        radius: theme.radius / 2
                        visible: modelData !== null

                        ColumnLayout {
                            id: notificationColumn
                            anchors.fill: parent
                            anchors.margins: theme.padding
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: modelData ? (root.urgencyIcons[modelData.urgency] || "N") : "N"
                                    color: modelData ? (root.urgencyColors[modelData.urgency] || theme.darkBlue) : theme.darkBlue
                                    font.pixelSize: 14
                                    font.family: theme.fontFamily
                                }

                                Text {
                                    text: modelData ? (modelData.appName || "Unknown") : "Unknown"
                                    color: theme.fg
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: theme.fontFamily
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "x"
                                    color: dismissMa.containsMouse ? theme.red : theme.fgMuted
                                    font.pixelSize: 12
                                    font.family: theme.fontFamily

                                    MouseArea {
                                        id: dismissMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: if (modelData) modelData.dismiss()
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData ? modelData.summary : ""
                                color: theme.fg
                                font.pixelSize: 13
                                font.bold: true
                                font.family: theme.fontFamily
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData ? modelData.body : ""
                                color: theme.fgMuted
                                font.pixelSize: 11
                                font.family: theme.fontFamily
                                wrapMode: Text.WordWrap
                                visible: modelData && modelData.body && modelData.body !== ""
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "No notifications"
                        color: theme.fgMuted
                        font.pixelSize: 14
                        font.family: theme.fontFamily
                        visible: notificationList.count === 0
                    }
                }
            }
        }
    }
  ''
else if isMango then
  ''
    import QtQuick
    import QtQuick.Layouts
    import Quickshell
    import Quickshell.Wayland
    import Quickshell.Services.Notifications

    PanelWindow {
        id: root
        property bool shown: false
        property var notifServer: null
        property var theme: null

        visible: shown
        screen: Quickshell.screens[0]
        color: "transparent"
        implicitWidth: shown ? 400 : 0
        implicitHeight: shown ? Math.min(600, Quickshell.screens[0]?.height * 0.8 || 600) : 0

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
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

        property var urgencyIcons: ({
            [NotificationUrgency.Low]: "󰂚",
            [NotificationUrgency.Normal]: "󰂚",
            [NotificationUrgency.Critical]: "󰂛"
        })
        property var urgencyColors: ({
            [NotificationUrgency.Low]: root.theme?.fgMuted || "#434C5E",
            [NotificationUrgency.Normal]: root.theme?.darkBlue || "#5E81AC",
            [NotificationUrgency.Critical]: root.theme?.red || "#BF616A"
        })

        Rectangle {
            anchors.fill: parent
            color: root.theme?.bg || "#2E3440"
            border.color: root.theme?.fgSubtle || "#4C566A"
            border.width: root.theme?.borderWidth || 2
            radius: root.theme?.radius || 10
            visible: root.shown

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.theme?.padding || 14
                spacing: root.theme?.spacing || 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.theme?.spacing || 10

                    Text {
                        text: "Notifications"
                        color: root.theme?.darkBlue || "#5E81AC"
                        font.pixelSize: 16
                        font.bold: true
                        font.family: root.theme?.fontFamily || "monospace"
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        color: clearMa.containsMouse ? (root.theme?.red || "#BF616A") : "transparent"
                        radius: (root.theme?.radius || 10) / 2
                        visible: notificationList.count > 0

                        Text {
                            anchors.centerIn: parent
                            text: "Clear"
                            color: clearMa.containsMouse ? (root.theme?.bg || "#2E3440") : (root.theme?.red || "#BF616A")
                            font.pixelSize: 10
                            font.family: root.theme?.fontFamily || "monospace"
                        }

                        MouseArea {
                            id: clearMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                let count = root.notifServer?.trackedNotifications?.count ?? 0
                                for (let i = count - 1; i >= 0; i--) {
                                    let notif = root.notifServer?.trackedNotifications?.get(i)
                                    if (notif) notif.dismiss()
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        color: closeMa.containsMouse ? (root.theme?.darkBlue || "#5E81AC") : "transparent"
                        radius: (root.theme?.radius || 10) / 2

                        Text {
                            anchors.centerIn: parent
                            text: "X"
                            color: closeMa.containsMouse ? (root.theme?.bg || "#2E3440") : (root.theme?.fg || "#D8DEE9")
                            font.pixelSize: 12
                            font.family: root.theme?.fontFamily || "monospace"
                        }

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

                ListView {
                    id: notificationList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: root.theme?.spacing || 10
                    clip: true
                    model: root.notifServer?.trackedNotifications

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: notificationList.width
                        height: notificationColumn.implicitHeight + (root.theme?.padding || 14) * 2
                        color: index % 2 === 0 ? (root.theme?.bgAlt || "#3B4252") : (root.theme?.bg || "#2E3440")
                        border.color: modelData ? (root.urgencyColors[modelData.urgency] || (root.theme?.darkBlue || "#5E81AC")) : (root.theme?.darkBlue || "#5E81AC")
                        border.width: 1
                        radius: (root.theme?.radius || 10) / 2
                        visible: modelData !== null

                        ColumnLayout {
                            id: notificationColumn
                            anchors.fill: parent
                            anchors.margins: root.theme?.padding || 14
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: modelData ? (root.urgencyIcons[modelData.urgency] || "N") : "N"
                                    color: modelData ? (root.urgencyColors[modelData.urgency] || (root.theme?.darkBlue || "#5E81AC")) : (root.theme?.darkBlue || "#5E81AC")
                                    font.pixelSize: 14
                                    font.family: root.theme?.fontFamily || "monospace"
                                }

                                Text {
                                    text: modelData ? (modelData.appName || "Unknown") : "Unknown"
                                    color: root.theme?.fg || "#D8DEE9"
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: root.theme?.fontFamily || "monospace"
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "x"
                                    color: dismissMa.containsMouse ? (root.theme?.red || "#BF616A") : (root.theme?.fgMuted || "#434C5E")
                                    font.pixelSize: 12
                                    font.family: root.theme?.fontFamily || "monospace"

                                    MouseArea {
                                        id: dismissMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: if (modelData) modelData.dismiss()
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData ? modelData.summary : ""
                                color: root.theme?.fg || "#D8DEE9"
                                font.pixelSize: 13
                                font.bold: true
                                font.family: root.theme?.fontFamily || "monospace"
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData ? modelData.body : ""
                                color: root.theme?.fgMuted || "#434C5E"
                                font.pixelSize: 11
                                font.family: root.theme?.fontFamily || "monospace"
                                wrapMode: Text.WordWrap
                                visible: modelData && modelData.body && modelData.body !== ""
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "No notifications"
                        color: root.theme?.fgMuted || "#434C5E"
                        font.pixelSize: 14
                        font.family: root.theme?.fontFamily || "monospace"
                        visible: notificationList.count === 0
                    }
                }
            }
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
        property var notifServer: null
        // No compositor detected
    }
  ''

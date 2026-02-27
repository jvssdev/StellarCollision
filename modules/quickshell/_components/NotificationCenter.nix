{ isNiri, isMango, ... }:
if isNiri then
  /* qml */ ''
    import QtQuick
    import QtQuick.Layouts
    import Quickshell
    import Quickshell.Wayland
    import Quickshell.Services.Notifications

    Scope {
        id: root
        property bool shown: false
        property var notifServer: null
        property var theme: null

        function toggle() {
            shown = !shown
        }

        PanelWindow {
            id: ncWindow
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
                top: 22
                right: 5
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
                    anchors.fill: parent
                    anchors.topMargin: 10
                    anchors.bottomMargin: 18
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 30
                        Text {
                            text: "Notifications"
                            color: root.theme?.darkBlue || "#5E81AC"
                            font.pixelSize: 16
                            font.bold: true
                            font.family: root.theme?.fontFamily || "monospace"
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "Clear"
                            color: clearMa.containsMouse ? root.theme?.red : root.theme?.fgMuted
                            font.pixelSize: 14

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

                        Text {
                            text: "x"
                            color: closeMa.containsMouse ? root.theme?.darkBlue : root.theme?.fg
                            font.pixelSize: 20

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
                        spacing: 10
                        clip: true
                        model: root.notifServer?.trackedNotifications

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: notificationList.width
                            height: 90
                            color: index % 2 === 0 ? (root.theme?.bgAlt || "#3B4252") : (root.theme?.bg || "#2E3440")
                            radius: 12
                            visible: modelData !== null

                            Row {
                                anchors.fill: parent
                                anchors.margins: 26
                                spacing: 10

                                Text {
                                    text: modelData && modelData.appName ? modelData.appName[0].toUpperCase() : "N"
                                    color: root.theme?.darkBlue || "#5E81AC"
                                    font.pixelSize: 19
                                    font.bold: true
                                    width: 30
                                }

                                Column {
                                    width: parent.width - 50
                                    spacing: 4

                                    Text {
                                        text: modelData ? modelData.summary : ""
                                        color: root.theme?.fg || "#D8DEE9"
                                        font.pixelSize: 15
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData ? modelData.body : ""
                                        color: root.theme?.fgMuted || "#434C5E"
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                        maximumLineCount: 2
                                    }
                                }

                                Text {
                                    text: "x"
                                    color: dismissMa.containsMouse ? root.theme?.red : root.theme?.fgMuted
                                    font.pixelSize: 16

                                    MouseArea {
                                        id: dismissMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: if (modelData) modelData.dismiss()
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "No notifications"
                            color: root.theme?.fgMuted || "#434C5E"
                            font.pixelSize: 14
                            visible: notificationList.count === 0
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
        property var notifServer: null
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
        property var notifServer: null
        property var theme: null

        function toggle() {
            shown = !shown
        }
    }
  ''

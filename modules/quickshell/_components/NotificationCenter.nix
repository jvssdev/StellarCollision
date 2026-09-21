{ isNiri, isMango, ... }:
if isNiri || isMango then
  /* qml */ ''
    import QtQuick
    import QtQuick.Layouts
    import QtQuick.Effects
    import Quickshell
    import Quickshell.Io
    import Quickshell.Wayland
    import Quickshell.Services.Notifications
    import Quickshell.Widgets

    Scope {
        id: root
        property bool shown: false
        property var notifServer: null
        property var theme: null
        property var history: []

        signal clearHistory()
        signal removeEntry(int index)

        function toggle() {
            shown = !shown
        }

        property string _clipboardText: ""

        Process {
            id: copyProc
            command: ["wl-copy", root._clipboardText]
        }

        PanelWindow {
            id: ncWindow
            visible: root.shown
            screen: Quickshell.screens[0]
            color: "transparent"

            implicitWidth: 400
            implicitHeight: 620

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                right: true
            }

            margins {
                top: 18
                right: 12
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

            // backdrop-ish card
            Rectangle {
                anchors.fill: parent
                color: root.theme.bg
                border.color: root.theme.darkBlue
                border.width: 2
                radius: 14

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            text: "󰂚"
                            color: root.theme.darkBlue
                            font.pixelSize: 20
                            font.family: root.theme.fontFamily
                        }

                        Text {
                            text: "Notifications"
                            color: root.theme.fg
                            font.pixelSize: 16
                            font.bold: true
                            font.family: root.theme.fontFamily
                        }

                        Text {
                            visible: root.history.length > 0
                            text: "(" + root.history.length + ")"
                            color: root.theme.fgMuted
                            font.pixelSize: 13
                            font.family: root.theme.fontFamily
                        }

                        Item { Layout.fillWidth: true }

                        // clear all
                        Rectangle {
                            width: clearLabel.implicitWidth + 16
                            height: 28
                            radius: 8
                            color: clearMa.containsMouse ? root.theme.bgLighter : "transparent"
                            border.width: clearMa.containsMouse ? 1 : 0
                            border.color: root.theme.fgSubtle
                            visible: root.history.length > 0

                            Text {
                                id: clearLabel
                                anchors.centerIn: parent
                                text: "Clear all"
                                color: clearMa.containsMouse ? root.theme.red : root.theme.fgMuted
                                font.pixelSize: 12
                                font.family: root.theme.fontFamily
                            }

                            MouseArea {
                                id: clearMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.clearHistory()
                            }
                        }

                        // close
                        Text {
                            text: "✕"
                            color: closeMa.containsMouse ? root.theme.darkBlue : root.theme.fgMuted
                            font.pixelSize: 18
                            width: 24
                            horizontalAlignment: Text.AlignHCenter

                            MouseArea {
                                id: closeMa
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.shown = false
                            }
                        }
                    }

                    // separator
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: root.theme.fgSubtle
                        opacity: 0.5
                    }

                    // empty state
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: notificationList.count === 0

                        Column {
                            anchors.centerIn: parent
                            spacing: 12

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰂜"
                                color: root.theme.fgMuted
                                font.pixelSize: 52
                                font.family: root.theme.fontFamily
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No notifications"
                                color: root.theme.fgMuted
                                font.pixelSize: 14
                                font.family: root.theme.fontFamily
                            }
                        }
                    }

                    // list
                    ListView {
                        id: notificationList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 8
                        clip: true
                        model: root.history
                        visible: notificationList.count > 0
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            id: entry
                            required property var modelData
                            required property int index

                            width: notificationList.width
                            height: entryInner.implicitHeight + 20
                            radius: 12
                            color: index % 2 === 0 ? root.theme.bgAlt : root.theme.bg
                            border.width: 1
                            border.color: {
                                if (!modelData) return "transparent"
                                if (modelData.urgency === 2) return root.theme.red   // Critical
                                if (modelData.urgency === 0) return root.theme.fgSubtle // Low
                                return "transparent"
                            }

                            property bool expanded: false

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                onClicked: entry.expanded = !entry.expanded
                            }

                            Column {
                                id: entryInner
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: 12
                                }
                                spacing: 6

                                Row {
                                    width: parent.width
                                    spacing: 12

                                    // icon / letter
                                    Item {
                                        width: 36
                                        height: 36

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 9
                                            color: root.theme.bgLighter
                                            visible: !histImg.visible
                                        }

                                        Image {
                                            id: histImg
                                            anchors.fill: parent
                                            source: modelData && (modelData.image || modelData.appIcon) ? (modelData.image || modelData.appIcon) : ""
                                            fillMode: Image.PreserveAspectCrop
                                            visible: status === Image.Ready
                                            layer.enabled: true
                                            layer.effect: MultiEffect {
                                                maskEnabled: true
                                                maskSource: histMask
                                            }
                                        }

                                        Rectangle {
                                            id: histMask
                                            anchors.fill: parent
                                            radius: 9
                                            visible: false
                                            layer.enabled: true
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            visible: !histImg.visible
                                            text: modelData && modelData.appName ? modelData.appName.charAt(0).toUpperCase() : "N"
                                            font.pixelSize: 15
                                            font.bold: true
                                            color: root.theme.darkBlue
                                            font.family: root.theme.fontFamily
                                        }
                                    }

                                    Column {
                                        width: parent.width - 36 - 70
                                        spacing: 2
                                        anchors.verticalCenter: parent.verticalCenter

                                        Text {
                                            width: parent.width
                                            text: modelData ? modelData.summary : ""
                                            color: root.theme.fg
                                            font.pixelSize: 14
                                            font.bold: true
                                            font.family: root.theme.fontFamily
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }

                                        Text {
                                            width: parent.width
                                            text: modelData ? modelData.body : ""
                                            color: root.theme.fgMuted
                                            font.pixelSize: 12
                                            font.family: root.theme.fontFamily
                                            elide: Text.ElideRight
                                            maximumLineCount: entry.expanded ? 10 : 2
                                            wrapMode: Text.WordWrap
                                            visible: modelData && modelData.body
                                            textFormat: {
                                                if (!modelData || !modelData.body) return Text.PlainText
                                                return /[<*_`#\[\]]/.test(modelData.body) ? Text.MarkdownText : Text.PlainText
                                            }
                                        }

                                        Text {
                                            visible: modelData && modelData.appName
                                            text: modelData ? modelData.appName : ""
                                            color: root.theme.fgSubtle
                                            font.pixelSize: 11
                                            font.family: root.theme.fontFamily
                                        }
                                    }

                                    // actions: copy + dismiss
                                    Row {
                                        spacing: 10
                                        anchors.verticalCenter: parent.verticalCenter

                                        Text {
                                            text: "󱉥"
                                            color: copyMa.containsMouse ? root.theme.darkBlue : root.theme.fgMuted
                                            font.pixelSize: 16
                                            width: 22
                                            horizontalAlignment: Text.AlignHCenter

                                            MouseArea {
                                                id: copyMa
                                                anchors.fill: parent
                                                anchors.margins: -4
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (!modelData) return
                                                    root._clipboardText = modelData.summary + (modelData.body ? "\n" + modelData.body : "")
                                                    copyProc.running = true
                                                }
                                            }
                                        }

                                        Text {
                                            text: "✕"
                                            color: dismissMa.containsMouse ? root.theme.red : root.theme.fgMuted
                                            font.pixelSize: 15
                                            width: 22
                                            horizontalAlignment: Text.AlignHCenter

                                            MouseArea {
                                                id: dismissMa
                                                anchors.fill: parent
                                                anchors.margins: -4
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.removeEntry(index)
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

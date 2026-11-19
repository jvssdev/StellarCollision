import QtQuick
import QtQuick.Effects

Item {
    id: root
    width: 1920
    height: 1080
    focus: true

    readonly property real s: width / 1920
    readonly property string fontFamily: "@fontFamily@"
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#99aab5"
    readonly property color accent: "#cde4ef"
    readonly property color danger: "#ff4444"
    readonly property color base: "#05080c"

    property string userName: ""
    property string sessionName: ""
    property var sessions: null
    property int sessionIndex: 0
    property bool showSession: false
    property bool showPower: false
    property bool canSwitchUser: false
    property bool busy: false
    property bool failed: false
    property string message: ""
    property bool sessionMenuOpen: false
    property date now: new Date()

    signal submitted(string password)
    signal userClicked()
    signal sessionSelected(int index)
    signal rebootRequested()
    signal powerOffRequested()

    function reportFailure(text) {
        failed = true
        message = text
        passInput.text = ""
        shake.restart()
        passInput.forceActiveFocus()
    }

    function focusPassword() {
        passInput.forceActiveFocus()
    }

    Component.onCompleted: passInput.forceActiveFocus()

    Timer {
        interval: 300
        running: true
        onTriggered: passInput.forceActiveFocus()
    }

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: root.now = new Date()
    }

    Rectangle {
        anchors.fill: parent
        color: root.base
    }

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("background.png")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#40000000" }
            GradientStop { position: 0.5; color: "#00000000" }
            GradientStop { position: 1.0; color: "#b005080c" }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        onClicked: root.sessionMenuOpen = false
    }

    Column {
        anchors.top: parent.top
        anchors.topMargin: 120 * root.s
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 15 * root.s

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: clockText.width
            height: clockText.height

            MultiEffect {
                source: clockText
                anchors.fill: clockText
                shadowEnabled: true
                shadowColor: "#000000"
                shadowOpacity: 0.35
                shadowBlur: 1.0
                shadowVerticalOffset: 6 * root.s
            }

            Text {
                id: clockText
                text: Qt.formatTime(root.now, "HH:mm")
                font.family: root.fontFamily
                font.pixelSize: 180 * root.s
                font.weight: Font.Light
                color: root.textPrimary
            }
        }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: dateText.width
            height: dateText.height

            MultiEffect {
                source: dateText
                anchors.fill: dateText
                shadowEnabled: true
                shadowColor: "#000000"
                shadowOpacity: 0.6
                shadowBlur: 0.6
                shadowVerticalOffset: 2 * root.s
            }

            Text {
                id: dateText
                text: Qt.formatDate(root.now, "dddd, MMMM d").toUpperCase()
                font.family: root.fontFamily
                font.pixelSize: 18 * root.s
                font.letterSpacing: 12 * root.s
                font.weight: Font.DemiBold
                color: root.accent
            }
        }
    }

    Item {
        id: loginArea
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 160 * root.s
        width: 400 * root.s
        height: 120 * root.s

        Column {
            anchors.centerIn: parent
            width: parent.width
            spacing: 25 * root.s

            Item {
                width: parent.width
                height: 30 * root.s

                Column {
                    anchors.centerIn: parent
                    spacing: 2 * root.s

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "USER"
                        font.family: root.fontFamily
                        font.pixelSize: 10 * root.s
                        font.letterSpacing: 4 * root.s
                        color: root.textSecondary
                        opacity: 0.8
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (root.userName !== "" ? root.userName : "UNKNOWN").toUpperCase()
                        font.family: root.fontFamily
                        font.pixelSize: 18 * root.s
                        font.letterSpacing: 3 * root.s
                        font.weight: Font.Bold
                        color: userArea.containsMouse && root.canSwitchUser ? root.accent : root.textPrimary
                        scale: userArea.containsMouse && root.canSwitchUser ? 1.08 : 1.0
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    }
                }

                MouseArea {
                    id: userArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.canSwitchUser
                    cursorShape: root.canSwitchUser ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.userClicked()
                }
            }

            Item {
                id: passBox
                anchors.horizontalCenter: parent.horizontalCenter
                width: 320 * root.s
                height: 50 * root.s
                transform: Translate { id: shakeShift; x: 0 }

                TextInput {
                    id: passInput
                    anchors.fill: parent
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "·"
                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                    font.family: root.fontFamily
                    font.pixelSize: 32 * root.s
                    font.letterSpacing: 10 * root.s
                    color: root.textPrimary
                    selectionColor: root.accent
                    selectedTextColor: root.base
                    clip: true
                    focus: true
                    readOnly: root.busy
                    cursorDelegate: Item { width: 0; height: 0 }
                    onAccepted: {
                        if (text.length > 0) root.submitted(text)
                    }
                    onTextEdited: {
                        root.failed = false
                        root.message = ""
                    }
                    Keys.onEscapePressed: {
                        text = ""
                        root.sessionMenuOpen = false
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "PASSWORD"
                        font.family: root.fontFamily
                        font.pixelSize: 14 * root.s
                        font.letterSpacing: 6 * root.s
                        color: root.textSecondary
                        opacity: passInput.text.length === 0 ? 0.6 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
                    }

                    Rectangle {
                        id: caret
                        width: 2.2 * root.s
                        height: 32 * root.s
                        color: root.textPrimary
                        anchors.verticalCenter: parent.verticalCenter
                        x: passInput.cursorRectangle.x - width / 2
                        visible: passInput.activeFocus && passInput.text.length > 0

                        SequentialAnimation {
                            loops: Animation.Infinite
                            running: caret.visible
                            NumberAnimation { target: caret; property: "opacity"; from: 1; to: 0.05; duration: 450 }
                            NumberAnimation { target: caret; property: "opacity"; from: 0.05; to: 1; duration: 450 }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor
                        onClicked: passInput.forceActiveFocus()
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 1
                    width: passInput.activeFocus ? parent.width : parent.width * 0.3
                    color: root.failed ? root.danger : root.textPrimary
                    opacity: passInput.activeFocus ? 0.8 : 0.2
                    Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
                    Behavior on opacity { NumberAnimation { duration: 350 } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Text {
                width: parent.width
                height: 15 * root.s
                verticalAlignment: Text.AlignTop
                horizontalAlignment: Text.AlignHCenter
                text: root.busy ? "VERIFYING" : root.message
                color: root.busy ? root.accent : root.danger
                font.family: root.fontFamily
                font.pixelSize: 10 * root.s
                font.letterSpacing: 2 * root.s
            }
        }
    }

    SequentialAnimation {
        id: shake
        NumberAnimation { target: shakeShift; property: "x"; to: -10 * root.s; duration: 50 }
        NumberAnimation { target: shakeShift; property: "x"; to: 10 * root.s; duration: 50 }
        NumberAnimation { target: shakeShift; property: "x"; to: -10 * root.s; duration: 50 }
        NumberAnimation { target: shakeShift; property: "x"; to: 10 * root.s; duration: 50 }
        NumberAnimation { target: shakeShift; property: "x"; to: 0; duration: 50 }
    }

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 50 * root.s
        height: 40 * root.s
        visible: root.showSession || root.showPower

        Row {
            id: sessionRow
            visible: root.showSession
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            spacing: 12 * root.s

            Text {
                text: "SESSION"
                font.family: root.fontFamily
                font.pixelSize: 12 * root.s
                font.letterSpacing: 2 * root.s
                color: root.textSecondary
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 1
                height: 14 * root.s
                color: root.textSecondary
                opacity: 0.5
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: (root.sessionName !== "" ? root.sessionName : "DEFAULT").toUpperCase()
                font.family: root.fontFamily
                font.pixelSize: 14 * root.s
                font.weight: Font.Bold
                font.letterSpacing: 1 * root.s
                color: sessionArea.containsMouse ? root.textPrimary : root.accent
                scale: sessionArea.containsMouse ? 1.08 : 1.0
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
            }
        }

        MouseArea {
            id: sessionArea
            visible: root.showSession
            anchors.fill: sessionRow
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.sessionMenuOpen = !root.sessionMenuOpen
        }

        Row {
            visible: root.showPower
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 25 * root.s

            Text {
                text: "REBOOT"
                font.family: root.fontFamily
                font.pixelSize: 12 * root.s
                font.letterSpacing: 2 * root.s
                color: rebootArea.containsMouse ? root.textPrimary : root.textSecondary
                scale: rebootArea.containsMouse ? 1.12 : 1.0
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                MouseArea {
                    id: rebootArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.rebootRequested()
                }
            }

            Text {
                text: "SHUTDOWN"
                font.family: root.fontFamily
                font.pixelSize: 12 * root.s
                font.letterSpacing: 2 * root.s
                color: powerArea.containsMouse ? "#ff6b6b" : root.textSecondary
                scale: powerArea.containsMouse ? 1.12 : 1.0
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                MouseArea {
                    id: powerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.powerOffRequested()
                }
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: 50 * root.s
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100 * root.s
        width: 220 * root.s
        height: sessionList.count * 45 * root.s + 20 * root.s
        color: "#d005080c"
        border.color: "#33cde4ef"
        border.width: 1
        radius: 4 * root.s
        opacity: root.sessionMenuOpen && root.showSession ? 1.0 : 0.0
        scale: root.sessionMenuOpen && root.showSession ? 1.0 : 0.96
        transformOrigin: Item.BottomLeft
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 250 } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

        ListView {
            id: sessionList
            anchors.fill: parent
            anchors.margins: 10 * root.s
            model: root.sessions
            clip: true

            delegate: Item {
                width: ListView.view.width
                height: 45 * root.s

                Text {
                    anchors.centerIn: parent
                    text: (model.name || "UNNAMED").toUpperCase()
                    font.family: root.fontFamily
                    font.pixelSize: 13 * root.s
                    font.letterSpacing: 2 * root.s
                    font.weight: index === root.sessionIndex ? Font.Bold : Font.Normal
                    color: index === root.sessionIndex ? root.accent : (itemArea.containsMouse ? root.textPrimary : root.textSecondary)
                }

                MouseArea {
                    id: itemArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.sessionSelected(index)
                        root.sessionMenuOpen = false
                    }
                }
            }
        }
    }
}

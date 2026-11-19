import QtQuick

Item {
    id: root
    width: 1920
    height: 1080

    readonly property bool hasUsers: typeof userModel !== "undefined" && userModel !== null
    readonly property bool hasSessions: typeof sessionModel !== "undefined" && sessionModel !== null

    property int userIndex: hasUsers && userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: hasSessions && sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0

    ListView {
        id: userHelper
        model: root.hasUsers ? userModel : null
        currentIndex: root.userIndex
        width: 1
        height: 1
        opacity: 0
        z: -100
        delegate: Item {
            property string loginName: model.name || ""
            property string displayName: model.realName || model.name || ""
        }
    }

    ListView {
        id: sessionHelper
        model: root.hasSessions ? sessionModel : null
        currentIndex: root.sessionIndex
        width: 1
        height: 1
        opacity: 0
        z: -100
        delegate: Item {
            property string sessionTitle: model.name || ""
        }
    }

    LoginScene {
        id: scene
        anchors.fill: parent
        userName: userHelper.currentItem ? userHelper.currentItem.displayName : ""
        sessionName: sessionHelper.currentItem ? sessionHelper.currentItem.sessionTitle : ""
        sessions: root.hasSessions ? sessionModel : null
        sessionIndex: root.sessionIndex
        showSession: true
        showPower: true
        canSwitchUser: userHelper.count > 1

        onSubmitted: password => {
            var name = userHelper.currentItem && userHelper.currentItem.loginName !== ""
                ? userHelper.currentItem.loginName
                : (root.hasUsers ? userModel.lastUser : "")
            sddm.login(name, password, root.sessionIndex)
        }
        onUserClicked: root.userIndex = (root.userIndex + 1) % userHelper.count
        onSessionSelected: index => root.sessionIndex = index
        onRebootRequested: sddm.reboot()
        onPowerOffRequested: sddm.powerOff()
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null

        function onLoginFailed() {
            scene.reportFailure("ACCESS DENIED")
        }
    }

    Component.onCompleted: {
        if (typeof keyboard !== "undefined") keyboard.numLock = true
    }
}

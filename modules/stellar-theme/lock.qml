import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    id: shell

    readonly property bool testMode: Quickshell.env("STELLAR_LOCK_TEST") === "1"
    readonly property string userName: Quickshell.env("USER") || "user"

    property bool locked: true
    property bool authenticating: false

    signal failed(string text)

    function tryUnlock(password) {
        if (authenticating || password === "") return
        authenticating = true
        pam.pendingPassword = password
        pam.start()
    }

    function finish() {
        locked = false
        quitTimer.start()
    }

    PamContext {
        id: pam
        config: "stellar-lock"
        property string pendingPassword: ""

        onPamMessage: {
            if (pam.responseRequired) pam.respond(pam.pendingPassword)
        }

        onCompleted: result => {
            shell.authenticating = false
            pam.pendingPassword = ""
            if (result === PamResult.Success) {
                shell.finish()
            } else if (result === PamResult.Error) {
                shell.failed("PAM ERROR")
            } else {
                shell.failed("ACCESS DENIED")
            }
        }
    }

    Timer {
        id: quitTimer
        interval: 150
        onTriggered: Qt.quit()
    }

    Component {
        id: sceneComponent

        LoginScene {
            id: scene
            userName: shell.userName
            busy: shell.authenticating
            onSubmitted: password => shell.tryUnlock(password)

            Connections {
                target: shell

                function onFailed(text) {
                    scene.reportFailure(text)
                }
            }
        }
    }

    Loader {
        active: !shell.testMode

        sourceComponent: Component {
            WlSessionLock {
                locked: shell.locked

                surface: Component {
                    WlSessionLockSurface {
                        color: "black"

                        Loader {
                            anchors.fill: parent
                            sourceComponent: sceneComponent
                        }
                    }
                }
            }
        }
    }

    Loader {
        active: shell.testMode

        sourceComponent: Component {
            FloatingWindow {
                visible: true
                title: "stellar-lock test"
                implicitWidth: 1280
                implicitHeight: 720

                Loader {
                    anchors.fill: parent
                    sourceComponent: sceneComponent
                }
            }
        }
    }
}

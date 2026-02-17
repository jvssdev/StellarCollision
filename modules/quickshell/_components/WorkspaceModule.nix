{
  fontFamily,
  isNiri,
  isMango,
  ...
}:
if isNiri then
  ''
    import QtQuick
    import QtQuick.Layouts
    import Quickshell
    import Quickshell.Io
    RowLayout {
        id: workspaceModule
        spacing: 4

        property var workspaces: []

        RowLayout {
            spacing: 12
            Row {
                spacing: 2
                Repeater {
                    model: 9
                    Rectangle {
                        required property int index
                        property int wsNum: index + 1

                        property var wsData: {
                            for (let i = 0; i < workspaceModule.workspaces.length; i++) {
                                if (workspaceModule.workspaces[i].idx === wsNum)
                                    return workspaceModule.workspaces[i];
                            }
                            return null;
                        }

                        property bool isOccupied: wsData !== null && wsData.hasWindows
                        property bool isActive: wsData !== null && wsData.isActive
                        property bool isVisible: isOccupied || isActive

                        visible: isVisible
                        width: visible ? 20 : 0
                        height: 20
                        color: "transparent"

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            color: isActive ? theme.darkBlue : (isOccupied ? theme.fgSubtle : "transparent")
                            radius: 12
                            Text {
                                text: wsNum.toString()
                                color: isActive ? theme.bg : theme.fgMuted
                                font.pixelSize: 11
                                font.family: theme.fontFamily
                                font.bold: isActive
                                anchors.centerIn: parent
                            }
                        }
                    }
                }
            }
        }

        Process {
            id: niriWorkspacesProc
            command: ["niri", "msg", "--json", "workspaces"]
            running: true

            stdout: SplitParser {
                onRead: data => {
                    if (!data) return;
                    try {
                        const wsList = JSON.parse(data.trim());
                        if (!Array.isArray(wsList)) return;

                        // Constrói o array de workspaces
                        const newWorkspaces = [];
                        for (let i = 0; i < wsList.length; i++) {
                            const ws = wsList[i];
                            newWorkspaces.push({
                                idx: ws.idx,
                                hasWindows: ws.active_window_id !== null && ws.active_window_id !== undefined,
                                isActive: ws.is_active === true
                            });
                        }

                        workspaceModule.workspaces = newWorkspaces;
                    } catch (e) {
                        console.log("Failed to parse niri workspaces:", e);
                    }
                }
            }

            onRunningChanged: {
                if (!running) running = true;
            }
        }

        Timer {
            interval: 100
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: niriWorkspacesProc.running = true
        }
    }
  ''
else if isMango then
  ''
    import QtQuick
    import QtQuick.Layouts
    import Quickshell
    import Quickshell.Io
    RowLayout {
        id: workspaceModule
        spacing: 4
        RowLayout {
            spacing: 12
            Row {
                spacing: 2
                Repeater {
                    model: ListModel {
                        id: dwlTagsModel
                        Component.onCompleted: {
                            for (let i = 1; i <= 9; i++) {
                                append({ tagId: i.toString(), isActive: false, isOccupied: false, isUrgent: false });
                            }
                        }
                    }
                    Rectangle {
                        visible: model.isActive || model.isOccupied || model.isUrgent
                        width: visible ? 20 : 0
                        height: 20
                        color: "transparent"
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            color: model.isUrgent ? theme.darkBlue : (model.isActive ? theme.darkBlue : (model.isOccupied ? theme.fgSubtle : "transparent"))
                            radius: 10
                            Text {
                                text: model.tagId
                                color: (model.isActive || model.isUrgent) ? theme.bg : theme.fgMuted
                                font.pixelSize: 11
                                font.family: theme.fontFamily
                                font.bold: model.isActive
                                anchors.centerIn: parent
                            }
                        }
                    }
                }
            }
            Text {
                id: dwlLayoutText
                text: ""
                color: theme.blue
                font.pixelSize: 11
                font.family: "${fontFamily}"
                font.bold: true
            }
        }
        Process {
            id: dwlUpdateProc
            command: ["mmsg", "-g"]
            stdout: SplitParser {
                onRead: data => {
                    if (!data) return;
                    const parts = data.trim().split(/\s+/);

                    const tagIndex = parts.indexOf("tag");
                    if (tagIndex !== -1 && parts.length > tagIndex + 4) {
                        const id = parseInt(parts[tagIndex + 1]);
                        if (id >= 1 && id <= 9) {
                            const state = parts[tagIndex + 2];
                            const active = state === "1";
                            const urgent = state === "2";
                            const occupied = parseInt(parts[tagIndex + 3]) > 0;

                            dwlTagsModel.setProperty(id - 1, "isActive", active);
                            dwlTagsModel.setProperty(id - 1, "isOccupied", occupied);
                            dwlTagsModel.setProperty(id - 1, "isUrgent", urgent);
                        }
                    }

                    const layoutIndex = parts.indexOf("layout");
                    if (layoutIndex !== -1 && parts.length > layoutIndex + 1) {
                        const symbol = parts[layoutIndex + 1] || "";
                        dwlLayoutText.text = symbol ? "[" + symbol.replace(/[\[\]]/g, "") + "]" : "";
                    }
                }
            }
        }
        Process {
            id: dwlWatchProc
            command: ["mmsg", "-w"]
            running: true
            stdout: SplitParser {
                onRead: data => {
                    if (data.trim()) {
                        dwlUpdateProc.running = true;
                    }
                }
            }
        }
        Timer {
            interval: 250
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                if (!dwlUpdateProc.running) {
                    dwlUpdateProc.running = true;
                }
            }
        }
        Component.onCompleted: dwlUpdateProc.running = true
    }
  ''
else
  ''
    import QtQuick
    import QtQuick.Layouts
    import Quickshell
    RowLayout {
        id: workspaceModule
        spacing: 4
    }
  ''

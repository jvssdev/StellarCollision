{
  fontFamily,
  isNiri,
  isMango,
  ...
}:
if isNiri then
  /* qml */ ''
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
  /* qml */ ''
    import QtQuick
    import QtQuick.Layouts
    import Quickshell
    import Quickshell.Io
    RowLayout {
        id: workspaceModule
        spacing: 4

        // New mmsg IPC is JSON-only:
        //   mmsg get all-tags  → { "all_tags": [ { "monitor": "...", "tags": [ { index, is_active, is_urgent, layout, client_count }, ... ] }, ... ] }
        //   mmsg watch all-tags → streams the same shape on change
        function applyTagsJson(obj) {
            if (!obj)
                return;

            // Prefer focused monitor entry if present; otherwise first entry
            let tags = null;
            let layoutSymbol = "";
            if (obj.all_tags && obj.all_tags.length > 0) {
                // Use first monitor for now (single-monitor is common; multi can be refined later)
                const entry = obj.all_tags[0];
                tags = entry.tags || [];
            } else if (obj.tags) {
                tags = obj.tags;
            }
            if (!tags)
                return;

            for (let i = 0; i < 9; i++) {
                dwlTagsModel.setProperty(i, "isActive", false);
                dwlTagsModel.setProperty(i, "isOccupied", false);
                dwlTagsModel.setProperty(i, "isUrgent", false);
            }

            for (let t = 0; t < tags.length; t++) {
                const tag = tags[t];
                const id = tag.index | 0;
                if (id < 1 || id > 9)
                    continue;
                const active = !!tag.is_active;
                const urgent = !!tag.is_urgent;
                const occupied = (tag.client_count | 0) > 0;
                dwlTagsModel.setProperty(id - 1, "isActive", active);
                dwlTagsModel.setProperty(id - 1, "isOccupied", occupied);
                dwlTagsModel.setProperty(id - 1, "isUrgent", urgent);
                if (active && tag.layout)
                    layoutSymbol = String(tag.layout).replace(/[\[\]]/g, "");
            }
            dwlLayoutText.text = layoutSymbol ? "[" + layoutSymbol + "]" : "";
        }

        function parseMmsgJson(data) {
            if (!data)
                return;
            const text = data.trim();
            if (!text || text[0] !== "{")
                return;
            try {
                applyTagsJson(JSON.parse(text));
            } catch (e) {
                console.log("WorkspaceModule: failed to parse mmsg JSON:", e);
            }
        }

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
            command: ["mmsg", "get", "all-tags"]
            stdout: SplitParser {
                onRead: data => workspaceModule.parseMmsgJson(data)
            }
        }
        Process {
            id: dwlWatchProc
            command: ["mmsg", "watch", "all-tags"]
            running: true
            stdout: SplitParser {
                onRead: data => workspaceModule.parseMmsgJson(data)
            }
        }
        Timer {
            interval: 2000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                if (!dwlUpdateProc.running)
                    dwlUpdateProc.running = true;
            }
        }
        Component.onCompleted: dwlUpdateProc.running = true
    }
  ''
else
  /* qml */ ''
    import QtQuick
    import QtQuick.Layouts
    import Quickshell
    RowLayout {
        id: workspaceModule
        spacing: 4
    }
  ''

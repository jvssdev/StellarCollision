{ fontFamily, ... }:
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

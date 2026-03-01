_:

/* qml */ ''
  import QtQuick
  import QtQuick.Layouts
  import Quickshell
  import Quickshell.Io
  import Quickshell.Wayland

  Scope {
      function toggle() {
          launcherWindow.isClipboardMode = false;
          if (!launcherWindow.appsLoaded) {
              launcherWindow.loadApps();
          }
          launcherWindow.visible = !launcherWindow.visible;
      }

      function openClipboard() {
          launcherWindow.isClipboardMode = true;
          launcherWindow.query = "";
          launcherWindow.selectedIndex = 0;
          launcherWindow.results = [];
          launcherWindow.visible = true;
          clipboardListProc.running = true;
      }

      function clearClipboard() {
          clipboardClearProc.running = true;
      }

      PanelWindow {
          id: launcherWindow
          visible: false
          color: "transparent"

          WlrLayershell.namespace: "stellar:launcher"
          WlrLayershell.layer: WlrLayer.Overlay
          WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

          anchors {
              top: true
              bottom: true
              left: true
              right: true
          }

          property string query: ""
          property int selectedIndex: 0
          property var results: []
          property bool appsLoaded: false
          property bool isClipboardMode: false

          property var clipboardEntries: []
          property var clipboardResults: []

          function loadApps() {
              if (appsLoaded) return;

              var allApps = DesktopEntries.applications.values;
              if (allApps && allApps.length > 0) {
                  appsLoaded = true;
                  doSearch();
              } else {
                  loadAppsTimer.start();
              }
          }

          Timer {
              id: loadAppsTimer
              interval: 200
              repeat: false
              onTriggered: launcherWindow.loadApps()
          }

          Process {
              id: clipboardListProc
              running: false
              command: ["cliphist", "list"]
              stdout: StdioCollector {
                  onStreamFinished: function() {
                      var lines = text.trim().split("\n");
                      var items = [];
                      for (var i = 0; i < lines.length; i++) {
                          var line = lines[i];
                          if (!line) continue;
                          var tabIndex = line.indexOf("\t");
                          if (tabIndex === -1) continue;
                          var id = line.substring(0, tabIndex);
                          var content = line.substring(tabIndex + 1);
                          var isImage = content.indexOf("[[") === 0 && content.indexOf("binary data") > 0;
                          items.push({
                              id: id,
                              text: content,
                              line: line,
                              isImage: isImage
                          });
                      }
                      launcherWindow.clipboardEntries = items;
                      launcherWindow.updateClipboardResults();
                  }
              }
          }

          Process {
              id: clipboardSelectProc
              running: false
              onExited: function(code) {
                  if (code === 0) {
                      launcherWindow.visible = false;
                  }
              }
          }

          Process {
              id: clipboardDeleteProc
              running: false
              onExited: function(code) {
                  if (code === 0) {
                      clipboardListProc.running = true;
                  }
              }
          }

          Process {
              id: clipboardClearProc
              running: false
              command: ["cliphist", "wipe"]
              onExited: function(code) {
                  if (code === 0) {
                      launcherWindow.clipboardEntries = [];
                      launcherWindow.updateClipboardResults();
                  }
              }
          }

          function shellEscape(str) {
              var result = "";
              for (var i = 0; i < str.length; i++) {
                  var ch = str.charCodeAt(i);
                  if (ch === 39) {
                      result = result + String.fromCharCode(39) + String.fromCharCode(92) + String.fromCharCode(39) + String.fromCharCode(39);
                  } else {
                      result = result + str.charAt(i);
                  }
              }
              return String.fromCharCode(39) + result + String.fromCharCode(39);
          }

          function launch(app) {
              if (app && app.execute) {
                  app.execute();
              }
              launcherWindow.visible = false;
          }

          function launchSelected() {
              if (results && results.length > 0 && selectedIndex >= 0 && selectedIndex < results.length) {
                  var item = results[selectedIndex];
                  if (item.type === "clipboard") {
                      clipboardSelectProc.command = ["sh", "-c", "echo " + shellEscape(item.line) + " | cliphist decode | wl-copy"];
                      clipboardSelectProc.running = true;
                  } else if (item.type === "app") {
                      launch(item.app);
                  }
              }
          }

          function deleteClipboardItem(index) {
              if (index >= 0 && index < clipboardEntries.length) {
                  var entry = clipboardEntries[index];
                  clipboardDeleteProc.command = ["sh", "-c", "echo " + shellEscape(entry.line) + " | cliphist delete"];
                  clipboardDeleteProc.running = true;
              }
          }

          function updateClipboardResults() {
              if (!isClipboardMode) return;

              if (clipboardEntries.length === 0) {
                  results = [
                      { name: "Loading...", description: "Fetching clipboard history", type: "clipboard", id: "", isLoading: true }
                  ];
                  return;
              }

              var matches = clipboardEntries.map(function(entry) {
                  var displayName = entry.isImage ? "[Image] " + entry.text : entry.text;
                  if (displayName.length > 60) {
                      displayName = displayName.substring(0, 57) + "...";
                  }
                  return {
                      name: displayName,
                      description: entry.isImage ? "Image" : "Text",
                      type: "clipboard",
                      id: entry.id,
                      line: entry.line,
                      isImage: entry.isImage
                  };
              });

              if (matches.length === 0) {
                  results = [
                      { name: "Clipboard is empty", description: "Copy something to see it here", type: "clipboard", id: "", isEmpty: true }
                  ];
                  return;
              }

              results = matches;
          }

          function doSearch() {
              selectedIndex = 0;

              if (isClipboardMode) {
                  updateClipboardResults();
                  return;
              }

              if (!DesktopEntries || !DesktopEntries.applications) {
                  results = [];
                  return;
              }

              var allApps = DesktopEntries.applications.values;
              if (!allApps || allApps.length === 0) {
                  results = [];
                  return;
              }

              var arr = allApps.slice();
              arr.sort(function(a, b) {
                  var na = (a.name || "").toLowerCase();
                  var nb = (b.name || "").toLowerCase();
                  return na.localeCompare(nb);
              });

              if (query === "") {
                  results = arr.slice(0, 50).map(function(app) {
                      return { type: "app", app: app, name: app.name, icon: app.icon };
                  });
                  return;
              }

              var q = query.toLowerCase();
              var matches = [];
              for (var i = 0; i < arr.length && matches.length < 20; i++) {
                  var app = arr[i];
                  var name = (app.name || "").toLowerCase();
                  if (name.indexOf(q) >= 0) {
                      matches.push({ type: "app", app: app, name: app.name, icon: app.icon });
                  }
              }
              results = matches;
          }

          onQueryChanged: {
              if (isClipboardMode) {
                  if (clipboardEntries.length > 0) {
                      updateClipboardResults();
                  }
              } else {
                  doSearch();
              }
          }

          Component.onCompleted: {
              loadAppsTimer.start();
          }

           Rectangle {
               anchors.centerIn: parent
               width: 500
               height: 420
               color: theme.bg
               radius: 12
               border.color: theme.fgSubtle
               border.width: 2
               clip: true

               Column {
                   anchors.fill: parent
                   anchors.margins: 12

                   Rectangle {
                       height: 44
                       width: parent.width
                       radius: 8
                       color: theme.bg

                       RowLayout {
                           anchors.fill: parent
                           anchors.leftMargin: 12
                           anchors.rightMargin: 12
                           spacing: 10

                           Text {
                               text: launcherWindow.isClipboardMode ? "󱉥" : "󰍉"
                               font.family: theme.fontFamily
                               font.pixelSize: 16
                               color: launcherWindow.isClipboardMode ? theme.yellow : theme.fgMuted
                           }

                           TextInput {
                               id: searchInput
                               Layout.fillWidth: true
                               font.family: theme.fontFamily
                               font.pixelSize: 14
                               color: theme.fg
                               verticalAlignment: TextInput.AlignVCenter
                               onTextChanged: launcherWindow.query = text
                              onAccepted: function() {
                                  if (launcherWindow.selectedIndex >= 0 && launcherWindow.results.length > 0) {
                                      var item = launcherWindow.results[launcherWindow.selectedIndex];
                                      if (item.id === "__clear__") {
                                          clipboardClearProc.running = true;
                                      } else if (!item.isLoading && !item.isEmpty) {
                                          launcherWindow.launchSelected();
                                      }
                                  }
                              }
                              Keys.onEscapePressed: function(event) {
                                  if (launcherWindow.query === "") {
                                      launcherWindow.visible = false;
                                  } else {
                                      launcherWindow.query = "";
                                      launcherWindow.visible = false;
                                  }
                              }
                              Keys.onTabPressed: function(event) {
                                  if (launcherWindow.selectedIndex < launcherWindow.results.length - 1) launcherWindow.selectedIndex++
                                  appListView.currentIndex = launcherWindow.selectedIndex
                                  event.accepted = true
                              }
                              Keys.onBacktabPressed: function(event) {
                                  if (launcherWindow.selectedIndex > 0) launcherWindow.selectedIndex--
                                  appListView.currentIndex = launcherWindow.selectedIndex
                                  event.accepted = true
                              }
                              Keys.onPressed: function(event) {
                                  if (event.modifiers === Qt.ControlModifier) {
                                      if (event.key === Qt.Key_N) {
                                          if (launcherWindow.selectedIndex < launcherWindow.results.length - 1) launcherWindow.selectedIndex++
                                          appListView.currentIndex = launcherWindow.selectedIndex
                                          event.accepted = true
                                      } else if (event.key === Qt.Key_P) {
                                          if (launcherWindow.selectedIndex > 0) launcherWindow.selectedIndex--
                                          appListView.currentIndex = launcherWindow.selectedIndex
                                          event.accepted = true
                                      }
                                  }
                              }
                              KeyNavigation.down: appListView
                              KeyNavigation.up: appListView
                          }
                      }
                  }

                   Rectangle {
                       height: 1
                       width: parent.width
                       color: theme.fgSubtle
                   }

                   ListView {
                       id: appListView
                       width: parent.width
                       height: parent.height - 58
                       model: launcherWindow.results
                       currentIndex: launcherWindow.selectedIndex
                       highlightMoveDuration: 0
                       clip: true

                       delegate: Rectangle {
                           width: ListView.view.width
                           height: 44
                           radius: 8
                           color: index === launcherWindow.selectedIndex ? Qt.rgba(theme.darkBlue.r, theme.darkBlue.g, theme.darkBlue.b, 0.2) : "transparent"

                           RowLayout {
                               anchors.fill: parent
                               anchors.leftMargin: 10
                               anchors.rightMargin: 10
                               spacing: 12

                               Image {
                                   width: 24
                                   height: 24
                                   visible: modelData.type === "app"
                                   source: {
                                       if (modelData.type === "app") return modelData.icon ? "image://icon/" + modelData.icon : "";
                                       return "";
                                   }
                                   sourceSize: Qt.size(24, 24)
                               }

                               Text {
                                   text: {
                                       if (modelData.type === "clipboard") {
                                           return modelData.isImage ? "󰋩" : "󱉥";
                                       }
                                       return "";
                                   }
                                   font.family: theme.fontFamily
                                   font.pixelSize: 16
                                   color: modelData.isImage ? theme.magenta : theme.yellow
                                   visible: modelData.type === "clipboard"
                               }

                               Text {
                                   Layout.fillWidth: true
                                   text: modelData.name || ""
                                   font.family: theme.fontFamily
                                   font.pixelSize: 13
                                   color: theme.fg
                                   elide: Text.ElideRight
                               }

                               Text {
                                   Layout.preferredWidth: 60
                                   horizontalAlignment: Text.AlignRight
                                   text: {
                                       if (modelData.isAction) return "Clear";
                                       if (modelData.isLoading || modelData.isEmpty) return "";
                                       if (modelData.type === "clipboard") return "Paste";
                                       return "Enter";
                                   }
                                   font.family: theme.fontFamily
                                   font.pixelSize: 10
                                   color: theme.fgMuted
                                   visible: index === launcherWindow.selectedIndex && !modelData.isLoading && !modelData.isEmpty
                               }
                           }

                          MouseArea {
                              anchors.fill: parent
                              cursorShape: Qt.PointingHandCursor
                              onClicked: function() {
                                  launcherWindow.selectedIndex = index;
                                  if (modelData.id === "__clear__") {
                                      clipboardClearProc.running = true;
                                  } else if (!modelData.isLoading && !modelData.isEmpty) {
                                      launcherWindow.launchSelected();
                                  }
                              }
                          }
                      }
                  }
              }
          }

          Item {
              anchors.fill: parent
              focus: true
              Keys.onEscapePressed: launcherWindow.visible = false
              Keys.onReturnPressed: function() {
                  if (launcherWindow.selectedIndex >= 0 && launcherWindow.results.length > 0) {
                      var item = launcherWindow.results[launcherWindow.selectedIndex];
                      if (item.id === "__clear__") {
                          clipboardClearProc.running = true;
                      } else if (!item.isLoading && !item.isEmpty) {
                          launcherWindow.launchSelected();
                      }
                  }
              }
              Keys.onUpPressed: function(event) {
                  if (launcherWindow.selectedIndex > 0) launcherWindow.selectedIndex--
                  appListView.currentIndex = launcherWindow.selectedIndex
              }
              Keys.onDownPressed: function(event) {
                  if (launcherWindow.selectedIndex < launcherWindow.results.length - 1) launcherWindow.selectedIndex++
                  appListView.currentIndex = launcherWindow.selectedIndex
              }
              Keys.onTabPressed: function(event) {
                  if (launcherWindow.selectedIndex < launcherWindow.results.length - 1) launcherWindow.selectedIndex++
                  appListView.currentIndex = launcherWindow.selectedIndex
              }
              Keys.onBacktabPressed: function(event) {
                  if (launcherWindow.selectedIndex > 0) launcherWindow.selectedIndex--
                  appListView.currentIndex = launcherWindow.selectedIndex
              }
              Keys.onPressed: function(event) {
                  if (event.modifiers === Qt.ControlModifier) {
                      if (event.key === Qt.Key_N) {
                          if (launcherWindow.selectedIndex < launcherWindow.results.length - 1) launcherWindow.selectedIndex++
                          appListView.currentIndex = launcherWindow.selectedIndex
                          event.accepted = true
                      } else if (event.key === Qt.Key_P) {
                          if (launcherWindow.selectedIndex > 0) launcherWindow.selectedIndex--
                          appListView.currentIndex = launcherWindow.selectedIndex
                          event.accepted = true
                      }
                  }
              }
          }

          onVisibleChanged: {
              if (visible) {
                  if (isClipboardMode) {
                      if (clipboardEntries.length === 0) {
                          clipboardListProc.running = true;
                      }
                  } else {
                      query = "";
                      searchInput.text = "";
                      selectedIndex = 0;
                      appsLoaded = false;
                      launcherWindow.loadApps();
                  }
                  Qt.callLater(function() { searchInput.forceActiveFocus(); });
              } else {
                  isClipboardMode = false;
              }
          }
      }
  }
''

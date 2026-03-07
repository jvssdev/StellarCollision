{
  fontFamily,
  colors,
  ...
}:
let
  c = colors;
in
/* qml */ ''
  import QtQuick
  import QtQuick.Layouts
  import Quickshell
  import Quickshell.Io
  import Quickshell.Wayland

  Scope {
      function toggle() {
          launcherWindow.isClipboardMode = false;
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
          property var appsCache: []
          property bool appsLoaded: false
          property bool isClipboardMode: false
          property var clipboardEntries: []

          function loadApps() {
              if (appsLoaded) return;
              if (typeof DesktopEntries === 'undefined' || !DesktopEntries.applications) return;

              var allApps = DesktopEntries.applications.values;
              if (!allApps || allApps.length === 0) {
                  loadAppsTimer.start();
                  return;
              }

              var seen = {};
              var filtered = [];
              for (var i = 0; i < allApps.length; i++) {
                  var app = allApps[i];
                  if (!app || app.noDisplay || app.hidden) continue;
                  var key = app.id || app.name || "";
                  if (seen[key]) continue;
                  seen[key] = true;
                  filtered.push(app);
              }

              filtered.sort(function(a, b) {
                  return (a.name || "").toLowerCase().localeCompare((b.name || "").toLowerCase());
              });

              appsCache = filtered;
              appsLoaded = true;
              doSearch();
          }

          Timer {
              id: loadAppsTimer
              interval: 200
              repeat: false
              onTriggered: launcherWindow.loadApps()
          }

          Connections {
              target: typeof DesktopEntries !== 'undefined' ? DesktopEntries.applications : null
              function onValuesChanged() {
                  launcherWindow.appsLoaded = false;
                  launcherWindow.appsCache = [];
                  launcherWindow.loadApps();
              }
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
                          items.push({ id: id, text: content, line: line, isImage: isImage });
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
                  if (code === 0) launcherWindow.visible = false;
              }
          }

          Process {
              id: clipboardDeleteProc
              running: false
              onExited: function(code) {
                  if (code === 0) clipboardListProc.running = true;
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

          function getExecutable(app) {
              if (app.command && app.command.length > 0) {
                  var parts = String(app.command[0]).split("/");
                  return parts[parts.length - 1].toLowerCase();
              }
              if (app.id) return String(app.id).replace(".desktop", "").toLowerCase();
              return "";
          }

          function launchApp(app) {
              if (!app) return;
              launcherWindow.visible = false;
              Qt.callLater(function() {
                  if (app.execute) {
                      app.execute();
                  } else if (app.command && app.command.length > 0) {
                      var cmd = [];
                      for (var i = 0; i < app.command.length; i++) cmd.push(String(app.command[i]));
                      if (app.runInTerminal) {
                          Quickshell.execDetached(["foot", "-e"].concat(cmd));
                      } else {
                          Quickshell.execDetached(cmd);
                      }
                  }
              });
          }

          function launchSelected() {
              if (!results || results.length === 0) return;
              if (selectedIndex < 0 || selectedIndex >= results.length) return;
              var item = results[selectedIndex];
              if (item.type === "clipboard") {
                  clipboardSelectProc.command = ["sh", "-c", "echo " + shellEscape(item.line) + " | cliphist decode | wl-copy"];
                  clipboardSelectProc.running = true;
              } else if (item.type === "app") {
                  launchApp(item.app);
              }
          }

          function deleteClipboardItem(index) {
              if (index < 0 || index >= clipboardEntries.length) return;
              var entry = clipboardEntries[index];
              clipboardDeleteProc.command = ["sh", "-c", "echo " + shellEscape(entry.line) + " | cliphist delete"];
              clipboardDeleteProc.running = true;
          }

          function updateClipboardResults() {
              if (!isClipboardMode) return;
              if (clipboardEntries.length === 0) {
                  results = [{ name: "Loading...", description: "Fetching clipboard history", type: "clipboard", id: "", isLoading: true }];
                  return;
              }
              var q = query.toLowerCase();
              var matches = clipboardEntries.filter(function(entry) {
                  return q === "" || entry.text.toLowerCase().indexOf(q) >= 0;
              }).map(function(entry) {
                  var displayName = entry.isImage ? "[Image] " + entry.text : entry.text;
                  if (displayName.length > 60) displayName = displayName.substring(0, 57) + "...";
                  return { name: displayName, description: entry.isImage ? "Image" : "Text", type: "clipboard", id: entry.id, line: entry.line, isImage: entry.isImage };
              });
              if (matches.length === 0) {
                  results = [{ name: q !== "" ? "No matches" : "Clipboard is empty", description: q !== "" ? "No clipboard entries match your search" : "Copy something to see it here", type: "clipboard", id: "", isEmpty: true }];
                  return;
              }
              results = matches;
          }

          function fuzzyScore(str, q) {
              if (!str) return -1;
              str = str.toLowerCase();
              var qi = 0;
              var score = 0;
              var consecutive = 0;
              for (var i = 0; i < str.length && qi < q.length; i++) {
                  if (str[i] === q[qi]) {
                      score += 1 + consecutive * 2;
                      consecutive++;
                      qi++;
                  } else {
                      consecutive = 0;
                  }
              }
              return qi < q.length ? -1 : score;
          }

          function doSearch() {
              selectedIndex = 0;

              if (isClipboardMode) {
                  updateClipboardResults();
                  return;
              }

              if (!appsLoaded || appsCache.length === 0) {
                  results = [];
                  return;
              }

              if (query === "") {
                  results = appsCache.slice(0, 50).map(function(app) {
                      return { type: "app", app: app, name: app.name, icon: app.icon };
                  });
                  return;
              }

              var q = query.toLowerCase();
              var scored = [];

              for (var i = 0; i < appsCache.length; i++) {
                  var app = appsCache[i];
                  var name        = (app.name || "").toLowerCase();
                  var genericName = (app.genericName || "").toLowerCase();
                  var comment     = (app.comment || "").toLowerCase();
                  var execName    = getExecutable(app);

                  var nameScore    = fuzzyScore(name, q);
                  var genericScore = fuzzyScore(genericName, q);
                  var execScore    = fuzzyScore(execName, q);
                  var commentScore = fuzzyScore(comment, q);

                  if (nameScore < 0 && genericScore < 0 && execScore < 0 && commentScore < 0) continue;

                  var best = Math.max(
                      nameScore    * 4,
                      genericScore * 2,
                      execScore    * 2,
                      commentScore
                  );

                  if (name === q)              best += 200;
                  else if (name.startsWith(q)) best += 100;
                  else if (name.indexOf(q) >= 0) best += 50;

                  scored.push({ app: app, score: best });
              }

              scored.sort(function(a, b) { return b.score - a.score; });

              results = scored.slice(0, 20).map(function(s) {
                  return { type: "app", app: s.app, name: s.app.name, icon: s.app.icon };
              });
          }

          function selectNext() {
              if (results.length === 0) return;
              if (selectedIndex < results.length - 1) selectedIndex++;
          }

          function selectPrevious() {
              if (results.length === 0) return;
              if (selectedIndex > 0) selectedIndex--;
          }

          onQueryChanged: {
              if (isClipboardMode) {
                  if (clipboardEntries.length > 0) updateClipboardResults();
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
              color: "${c.base00}"
              radius: 12
              border.color: "${c.base0D}"
              border.width: 2
              clip: true

              Column {
                  anchors.fill: parent
                  anchors.margins: 12

                  Rectangle {
                      height: 44
                      width: parent.width
                      radius: 8
                      color: "${c.base00}"

                      RowLayout {
                          anchors.fill: parent
                          anchors.leftMargin: 12
                          anchors.rightMargin: 12
                          spacing: 10

                          Text {
                              text: launcherWindow.isClipboardMode ? "󱉥" : "󰍉"
                              font.family: "${fontFamily}"
                              font.pixelSize: 16
                              color: launcherWindow.isClipboardMode ? "${c.base0A}" : "${c.base03}"
                          }

                          TextInput {
                              id: searchInput
                              Layout.fillWidth: true
                              font.family: "${fontFamily}"
                              font.pixelSize: 14
                              color: "${c.base05}"
                              verticalAlignment: TextInput.AlignVCenter
                              onTextChanged: launcherWindow.query = text
                              onAccepted: function() {
                                  var item = launcherWindow.results[launcherWindow.selectedIndex];
                                  if (!item || item.isLoading || item.isEmpty) return;
                                  if (item.id === "__clear__") clipboardClearProc.running = true;
                                  else launcherWindow.launchSelected();
                              }
                              Keys.onEscapePressed: function(event) {
                                  launcherWindow.visible = false;
                                  event.accepted = true;
                              }
                              Keys.onUpPressed: function(event) {
                                  launcherWindow.selectPrevious();
                                  event.accepted = true;
                              }
                              Keys.onDownPressed: function(event) {
                                  launcherWindow.selectNext();
                                  event.accepted = true;
                              }
                              Keys.onTabPressed: function(event) {
                                  launcherWindow.selectNext();
                                  event.accepted = true;
                              }
                              Keys.onBacktabPressed: function(event) {
                                  launcherWindow.selectPrevious();
                                  event.accepted = true;
                              }
                              Keys.onPressed: function(event) {
                                  if (event.modifiers === Qt.ControlModifier) {
                                      if (event.key === Qt.Key_N || event.key === Qt.Key_J) {
                                          launcherWindow.selectNext();
                                          event.accepted = true;
                                      } else if (event.key === Qt.Key_P || event.key === Qt.Key_K) {
                                          launcherWindow.selectPrevious();
                                          event.accepted = true;
                                      }
                                  }
                              }
                          }
                      }
                  }

                  Rectangle {
                      height: 1
                      width: parent.width
                      color: "${c.base03}"
                  }

                  ListView {
                      id: appListView
                      width: parent.width
                      height: parent.height - 58
                      model: launcherWindow.results
                      currentIndex: launcherWindow.selectedIndex
                      highlightMoveDuration: 0
                      clip: true
                      keyNavigationEnabled: false

                      onCurrentIndexChanged: {
                          positionViewAtIndex(currentIndex, ListView.Contain);
                      }

                      delegate: Rectangle {
                          width: ListView.view.width
                          height: 44
                          radius: 8
                          color: index === launcherWindow.selectedIndex ? "${c.base01}" : "transparent"

                          RowLayout {
                              anchors.fill: parent
                              anchors.leftMargin: 10
                              anchors.rightMargin: 10
                              spacing: 12

                              Item {
                                  id: iconContainer
                                  width: 24
                                  height: 24
                                  visible: modelData.type === "app"

                                  readonly property string resolvedSource: {
                                      if (modelData.type !== "app" || !modelData.icon) return "";
                                      var ic = String(modelData.icon);
                                      if (ic.startsWith("file://")) return ic;
                                      if (ic.startsWith("/")) {
                                          if (ic.indexOf("/nix/store/") === 0)
                                              return "image://icon/" + ic.split("/").pop().replace(/\.[^.]+$/, "");
                                          var ext = ic.split(".").pop().toLowerCase();
                                          if (ext === "png" || ext === "svg" || ext === "xpm")
                                              return "file://" + ic;
                                          return "image://icon/" + ic.split("/").pop().replace(/\.[^.]+$/, "");
                                      }
                                      return "image://icon/" + ic;
                                  }

                                  Image {
                                      id: appIconImage
                                      anchors.fill: parent
                                      asynchronous: true
                                      smooth: true
                                      mipmap: true
                                      fillMode: Image.PreserveAspectFit
                                      cache: true
                                      sourceSize: Qt.size(48, 48)
                                      source: iconContainer.resolvedSource
                                  }

                                  Rectangle {
                                      anchors.fill: parent
                                      color: "${c.base01}"
                                      radius: 4
                                      visible: appIconImage.status === Image.Error || appIconImage.status === Image.Null

                                      Text {
                                          anchors.centerIn: parent
                                          text: (modelData.name || "?").charAt(0).toUpperCase()
                                          font.family: "${fontFamily}"
                                          font.pixelSize: 13
                                          font.bold: true
                                          color: "${c.base05}"
                                      }
                                  }
                              }

                              Text {
                                  text: {
                                      if (modelData.type === "clipboard") return modelData.isImage ? "󰋩" : "󱉥";
                                      return "";
                                  }
                                  font.family: "${fontFamily}"
                                  font.pixelSize: 16
                                  color: modelData.isImage ? "${c.base0E}" : "${c.base0A}"
                                  visible: modelData.type === "clipboard"
                              }

                              Text {
                                  Layout.fillWidth: true
                                  text: modelData.name || ""
                                  font.family: "${fontFamily}"
                                  font.pixelSize: 13
                                  color: "${c.base05}"
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
                                  font.family: "${fontFamily}"
                                  font.pixelSize: 10
                                  color: "${c.base03}"
                                  visible: index === launcherWindow.selectedIndex && !modelData.isLoading && !modelData.isEmpty
                              }
                          }

                          MouseArea {
                              anchors.fill: parent
                              cursorShape: Qt.PointingHandCursor
                              onClicked: function() {
                                  launcherWindow.selectedIndex = index;
                                  var item = launcherWindow.results[index];
                                  if (!item || item.isLoading || item.isEmpty) return;
                                  if (item.id === "__clear__") clipboardClearProc.running = true;
                                  else launcherWindow.launchSelected();
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
                  var item = launcherWindow.results[launcherWindow.selectedIndex];
                  if (!item || item.isLoading || item.isEmpty) return;
                  if (item.id === "__clear__") clipboardClearProc.running = true;
                  else launcherWindow.launchSelected();
              }
              Keys.onUpPressed: function() { launcherWindow.selectPrevious(); }
              Keys.onDownPressed: function() { launcherWindow.selectNext(); }
          }

          onVisibleChanged: {
              if (visible) {
                  if (isClipboardMode) {
                      if (clipboardEntries.length === 0) clipboardListProc.running = true;
                  } else {
                      query = "";
                      searchInput.text = "";
                      selectedIndex = 0;
                      if (!appsLoaded) loadApps();
                      else doSearch();
                  }
                  Qt.callLater(function() { searchInput.forceActiveFocus(); });
              } else {
                  isClipboardMode = false;
              }
          }
      }
  }
''

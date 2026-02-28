{
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
      property var theme: null

      function toggle() {
          launcherWindow.visible = !launcherWindow.visible
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

          function launch(app) {
              if (app && app.execute) {
                  app.execute();
              }
              launcherWindow.visible = false;
          }

          function launchSelected() {
              if (results && results.length > 0 && selectedIndex >= 0 && selectedIndex < results.length) {
                  launch(results[selectedIndex]);
              }
          }

          function doSearch() {
              selectedIndex = 0;

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
                  results = arr.slice(0, 50);
                  return;
              }

              var q = query.toLowerCase();
              var matches = [];
              for (var i = 0; i < arr.length && matches.length < 20; i++) {
                  var app = arr[i];
                  var name = (app.name || "").toLowerCase();
                  if (name.indexOf(q) >= 0) {
                      matches.push(app);
                  }
              }
              results = matches;
          }

          onQueryChanged: doSearch()

          Component.onCompleted: {
              loadAppsTimer.start();
          }

          Rectangle {
              anchors.centerIn: parent
              width: 500
              height: 420
              color: theme?.bg || "${c.base00}"
              radius: 12
              border.color: theme?.fgSubtle || "${c.base03}"
              border.width: 2
              clip: true

              Column {
                  anchors.fill: parent
                  anchors.margins: 12

                  Rectangle {
                      height: 44
                      width: parent.width
                      radius: 8
                      color: theme?.bg || "${c.base00}"

                      RowLayout {
                          anchors.fill: parent
                          anchors.leftMargin: 12
                          anchors.rightMargin: 12
                          spacing: 10

                          Text {
                              text: "󰍉"
                              font.family: theme?.fontFamily || "monospace"
                              font.pixelSize: 16
                              color: theme?.fgMuted || "${c.base04}"
                          }

                          TextInput {
                              id: searchInput
                              Layout.fillWidth: true
                              font.family: theme?.fontFamily || "monospace"
                              font.pixelSize: 14
                              color: theme?.fg || "${c.base05}"
                              verticalAlignment: TextInput.AlignVCenter
                              onTextChanged: launcherWindow.query = text
                              onAccepted: launcherWindow.launchSelected()
                              Keys.onEscapePressed: function(event) {
                                  if (launcherWindow.query === "") {
                                      launcherWindow.visible = false;
                                  } else {
                                      launcherWindow.query = "";
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
                      color: theme?.fgSubtle || "${c.base03}"
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
                          color: index === launcherWindow.selectedIndex ? Qt.rgba(theme?.darkBlue?.r || 0.37, theme?.darkBlue?.g || 0.51, theme?.darkBlue?.b || 0.71, 0.2) : "transparent"

                          RowLayout {
                              anchors.fill: parent
                              anchors.leftMargin: 10
                              anchors.rightMargin: 10
                              spacing: 12

                              Image {
                                  width: 24
                                  height: 24
                                  source: modelData.icon ? "image://icon/" + modelData.icon : ""
                                  sourceSize: Qt.size(24, 24)
                              }

                              Text {
                                  Layout.fillWidth: true
                                  text: modelData.name || ""
                                  font.family: theme?.fontFamily || "monospace"
                                  font.pixelSize: 13
                                  color: theme?.fg || "${c.base05}"
                                  elide: Text.ElideRight
                              }

                              Text {
                                  text: "Enter"
                                  font.family: theme?.fontFamily || "monospace"
                                  font.pixelSize: 10
                                  color: theme?.fgMuted || "${c.base04}"
                                  visible: index === launcherWindow.selectedIndex
                              }
                          }

                          MouseArea {
                              anchors.fill: parent
                              cursorShape: Qt.PointingHandCursor
                              onClicked: function() {
                                  launcherWindow.selectedIndex = index;
                                  launcherWindow.launchSelected();
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
              Keys.onReturnPressed: launcherWindow.launchSelected()
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
                  query = "";
                  selectedIndex = 0;
                  appsLoaded = false;
                  launcherWindow.loadApps();
                  Qt.callLater(function() { searchInput.forceActiveFocus(); });
              }
          }
      }
  }
''

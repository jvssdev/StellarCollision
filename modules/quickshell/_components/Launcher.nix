{
  pkgs,
  lib,
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

      function toggle() {
          visible = !visible;
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
              console.log("DesktopEntries not ready, retrying...");
              loadAppsTimer.start();
          }
      }

      Timer {
          id: loadAppsTimer
          interval: 200
          repeat: false
          onTriggered: loadApps()
      }

      function launch(app) {
          console.log("Launching app:", app.name);
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
              console.log("DesktopEntries not available");
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
          console.log("Launcher component completed, starting loadAppsTimer");
          loadAppsTimer.start();
      }

      MouseArea {
          anchors.fill: parent
          onClicked: launcherWindow.visible = false
      }

      Rectangle {
          anchors.centerIn: parent
          width: 600
          height: 400
          color: "${c.base01}"
          radius: 12
          clip: true

          Column {
              anchors.fill: parent
              anchors.margins: 16

              Rectangle {
                  height: 48
                  width: parent.width
                  color: "transparent"

                  TextInput {
                      id: searchInput
                      anchors.fill: parent
                      anchors.leftMargin: 12
                      font.pixelSize: 18
                      color: "${c.base05}"
                      onTextChanged: launcherWindow.query = text
                      onAccepted: launcherWindow.launchSelected()
                      Keys.onEscapePressed: {
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

              ListView {
                  id: appListView
                  width: parent.width
                  height: parent.height - 60
                  model: launcherWindow.results
                  currentIndex: launcherWindow.selectedIndex
                  highlightMoveDuration: 0
                  clip: true

                  delegate: Item {
                      width: ListView.view.width
                      height: 50

                      Rectangle {
                          anchors.fill: parent
                          color: index === launcherWindow.selectedIndex ? "${c.base0D}40" : "transparent"
                          radius: 8
                      }

                      Row {
                          anchors.fill: parent
                          anchors.leftMargin: 8
                          anchors.rightMargin: 8
                          spacing: 12

                          Image {
                              width: 32
                              height: 32
                              anchors.verticalCenter: parent.verticalCenter
                              source: modelData.icon ? "image://icon/" + modelData.icon : ""
                              sourceSize: Qt.size(32, 32)
                          }

                          Text {
                              anchors.verticalCenter: parent.verticalCenter
                              text: modelData.name || ""
                              color: "${c.base05}"
                              font.pixelSize: 14
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
          Keys.onUpPressed: {
              if (launcherWindow.selectedIndex > 0) launcherWindow.selectedIndex--
              appListView.currentIndex = launcherWindow.selectedIndex
          }
          Keys.onDownPressed: {
              if (launcherWindow.selectedIndex < launcherWindow.results.length - 1) launcherWindow.selectedIndex++
              appListView.currentIndex = launcherWindow.selectedIndex
          }
          Keys.onTabPressed: {
              if (launcherWindow.selectedIndex < launcherWindow.results.length - 1) launcherWindow.selectedIndex++
              appListView.currentIndex = launcherWindow.selectedIndex
          }
          Keys.onBacktabPressed: {
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
              loadApps();
              Qt.callLater(function() { searchInput.forceActiveFocus(); });
          }
      }
  }
''

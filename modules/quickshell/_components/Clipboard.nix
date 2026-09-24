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
  import QtQuick.Controls
  import Quickshell
  import Quickshell.Io
  import Quickshell.Wayland

  Scope {
      function toggle() {
          if (clipboardWindow.visible) {
              clipboardWindow.closeMenu();
          } else {
              clipboardWindow.openMenu();
          }
      }

      function open() {
          clipboardWindow.openMenu();
      }

      function clear() {
          backend.clearUnpinnedHistory();
      }

      // ── Backend ──────────────────────────────────────────────────────────
      Item {
          id: backend

          property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/scripts/cliphist-visual.sh"
          property string pinnedCachePath: Quickshell.env("HOME") + "/.local/state/quickshell/pinned_clips.json"

          property var allItems: []
          property var filteredItems: []
          property var pinnedRaws: []
          property string searchText: ""
          property int currentTab: 0
          property bool resetSelectionPending: false
          property bool repinTopOnRefresh: false
          property string repinDisplayHint: ""

          signal closeRequested

          Component.onCompleted: loadPinnedProcess.running = true

          onSearchTextChanged: updateSearch()
          onCurrentTabChanged: updateSearch()

          function pinKey(rawString) {
              var tabIndex = rawString.indexOf("\t");
              return tabIndex > -1 ? rawString.substring(0, tabIndex) : rawString;
          }

          function updateSearch() {
              var baseList = backend.currentTab === 0
                  ? backend.allItems
                  : backend.allItems.filter(function(item) {
                      return backend.pinnedRaws.indexOf(backend.pinKey(item.raw)) !== -1;
                  });

              if (backend.searchText.trim() === "") {
                  backend.filteredItems = baseList;
                  return;
              }

              var query = backend.searchText.toLowerCase();
              // Fuzzy subsequence match (same as octashell)
              backend.filteredItems = baseList.filter(function(item) {
                  var str = (item.display || "").toLowerCase();
                  var i = 0, j = 0;
                  while (i < str.length && j < query.length) {
                      if (str[i] === query[j]) j++;
                      i++;
                  }
                  return j === query.length;
              });
          }

          function togglePin(rawString) {
              var key = backend.pinKey(rawString);
              var index = backend.pinnedRaws.indexOf(key);
              if (index > -1) {
                  backend.pinnedRaws.splice(index, 1);
              } else {
                  backend.pinnedRaws.push(key);
              }
              backend.pinnedRaws = backend.pinnedRaws.slice();
              savePinnedProcess.jsonString = JSON.stringify(backend.pinnedRaws);
              savePinnedProcess.running = true;
              if (backend.currentTab === 1) updateSearch();
          }

          function selectItem(rawString) {
              if (backend.pinnedRaws.indexOf(backend.pinKey(rawString)) !== -1) {
                  backend.repinTopOnRefresh = true;
                  var tabIndex = rawString.indexOf("\t");
                  backend.repinDisplayHint = tabIndex > -1 ? rawString.substring(tabIndex + 1) : "";
              }
              copyToClipboard.selectedItem = rawString;
              copyToClipboard.running = true;
          }

          function removeItem(rawString, itemId) {
              var pinIndex = backend.pinnedRaws.indexOf(backend.pinKey(rawString));
              if (pinIndex > -1) {
                  backend.pinnedRaws.splice(pinIndex, 1);
                  backend.pinnedRaws = backend.pinnedRaws.slice();
                  savePinnedProcess.jsonString = JSON.stringify(backend.pinnedRaws);
                  savePinnedProcess.running = true;
              }
              backend.allItems = backend.allItems.filter(function(item) {
                  return item.raw !== rawString;
              });
              backend.updateSearch();
              deleteEntry.targetRaw = rawString;
              deleteEntry.targetId = itemId;
              deleteEntry.running = true;
          }

          function clearUnpinnedHistory() {
              var unpinnedRaws = backend.allItems
                  .filter(function(item) {
                      return backend.pinnedRaws.indexOf(backend.pinKey(item.raw)) === -1;
                  })
                  .map(function(item) { return item.raw; });
              if (unpinnedRaws.length === 0) return;

              backend.allItems = backend.allItems.filter(function(item) {
                  return unpinnedRaws.indexOf(item.raw) === -1;
              });
              backend.updateSearch();
              clearHistoryProcess.unpinnedList = unpinnedRaws.join("\n");
              clearHistoryProcess.running = true;
          }

          function triggerRefresh() {
              // Restart even if a previous run is still marked running
              fetchHistory.running = false;
              fetchHistory.running = true;
          }

          Process {
              id: savePinnedProcess
              property string jsonString: "[]"
              command: ["bash", "-c",
                  "mkdir -p \"$(dirname \"" + backend.pinnedCachePath + "\")\" && printf '%s' \"$1\" > \"" + backend.pinnedCachePath + "\"",
                  "_", jsonString]
          }

          Process {
              id: loadPinnedProcess
              command: ["bash", "-c", "cat \"" + backend.pinnedCachePath + "\" 2>/dev/null || echo '[]'"]
              stdout: StdioCollector {
                  onStreamFinished: {
                      try {
                          backend.pinnedRaws = JSON.parse(this.text.trim() || "[]");
                      } catch (e) {
                          backend.pinnedRaws = [];
                      }
                      backend.triggerRefresh();
                  }
              }
          }

          Process {
              id: fetchHistory
              // Prefer visual script (image thumbs); fall back to plain cliphist list.
              command: ["bash", "-c",
                  "script=\"$1\"; "
                  + "if [ -r \"$script\" ]; then bash \"$script\" 2>/dev/null || cliphist list; "
                  + "else cliphist list; fi",
                  "_", backend.scriptPath]
              stdout: StdioCollector {
                  onStreamFinished: {
                      var raw = (this.text || "").replace(/\r/g, "");
                      backend.allItems = raw.split("\n").filter(function(line) {
                          return line.trim() !== "";
                      }).map(function(line) {
                          var parts = line.split("\t");
                          return {
                              raw: parts[0] + "\t" + (parts[1] || ""),
                              display: parts[1] || "",
                              imagePath: parts[2] || ""
                          };
                      });

                      var originalLength = backend.pinnedRaws.length;
                      backend.pinnedRaws = backend.pinnedRaws.filter(function(pinnedKey) {
                          return backend.allItems.some(function(item) {
                              return backend.pinKey(item.raw) === pinnedKey;
                          });
                      });

                      if (backend.repinTopOnRefresh) {
                          var top = backend.allItems[0];
                          if (top && top.display === backend.repinDisplayHint) {
                              var topKey = backend.pinKey(top.raw);
                              if (backend.pinnedRaws.indexOf(topKey) === -1)
                                  backend.pinnedRaws = backend.pinnedRaws.concat([topKey]);
                          }
                          backend.repinTopOnRefresh = false;
                          backend.repinDisplayHint = "";
                      }

                      if (backend.pinnedRaws.length !== originalLength) {
                          savePinnedProcess.jsonString = JSON.stringify(backend.pinnedRaws);
                          savePinnedProcess.running = true;
                      }
                      backend.updateSearch();
                  }
              }
          }

          Process {
              id: copyToClipboard
              property string selectedItem: ""
              command: ["bash", "-c",
                  "printf '%s' \"$1\" | cliphist decode | wl-copy",
                  "_", selectedItem]
              onRunningChanged: {
                  if (!running && copyToClipboard.selectedItem !== "") {
                      backend.closeRequested();
                      copyToClipboard.selectedItem = "";
                  }
              }
          }

          Process {
              id: deleteEntry
              property string targetRaw: ""
              property string targetId: ""
              command: ["bash", "-c",
                  "printf '%s' \"$1\" | cliphist delete && rm -f /tmp/cliphist/\"$2\".*",
                  "_", targetRaw, targetId]
              onRunningChanged: {
                  if (!running && targetRaw !== "") {
                      targetRaw = "";
                      targetId = "";
                  }
              }
          }

          Process {
              id: clearHistoryProcess
              property string unpinnedList: ""
              command: ["bash", "-c",
                  "echo \"$1\" | while IFS= read -r line; do " +
                  "if [ -n \"$line\" ]; then " +
                  "printf '%s\\n' \"$line\" | cliphist delete; " +
                  "id=$(printf '%s' \"$line\" | cut -d$'\\t' -f1); " +
                  "rm -f \"/tmp/cliphist/''${id}.*\"; " +
                  "fi; done",
                  "_", unpinnedList]
              onRunningChanged: {
                  if (!running && unpinnedList !== "") unpinnedList = "";
              }
          }
      }

      // ── Window ───────────────────────────────────────────────────────────
      PanelWindow {
          id: clipboardWindow
          visible: false
          color: "transparent"

          WlrLayershell.namespace: "stellar:clipboard"
          WlrLayershell.layer: WlrLayer.Overlay
          WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
          exclusiveZone: -1

          anchors {
              top: true
              bottom: true
              left: true
              right: true
          }

          function openMenu() {
              backend.resetSelectionPending = true;
              backend.triggerRefresh();
              backend.searchText = "";
              backend.currentTab = 0;
              clipboardWindow.visible = true;
          }

          function closeMenu() {
              clipboardWindow.visible = false;
          }

          Connections {
              target: backend
              function onCloseRequested() { clipboardWindow.closeMenu(); }
          }

          // Dim backdrop – click to dismiss
          MouseArea {
              anchors.fill: parent
              onClicked: clipboardWindow.closeMenu()
          }

          Rectangle {
              id: mainUi
              anchors.centerIn: parent
              width: 560
              height: 640
              radius: 16
              color: "${c.base00}"
              border.color: "${c.base0D}"
              border.width: 2
              clip: true
              focus: true

              // Block click-through to backdrop
              MouseArea {
                  anchors.fill: parent
                  onClicked: {}
              }

              property int navRepeatCount: 0

              function navigate(direction, isAutoRepeat) {
                  navRepeatCount = isAutoRepeat ? navRepeatCount + 1 : 0;
                  var step = navRepeatCount > 12 ? 4 : (navRepeatCount > 6 ? 3 : (navRepeatCount > 2 ? 2 : 1));
                  listView.cancelFlick();
                  listView.suppressHoverSelect = true;
                  hoverSuppressTimer.restart();
                  listView.currentIndex = Math.max(0, Math.min(
                      listView.currentIndex + direction * step,
                      listView.count - 1
                  ));
              }

              Timer {
                  id: hoverSuppressTimer
                  interval: 150
                  onTriggered: listView.suppressHoverSelect = false
              }

              Keys.onPressed: function(event) {
                  // Navigation (no bare j/k/p — those type into search)
                  if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_N) {
                      mainUi.navigate(1, event.isAutoRepeat);
                      event.accepted = true;
                      return;
                  }
                  if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_P) {
                      mainUi.navigate(-1, event.isAutoRepeat);
                      event.accepted = true;
                      return;
                  }
                  if (event.key === Qt.Key_Down) {
                      mainUi.navigate(1, event.isAutoRepeat);
                      event.accepted = true;
                      return;
                  }
                  if (event.key === Qt.Key_Up) {
                      mainUi.navigate(-1, event.isAutoRepeat);
                      event.accepted = true;
                      return;
                  }
                  if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                      if (listView.currentItem) listView.currentItem.select();
                      event.accepted = true;
                      return;
                  }
                  if (event.key === Qt.Key_Tab) {
                      backend.currentTab = backend.currentTab === 0 ? 1 : 0;
                      listView.currentIndex = 0;
                      event.accepted = true;
                      return;
                  }
                  if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
                      backend.clearUnpinnedHistory();
                      event.accepted = true;
                      return;
                  }
                  if (event.key === Qt.Key_Escape) {
                      if (searchInput.text !== "") {
                          searchInput.text = "";
                          backend.searchText = "";
                      } else {
                          clipboardWindow.closeMenu();
                      }
                      event.accepted = true;
                      return;
                  }
                  if (event.key === Qt.Key_Backspace) {
                      if (searchInput.text.length > 0) {
                          searchInput.text = searchInput.text.slice(0, -1);
                          backend.searchText = searchInput.text;
                      }
                      event.accepted = true;
                      return;
                  }
                  // Any printable character → search (no need to focus the bar)
                  if (event.text && event.text.length > 0 && !(event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.AltModifier) && !(event.modifiers & Qt.MetaModifier)) {
                      var ch = event.text;
                      if (ch !== "\n" && ch !== "\r" && ch.charCodeAt(0) >= 32) {
                          searchInput.text = searchInput.text + ch;
                          backend.searchText = searchInput.text;
                          listView.currentIndex = 0;
                          event.accepted = true;
                      }
                  }
              }

              ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 16
                  spacing: 12

                  // Header
                  RowLayout {
                      Layout.fillWidth: true
                      spacing: 10

                      Text {
                          text: "󱉨"
                          font.family: "${fontFamily}"
                          font.pixelSize: 20
                          color: "${c.base0A}"
                      }
                      Text {
                          text: "Clipboard"
                          font.family: "${fontFamily}"
                          font.pixelSize: 16
                          font.bold: true
                          color: "${c.base05}"
                          Layout.fillWidth: true
                      }
                      // Clear unpinned
                      Rectangle {
                          width: clearLabel.implicitWidth + 16
                          height: 28
                          radius: 8
                          color: clearHover.containsMouse ? Qt.rgba(0.8, 0.2, 0.2, 0.25) : "transparent"
                          border.width: 1
                          border.color: "${c.base03}"

                          Text {
                              id: clearLabel
                              anchors.centerIn: parent
                              text: "Clear"
                              font.family: "${fontFamily}"
                              font.pixelSize: 11
                              color: clearHover.containsMouse ? "${c.base08}" : "${c.base04}"
                          }
                          MouseArea {
                              id: clearHover
                              anchors.fill: parent
                              hoverEnabled: true
                              cursorShape: Qt.PointingHandCursor
                              onClicked: backend.clearUnpinnedHistory()
                          }
                      }
                  }

                  // Search
                  Rectangle {
                      Layout.fillWidth: true
                      height: 40
                      radius: 10
                      color: "${c.base01}"
                      border.width: searchInput.activeFocus ? 1 : 0
                      border.color: "${c.base0D}"

                      RowLayout {
                          anchors.fill: parent
                          anchors.leftMargin: 12
                          anchors.rightMargin: 12
                          spacing: 8

                          Text {
                              text: "󰍉"
                              font.family: "${fontFamily}"
                              font.pixelSize: 14
                              color: searchInput.activeFocus ? "${c.base0D}" : "${c.base03}"
                          }
                          TextInput {
                              id: searchInput
                              Layout.fillWidth: true
                              font.family: "${fontFamily}"
                              font.pixelSize: 13
                              color: "${c.base05}"
                              verticalAlignment: TextInput.AlignVCenter
                              clip: true
                              onTextChanged: backend.searchText = text

                              Keys.onPressed: function(event) {
                                  if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_N) {
                                      mainUi.navigate(1, false);
                                      event.accepted = true;
                                  } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_P) {
                                      mainUi.navigate(-1, false);
                                      event.accepted = true;
                                  } else if (event.key === Qt.Key_Down) {
                                      mainUi.navigate(1, false);
                                      event.accepted = true;
                                  } else if (event.key === Qt.Key_Up) {
                                      mainUi.navigate(-1, false);
                                      event.accepted = true;
                                  } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                      if (listView.currentItem) listView.currentItem.select();
                                      event.accepted = true;
                                  } else if (event.key === Qt.Key_Escape) {
                                      if (text !== "") {
                                          text = "";
                                          backend.searchText = "";
                                      } else {
                                          clipboardWindow.closeMenu();
                                      }
                                      event.accepted = true;
                                  }
                              }
                          }
                      }
                  }

                  // Tabs
                  Row {
                      Layout.alignment: Qt.AlignHCenter
                      spacing: 10

                      Repeater {
                          model: [
                              { label: "All Clips", index: 0 },
                              { label: "Pinned", index: 1 }
                          ]
                          delegate: Rectangle {
                              required property var modelData
                              width: 120
                              height: 32
                              radius: 16
                              color: backend.currentTab === modelData.index ? "${c.base0D}" : "transparent"
                              border.width: backend.currentTab === modelData.index ? 0 : 1
                              border.color: "${c.base03}"

                              Text {
                                  anchors.centerIn: parent
                                  text: modelData.label
                                  font.family: "${fontFamily}"
                                  font.pixelSize: 12
                                  font.bold: true
                                  color: backend.currentTab === modelData.index ? "${c.base00}" : "${c.base04}"
                              }
                              MouseArea {
                                  anchors.fill: parent
                                  cursorShape: Qt.PointingHandCursor
                                  onClicked: {
                                      backend.currentTab = modelData.index;
                                      listView.currentIndex = 0;
                                  }
                              }
                          }
                      }
                  }

                  // List
                  ListView {
                      id: listView
                      Layout.fillWidth: true
                      Layout.fillHeight: true
                      clip: true
                      spacing: 6
                      model: backend.filteredItems
                      currentIndex: 0
                      highlightMoveDuration: 0
                      keyNavigationEnabled: false

                      property bool suppressHoverSelect: false
                      property string pendingSelectKey: ""

                      onCountChanged: {
                          if (backend.resetSelectionPending) {
                              currentIndex = 0;
                              backend.resetSelectionPending = false;
                          } else if (pendingSelectKey !== "") {
                              for (var i = 0; i < backend.filteredItems.length; i++) {
                                  if (backend.filteredItems[i].raw === pendingSelectKey) {
                                      currentIndex = i;
                                      break;
                                  }
                              }
                              pendingSelectKey = "";
                          }
                      }

                      onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                      delegate: Rectangle {
                          id: delegateRoot
                          width: listView.width
                          height: modelData.imagePath !== "" ? 180 : 64
                          radius: 10
                          color: {
                              if (ListView.isCurrentItem)
                                  return Qt.rgba(
                                      parseInt("${c.base0D}".slice(1,3),16)/255,
                                      parseInt("${c.base0D}".slice(3,5),16)/255,
                                      parseInt("${c.base0D}".slice(5,7),16)/255,
                                      0.22
                                  );
                              return itemMouse.containsMouse ? "${c.base01}" : "transparent";
                          }
                          border.width: ListView.isCurrentItem ? 1 : 0
                          border.color: "${c.base0D}"

                          property bool isPinned: backend.pinnedRaws.indexOf(backend.pinKey(modelData.raw)) !== -1

                          function select() {
                              backend.selectItem(modelData.raw);
                          }

                          function neighborKey() {
                              var list = backend.filteredItems;
                              var next = list[index + 1];
                              var prev = list[index - 1];
                              return next ? next.raw : (prev ? prev.raw : "");
                          }

                          function markPendingRestore() {
                              listView.pendingSelectKey = neighborKey();
                          }

                          function remove() {
                              markPendingRestore();
                              var id = modelData.raw.split("\t")[0];
                              backend.removeItem(modelData.raw, id);
                          }

                          function togglePinState() {
                              if (backend.currentTab === 1) markPendingRestore();
                              backend.togglePin(modelData.raw);
                          }

                          RowLayout {
                              anchors.fill: parent
                              anchors.margins: 10
                              spacing: 12

                              // Thumbnail or type icon
                              Rectangle {
                                  visible: modelData.imagePath !== ""
                                  Layout.preferredWidth: 120
                                  Layout.preferredHeight: parent.height - 4
                                  radius: 8
                                  color: "${c.base01}"
                                  clip: true

                                  Image {
                                      anchors.fill: parent
                                      source: modelData.imagePath !== "" ? ("file://" + modelData.imagePath) : ""
                                      fillMode: Image.PreserveAspectCrop
                                      asynchronous: true
                                      cache: true
                                  }
                              }

                              Text {
                                  visible: modelData.imagePath === ""
                                  text: "󱉥"
                                  font.family: "${fontFamily}"
                                  font.pixelSize: 22
                                  color: ListView.isCurrentItem ? "${c.base0D}" : "${c.base03}"
                                  Layout.preferredWidth: 28
                                  horizontalAlignment: Text.AlignHCenter
                              }

                              // Text content
                              ColumnLayout {
                                  Layout.fillWidth: true
                                  Layout.fillHeight: true
                                  spacing: 4

                                  Text {
                                      Layout.fillWidth: true
                                      text: {
                                          var d = modelData.display || "";
                                          if (modelData.imagePath !== "") return "[Image]";
                                          if (d.length > 90) return d.substring(0, 87) + "...";
                                          return d;
                                      }
                                      font.family: "${fontFamily}"
                                      font.pixelSize: 13
                                      font.bold: ListView.isCurrentItem
                                      color: "${c.base05}"
                                      elide: Text.ElideRight
                                      wrapMode: modelData.imagePath !== "" ? Text.NoWrap : Text.WordWrap
                                      maximumLineCount: modelData.imagePath !== "" ? 1 : 2
                                  }

                                  Text {
                                      visible: modelData.imagePath === "" && (modelData.display || "").indexOf("\n") !== -1
                                      text: "multiline"
                                      font.family: "${fontFamily}"
                                      font.pixelSize: 10
                                      color: "${c.base03}"
                                  }
                              }

                              // Pin button
                              Rectangle {
                                  width: 36
                                  height: 36
                                  radius: 18
                                  color: pinMouse.containsMouse
                                      ? Qt.rgba(
                                          parseInt("${c.base0A}".slice(1,3),16)/255,
                                          parseInt("${c.base0A}".slice(3,5),16)/255,
                                          parseInt("${c.base0A}".slice(5,7),16)/255,
                                          0.2
                                        )
                                      : "transparent"

                                  Text {
                                      anchors.centerIn: parent
                                      text: delegateRoot.isPinned ? "󰐃" : "󰐄"
                                      font.family: "${fontFamily}"
                                      font.pixelSize: 16
                                      color: delegateRoot.isPinned ? "${c.base0A}" : "${c.base03}"
                                  }
                                  MouseArea {
                                      id: pinMouse
                                      anchors.fill: parent
                                      hoverEnabled: true
                                      cursorShape: Qt.PointingHandCursor
                                      preventStealing: true
                                      onClicked: function(mouse) {
                                          mouse.accepted = true;
                                          delegateRoot.togglePinState();
                                      }
                                  }
                              }

                              // Delete button
                              Rectangle {
                                  width: 36
                                  height: 36
                                  radius: 18
                                  color: delMouse.containsMouse
                                      ? Qt.rgba(
                                          parseInt("${c.base08}".slice(1,3),16)/255,
                                          parseInt("${c.base08}".slice(3,5),16)/255,
                                          parseInt("${c.base08}".slice(5,7),16)/255,
                                          0.25
                                        )
                                      : "transparent"

                                  Text {
                                      anchors.centerIn: parent
                                      text: "󰆴"
                                      font.family: "${fontFamily}"
                                      font.pixelSize: 16
                                      color: delMouse.containsMouse ? "${c.base08}" : "${c.base03}"
                                  }
                                  MouseArea {
                                      id: delMouse
                                      anchors.fill: parent
                                      hoverEnabled: true
                                      cursorShape: Qt.PointingHandCursor
                                      preventStealing: true
                                      onClicked: function(mouse) {
                                          mouse.accepted = true;
                                          delegateRoot.remove();
                                      }
                                  }
                              }
                          }

                          MouseArea {
                              id: itemMouse
                              anchors.fill: parent
                              hoverEnabled: true
                              cursorShape: Qt.PointingHandCursor
                              z: -1
                              onEntered: {
                                  if (!listView.suppressHoverSelect)
                                      listView.currentIndex = index;
                              }
                              onClicked: delegateRoot.select()
                          }
                      }

                      // Empty state
                      Text {
                          anchors.centerIn: parent
                          visible: listView.count === 0
                          text: backend.currentTab === 1 ? "No pinned clips" : "Clipboard is empty"
                          font.family: "${fontFamily}"
                          font.pixelSize: 14
                          color: "${c.base03}"
                      }
                  }

                  // Footer hints
                  Text {
                      Layout.fillWidth: true
                      horizontalAlignment: Text.AlignHCenter
                      text: "type to search  ·  Ctrl+N/P navigate  ·  Enter select  ·  Esc close"
                      font.family: "${fontFamily}"
                      font.pixelSize: 10
                      color: "${c.base03}"
                  }
              }

              Component.onCompleted: {
                  if (clipboardWindow.visible) mainUi.forceActiveFocus();
              }
          }

          onVisibleChanged: {
              if (visible) {
                  Qt.callLater(function() { mainUi.forceActiveFocus(); });
              }
          }
      }
  }
''

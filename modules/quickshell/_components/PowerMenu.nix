{ backgroundColor, base07, ... }:
''
  import QtQuick
  import QtQuick.Layouts
  import Quickshell
  import Quickshell.Io
  import Quickshell.Wayland
  Variants {
      id: root
      property bool shown: false
      property int focusedIndex: -1
      property color backgroundColor: "${backgroundColor}"
      property color buttonColor: "transparent"
      property color buttonHoverColor: theme.darkBlue
      default property list<PowerButton> buttons
      model: Quickshell.screens
      onShownChanged: if (shown) focusedIndex = 0; else focusedIndex = -1;
      PanelWindow {
          id: w
          visible: root.shown
          property var modelData
          screen: modelData
          exclusionMode: ExclusionMode.Ignore
          WlrLayershell.layer: WlrLayer.Overlay
          WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
          color: "transparent"
          contentItem {
              focus: true
              Keys.onPressed: event => {
                  if (event.key == Qt.Key_Escape) {
                      root.shown = false;
                      event.accepted = true;
                  }
                  else if (event.key == Qt.Key_Left || event.key == Qt.Key_H) {
                      if (root.focusedIndex > 0) root.focusedIndex--;
                      event.accepted = true;
                  }
                  else if (event.key == Qt.Key_Right || event.key == Qt.Key_L) {
                      if (root.focusedIndex + 1 < buttons.length) root.focusedIndex++;
                      event.accepted = true;
                  }
                  else if (event.key == Qt.Key_Up || event.key == Qt.Key_K) {
                      if (root.focusedIndex > 0) root.focusedIndex--;
                      event.accepted = true;
                  }
                  else if (event.key == Qt.Key_Down || event.key == Qt.Key_J) {
                      if (root.focusedIndex + 1 < buttons.length) root.focusedIndex++;
                      event.accepted = true;
                  }
                  else if (event.key == Qt.Key_Return || event.key == Qt.Key_Space) {
                      if (root.focusedIndex >= 0 && root.focusedIndex < buttons.length) {
                          buttons[root.focusedIndex].exec();
                          root.shown = false;
                      }
                      event.accepted = true;
                  }
              }
          }
          anchors {
              top: true
              left: true
              bottom: true
              right: true
          }
          Rectangle {
              color: backgroundColor
              anchors.fill: parent
              MouseArea {
                  anchors.fill: parent
                  onClicked: root.shown = false
                  RowLayout {
                      anchors.centerIn: parent
                      spacing: 20
                      Repeater {
                          model: buttons
                          delegate: Rectangle {
                              required property PowerButton modelData;
                              required property int index;
                              Layout.preferredWidth: 180
                              Layout.preferredHeight: 180
                              color: ma.containsMouse || (index == root.focusedIndex) ? root.buttonHoverColor : root.buttonColor
                              radius: 10
                              border.color: theme.fgSubtle
                              border.width: 2
                              MouseArea {
                                  id: ma
                                  anchors.fill: parent
                                  hoverEnabled: true
                                  onClicked: {
                                      modelData.exec();
                                      root.shown = false;
                                  }
                              }
                              ColumnLayout {
                                  anchors.centerIn: parent
                                  spacing: 10
                                  Image {
                                      source: ma.containsMouse || (index == root.focusedIndex) ? "icons/" + modelData.icon + "-hover.png" : "icons/" + modelData.icon + ".png"
                                      Layout.preferredWidth: 114
                                      Layout.preferredHeight: 114
                                      fillMode: Image.PreserveAspectFit
                                      Layout.alignment: Qt.AlignHCenter
                                  }
                                  Text {
                                      text: modelData.text
                                      font.pixelSize: 12
                                      color: "${base07}"
                                      Layout.alignment: Qt.AlignHCenter
                                  }
                              }
                          }
                      }
                  }
              }
          }
      }
  }
''

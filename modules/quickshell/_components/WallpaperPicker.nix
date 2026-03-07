{
  lib,
  wallpapersList,
  ...
}:
let
  wallpapersArray = lib.concatStringsSep ", " (map (w: "\"${w}\"") wallpapersList);
in
/* qml */ ''
  import QtQuick
  import QtQuick.Layouts
  import Quickshell
  import Quickshell.Wayland

  Variants {
      id: pickerRoot
      property bool shown: false
      property var wallpaperLoader: null
      property var overviewWallpaperLoader: null

      model: Quickshell.screens

      delegate: PanelWindow {
          id: pickerWindow
          required property var modelData

          screen: modelData
          visible: pickerRoot.shown

          WlrLayershell.layer: WlrLayer.Overlay
          WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
          WlrLayershell.namespace: "wallpaper-picker"

          anchors {
              top: true
              bottom: true
              left: true
              right: true
          }

          color: "#cc000000"

          contentItem {
              focus: true
              Keys.onEscapePressed: {
                  pickerRoot.shown = false
              }
          }

          MouseArea {
              anchors.fill: parent
              onClicked: pickerRoot.shown = false
          }

          Rectangle {
              anchors.centerIn: parent
              width: Math.min(800, parent.width - 100)
              height: Math.min(500, parent.height - 100)
              radius: 12
              color: "#1e1e2e"

              MouseArea {
                  anchors.fill: parent
              }

              ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 20
                  spacing: 15

                  RowLayout {
                      Layout.fillWidth: true

                      Text {
                          text: "Wallpapers"
                          color: "#cdd6f4"
                          font.pixelSize: 20
                          font.bold: true
                      }

                      Item { Layout.fillWidth: true }

                      Text {
                          text: "󰅖"
                          color: "#a6adc8"
                          font.pixelSize: 18
                          MouseArea {
                              anchors.fill: parent
                              cursorShape: Qt.PointingHandCursor
                              onClicked: pickerRoot.shown = false
                          }
                      }
                  }

                  GridView {
                      id: wallpaperGrid
                      Layout.fillWidth: true
                      Layout.fillHeight: true

                      cellWidth: 180
                      cellHeight: 120

                      model: [${wallpapersArray}]

                      delegate: Rectangle {
                          id: wpItem
                          required property string modelData

                          width: wallpaperGrid.cellWidth - 10
                          height: wallpaperGrid.cellHeight - 10
                          radius: 8
                          color: "#313244"

                          property bool isHovered: wpMouse.containsMouse

                          Image {
                              anchors.fill: parent
                              anchors.margins: 4
                              source: "file://" + wpItem.modelData
                              fillMode: Image.PreserveAspectCrop
                              asynchronous: true
                          }

                          MouseArea {
                              id: wpMouse
                              anchors.fill: parent
                              hoverEnabled: true
                              cursorShape: Qt.PointingHandCursor
                              onClicked: {
                                  var wl = pickerRoot.wallpaperLoader
                                  if (wl && wl.item) {
                                      wl.item.setWallpaper(wpItem.modelData)
                                  }
                                  var owl = pickerRoot.overviewWallpaperLoader
                                  if (owl && owl.item) {
                                      owl.item.setWallpaper(wpItem.modelData)
                                  }
                                  pickerRoot.shown = false
                              }
                          }

                          Rectangle {
                              anchors.fill: parent
                              color: "#000000"
                              opacity: wpItem.isHovered ? 0.3 : 0
                          }

                          Text {
                              anchors.centerIn: parent
                              text: "󰄬"
                              color: "#ffffff"
                              font.pixelSize: 24
                              opacity: wpItem.isHovered ? 1 : 0
                          }
                      }
                  }
              }
          }
      }
  }
''

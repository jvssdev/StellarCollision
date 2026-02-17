{
  lib,
  wallpapersList,
  ...
}:
let
  wallpapersArray = lib.concatStringsSep ", " (map (w: "\"${w}\"") wallpapersList);
in
''
  import QtQuick
  import QtQuick.Effects
  import Quickshell
  import Quickshell.Wayland

  Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
      id: root
      required property ShellScreen modelData

      color: "transparent"
      screen: modelData

      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "wallpaper"

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      property var wallpapers: [${wallpapersArray}]
      property int currentIndex: 0
      property real transitionProgress: 0

      Component.onCompleted: {
        if (wallpapers.length > 0) {
          currentWallpaper.source = wallpapers[0]
        }
      }

      Timer {
        id: wallpaperTimer
        interval: 600000
        running: root.wallpapers.length > 1
        repeat: true
        onTriggered: root.nextWallpaper()
      }

      NumberAnimation {
        id: transitionAnimation
        target: root
        property: "transitionProgress"
        from: 0.0
        to: 1.0
        duration: 1000
        easing.type: Easing.InOutCubic
        onFinished: {
          currentWallpaper.source = nextWallpaperImage.source
          root.transitionProgress = 0.0
        }
      }

      function nextWallpaper() {
        if (wallpapers.length <= 1) return

        currentIndex = (currentIndex + 1) % wallpapers.length
        nextWallpaperImage.source = wallpapers[currentIndex]

        if (nextWallpaperImage.status === Image.Ready) {
          transitionAnimation.start()
        } else {
          nextWallpaperImage.onStatusChanged.connect(function() {
            if (nextWallpaperImage.status === Image.Ready) {
              transitionAnimation.start()
            }
          })
        }
      }

      Image {
        id: currentWallpaper
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        cache: true
        opacity: 1 - root.transitionProgress
        visible: source !== ""

        layer.enabled: true
        layer.smooth: false
        layer.effect: MultiEffect {
          blurEnabled: false
          blur: 0.6
          blurMax: 64
        }

        Rectangle {
          anchors.fill: parent
          color: "#000000"
          opacity: 0.3
        }
      }

      Image {
        id: nextWallpaperImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        cache: false
        opacity: root.transitionProgress
        visible: source !== "" && root.transitionProgress > 0
        onStatusChanged: {
          if (status === Image.Ready && !transitionAnimation.running && source !== currentWallpaper.source) {
            transitionAnimation.start()
          }
        }

        layer.enabled: true
        layer.smooth: false
        layer.effect: MultiEffect {
          blurEnabled: true
          blur: 0.6
          blurMax: 64
        }

        Rectangle {
          anchors.fill: parent
          color: "#000000"
          opacity: 0.3
        }
      }
    }
  }
''

{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) getExe;
in
''
  import QtQuick
  import QtQuick.Effects
  import Quickshell
  import Quickshell.Wayland

  // Wallpaper normal para o desktop
  Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
      id: root
      required property ShellScreen modelData

      color: "transparent"
      screen: modelData
      
      // Layer shell configuration
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "quickshell-wallpaper-" + (screen?.name || "unknown")

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      // Wallpaper Image - usa o arquivo na pasta quickshell
      Image {
        id: wallpaperImage
        anchors.fill: parent
        source: Quickshell.shellDir + "/wallpaper.png"
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        cache: true
      }
    }
  }
''

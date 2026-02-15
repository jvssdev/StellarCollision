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

  // Wallpaper para o backdrop do Overview (Niri)
  // Usa namespace "wallpaper" para ser capturado pela layer-rule do Niri
  Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
      id: root
      required property ShellScreen modelData

      color: "transparent"
      screen: modelData
      
      // Layer shell configuration - namespace especial para o backdrop
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "wallpaper"

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      // Wallpaper Image com blur - usa o arquivo na pasta quickshell
      Image {
        id: wallpaperImage
        anchors.fill: parent
        source: Quickshell.shellDir + "/wallpaper.png"
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        cache: true

        // Efeito de blur para o overview
        layer.enabled: true
        layer.smooth: false
        layer.effect: MultiEffect {
          blurEnabled: true
          blur: 0.6  // 60% blur
          blurMax: 64
        }

        // Overlay escuro para melhor contraste
        Rectangle {
          anchors.fill: parent
          color: "#000000"
          opacity: 0.3
        }
      }
    }
  }
''

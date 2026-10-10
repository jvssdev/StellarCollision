{ ... }:
/* qml */ ''
  import QtQuick
  import QtQuick.Shapes
  import Quickshell
  import Quickshell.Wayland

  PanelWindow {
      id: root

      property bool atTop: true
      property bool atLeft: true
      property int radius: 12
      property int edgeOffset: 0
      property color fillColor: "#000000"

      screen: Quickshell.screens[0]
      color: "transparent"
      implicitWidth: radius
      implicitHeight: radius

      WlrLayershell.layer: WlrLayer.Bottom
      WlrLayershell.namespace: "stellar:corner"
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      anchors {
          top: root.atTop
          bottom: !root.atTop
          left: root.atLeft
          right: !root.atLeft
      }

      margins {
          top: root.atTop ? root.edgeOffset : 0
          bottom: root.atTop ? 0 : root.edgeOffset
      }

      Shape {
          anchors.fill: parent
          preferredRendererType: Shape.CurveRenderer
          transform: Scale {
              origin.x: root.radius / 2
              origin.y: root.radius / 2
              xScale: root.atLeft ? 1 : -1
              yScale: root.atTop ? 1 : -1
          }
          ShapePath {
              fillColor: root.fillColor
              strokeColor: "transparent"
              strokeWidth: -1
              startX: 0
              startY: 0
              PathLine { x: root.radius; y: 0 }
              PathArc {
                  x: 0
                  y: root.radius
                  radiusX: root.radius
                  radiusY: root.radius
                  direction: PathArc.Counterclockwise
              }
              PathLine { x: 0; y: 0 }
          }
      }
  }
''

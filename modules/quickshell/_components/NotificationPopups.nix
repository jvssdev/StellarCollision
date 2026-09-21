_:

/* qml */ ''
  import QtQuick
  import QtQuick.Layouts
  import QtQuick.Effects
  import Quickshell
  import Quickshell.Wayland
  import Quickshell.Services.Notifications
  import Quickshell.Widgets

  PanelWindow {
      id: popupsWindow

      property bool dndEnabled: false
      property int maxVisible: 5

      implicitWidth: 400
      implicitHeight: 900
      screen: Quickshell.screens[0]
      color: "transparent"

      visible: notificationColumn.children.length > 0 && !dndEnabled

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      mask: notificationColumn.children.length > 0 && !dndEnabled ? popupMask : null

      Region {
          id: popupMask
          item: notificationColumn
          radius: theme.radius
      }

      anchors {
          top: true
          right: true
      }

      margins {
          top: 18
          right: 12
      }

      Column {
          id: notificationColumn
          spacing: 10
          width: 380
          anchors.right: parent.right
          anchors.top: parent.top

          Repeater {
              model: notificationServer.trackedNotifications

              delegate: Item {
                  id: notifDelegate
                  required property Notification modelData
                  required property int index

                  width: 380
                  height: card.implicitHeight
                  visible: index < popupsWindow.maxVisible

                  property bool expanded: false
                  property real dragX: 0

                  // slide-in animation
                  opacity: 0
                  x: 40

                  Component.onCompleted: {
                      opacity = 1
                      x = 0
                  }

                  Behavior on opacity {
                      NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
                  }
                  Behavior on x {
                      NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                  }
                  Behavior on height {
                      NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                  }

                  // auto-dismiss timer
                  Timer {
                      id: closeTimer
                      interval: {
                          if (!modelData) return 5000
                          if (modelData.urgency === NotificationUrgency.Critical) return 8000
                          if (modelData.expireTimeout > 0) return modelData.expireTimeout * 1000
                          return 5500
                      }
                      running: modelData && !modelData.resident && !notifDelegate.expanded
                      onTriggered: {
                          if (modelData) modelData.expire()
                      }
                  }

                  // card
                  Rectangle {
                      id: card
                      width: parent.width
                      anchors.right: parent.right
                      x: notifDelegate.dragX
                      implicitHeight: inner.implicitHeight + 24
                      radius: theme.radius
                      color: theme.bg
                      border.width: 2
                      border.color: {
                          if (!modelData) return theme.darkBlue
                          if (modelData.urgency === NotificationUrgency.Critical) return theme.red
                          if (modelData.urgency === NotificationUrgency.Low) return theme.fgSubtle
                          return theme.darkBlue
                      }

                      // subtle left accent bar for urgency
                      Rectangle {
                          width: 4
                          height: parent.height - 8
                          anchors.left: parent.left
                          anchors.leftMargin: 4
                          anchors.verticalCenter: parent.verticalCenter
                          radius: 2
                          color: {
                              if (!modelData) return theme.darkBlue
                              if (modelData.urgency === NotificationUrgency.Critical) return theme.red
                              if (modelData.urgency === NotificationUrgency.Low) return theme.fgSubtle
                              return theme.darkBlue
                          }
                      }

                      MouseArea {
                          id: cardMa
                          anchors.fill: parent
                          hoverEnabled: true
                          acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                          cursorShape: Qt.PointingHandCursor

                          property real startX: 0
                          property bool dragging: false

                          onEntered: closeTimer.stop()
                          onExited: {
                              if (!dragging && modelData && !modelData.resident && !notifDelegate.expanded)
                                  closeTimer.restart()
                          }

                          onPressed: (mouse) => {
                              closeTimer.stop()
                              if (mouse.button === Qt.MiddleButton) {
                                  if (modelData) modelData.dismiss()
                                  return
                              }
                              startX = mouse.x
                              dragging = false
                          }

                          onPositionChanged: (mouse) => {
                              if (pressed) {
                                  const dx = mouse.x - startX
                                  if (Math.abs(dx) > 8) dragging = true
                                  if (dragging) {
                                      // only allow swipe to the right (dismiss)
                                      notifDelegate.dragX = Math.max(0, dx)
                                  }
                              }
                          }

                          onReleased: (mouse) => {
                              if (dragging) {
                                  if (notifDelegate.dragX > card.width * 0.35) {
                                      // dismiss
                                      if (modelData) modelData.dismiss()
                                  } else {
                                      // snap back
                                      notifDelegate.dragX = 0
                                  }
                              } else {
                                  // toggle expand
                                  notifDelegate.expanded = !notifDelegate.expanded
                              }
                              dragging = false
                          }

                          onClicked: (mouse) => {
                              // handled in released for expand / dismiss
                          }
                      }

                      Column {
                          id: inner
                          anchors {
                              left: parent.left
                              right: parent.right
                              top: parent.top
                              margins: 14
                              leftMargin: 18
                          }
                          spacing: 8

                          // header row: icon + text + close
                          Row {
                              width: parent.width
                              spacing: 12

                              // app icon / image / fallback letter
                              Item {
                                  width: 42
                                  height: 42

                                  Rectangle {
                                      anchors.fill: parent
                                      radius: 10
                                      color: theme.bgLighter
                                      visible: !appImage.visible && !appIconImg.visible
                                  }

                                  // notification image (if any)
                                  Image {
                                      id: appImage
                                      anchors.fill: parent
                                      source: modelData && modelData.image ? modelData.image : ""
                                      fillMode: Image.PreserveAspectCrop
                                      visible: status === Image.Ready
                                      layer.enabled: true
                                      layer.effect: MultiEffect {
                                          maskEnabled: true
                                          maskSource: iconMask
                                      }
                                  }

                                  // app icon
                                  Image {
                                      id: appIconImg
                                      anchors.fill: parent
                                      anchors.margins: 4
                                      source: modelData && modelData.appIcon ? modelData.appIcon : ""
                                      fillMode: Image.PreserveAspectFit
                                      visible: status === Image.Ready && !appImage.visible
                                      layer.enabled: true
                                      layer.effect: MultiEffect {
                                          maskEnabled: true
                                          maskSource: iconMask
                                      }
                                  }

                                  Rectangle {
                                      id: iconMask
                                      anchors.fill: parent
                                      radius: 10
                                      visible: false
                                      layer.enabled: true
                                  }

                                  Text {
                                      anchors.centerIn: parent
                                      visible: !appImage.visible && !appIconImg.visible
                                      text: modelData && modelData.appName ? modelData.appName.charAt(0).toUpperCase() : "N"
                                      font.pixelSize: 18
                                      font.bold: true
                                      color: theme.darkBlue
                                      font.family: theme.fontFamily
                                  }
                              }

                              // summary + body preview
                              Column {
                                  width: parent.width - 42 - 28 - 24
                                  spacing: 3
                                  anchors.verticalCenter: parent.verticalCenter

                                  Text {
                                      width: parent.width
                                      text: modelData ? modelData.summary : ""
                                      font.family: theme.fontFamily
                                      font.pixelSize: 14
                                      font.bold: true
                                      color: theme.fg
                                      elide: Text.ElideRight
                                      maximumLineCount: 1
                                  }

                                  Text {
                                      width: parent.width
                                      text: modelData ? modelData.body : ""
                                      font.family: theme.fontFamily
                                      font.pixelSize: 12
                                      color: theme.fgMuted
                                      wrapMode: Text.WordWrap
                                      maximumLineCount: notifDelegate.expanded ? 12 : 2
                                      elide: Text.ElideRight
                                      visible: modelData && modelData.body && modelData.body !== ""
                                      textFormat: {
                                          if (!modelData || !modelData.body) return Text.PlainText
                                          return /[<*_`#\[\]]/.test(modelData.body) ? Text.MarkdownText : Text.PlainText
                                      }
                                  }

                                  // app name when expanded
                                  Text {
                                      visible: notifDelegate.expanded && modelData && modelData.appName
                                      text: modelData ? modelData.appName : ""
                                      font.family: theme.fontFamily
                                      font.pixelSize: 11
                                      color: theme.fgSubtle
                                  }
                              }

                              // close button
                              Text {
                                  text: "✕"
                                  color: closeMa.containsMouse ? theme.red : theme.fgMuted
                                  font.pixelSize: 15
                                  anchors.verticalCenter: parent.verticalCenter
                                  width: 22
                                  horizontalAlignment: Text.AlignHCenter

                                  MouseArea {
                                      id: closeMa
                                      anchors.fill: parent
                                      anchors.margins: -6
                                      hoverEnabled: true
                                      cursorShape: Qt.PointingHandCursor
                                      onClicked: if (modelData) modelData.dismiss()
                                  }
                              }
                          }

                          // actions row (when expanded or always if few)
                          Flow {
                              id: actionsRow
                              width: parent.width
                              spacing: 8
                              visible: modelData && modelData.actions && modelData.actions.length > 0 && (notifDelegate.expanded || modelData.actions.length <= 2)

                              Repeater {
                                  model: modelData ? modelData.actions : []

                                  Rectangle {
                                      required property var modelData
                                      width: actionText.implicitWidth + 20
                                      height: 28
                                      radius: 8
                                      color: actionMa.containsMouse ? theme.bgLighter : theme.bgAlt
                                      border.width: 1
                                      border.color: theme.fgSubtle

                                      Text {
                                          id: actionText
                                          anchors.centerIn: parent
                                          text: modelData ? modelData.text : ""
                                          font.family: theme.fontFamily
                                          font.pixelSize: 12
                                          color: theme.fg
                                      }

                                      MouseArea {
                                          id: actionMa
                                          anchors.fill: parent
                                          hoverEnabled: true
                                          cursorShape: Qt.PointingHandCursor
                                          onClicked: {
                                              if (modelData) modelData.invoke()
                                          }
                                      }
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

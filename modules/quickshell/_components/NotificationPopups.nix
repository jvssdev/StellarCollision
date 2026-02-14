{ pkgs, lib, ... }:
let
  inherit (lib) getExe getExe';
in
''
  import QtQuick
  import QtQuick.Layouts
  import Quickshell
  import Quickshell.Wayland
  import Quickshell.Services.Notifications

  PanelWindow {
      id: popupsWindow
      
      implicitWidth: 380
      implicitHeight: 800
      screen: Quickshell.screens[0]
      color: "transparent"
      
      // FIX: Only visible when there are notification children
      visible: notificationColumn.children.length > 0
      
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore
      
      // FIX: Allow clickthrough when no notifications
      mask: notificationColumn.children.length > 0 ? popupMask : null
      
      Region {
          id: popupMask
          item: notificationColumn
      }
      
      anchors {
          top: true
          right: true
      }
      
      margins {
          top: 60
          right: 20
      }
      
      Column {
          id: notificationColumn
          spacing: 12
          width: 360
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.topMargin: 0
          anchors.rightMargin: 0
          
          Repeater {
              model: notificationServer.trackedNotifications
              
              Rectangle {
                  required property Notification modelData
                  
                  width: 360
                  height: 90
                  color: theme.bg
                  border.color: modelData ? ({
                      [NotificationUrgency.Critical]: theme.red,
                      [NotificationUrgency.Low]: theme.fgMuted
                  }[modelData.urgency] || theme.darkBlue) : theme.darkBlue
                  border.width: 2
                  radius: theme.radius
                  
                  opacity: 0
                  y: -30
                  
                  Component.onCompleted: {
                      opacity = 1
                      y = 0
                  }
                  
                  Behavior on opacity {
                      NumberAnimation { duration: 250 }
                  }
                  
                  Behavior on y {
                      NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                  }
                  
                  MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      onClicked: if (modelData) modelData.dismiss()
                      onEntered: closeTimer.stop()
                      onExited: if (modelData && !modelData.resident) closeTimer.start()
                  }
                  
                  Timer {
                      id: closeTimer
                      interval: modelData && modelData.expireTimeout > 0 ? modelData.expireTimeout * 1000 : 5000
                      running: modelData ? !modelData.resident : false
                      onTriggered: if (modelData) modelData.expire()
                  }
                  
                  Row {
                      anchors.fill: parent
                      anchors.margins: 12
                      spacing: 12
                      
                      Rectangle {
                          width: 44
                          height: 44
                          color: theme.bgLighter
                          radius: 8
                          
                          Text {
                              anchors.centerIn: parent
                              text: modelData && modelData.appName ? modelData.appName[0].toUpperCase() : "N"
                              font.pixelSize: 18
                              font.bold: true
                              color: theme.darkBlue
                          }
                      }
                      
                      Column {
                          width: parent.width - 56
                          spacing: 6
                          
                          Row {
                              width: parent.width
                              
                              Text {
                                  width: parent.width - 24
                                  text: modelData ? modelData.summary : ""
                                  font.family: theme.fontFamily
                                  font.pixelSize: 14
                                  font.bold: true
                                  color: theme.fg
                                  elide: Text.ElideRight
                                  maximumLineCount: 1
                              }
                              
                              Text {
                                  text: "✕"
                                  color: theme.fgMuted
                                  font.pixelSize: 14
                                  anchors.verticalCenter: parent.verticalCenter
                                  
                                  MouseArea {
                                      anchors.fill: parent
                                      hoverEnabled: true
                                      onClicked: if (modelData) modelData.dismiss()
                                      onEntered: parent.color = theme.red
                                      onExited: parent.color = theme.fgMuted
                                  }
                              }
                          }
                          
                          Text {
                              width: parent.width
                              text: modelData ? modelData.body : ""
                              font.family: theme.fontFamily
                              font.pixelSize: 12
                              color: theme.fgMuted
                              wrapMode: Text.WordWrap
                              maximumLineCount: 2
                              elide: Text.ElideRight
                              visible: modelData && modelData.body && modelData.body !== ""
                          }
                      }
                  }
              }
          }
      }
  }
''

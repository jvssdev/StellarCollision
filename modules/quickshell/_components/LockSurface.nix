_:

/* qml */ ''
  import QtQuick
  import QtQuick.Layouts
  import QtQuick.Controls
  import Quickshell.Wayland

  Rectangle {
      id: root
      required property LockContext context
      property var theme: null

      color: theme.bg

      Image {
          id: wall
          anchors.fill: parent
          source: "wallpaper.png"
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: true
      }

      Rectangle {
          anchors.fill: parent
          color: Qt.rgba(0, 0, 0, 0.35)
      }

      ColumnLayout {
          anchors.centerIn: parent
          spacing: 20

          Text {
              id: clockLabel
              property var currentDate: new Date()
              text: Qt.formatTime(currentDate, "HH:mm")
              color: theme.darkBlue
              font.pixelSize: 72
              font.family: theme.fontFamily
              font.bold: true
              style: Text.Outline
              styleColor: Qt.rgba(0, 0, 0, 0.8)
              Layout.alignment: Qt.AlignHCenter

              Timer {
                  interval: 1000
                  running: true
                  repeat: true
                  onTriggered: clockLabel.currentDate = new Date()
              }
          }

          Text {
              id: dateLabel
              property var currentDate: new Date()
              text: Qt.formatDate(currentDate, "dd/MM/yyyy")
              color: theme.darkBlue
              font.pixelSize: 24
              font.family: theme.fontFamily
              Layout.alignment: Qt.AlignHCenter

              Timer {
                  interval: 60000
                  running: true
                  repeat: true
                  onTriggered: dateLabel.currentDate = new Date()
              }
          }

          Text {
              text: "Enter Password"
              color: theme.fg
              font.pixelSize: 18
              font.family: theme.fontFamily
              Layout.alignment: Qt.AlignHCenter
          }

          RowLayout {
              spacing: 10
              Layout.alignment: Qt.AlignHCenter

              TextField {
                  id: passwordBox
                  implicitWidth: 300
                  padding: 15
                  enabled: !root.context.unlockInProgress
                  echoMode: TextInput.Password
                  inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                  color: theme.fg
                  background: Rectangle {
                      color: Qt.rgba(46 / 255, 52 / 255, 64 / 255, 0.85)
                      border.color: theme.darkBlue
                      border.width: 2
                      radius: 12
                  }

                  onTextChanged: root.context.currentText = text
                  onAccepted: root.context.tryUnlock()

                  Connections {
                      target: root.context
                      function onCurrentTextChanged() {
                          if (passwordBox.text !== root.context.currentText)
                              passwordBox.text = root.context.currentText
                      }
                  }

                  Component.onCompleted: {
                      text = ""
                      root.context.currentText = ""
                  }
              }

              Button {
                  text: "Unlock"
                  padding: 12
                  focusPolicy: Qt.NoFocus
                  enabled: !root.context.unlockInProgress && root.context.currentText !== ""
                  onClicked: root.context.tryUnlock()
                  contentItem: Text {
                      text: parent.text
                      color: theme.bg
                      horizontalAlignment: Text.AlignHCenter
                      verticalAlignment: Text.AlignVCenter
                      font.pixelSize: 16
                      font.bold: true
                      font.family: theme.fontFamily
                  }
                  background: Rectangle {
                      color: parent.down ? theme.green : (parent.hovered ? theme.cyan : theme.darkBlue)
                      radius: 8
                  }
              }
          }

          Text {
              visible: root.context.showFailure
              text: "Incorrect password"
              color: theme.red
              font.pixelSize: 14
              font.family: theme.fontFamily
              Layout.alignment: Qt.AlignHCenter
          }
      }

      Timer {
          id: focusTimer
          interval: 80
          repeat: true
          running: !passwordBox.activeFocus && !root.context.unlockInProgress
          onTriggered: passwordBox.forceActiveFocus()
      }
  }
''

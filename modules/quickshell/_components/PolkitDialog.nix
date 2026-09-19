_:

/* qml */ ''
  import QtQuick
  import QtQuick.Layouts
  import QtQuick.Controls
  import Quickshell
  import Quickshell.Wayland
  import Quickshell.Services.Polkit

  Scope {
      id: root

      PolkitAgent {
          id: polkitAgent
      }

      Variants {
          id: windows
          model: Quickshell.screens

          PanelWindow {
              id: w
              property var modelData
              screen: modelData
              visible: polkitAgent.isActive
              exclusionMode: ExclusionMode.Ignore
              WlrLayershell.layer: WlrLayer.Overlay
              WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
              color: "transparent"
              anchors {
                  top: true
                  left: true
                  right: true
                  bottom: true
              }

              Rectangle {
                  anchors.fill: parent
                  color: Qt.rgba(0, 0, 0, 0.55)

                  MouseArea {
                      anchors.fill: parent
                  }

                  Rectangle {
                      id: dialog
                      anchors.centerIn: parent
                      width: 420
                      implicitHeight: content.implicitHeight + theme.padding * 2
                      radius: theme.radius
                      color: theme.bg
                      border.color: theme.darkBlue
                      border.width: theme.borderWidth

                      MouseArea {
                          anchors.fill: parent
                      }

                      ColumnLayout {
                          id: content
                          anchors.fill: parent
                          anchors.margins: theme.padding
                          spacing: theme.spacing

                          Text {
                              Layout.fillWidth: true
                              text: "Authentication Required"
                              color: theme.fg
                              font.pixelSize: theme.fontPixelSize + 6
                              font.bold: true
                              font.family: theme.fontFamily
                              wrapMode: Text.Wrap
                          }

                          Text {
                              Layout.fillWidth: true
                              text: polkitAgent.flow?.message ?? ""
                              color: theme.fg
                              font.pixelSize: theme.fontPixelSize + 2
                              font.family: theme.fontFamily
                              wrapMode: Text.Wrap
                          }

                          Text {
                              Layout.fillWidth: true
                              visible: (polkitAgent.flow?.supplementaryMessage ?? "") !== ""
                              text: polkitAgent.flow?.supplementaryMessage ?? ""
                              color: polkitAgent.flow?.supplementaryIsError ? theme.red : theme.fgMuted
                              font.pixelSize: theme.fontPixelSize
                              font.family: theme.fontFamily
                              wrapMode: Text.Wrap
                          }

                          TextField {
                              id: passwordField
                              Layout.fillWidth: true
                              padding: 12
                              visible: polkitAgent.flow?.isResponseRequired ?? false
                              enabled: polkitAgent.flow?.isResponseRequired ?? false
                              echoMode: polkitAgent.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                              inputMethodHints: Qt.ImhSensitiveData
                              color: theme.fg
                              placeholderText: polkitAgent.flow?.inputPrompt ?? ""
                              background: Rectangle {
                                  color: theme.bgAlt
                                  border.color: theme.darkBlue
                                  border.width: 2
                                  radius: theme.radius - 4
                              }
                              onAccepted: authButton.clicked()

                              Connections {
                                  target: polkitAgent.flow
                                  function onIsResponseRequiredChanged() {
                                      passwordField.text = ""
                                      if (polkitAgent.flow.isResponseRequired) {
                                          passwordField.forceActiveFocus()
                                      }
                                  }
                              }
                          }

                          Text {
                              Layout.fillWidth: true
                              visible: polkitAgent.flow?.failed ?? false
                              text: "Authentication failed, try again"
                              color: theme.red
                              font.pixelSize: theme.fontPixelSize
                              font.family: theme.fontFamily
                          }

                          RowLayout {
                              spacing: theme.spacing
                              Layout.alignment: Qt.AlignRight

                              Button {
                                  padding: 10
                                  focusPolicy: Qt.NoFocus
                                  onClicked: polkitAgent.flow?.cancelAuthenticationRequest()
                                  contentItem: Text {
                                      text: "Cancel"
                                      color: theme.fg
                                      font.pixelSize: theme.fontPixelSize
                                      font.family: theme.fontFamily
                                      horizontalAlignment: Text.AlignHCenter
                                  }
                                  background: Rectangle {
                                      color: parent.hovered ? theme.bgAlt : "transparent"
                                      border.color: theme.darkBlue
                                      border.width: 1
                                      radius: theme.radius - 4
                                  }
                              }

                              Button {
                                  id: authButton
                                  padding: 10
                                  focusPolicy: Qt.NoFocus
                                  enabled: (polkitAgent.flow?.isResponseRequired ?? false) ? passwordField.text.length > 0 : true
                                  onClicked: {
                                      polkitAgent.flow?.submit(passwordField.text)
                                      passwordField.text = ""
                                  }
                                  contentItem: Text {
                                      text: "Authenticate"
                                      color: theme.bg
                                      font.pixelSize: theme.fontPixelSize
                                      font.bold: true
                                      font.family: theme.fontFamily
                                      horizontalAlignment: Text.AlignHCenter
                                  }
                                  background: Rectangle {
                                      color: parent.down ? theme.green : (parent.hovered ? theme.cyan : theme.darkBlue)
                                      radius: theme.radius - 4
                                  }
                              }
                          }
                      }

                      Connections {
                          target: polkitAgent
                          function onIsActiveChanged() {
                              if (polkitAgent.isActive && (polkitAgent.flow?.isResponseRequired ?? false)) {
                                  passwordField.forceActiveFocus()
                              }
                          }
                      }
                  }
              }
          }
      }
  }
''

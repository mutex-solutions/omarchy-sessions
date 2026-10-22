import QtQuick
import qs.Commons

// Sessions page, rendered by Deck and by this plugin's own popup.
//
// One block per monitor: its workspaces, then every visible window on it. Any
// workspace, any window, or the whole session can be moved to another monitor,
// and the two sessions can be swapped. A window move focuses it for a moment
// (Hyprland's move acts on the active window) and then restores focus.
Item {
  id: page

  property var state: null
  property var host: null

  implicitHeight: col.implicitHeight

  readonly property var sessions: state ? state.sessions : []

  function otherFor(name) {
    return state ? state.otherFor(name) : ""
  }

  onStateChanged: if (state) state.refresh()

  component Caps: Text {
    color: Util.alpha(Color.foreground, 0.45)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1.5
  }

  component Rule: Rectangle {
    width: parent ? parent.width : 0
    height: 1
    color: Util.alpha(Color.foreground, 0.1)
  }

  component Head: Item {
    id: head
    property string glyph: ""
    property string title: ""
    property string value: ""
    // Upper-casing is for section labels; a monitor's own name (eDP-1) is not
    // a label and reads wrongly as EDP-1.
    property bool keepCase: false
    property int gap: 0
    width: parent ? parent.width : 0
    height: Style.space(22) + gap

    Item {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: Style.space(22)

      Text {
        id: headGlyph
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(14)
        text: head.glyph
        color: Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }

      Text {
        anchors.left: headGlyph.right
        anchors.leftMargin: Style.space(6)
        anchors.verticalCenter: parent.verticalCenter
        text: head.keepCase ? head.title : head.title.toUpperCase()
        color: Util.alpha(Color.foreground, 0.45)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1.5
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: head.value
        color: Util.alpha(Color.foreground, 0.45)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }
  }

  component Chip: Rectangle {
    id: chip
    property string label: ""
    signal picked()

    width: chipText.implicitWidth + Style.space(16)
    height: Style.space(22)
    radius: Style.cornerRadius
    property bool hovered: false
    color: chip.hovered ? Util.alpha(Color.accent, Style.hoverFillAlpha) : "transparent"
    border.width: 1
    border.color: Util.alpha(Color.foreground, chip.enabled ? Style.normalBorderAlpha : 0.12)

    Text {
      id: chipText
      anchors.centerIn: parent
      text: chip.label
      color: chip.enabled ? Color.foreground : Util.alpha(Color.foreground, 0.35)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: chip.hovered = true
      onExited: chip.hovered = false
      onClicked: chip.picked()
    }
  }

  Column {
    id: col
    width: parent.width
    spacing: Style.space(2)

    // ---- hero ----
    Item {
      width: parent.width
      height: Style.space(44)

      Text {
        id: heroGlyph
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(30)
        text: page.state ? page.state.icon : ""
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.display
        horizontalAlignment: Text.AlignHCenter
      }

      Column {
        anchors.left: heroGlyph.right
        anchors.leftMargin: Style.space(10)
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
          width: parent.width
          // Deck's header already says "Sessions"; the hero says what is in them.
          text: page.state ? page.state.detail : ""
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
        }

        Caps {
          width: parent.width
          text: page.sessions.length + (page.sessions.length === 1 ? " display" : " displays")
        }
      }
    }

    Rule { }

    // ---- swap the two sessions ----
    Item {
      width: parent.width
      height: Style.space(30)
      visible: page.sessions.length > 1

      Text {
        anchors.left: parent.left
        anchors.leftMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        text: "Swap sessions"
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        elide: Text.ElideRight
        width: parent.width - swapChip.width - Style.space(20)
      }

      Chip {
        id: swapChip
        anchors.right: parent.right
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        label: page.sessions.length > 1
          ? "⇄ " + page.sessions[0].name + " ↔ " + page.sessions[1].name
          : ""
        onPicked: {
          if (page.sessions.length > 1)
            page.state.swapSessions(page.sessions[0].name, page.sessions[1].name)
        }
      }
    }

    Rule { visible: page.sessions.length > 1 }

    // ---- one block per monitor ----
    Repeater {
      model: page.sessions

      delegate: Column {
        id: sessionCol
        required property var modelData

        readonly property var session: modelData
        readonly property string other: page.otherFor(modelData.name)

        width: col.width
        spacing: Style.space(2)

        Head {
          glyph: "▭"
          keepCase: true
          title: sessionCol.session.name
          value: sessionCol.session.windows.length
            + (sessionCol.session.windows.length === 1 ? " window" : " windows")
          gap: Style.space(4)
        }

        // every workspace in this session
        Repeater {
          model: sessionCol.session.workspaces

          delegate: Item {
            required property var modelData

            width: sessionCol.width
            height: Style.space(28)

            Text {
              id: wsName
              anchors.left: parent.left
              anchors.leftMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              text: "Workspace " + modelData.id
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              font.bold: modelData.id === sessionCol.session.activeWorkspaceId
            }

            Caps {
              anchors.left: wsName.right
              anchors.leftMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.windows + (modelData.windows === 1 ? " window" : " windows")
            }

            Chip {
              anchors.right: parent.right
              anchors.rightMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              label: "→ " + sessionCol.other
              visible: sessionCol.other !== ""
              onPicked: page.state.moveWorkspace(modelData.id, sessionCol.other)
            }
          }
        }

        // the whole session
        Item {
          width: sessionCol.width
          height: Style.space(30)
          visible: sessionCol.other !== ""

          Text {
            anchors.left: parent.left
            anchors.leftMargin: Style.space(8)
            anchors.right: sessionChip.left
            anchors.rightMargin: Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
            text: "Move session"
            color: Util.alpha(Color.foreground, 0.75)
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            elide: Text.ElideRight
          }

          Chip {
            id: sessionChip
            anchors.right: parent.right
            anchors.rightMargin: Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
            label: "→ " + sessionCol.other
            onPicked: page.state.moveSession(sessionCol.session.name, sessionCol.other)
          }
        }

        // the windows on this monitor
        Head {
          glyph: "▣"
          title: "Windows"
          value: String(sessionCol.session.windows.length)
          gap: Style.space(2)
          visible: sessionCol.session.windows.length > 0
        }

        Repeater {
          model: sessionCol.session.windows

          delegate: Item {
            required property var modelData

            width: sessionCol.width
            // Two lines of text (body + caption) need more than 30 px.
            height: Style.space(38)

            Column {
              anchors.left: parent.left
              anchors.leftMargin: Style.space(8)
              anchors.right: winChip.visible ? winChip.left : parent.right
              anchors.rightMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              spacing: 1

              Text {
                width: parent.width
                text: modelData.title !== "" ? modelData.title : modelData.class
                color: Color.foreground
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                elide: Text.ElideRight
              }

              Caps {
                width: parent.width
                text: modelData.class + " · ws " + modelData.workspaceId
                elide: Text.ElideRight
              }
            }

            Chip {
              id: winChip
              anchors.right: parent.right
              anchors.rightMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              label: "→ " + sessionCol.other
              visible: sessionCol.other !== ""
              onPicked: page.state.moveWindow(modelData.address, sessionCol.other)
            }
          }
        }

        Rule { }
      }
    }

    Caps {
      width: parent.width
      wrapMode: Text.WordWrap
      topPadding: Style.space(3)
      leftPadding: Style.space(8)
      text: page.sessions.length > 1
        ? "Moves go to the other display's active workspace"
        : "Connect a second display to move windows between them"
    }
  }
}

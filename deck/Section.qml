import QtQuick
import Quickshell
import qs.Commons

// Deck adapter. There is no toggle: a tap opens the page, which is what Deck
// does for a section without toggle().
//
// tileFull lists the sessions by monitor. The half tile says how many windows
// there are; the full tile says where they are.
Item {
  id: s

  readonly property var state: stateLoader.item

  // Sessions is not a toggle; keep the tile surface neutral.
  readonly property bool active: false
  readonly property string label: state ? state.label : ""
  readonly property string detail: state ? state.detail : ""
  readonly property string icon: state ? state.icon : ""

  function openPage() {
    Quickshell.execDetached(["omarchy-shell", "mutex-solutions.deck", "openSection", "sessions"])
  }

  readonly property Component tileFull: fullTile

  Component {
    id: fullTile

    Item {
      id: full
      readonly property var st: s.state
      readonly property var groups: st ? st.sessions : []

      MouseArea {
        id: pageArea
        anchors.fill: parent
        property bool held: false
        onPressed: {
          held = false
          pageHold.restart()
        }
        onReleased: {
          pageHold.stop()
          if (!held) s.openPage()
        }
        onCanceled: pageHold.stop()

        // A custom body does not get the host's hold gesture. Match it here:
        // holding opens the page without waiting for release.
        Timer {
          id: pageHold
          interval: 450
          onTriggered: {
            pageArea.held = true
            s.openPage()
          }
        }
      }

      // The glyph sits in the same fixed cell as Deck's default tile body, so
      // the text column lines up with the other tiles whatever the glyph is.
      Item {
        id: glyph
        anchors.left: parent.left
        anchors.leftMargin: Style.space(12)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Style.space(28)

        Text {
          anchors.centerIn: parent
          text: s.icon
          color: s.active ? Color.accent : Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.display
        }
      }

      Column {
        anchors.left: glyph.right
        anchors.leftMargin: Style.space(8)
        anchors.right: parent.right
        anchors.rightMargin: Style.space(12)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(1)

        Text {
          width: parent.width
          text: "Sessions"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          font.bold: true
        }

        Repeater {
          model: full.groups

          delegate: Text {
            required property var modelData
            width: parent.width
            text: String(modelData.name || "") + "   "
              + modelData.windows.length
              + (modelData.windows.length === 1 ? " window" : " windows")
              + "   ws " + modelData.activeWorkspaceId
            color: Util.alpha(Color.foreground, 0.55)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }
        }

        Text {
          visible: full.groups.length === 0
          width: parent.width
          text: "No displays"
          color: Util.alpha(Color.foreground, 0.45)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }
  }

  Loader {
    id: stateLoader
    source: "../State.qml"
  }
}

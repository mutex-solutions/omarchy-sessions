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

  readonly property bool active: state ? state.active : false
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
        anchors.fill: parent
        onClicked: s.openPage()
      }

      Text {
        id: glyph
        anchors.left: parent.left
        anchors.leftMargin: Style.space(14)
        anchors.verticalCenter: parent.verticalCenter
        text: "▤"
        color: Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.display
      }

      Column {
        anchors.left: glyph.right
        anchors.leftMargin: Style.space(11)
        anchors.right: parent.right
        anchors.rightMargin: Style.space(14)
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

import QtQuick

// Deck adapter. There is no toggle: the tile opens the page on a tap, which is
// what Deck does for a section without toggle().
Item {
  id: s

  readonly property var state: stateLoader.item

  readonly property bool active: state ? state.active : false
  readonly property string label: state ? state.label : ""
  readonly property string detail: state ? state.detail : ""
  readonly property string icon: state ? state.icon : ""

  Loader {
    id: stateLoader
    source: "../State.qml"
  }
}

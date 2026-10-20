import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Ui
import qs.Commons

// Standalone bar widget. Click opens the panel; the same page Deck renders is
// shown inside it.
Panel {
  id: root

  moduleName: "mutex-solutions.sessions"
  ipcTarget: "mutex-solutions.sessions"

  readonly property var state: stateLoader.item

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Loader {
    id: stateLoader
    source: "State.qml"
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.state ? root.state.icon : ""
    active: root.state ? root.state.active : false
    onPressed: function(b) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(Math.min(content.implicitHeight, Style.space(540)), Style.space(620))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onActivateRequested: root.close()
    }

    ScrollView {
      id: scroll
      anchors.fill: parent
      clip: true
      ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
      ScrollBar.vertical.policy: ScrollBar.AlwaysOff

      Column {
        id: content
        width: scroll.availableWidth
        spacing: Style.space(10)

        Item {
          width: parent.width
          height: Style.space(24)

          Text {
            id: headerGlyph
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "▤"
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.title
          }

          Text {
            anchors.left: headerGlyph.right
            anchors.leftMargin: Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
            text: "Sessions"
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.state ? root.state.detail : ""
            color: Util.alpha(Color.foreground, 0.45)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Util.alpha(Color.foreground, 0.12)
        }

        Loader {
          id: pageLoader
          width: parent.width
          active: root.opened
          source: "deck/Page.qml"
          onLoaded: if (item) item.state = root.state
        }
      }
    }
  }

  onStateChanged: if (pageLoader.item) pageLoader.item.state = root.state

  onOpenedChanged: {
    if (root.opened && root.state)
      root.state.refresh()
  }
}

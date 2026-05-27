import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    anchors { top: true; left: true }
    implicitWidth: 700; implicitHeight: 650
    color: "transparent"; visible: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-music-standalone"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    Shortcut { sequence: "Escape"; context: Qt.ApplicationShortcut; onActivated: { root.visible = false } }
    Loader { anchors.fill: parent; source: "MusicPopup.qml"; onLoaded: { loader.item.forceActiveFocus() } }
}

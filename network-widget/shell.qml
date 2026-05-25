import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    
    anchors {
        top: true
        right: true
    }
    
    implicitWidth: 900
    implicitHeight: 700
    
    color: "transparent"
    visible: true
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-network-standalone"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    
    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        onActivated: { root.visible = false }
    }
    
    Loader {
        id: loader
        anchors.fill: parent
        source: "NetworkPopup_fixed.qml"
        onLoaded: { loader.item.forceActiveFocus() }
    }
}

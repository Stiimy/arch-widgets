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
    
    implicitWidth: 1450
    implicitHeight: 750
    
    color: "transparent"
    visible: true
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-calendar-standalone"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    
    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        onActivated: { root.visible = false }
    }
    
    Loader {
        id: loader
        anchors.fill: parent
        source: "CalendarPopup_fixed.qml"
        onLoaded: { loader.item.forceActiveFocus() }
    }
}

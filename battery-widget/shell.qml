import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root
    
    anchors {
        top: true
        right: true
    }
    
    implicitWidth: 801
    implicitHeight: 760
    
    color: "transparent"
    visible: true
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-battery-standalone"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    
    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        onActivated: { root.visible = false }
    }
    
    // Trigger first poll immediately
    Component.onCompleted: { dunstPoller.running = true }
    
    // ── Poll dunst history every 2s ──
    property var _liveNotifs: ({})
    ListModel { id: _notifModel }
    
    Process {
        id: dunstPoller
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/battery-widget/dunst_poller.sh"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text.trim())
                    // Diff with current model: add new, remove old
                    let currentIds = {}
                    for (let i = 0; i < _notifModel.count; i++) {
                        currentIds[_notifModel.get(i).uid] = true
                    }
                    
                    // Add new notifications
                    for (let j = 0; j < data.length; j++) {
                        let n = data[j]
                        if (!currentIds[n.uid]) {
                            _notifModel.insert(0, {
                                uid: n.uid,
                                appName: n.appName,
                                summary: n.summary,
                                body: n.body,
                                appIcon: n.appIcon,
                                actionsJson: n.actionsJson,
                                timestamp: new Date(n.timestamp * 1000),
                                hasActions: n.hasActions,
                                notif: null
                            })
                        }
                    }
                    
                    // Remove stale (keep max 50)
                    while (_notifModel.count > 50) {
                        _notifModel.remove(_notifModel.count - 1)
                    }
                } catch(e) {}
            }
        }
    }
    
    // Poll dunst every 2 seconds
    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: { if (!dunstPoller.running) dunstPoller.running = true }
    }
    
    Loader {
        id: loader
        anchors.fill: parent
        source: "BatteryPopup_fixed.qml"
        onLoaded: {
            if (loader.item) {
                loader.item.notifModel = _notifModel
                loader.item.liveNotifs = _liveNotifs
            }
        }
    }
}

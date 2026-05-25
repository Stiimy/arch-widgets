import QtQuick
import QtCore
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

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
    
    // ── Notification Server ──
    NotificationServer {
        id: notifServer
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        
        onNotification: (n) => {
            n.tracked = true
            notifCounter++
            let uid = notifCounter
            _liveNotifs[uid] = n
            
            let actions = []
            if (n.actions) {
                for (let i = 0; i < n.actions.length; i++) {
                    actions.push(JSON.stringify({
                        id: n.actions[i].identifier || "",
                        text: n.actions[i].text || n.actions[i].name || "Action"
                    }))
                }
            }
            
            _notifModel.insert(0, {
                uid: uid, appName: n.appName || "System",
                summary: n.summary || "Notification",
                body: n.body || "", appIcon: n.appIcon || "",
                actionsJson: JSON.stringify(actions),
                timestamp: new Date(), hasActions: actions.length > 0, notif: n
            })
            
            while (_notifModel.count > 50) {
                let last = _notifModel.get(_notifModel.count - 1)
                delete _liveNotifs[last.uid]
                _notifModel.remove(_notifModel.count - 1)
            }
        }
    }
    
    property int notifCounter: 0
    property var _liveNotifs: ({})
    ListModel { id: _notifModel }
    
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

/*
 *  Monitor KWin's "showingDesktop" state via D-Bus.
 */

import QtQuick

Item {
    id: root

    // Whether KWin is currently showing the desktop
    property bool showingDesktop: false

    // Used to namespace the helper process so we can clean it up
    property string instanceId

    DBusSignalMonitor {
        id: monitor
        enabled: true
        busType: "session"
        service: "org.kde.KWin"
        path: "/KWin"
        iface: "org.kde.KWin"
        method: "showingDesktopChanged"
        instanceId: root.instanceId
        onSignalReceived: message => {
            if (message) {
                root.showingDesktop = message.trim() === "true";
            }
        }
    }
}


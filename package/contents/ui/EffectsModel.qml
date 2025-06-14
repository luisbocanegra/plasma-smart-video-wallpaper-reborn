import QtQuick

Item {
    id: root
    property var activeEffects: []
    property var loadedEffects: []
    property var installedEffects: []
    property bool activeEffectsCallRunning: false
    property bool loadedEffectsCallRunning: false
    property bool installedEffectsCallRunning: false
    property bool monitorActive: false
    property bool monitorLoaded: false
    property bool monitorInstalled: false
    property int monitorActiveInterval: 100
    property int monitorLoadedInterval: 1000
    property int monitorInstalledInterval: 1000

    function isEffectActive(effectId) {
        return activeEffects.includes(effectId);
    }

    DBusMethodCall {
        id: dbusKWinActiveEffects
        service: "org.kde.KWin"
        objectPath: "/Effects"
        iface: "org.freedesktop.DBus.Properties"
        method: "Get"
        arguments: ["org.kde.kwin.Effects", "activeEffects"]
    }

    DBusMethodCall {
        id: dbusKWinLoadedEffects
        service: "org.kde.KWin"
        objectPath: "/Effects"
        iface: "org.freedesktop.DBus.Properties"
        method: "Get"
        arguments: ["org.kde.kwin.Effects", "loadedEffects"]
    }

    DBusMethodCall {
        id: dbusKWinInstalledEffects
        service: "org.kde.KWin"
        objectPath: "/Effects"
        iface: "org.freedesktop.DBus.Properties"
        method: "Get"
        arguments: ["org.kde.kwin.Effects", "listOfEffects"]
    }

    function updateActiveEffects() {
        if (!activeEffectsCallRunning) {
            activeEffectsCallRunning = true;
            dbusKWinActiveEffects.call(reply => {
                activeEffectsCallRunning = false;
                if (reply.isValid && reply?.value) {
                    activeEffects = reply.value;
                }
            });
        }
    }

    function updateLoadedEffects() {
        if (!loadedEffectsCallRunning) {
            loadedEffectsCallRunning = true;
            dbusKWinLoadedEffects.call(reply => {
                loadedEffectsCallRunning = false;
                if (reply.isValid && reply?.value) {
                    loadedEffects = reply.value;
                }
            });
        }
    }

    function updateInstalledEffects() {
        if (!installedEffectsCallRunning) {
            installedEffectsCallRunning = true;
            dbusKWinInstalledEffects.call(reply => {
                installedEffectsCallRunning = false;
                if (reply.isValid && reply?.value) {
                    installedEffects = reply.value;
                }
            });
        }
    }

    Timer {
        running: root.monitorInstalled
        repeat: true
        interval: root.monitorInstalledInterval
        onTriggered: {
            root.updateInstalledEffects();
        }
    }

    Timer {
        running: root.monitorLoaded
        repeat: true
        interval: root.monitorLoadedInterval
        onTriggered: {
            root.updateLoadedEffects();
        }
    }

    Timer {
        running: root.monitorActive
        repeat: true
        interval: root.monitorActiveInterval
        onTriggered: {
            root.updateActiveEffects();
        }
    }
}

import QtQuick

Item {
    id: root
    property var activeEffects: []
    property var loadedEffects: []
    property bool activeEffectsCallRunning: false
    property bool loadedEffectsCallRunning: false
    property bool monitorActive: false
    property bool monitorLoaded: false

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

    function updateActiveEffects() {
        if (!activeEffectsCallRunning) {
            activeEffectsCallRunning = true;
            dbusKWinActiveEffects.call(reply => {
                activeEffectsCallRunning = false;
                if (reply?.value) {
                    activeEffects = reply.value;
                }
            });
        }
    }

    function updateLoadedEffects() {
        if (!loadedEffectsCallRunning) {
            loadedEffectsCallRunning = true;
            dbusKWinActiveEffects.call(reply => {
                loadedEffectsCallRunning = false;
                if (reply?.value) {
                    loadedEffects = reply.value;
                }
            });
        }
    }

    Timer {
        running: root.monitorLoaded
        repeat: true
        interval: 1000
        onTriggered: {
            root.updateLoadedEffects();
        }
    }

    Timer {
        running: root.monitorActive
        repeat: true
        interval: 100
        onTriggered: {
            root.updateActiveEffects();
        }
    }
}

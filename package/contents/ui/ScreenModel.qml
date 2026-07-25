/*
 *  Copyright 2024 Luis Bocanegra <luisbocanegra17b@gmail.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */

import QtQuick

Item {
    id: root
    property bool screenIsLocked: false
    property bool checkScreenLock: false
    property bool screenIsOff: false
    property string screenStateCmd
    property bool screenStateCmdRunning: false
    property bool checkScreenState: false
    property string instanceId
    // This screen's geometry, used to pick the matching output when the
    // native DPMS monitor is available. See main.qml's `screenGeometry:
    // main.parent?.screenGeometry ?? null` for the same pattern.
    property var screenGeometry: null

    property QtObject nativeDpms: null
    // False on X11, non-KWin compositors, or when the native plugin isn't
    // installed (e.g. installed from the KDE Store, which can only ship
    // plain QML) - runScreenStateCmd()/screenTimer below cover those cases.
    readonly property bool nativeDpmsAvailable: root.nativeDpms?.available ?? false

    RunCommand {
        id: runCommand
    }

    DBusSignalMonitor {
        enabled: root.checkScreenLock
        service: "org.freedesktop.ScreenSaver"
        path: "/ScreenSaver"
        method: "ActiveChanged"
        onSignalReceived: message => {
            if (message) {
                root.screenIsLocked = message.trim() === "true";
            }
        }
        instanceId: root.instanceId
    }

    // Event-driven DPMS detection via the KWin/Wayland org_kde_kwin_dpms
    // protocol (see package/contents/ui/dpms) - pushed by the compositor
    // instantly instead of polled. Loaded dynamically because the module is
    // an optional native plugin that may not be installed; a failed import
    // throws a catchable JS exception instead of a fatal QML load error.
    function tryInitNativeDpms() {
        if (root.nativeDpms) {
            return;
        }
        try {
            const obj = Qt.createQmlObject('import org.kde.smartvideowallpaper.dpms 1.0; DpmsMonitor {}', root, "nativeDpmsMonitor");
            obj.screenGeometry = Qt.binding(() => root.screenGeometry ?? Qt.rect(0, 0, 0, 0));
            root.nativeDpms = obj;
        } catch (e) {
            root.nativeDpms = null;
        }
    }

    Connections {
        target: root.nativeDpms
        function onScreenIsOffChanged() {
            if (root.nativeDpms.available) {
                root.screenIsOff = root.nativeDpms.screenIsOff;
            }
        }
        function onAvailableChanged() {
            if (root.nativeDpms.available) {
                root.screenIsOff = root.nativeDpms.screenIsOff;
            }
        }
    }

    onCheckScreenStateChanged: {
        if (checkScreenState) {
            tryInitNativeDpms();
        }
    }

    Component.onCompleted: {
        if (root.checkScreenState) {
            tryInitNativeDpms();
        }
    }

    function runScreenStateCmd() {
        if (!root.checkScreenState || root.screenStateCmdRunning || root.nativeDpmsAvailable)
            return;
        root.screenStateCmdRunning = true;
        runCommand.exec(root.screenStateCmd, output => {
            root.screenStateCmdRunning = false;
            if (output.exitCode === 0 && output.stdout.length > 0) {
                const out = output.stdout.trim().toLowerCase();
                root.screenIsOff = out === "0" || out === "off";
            }
        });
    }

    // Fallback for when the native monitor isn't available.
    Timer {
        id: screenTimer
        running: root.checkScreenState && !root.nativeDpmsAvailable
        repeat: true
        interval: 1000
        onTriggered: root.runScreenStateCmd()
    }
}

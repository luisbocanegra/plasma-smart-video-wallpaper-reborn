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

    Timer {
        id: screenTimer
        running: root.checkScreenState
        repeat: true
        interval: 1000
        onTriggered: {
            if (root.checkScreenState && !root.screenStateCmdRunning) {
                root.screenStateCmdRunning = true;
                // ensure each command is unique to avoid race condition where the
                // same command runs twice but the first run fails deleting the callback
                // that was going to be used by the second one
                runCommand.exec(root.screenStateCmd + `;t=${Date.now()}`, output => {
                    root.screenStateCmdRunning = false;
                    if (output.exitCode === 0 && output.stdout.length > 0) {
                        const out = output.stdout.trim().toLowerCase();
                        root.screenIsOff = out === "0" || out === "off";
                    }
                });
            }
        }
    }
}

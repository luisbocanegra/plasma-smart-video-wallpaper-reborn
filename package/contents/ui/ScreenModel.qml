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
import org.kde.plasma.plasma5support as P5Support

Item {
    id: root
    property bool screenIsLocked: false
    property bool checkScreenLock: false
    property bool screenIsOff: false
    property string screenStateCmd
    property bool screenStateCmdRunning: false
    property bool checkScreenState: false

    RunCommand {
        id: runCommand
        onExited: (cmd, exitCode, exitStatus, stdout, stderr) => {
            if (cmd === root.screenStateCmd)
                root.screenStateCmdRunning = false;
            if (exitCode !== 0)
                return;
            if (cmd === root.screenStateCmd) {
                if (stdout.length > 0) {
                    stdout = stdout.trim().toLowerCase();
                    root.screenIsOff = stdout === "0" || stdout.includes("off");
                }
            }
        }
    }

    function dumpProps(obj) {
        console.error("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
        for (var k of Object.keys(obj)) {
            print(k + "=" + obj[k] + "\n");
        }
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
    }

    Timer {
        id: screenTimer
        running: root.checkScreenState
        repeat: true
        interval: 200
        onTriggered: {
            if (root.checkScreenState && !root.screenStateCmdRunning) {
                root.screenStateCmdRunning = true;
                runCommand.run(root.screenStateCmd);
            }
        }
    }
}

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
    id: screenModel
    property bool screenIsLocked: false
    property string qdbusExecName: wallpaper.configuration.QdbusExecName
    property string getScreenLockCmd: qdbusExecName + " org.kde.screensaver /ScreenSaver org.freedesktop.ScreenSaver.GetActive"
    property bool checkScreenLock: false

    P5Support.DataSource {
        id: runCommand
        engine: "executable"
        connectedSources: []

        onNewData: function (source, data) {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(source, exitCode, exitStatus, stdout, stderr)
            disconnectSource(source) // cmd finished
        }

        function exec(cmd) {
            runCommand.connectSource(cmd)
        }

        signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
    }

    Connections {
        target: runCommand
        function onExited(cmd, exitCode, exitStatus, stdout, stderr) {
            if (exitCode!==0) return
            if(cmd === getScreenLockCmd) {
                if (stdout.length > 0) {
                    screenIsLocked = stdout.trim() === "true"
                    // console.log("SCREEN LOCKED:", screenIsLocked, getScreenLockCmd);
                }
            }
        }
    }

    Timer {
        id: debugTimer
        running: checkScreenLock
        repeat: true
        interval: 200
        onTriggered: {
            runCommand.exec(getScreenLockCmd)
        }
    }
}

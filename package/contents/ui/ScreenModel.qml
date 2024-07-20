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
    // sed -e "s|^(\(.*\),)$|\1|;s|^<\(.*\)>$|\1|;s|'|\"|g"
    property string sed: "sed -e \"s|^(\\(.*\\),)$|\\1|;s|^<\\(.*\\)>$|\\1|;s|'|\\\"|g\""
    property string getScreenLockCmd: "gdbus call --session --dest org.kde.screensaver --object-path /ScreenSaver --method org.freedesktop.ScreenSaver.GetActive | " + sed
    property bool getScreenLockCmdRunning: false
    property bool checkScreenLock: false

    property bool screenIsOff: false
    property string screenStateCmd: main.configuration.ScreenStateCmd
    property bool screenStateCmdRunning: false
    property bool checkScreenState: false

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
            sourceConnected(source)
        }

        function exec(cmd) {
            if (cmd === getScreenLockCmd) getScreenLockCmdRunning = true
            if (cmd === screenStateCmd) screenStateCmdRunning = true
            runCommand.connectSource(cmd)
        }

        signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
    }

    function dumpProps(obj) {
        console.error("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
        for (var k of Object.keys(obj)) {
            print(k + "=" + obj[k]+"\n")
        }
    }


    Connections {
        target: runCommand
        function onExited(cmd, exitCode, exitStatus, stdout, stderr) {
            if (cmd === getScreenLockCmd) getScreenLockCmdRunning = false
            if (cmd === screenStateCmd) screenStateCmdRunning = false
            if (exitCode!==0) return
            if(cmd === getScreenLockCmd) {
                if (stdout.length > 0) {
                    screenIsLocked = stdout.trim() === "true"
                    // console.log("SCREEN LOCKED:", screenIsLocked, getScreenLockCmd);
                }
            }
            if(cmd === screenStateCmd) {
                if (stdout.length > 0) {
                    stdout = stdout.trim().toLowerCase()
                    screenIsOff = stdout === "0" || stdout.includes("off")
                    // console.log("SCREEN OFF:", screenIsOff, screenStateCmd);
                }
            }
        }
    }

    Timer {
        id: screenTimer
        running: checkScreenState || checkScreenLock
        repeat: true
        interval: 200
        onTriggered: {
            if (checkScreenLock) {
                if (!getScreenLockCmdRunning) runCommand.exec(getScreenLockCmd)
            }
            if (checkScreenState) {
                if (!screenStateCmdRunning) runCommand.exec(screenStateCmd)
            }
        }
    }
}

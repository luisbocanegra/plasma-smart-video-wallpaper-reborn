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

    id: effectsModel
    property var activeEffects: []
    property var loadedEffects: []
    property string qdbusExecName: main.configuration.QdbusExecName
    property string activeEffectsCmd: qdbusExecName + " org.kde.KWin.Effect.WindowView1 /Effects org.kde.kwin.Effects.activeEffects"
    property bool activeEffectsCmdRunning: false
    property string loadedEffectsCmd: qdbusExecName + " org.kde.KWin.Effect.WindowView1 /Effects org.kde.kwin.Effects.loadedEffects"
    property bool loadedEffectsCmdRunning: false
    property bool active: false

    function isEffectActive(effectId) {
        return activeEffects.includes(effectId)
    }

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
            if (cmd === activeEffectsCmd) activeEffectsCmdRunning = true
            runCommand.connectSource(cmd)
        }

        signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
    }

    Connections {
        target: runCommand
        function onExited(cmd, exitCode, exitStatus, stdout, stderr) {
            if(cmd === activeEffectsCmd) {
                activeEffectsCmdRunning = false
                if (exitCode !== 0 ) return
                if (stdout.length > 0) {
                    activeEffects = stdout.trim().split("\n")
                    // console.log("ACTIVE EFFECTS:", activeEffects);
                }
            }
            if(cmd === loadedEffectsCmd) {
                loadedEffectsCmdRunning = false
                if (exitCode !== 0 ) return
                if (stdout.length > 0) {
                    loadedEffects = stdout.trim().split("\n")
                    // console.log("LOADED EFFECTS:", loadedEffects);
                }
            }
        }
    }

    function updateActiveEffects() {
        if (!activeEffectsCmdRunning) runCommand.exec(activeEffectsCmd)
    }

    Timer {
        running: active
        repeat: true
        interval: 100
        onTriggered: {
            updateActiveEffects()
        }
    }
}


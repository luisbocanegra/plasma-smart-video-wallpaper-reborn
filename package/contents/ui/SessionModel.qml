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
import org.kde.plasma.workspace.dbus as DBus

Item {
    id: root
    property bool sessionIsActive: true
    property bool checkSessionActivity: false
    property string sessionPath: ""
    property bool debugEnabled: false

    Component.onCompleted: {
        if (checkSessionActivity) {
            getSessionPath();
        }
    }

    onCheckSessionActivityChanged: {
        if (checkSessionActivity && sessionPath === "") {
            getSessionPath();
        }
    }

    function getSessionPath() {
        runCommand.run("loginctl show-user $USER -p Display --value");
    }

    RunCommand {
        id: runCommand
        onExited: (cmd, exitCode, exitStatus, stdout, stderr) => {
            if (exitCode !== 0) {
                if (debugEnabled) {
                    console.error("SessionModel: Failed to get session:", stderr);
                }
                return;
            }
            const sessionId = stdout.trim();
            if (sessionId) {
                root.sessionPath = "/org/freedesktop/login1/session/" + sessionId;
                getSessionActiveProperty();
            } else if (debugEnabled) {
                console.error("SessionModel: No session ID found");
            }
        }
    }

    function getSessionActiveProperty() {
        if (sessionPath === "") return;

        const getPropertyMsg = {
            "service": "org.freedesktop.login1",
            "path": root.sessionPath,
            "iface": "org.freedesktop.DBus.Properties",
            "member": "Get",
            "arguments": ["org.freedesktop.login1.Session", "Active"],
            "signature": null,
            "inSignature": "ss"
        };

        const reply = DBus.SystemBus.asyncCall(getPropertyMsg);
        reply.finished.connect(() => {
            if (reply.value !== undefined && reply.value !== null) {
                root.sessionIsActive = reply.value;
            } else if (debugEnabled) {
                console.error("SessionModel: Failed to get Active property");
            }
            reply.destroy();
        });
    }

    function refresh() {
        if (checkSessionActivity && sessionPath !== "") {
            getSessionActiveProperty();
        }
    }

    // Poll session state periodically (similar to ScreenModel.qml polling for screen state)
    Timer {
        id: sessionTimer
        running: root.checkSessionActivity && root.sessionPath !== ""
        repeat: true
        interval: 1000
        onTriggered: {
            root.getSessionActiveProperty();
        }
    }
}

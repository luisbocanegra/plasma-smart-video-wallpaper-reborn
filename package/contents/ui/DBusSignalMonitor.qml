pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable

import QtQuick
import "code/utils.js" as Utils

Item {
    id: root
    property bool enabled: false
    property string busType: "session"
    property string service: ""
    property string path: ""
    property string iface: service
    property string method: ""
    property string instanceId

    readonly property string toolsDir: Qt.resolvedUrl("./tools").toString().substring(7) + "/"
    readonly property string dbusMessageTool: toolsDir + "gdbus_get_signal.sh"
    readonly property string monitorCmd: `"${dbusMessageTool}" ${busType} ${service} ${iface} ${path} ${method} id=${instanceId}`

    signal signalReceived(message: string)

    function getMessage(rawOutput) {
        let [path, interfaceAndMember, ...message] = rawOutput.split(" ");

        return message.join(" ").replace(/^\([']?/, "") // starting ( or ('
        .replace(/[']?,\)$/, ""); // ending ,) or ',)
    }

    RunCommand {
        id: runCommand
        onExited: (cmd, exitCode, exitStatus, stdout, stderr) => {
            if (exitCode !== 130) {
                console.error(cmd, exitCode, exitStatus, stdout, stderr);
                return;
            }
            root.signalReceived(root.getMessage(stdout.trim()));
            // for some reason it won't restart without a delay???
            Utils.delay(50, () => {
                runCommand.exec(root.monitorCmd);
            }, root);
        }
    }

    function cleanup() {
        if (instanceId) {
            runCommand.exec(`ps -axo pid,cmd | grep '${root.monitorCmd.replace(/"/g, '')}$' | grep -v grep | awk '{print $1}' | xargs kill`);
        }
    }

    function toggleMonitor() {
        if (enabled) {
            runCommand.exec(root.monitorCmd);
        } else {
            cleanup();
        }
    }

    Component.onCompleted: {
        Utils.delay(100, () => {
            runCommand.exec(root.monitorCmd);
        }, root);
    }

    Component.onDestruction: cleanup()
    Connections {
        target: Qt.application
        function onAboutToQuit() {
            root.cleanup();
        }
    }
}

import QtQuick
import org.kde.plasma.plasma5support as P5Support
import QtQml

P5Support.DataSource {
    id: dataSource

    property string output: ""
    property var callbacks: ({})

    function exec(cmd, callback) {
        // ensure each command is unique to avoid race condition where the
        // same command runs twice but the first run fails deleting the callback
        // that was going to be used by the second one
        cmd = cmd + ";t=$(date +%N)";
        // console.log("running", cmd, "callback", callback);
        if (callback && typeof callback === "function") {
            callbacks[cmd] = callback;
        }
        dataSource.connectSource(cmd);
    }

    function exit(cmd) {
        dataSource.disconnectSource(cmd);
    }

    signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)

    onExited: (cmd, exitCode, exitStatus, stdout, stderr) => {
        if (cmd in callbacks) {
            if (typeof callbacks[cmd] === "function") {
                callbacks[cmd]({
                    cmd,
                    exitCode,
                    exitStatus,
                    stdout,
                    stderr
                });
            }
            delete callbacks[cmd];
        }
    }

    engine: "executable"
    connectedSources: []
    onNewData: function (source, data) {
        var exitCode = data["exit code"];
        var exitStatus = data["exit status"];
        var stdout = data["stdout"];
        var stderr = data["stderr"];
        exited(source, exitCode, exitStatus, stdout, stderr);
        disconnectSource(source);
    }
}

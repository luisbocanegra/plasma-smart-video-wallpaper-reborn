import QtQuick

Item {
    id: root
    property string metaDataFile: Qt.resolvedUrl("../../").toString().substring(7) + "metadata.json"
    property var metaData: ({})

    property string name: metaData.Name ?? ""
    property string description: metaData.Description ?? ""
    property string version: metaData.Version ?? ""
    property string bugReportUrl: metaData.BugReportUrl ?? ""
    property string icon: metaData.Icon ?? ""

    signal ready

    Component.onCompleted: {
        runCommand.exec(`cat "${root.metaDataFile}"`, output => {
            if (output.exitCode === 0) {
                try {
                    const metadata = JSON.parse(output.stdout);
                    metaData = metadata.KPlugin;
                } catch (e) {
                    console.error(e, e.stack);
                }
                ready();
            }
        });
    }

    RunCommand {
        id: runCommand
    }
}

import QtQuick

// import "code/utils.js" as Utils

Item {
    id: root
    property ListModel model: ListModel {}
    property bool isLoading: true
    readonly property string plasmaEnvFile: "$HOME/.config/plasma-workspace/env/luisbocanegra.smart.video.wallpaper.reborn.sh"

    signal updated
    signal loaded

    function initModel(envVars) {
        model.clear();
        let varList = envVars.split("\n");
        for (let envVar of varList) {
            let [name, value] = envVar.split("=");
            const existsIndex = getIndex(name);
            if (existsIndex !== -1) {
                model.set(existsIndex, {
                    name,
                    value
                });
                continue;
            }
            model.append({
                name,
                value
            });
        }
        root.isLoading = false;
        loaded();
    }

    function getValue(name) {
        for (let i = 0; i < model.count; i++) {
            const item = model.get(i);
            if (item.name === name) {
                return item.value;
            }
        }
        return "";
    }

    function getIndex(name) {
        for (let i = 0; i < model.count; i++) {
            const item = model.get(i);
            if (item.name === name) {
                return i;
            }
        }
        return -1;
    }

    function getPlasmaEnvVar(name, c) {
        runCommand.exec(`grep 'export ${name}' "${plasmaEnvFile}" | sed 's/export ${name}=//'`, output => {
            if (c) {
                if (output.exitCode === 0 && output.stdout.length > 0) {
                    return c(output.stdout.trim());
                }
                return c(null);
            }
        });
    }

    function setPlasmaEnvVar(name, value) {
        // check if it exists
        //   if it does replace
        //   if it does not, append
        runCommand.exec(`grep 'export ${name}' "${plasmaEnvFile}"`, output => {
            if (output.exitCode === 0 && output.stdout.length > 0) {
                console.log(`${name}`, output.stdout);
                console.log(`sed -i 's/export ${name}=.*/export ${name}=${value}/g' "${plasmaEnvFile}"`);
                runCommand.exec(`sed -i 's/export ${name}=.*/export ${name}=${value}/g' "${plasmaEnvFile}"`);
            } else {
                runCommand.exec(`touch "${plasmaEnvFile}" && echo "export ${name}=${value}" >> "${plasmaEnvFile}"`);
            }
        });
    }

    function removePlasmaEnvVar(name) {
        console.log(`sed -i '/export ${name}=.*/d' "${plasmaEnvFile}"`);
        runCommand.exec(`sed -i '/export ${name}=.*/d' "${plasmaEnvFile}"`);
    }

    function varExists(name) {
        return getValue(name) !== "";
    }

    RunCommand {
        id: runCommand
    }

    function getVars() {
        let vars;
        runCommand.exec(`printenv`, output => {
            if (output.exitCode === 0 && output.stdout.length > 0) {
                initModel(output.stdout.trim());
            }
        });
    }

    Component.onCompleted: {
        getVars();
    }
}

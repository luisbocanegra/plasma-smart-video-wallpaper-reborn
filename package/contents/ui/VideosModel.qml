pragma ComponentBehavior: Bound
import QtQuick
import "code/utils.js" as Utils

Item {
    id: root
    property ListModel model: ListModel {}
    property bool isLoading: true

    signal updated

    function initModel(configString) {
        model.clear();
        let videos = Utils.parseCompat(configString);

        for (let video of videos) {
            model.append(video);
        }
        root.isLoading = false;
    }

    function addItem(file) {
        model.append({
            "filename": file ?? "",
            "enabled": true,
            "duration": 0,
            "customDuration": 0,
            "playbackRate": 0.0,
            "loop": false
        });
        updated();
    }

    function clear() {
        model.clear();
        updated();
    }

    function removeItem(index) {
        model.remove(index, 1);
        updated();
    }

    function updateItem(index, actionType, value) {
        model.setProperty(index, actionType, value);
        updated();
    }

    function moveItem(oldIndex, newIndex) {
        model.move(oldIndex, newIndex, 1);
        updated();
    }

    function fileExists(filename) {
        let exists = false;

        for (let i = 0; i < model.count; i++) {
            const item = model.get(i);
            if (item.filename === filename) {
                return true;
            }
        }
        return false;
    }

    function disableAll() {
        for (let i = 0; i < model.count; i++) {
            const item = model.get(i);
            item.enabled = false;
        }
        updated();
    }

    function enableAll() {
        for (let i = 0; i < model.count; i++) {
            const item = model.get(i);
            item.enabled = true;
        }
        updated();
    }

    function toggleAll() {
        for (let i = 0; i < model.count; i++) {
            const item = model.get(i);
            item.enabled = !item.enabled;
        }
        updated();
    }

    function disableAllOthers(index) {
        for (let i = 0; i < model.count; i++) {
            const item = model.get(i);
            if (i === index) {
                item.enabled = true;
            } else {
                item.enabled = false;
            }
        }
        updated();
    }
}

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
            "alternativePlaybackRate": 0.0,
            "loop": false,
            "videoWidth": 0,
            "videoHeight": 0,
            "videoCodec": "",
            "videoBitRate": 0,
            "videoFrameRate": 0.0,
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

    function resolutionLabel(item) {
        if (item.videoWidth === 0 || item.videoHeight === 0) {
            return "";
        }

        // Format resolution as a nice label
        let resolutionLabel = "";
        const height = item.videoHeight;

        // Common resolution names
        if (height >= 2160) {
            resolutionLabel = "4K";
        } else if (height >= 1440) {
            resolutionLabel = "2K";
        } else if (height >= 1080) {
            resolutionLabel = "1080p";
        } else if (height >= 720) {
            resolutionLabel = "720p";
        } else if (height >= 480) {
            resolutionLabel = "480p";
        } else {
            resolutionLabel = "Low";
        }

        return resolutionLabel;
    }

    function aspectRatioLabel(item) {
        if (item.videoWidth === 0 || item.videoHeight === 0) {
            return "";
        }

        let aspectRatioLabel = ""
        const ratio = 1.0 * item.videoWidth / item.videoHeight;
        if ((ratio > 1.13) && (ratio < 1.50)) {
            aspectRatioLabel = "4:3";
        } else if (ratio < 2.00) {
            aspectRatioLabel = "16:9";
        }
        else if (ratio < 2.68) {
            aspectRatioLabel = "21:9";
        }
        else if ((ratio > 3.02) && (ratio < 4.09)) {
            aspectRatioLabel = "32:9";
        } else {
            aspectRatioLabel = ratio.toFixed(2);
        }
        return aspectRatioLabel;
    }
}

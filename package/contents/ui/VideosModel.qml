pragma ComponentBehavior: Bound
import QtQuick
import QtMultimedia
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
            "isHdr": false,
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
        if (height >= 4320) {
            resolutionLabel = "8K";
        } else if (height >= 3160) {
            resolutionLabel = "6K";
        } else if (height >= 2160) {
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

        let aspectRatioLabel = "";
        const ratio = 1.0 * item.videoWidth / item.videoHeight;
        // Anything that is roughly +/-15% counts.
        if (item.videoHeight > item.videoWidth) {
            // Provide a tall numberic ratio.
            const tall_ratio = 1.0 * item.videoHeight / item.videoWidth;
            aspectRatioLabel = "1:" + tall_ratio.toFixed(2);
        } else if (item.videoWidth === item.videoHeight) {
            // Edge case of equal sides.
            aspectRatioLabel = "1:1";
        } else if ((ratio > 1.13) && (ratio < 1.52)) {
            // Officially 1.33, but we allow anything +/-15% or
            // between 1.133333 and 1.533333, except see below.
            aspectRatioLabel = "4:3";
        } else if (ratio < 2.00) {
            // Officially 1.78, but we allow anything +/-15% or
            // between 1.5111111 and 2.044444, except see above and below.
            aspectRatioLabel = "16:9";
        }
        else if (ratio < 2.68) {
            // Actual is 2.33, but we allow anything +/-15% or
            // between 1.9833333 and 2.6833333, except see above.
            aspectRatioLabel = "21:9";
        }
        else if ((ratio > 3.02) && (ratio < 4.09)) {
            // Actual is 3.55555, between 3.022222 and 4.088888 counts.
            aspectRatioLabel = "32:9";
        } else {
            // Provide a wide numeric ratio.
            aspectRatioLabel = ratio.toFixed(2) + ":1";
        }
        return aspectRatioLabel;
    }

    function videoCodecLabel(item) {
        // videoCodec is stored as a string, just return it directly
        // or format it if needed
        return item.videoCodec || "UNK";
    }

    /**
     * Generates the HDR badge SVG with appropriate color based on enabled state
     * @param {Object} itemDelegate - The item delegate containing video properties
     * @returns {String} Base64-encoded SVG string for the badge
     */
    function getHdrBadge(itemDelegate) {
        const bgColor = itemDelegate.enabled ? "#FF6B00" : "#8A5C3D";
        return "data:image/svg+xml;base64," + Qt.btoa(Utils.generateBadge("HDR", bgColor));
    }

    /**
     * Generates the codec badge SVG with appropriate color based on enabled state
     * @param {Object} itemDelegate - The item delegate containing video properties
     * @returns {String} Base64-encoded SVG string for the badge
     */
    function getCodecBadge(itemDelegate) {
        const codecLabel = this.videoCodecLabel(itemDelegate);
        if (codecLabel === "" || codecLabel === "Unspecified") {
            return "";
        }
        const bgColor = itemDelegate.enabled ? "#4285F4" : "#6B7BB9";
        return "data:image/svg+xml;base64," + Qt.btoa(Utils.generateBadge(codecLabel, bgColor));
    }

    /**
     * Generates the resolution badge SVG with appropriate color based on enabled state
     * @param {Object} itemDelegate - The item delegate containing video properties
     * @returns {String} Base64-encoded SVG string for the badge
     */
    function getResolutionBadge(itemDelegate) {
        const resolutionLabel = this.resolutionLabel(itemDelegate);
        if (resolutionLabel === "") {
            return "";
        }
        const bgColor = itemDelegate.enabled ? "#34A853" : "#5B7C6D";
        return "data:image/svg+xml;base64," + Qt.btoa(Utils.generateBadge(resolutionLabel, bgColor));
    }

    /**
     * Generates the aspect ratio badge SVG with appropriate color based on enabled state
     * @param {Object} itemDelegate - The item delegate containing video properties
     * @returns {String} Base64-encoded SVG string for the badge
     */
    function getAspectBadge(itemDelegate) {
        const aspectRatioLabel = this.aspectRatioLabel(itemDelegate);
        if (aspectRatioLabel === "") {
            return "";
        }
        const bgColor = itemDelegate.enabled ? "#EA4335" : "#7C5A56";
        return "data:image/svg+xml;base64," + Qt.btoa(Utils.generateBadge(aspectRatioLabel, bgColor));
    }
}

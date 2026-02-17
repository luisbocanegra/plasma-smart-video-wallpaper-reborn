import QtQuick
import QtMultimedia
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property real volume: 1.0
    property int actualDuration: player.duration / playbackRate
    property int fillBlurRadius: 32
    property bool fillBlur: true
    property alias source: player.source
    property alias muted: audioOutput.muted
    property real playbackRate
    property alias fillMode: videoOutput.fillMode
    property alias loops: player.loops
    property alias position: player.position
    readonly property alias mediaStatus: player.mediaStatus
    readonly property alias playing: player.playing
    readonly property alias seekable: player.seekable
    readonly property alias duration: player.duration
    readonly property alias videoHeight: videoOutput.contentRect.height
    readonly property alias videoWidth: videoOutput.contentRect.width
    readonly property bool showFillBlur: root.fillBlur && root.fitScale !== 1
    property real fitScale: {
        if (height > videoHeight) {
            return height / videoHeight;
        }

        if (width > videoWidth) {
            return width / videoWidth;
        }
        return 1;
    }

    function play() {
        player.play();
    }
    function pause() {
        player.pause();
    }
    function stop() {
        player.stop();
    }

    VideoOutput {
        id: videoOutput
        fillMode: VideoOutput.PreserveAspectCrop
        anchors.fill: parent
    }

    property string audioOutputDevice: "default"

    function updateAudioDevice() {
        if (root.audioOutputDevice === "default" || root.audioOutputDevice === "") {
             if (audioOutput.device !== mediaDevices.defaultAudioOutput) {
                 audioOutput.device = mediaDevices.defaultAudioOutput
                 console.log("SmartVideoWallpaper: Switched to default audio device: " + mediaDevices.defaultAudioOutput.description)
             }
             return;
        }

        let found = false
        for (var i = 0; i < mediaDevices.audioOutputs.length; i++) {
             if (mediaDevices.audioOutputs[i].description === root.audioOutputDevice) {
                 audioOutput.device = mediaDevices.audioOutputs[i]
                 console.log("SmartVideoWallpaper: Switched to selected audio device: " + root.audioOutputDevice)
                 found = true
                 break
             }
        }
        if (!found) {
             console.log("SmartVideoWallpaper: Requested device '" + root.audioOutputDevice + "' not found, using default")
             audioOutput.device = mediaDevices.defaultAudioOutput
        }
    }

    onAudioOutputDeviceChanged: updateAudioDevice()

    MediaDevices {
        id: mediaDevices
        onAudioOutputsChanged: updateAudioDevice()
        onDefaultAudioOutputChanged: updateAudioDevice()
    }

    Component.onCompleted: {
        console.log("SmartVideoWallpaper: Available audio outputs:")
        for (var i = 0; i < mediaDevices.audioOutputs.length; i++) {
             console.log(" - " + mediaDevices.audioOutputs[i].description + " (id: " + mediaDevices.audioOutputs[i].id + ")")
        }
        updateAudioDevice()
    }

    AudioOutput {
        id: audioOutput
        volume: root.opacity * root.volume
        onDeviceChanged: {
             console.log("SmartVideoWallpaper: AudioOutput device is now: " + device.description)
        }
    }

    MediaPlayer {
        id: player
        videoOutput: videoOutput
        audioOutput: audioOutput
        loops: root.loops
        // Ignore very small values as it makes the video go crazy fast, stops
        // responding to this property and needs to be stopped to recover
        // TODO: Check if this has been reported to Qt
        playbackRate: Math.max(root.playbackRate, 0.01)
    }

    property string currentAudioDevice: audioOutput.device ? audioOutput.device.description : "Unknown"

    ShaderEffectSource {
        id: videoBlur
        width: parent.width * root.fitScale + (root.fillBlurRadius * 2)
        height: parent.height * root.fitScale + (root.fillBlurRadius * 2)
        sourceItem: root.showFillBlur ? videoOutput : null
        live: true
        anchors.centerIn: parent
        clip: true
        visible: false
    }

    FastBlur {
        id: fillBlur
        source: videoBlur
        radius: root.fillBlurRadius
        visible: root.showFillBlur && videoBlur.sourceItem
        anchors.fill: videoBlur
        anchors.centerIn: parent
        z: -1
    }
}

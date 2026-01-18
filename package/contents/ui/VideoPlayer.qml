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

    AudioOutput {
        id: audioOutput
        volume: root.opacity * root.volume
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

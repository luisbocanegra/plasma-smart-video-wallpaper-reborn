import QtQuick
import QtMultimedia

Item {
    id: root
    property real volume: 1.0
    property int actualDuration: player.duration / playbackRate
    property alias source: player.source
    property alias muted: audioOutput.muted
    property alias playbackRate: player.playbackRate
    property alias fillMode: videoOutput.fillMode
    property alias loops: player.loops
    property alias position: player.position
    readonly property alias mediaStatus: player.mediaStatus
    readonly property alias playing: player.playing
    readonly property alias seekable: player.seekable
    readonly property alias duration: player.duration

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
    }
}

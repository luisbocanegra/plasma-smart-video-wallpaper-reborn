import QtQuick
import QtMultimedia

Item {
    id: root
    property url source
    property real volume: 1.0
    property bool muted: true
    property int playbackRate: 1
    property int fillMode: VideoOutput.PreserveAspectCrop
    property int loops: MediaPlayer.Infinite
    property int position: 0
    property int actualDuration: player.duration / playbackRate
    property int playerId: 0

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
        fillMode: root.fillMode
        anchors.fill: parent
    }

    AudioOutput {
        id: audioOutput
        muted: root.muted
        volume: root.opacity * root.volume
    }

    MediaPlayer {
        id: player
        source: root.source
        videoOutput: videoOutput
        audioOutput: audioOutput
        playbackRate: root.playbackRate
        loops: root.loops
        onPositionChanged: position => {
            root.position = position;
        }
    }
}

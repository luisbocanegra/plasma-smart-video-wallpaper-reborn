import QtQuick
import QtMultimedia

Item {
    id: root
    property real volume: 1.0
    property string source: ""
    property int position: playerLoader.item ? playerLoader.item.position : 0
    property bool muted: false
    property real playbackRate: 1.0
    property int fillMode: VideoOutput.PreserveAspectCrop
    property int loops: MediaPlayer.Infinite

    property int mediaStatus: MediaPlayer.NoMedia
    readonly property bool playing: playerLoader.item ? playerLoader.item.playing : false
    readonly property bool seekable: playerLoader.item ? playerLoader.item.seekable : true
    readonly property int duration: playerLoader.item ? playerLoader.item.duration : 0
    property bool useMpvQt: false

    function play() {
        if (playerLoader.item)
            playerLoader.item.play();
    }
    function pause() {
        if (playerLoader.item)
            playerLoader.item.pause();
    }
    function stop() {
        if (playerLoader.item)
            playerLoader.item.stop();
    }

    function setPosition(newPosition) {
        if (playerLoader.item) {
            playerLoader.item.position = newPosition;
        }
    }

    Loader {
        id: playerLoader
        source: root.useMpvQt ? "VideoPlayerMpvQt.qml" : "VideoPlayerQt.qml"
        anchors.fill: parent
        onLoaded: {
            if (playerLoader.item) {
                playerLoader.item.volume = root.volume;
                playerLoader.item.source = root.source;
                playerLoader.item.muted = root.muted;
                playerLoader.item.loops = root.loops;
                playerLoader.item.fillMode = root.fillMode;
                playerLoader.item.playbackRate = root.playbackRate;
                playerLoader.item.mediaStatusChanged.connect(() => {
                    root.mediaStatus = playerLoader.item.mediaStatus;
                });
            }
        }
    }

    Connections {
        target: playerLoader.item
    }

    onVolumeChanged: {
        if (playerLoader.item)
            playerLoader.item.volume = root.volume;
    }
    onSourceChanged: {
        if (playerLoader.item)
            playerLoader.item.source = root.source;
    }
    onMutedChanged: {
        console.error("VideoPlayer muted:", root.muted);
        if (playerLoader.item)
            playerLoader.item.muted = root.muted;
    }
    onPlaybackRateChanged: {
        if (playerLoader.item)
            playerLoader.item.playbackRate = root.playbackRate;
    }
    onFillModeChanged: {
        if (playerLoader.item)
            playerLoader.item.fillMode = root.fillMode;
    }
    onLoopsChanged: {
        if (playerLoader.item)
            playerLoader.item.loops = root.loops;
    }
}

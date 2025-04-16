import QtQuick
import QtQuick.Layouts
import QtMultimedia
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "code/utils.js" as Utils

Item {
    id: root
    property var currentSource
    property real volume: 1.0
    property bool muted: true
    property int playbackRate: 1
    property int fillMode: VideoOutput.PreserveAspectCrop
    property int loops: MediaPlayer.Infinite
    property bool crossfadeEnabled: false
    property int targetCrossfadeDuration: 1000
    property bool multipleVideos: false
    property int lastVideoPosition: 0
    property bool restoreLastPosition: true
    property bool debugEnabled: false
    property bool slideshowEnabled: true

    property int position

    // Crossfade must not be longer than the shortest video or the fade becomes glitchy
    // we don't know the length until a video gets played, so the crossfade duration
    // will decrease below the configured duration if needed as videos get played
    property int crossfadeMinDuration: parseInt(Math.max(Math.min(videoPlayer1.actualDuration, videoPlayer2.actualDuration) / 3, 1))
    property int crossfadeDuration: Math.min(root.targetCrossfadeDuration, crossfadeMinDuration)

    property bool primaryPlayer: true
    property VideoPlayer player: primaryPlayer ? videoPlayer1 : videoPlayer2

    function play() {
        player.play();
    }
    function pause() {
        player.pause();
    }
    function stop() {
        player.stop();
    }
    function next() {
        setNextSource();
        primaryPlayer = true;
        videoPlayer2.pause();
        videoPlayer1.opacity = 1;
        videoPlayer1.playerSource = root.currentSource;
        videoPlayer1.play();
    }
    signal setNextSource

    VideoPlayer {
        id: videoPlayer1
        anchors.fill: parent
        property var playerSource: root.currentSource
        property int actualDuration: duration / playbackRate
        playbackRate: playerSource.playbackRate || root.playbackRate
        source: playerSource.filename ?? ""
        loops: {
            if (!root.slideshowEnabled) {
                return MediaPlayer.Infinite;
            }
            if (root.multipleVideos || root.crossfadeEnabled) {
                return 1;
            }
            return MediaPlayer.Infinite;
        }
        muted: root.muted
        z: 2
        opacity: 1
        playerId: 1
        onPositionChanged: {
            if (!root.primaryPlayer) {
                return;
            }
            root.position = position;

            if ((position / playbackRate) > actualDuration - root.crossfadeDuration) {
                if (root.crossfadeEnabled) {
                    if (root.slideshowEnabled) {
                        root.setNextSource();
                    }
                    if (root.debugEnabled) {
                        console.log("player1 fading out");
                    }
                    opacity = 0;
                    root.primaryPlayer = false;
                    videoPlayer2.playerSource = root.currentSource;
                    videoPlayer2.play();
                }
            }
        }
        onMediaStatusChanged: {
            if (mediaStatus == MediaPlayer.EndOfMedia) {
                if (root.crossfadeEnabled)
                    return;
                if (root.slideshowEnabled) {
                    root.setNextSource();
                }
                videoPlayer1.playerSource = root.currentSource;
                videoPlayer1.play();
            }

            if (mediaStatus == MediaPlayer.LoadedMedia && seekable) {
                if (!root.position)
                    return;
                if (root.position < duration) {
                    position = root.lastVideoPosition;
                }
                root.restoreLastPosition = false;
            }
        }
        onPlayingChanged: {
            if (playing) {
                if (videoPlayer1.opacity === 0) {
                    opacity = 1;
                }
                if (root.debugEnabled) {
                    console.log("Player 1 playing");
                }
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: root.crossfadeDuration
            }
        }
    }

    VideoPlayer {
        id: videoPlayer2
        loops: 1
        property var playerSource: Utils.createVideo("")
        property int actualDuration: duration / playbackRate
        playbackRate: playerSource.playbackRate || root.playbackRate
        source: playerSource.filename ?? ""
        anchors.fill: parent
        muted: root.muted
        z: 1
        playerId: 2
        onPositionChanged: {
            if (root.primaryPlayer) {
                return;
            }
            root.position = position;

            if ((position / playbackRate) > actualDuration - root.crossfadeDuration) {
                if (root.debugEnabled) {
                    console.log("player1 fading in");
                }
                videoPlayer1.opacity = 1;
                if (root.slideshowEnabled) {
                    root.setNextSource();
                }
                root.primaryPlayer = true;
                videoPlayer1.playerSource = root.currentSource;
                videoPlayer1.play();
            }
        }
        onPlayingChanged: {
            if (playing && root.debugEnabled) {
                console.log("player2 playing");
            }
        }
    }

    ColumnLayout {
        visible: root.debugEnabled
        z: 2
        Item {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 100
        }
        Kirigami.AbstractCard {
            Layout.margins: Kirigami.Units.largeSpacing
            contentItem: ColumnLayout {
                id: content
                PlasmaComponents.Label {
                    text: root.player.source
                }
                PlasmaComponents.Label {
                    text: "slideshow " + root.slideshowEnabled
                }
                PlasmaComponents.Label {
                    text: "crossfade " + root.crossfadeEnabled
                }
                PlasmaComponents.Label {
                    text: "multipleVideos " + root.multipleVideos
                }
                PlasmaComponents.Label {
                    text: "player " + root.player.playerId
                }
                PlasmaComponents.Label {
                    text: "media status " + root.player.mediaStatus
                }
                PlasmaComponents.Label {
                    text: "playing " + root.player.playing
                }
                PlasmaComponents.Label {
                    text: "position " + root.player.position
                }
                PlasmaComponents.Label {
                    text: "duration " + root.player.duration
                }
            }
        }
    }
}

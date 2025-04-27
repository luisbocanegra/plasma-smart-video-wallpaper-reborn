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
    property real playbackRate: 1
    property int fillMode
    property bool crossfadeEnabled: false
    property int targetCrossfadeDuration: 1000
    property bool multipleVideos: false
    property int lastVideoPosition: 0
    property bool restoreLastPosition: true
    property bool debugEnabled: false
    property bool slideshowEnabled: true

    property bool disableCrossfade: false
    property int position

    // Crossfade must not be longer than the shortest video or the fade becomes glitchy
    // we don't know the length until a video gets played, so the crossfade duration
    // will decrease below the configured duration if needed as videos get played
    property int crossfadeMinDuration: parseInt(Math.max(Math.min(videoPlayer1.actualDuration, videoPlayer2.actualDuration) / 3, 1))
    property int crossfadeDuration: disableCrossfade ? 0 : Math.min(root.targetCrossfadeDuration, crossfadeMinDuration)

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
    function next(switchSource, fade) {
        if (switchSource) {
            setNextSource();
        }
        if (fade) {
            if (primaryPlayer) {
                videoPlayer1.opacity = 0;
                videoPlayer2.playerSource = root.currentSource;
                videoPlayer2.play();
                root.primaryPlayer = false;
            } else {
                videoPlayer1.opacity = 1;
                videoPlayer1.playerSource = root.currentSource;
                videoPlayer1.play();
                root.primaryPlayer = true;
            }
        } else {
            primaryPlayer = true;
            root.disableCrossfade = true;
            videoPlayer2.stop();
            videoPlayer1.stop();
            videoPlayer1.playerSource = root.currentSource;
            videoPlayer1.opacity = 1;
            videoPlayer1.play();
            root.disableCrossfade = false;
        }
    }
    signal setNextSource

    VideoPlayer {
        id: videoPlayer1
        objectName: "1"
        anchors.fill: parent
        property var playerSource: root.currentSource
        property int actualDuration: duration / playbackRate
        playbackRate: playerSource.playbackRate || root.playbackRate
        source: playerSource.filename ?? ""
        volume: root.volume
        muted: root.muted
        z: 2
        opacity: 1
        fillMode: root.fillMode
        loops: {
            if (!root.slideshowEnabled) {
                return MediaPlayer.Infinite;
            }
            if (root.multipleVideos || root.crossfadeEnabled) {
                return 1;
            }
            return MediaPlayer.Infinite;
        }
        onPositionChanged: {
            if (!root.primaryPlayer) {
                return;
            }
            if (!root.restoreLastPosition) {
                root.lastVideoPosition = position;
            }

            if ((position / playbackRate) > (actualDuration - root.crossfadeDuration)) {
                if (root.crossfadeEnabled) {
                    if (root.slideshowEnabled) {
                        root.setNextSource();
                    }
                    if (root.debugEnabled) {
                        console.log("player1 fading out");
                    }
                    root.next(false, true);
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
                if (!root.restoreLastPosition)
                    return;
                if (root.lastVideoPosition < duration) {
                    console.error("RESTORE LAST POSITION:", root.lastVideoPosition);
                    videoPlayer1.position = root.lastVideoPosition;
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
                easing.type: Easing.OutQuint
            }
        }
    }

    VideoPlayer {
        id: videoPlayer2
        objectName: "2"
        anchors.fill: parent
        property var playerSource: Utils.createVideo("")
        property int actualDuration: duration / playbackRate
        playbackRate: playerSource.playbackRate || root.playbackRate
        source: playerSource.filename ?? ""
        volume: root.volume
        muted: root.muted
        z: 1
        fillMode: root.fillMode
        loops: 1
        onPositionChanged: {
            if (root.primaryPlayer) {
                return;
            }
            root.lastVideoPosition = position;

            if ((position / playbackRate) > (actualDuration - root.crossfadeDuration)) {
                if (root.debugEnabled) {
                    console.log("player1 fading in");
                }
                if (root.slideshowEnabled) {
                    root.setNextSource();
                }
                root.next(false, true);
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
                    text: "player " + root.player.objectName
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

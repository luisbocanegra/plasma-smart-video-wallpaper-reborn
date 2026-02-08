import QtQuick
import QtMultimedia
import "code/utils.js" as Utils
import "code/enum.js" as Enum

Item {
    id: root
    property var currentSource: Utils.createVideo("")
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
    property int changeWallpaperMode: Enum.ChangeWallpaperMode.Slideshow
    property int changeWallpaperTimerSeconds: 0
    property int changeWallpaperTimerMinutes: 10
    property int changeWallpaperTimerHours: 0
    property int changeWallpaperTimerMs: ((changeWallpaperTimerHours * 60 * 60) + (changeWallpaperTimerMinutes * 60) + changeWallpaperTimerSeconds) * 1000
    property bool resumeLastVideo: true
    property int fillBlurRadius: 32
    property bool fillBlur: true
    property real alternativePlaybackRateGlobal: 0.5
    property bool useAlternativePlaybackRate: false

    property bool prebufferNextVideo: true
    property var nextSource: Utils.createVideo("")

    // Crossfade must not be longer than the shortest video or the fade becomes glitchy
    // we don't know the length until a video gets played, so the crossfade duration
    // will decrease below the configured duration if needed as videos get played
    // Split the crossfade duration between the two videos. If either video is too short,
    // reduce only it's part of the crossfade duration accordingly
    property int crossfadeMinDurationLast: Math.min(root.targetCrossfadeDuration / 2, otherPlayer.actualDuration / 3)
    property int crossfadeMinDurationCurrent: Math.min(root.targetCrossfadeDuration / 2, player.actualDuration / 3)
    property int crossfadeDuration: {
        if (!root.crossfadeEnabled) {
            return 0;
        } else if (root.changeWallpaperMode === Enum.ChangeWallpaperMode.OnATimer) {
            return Math.min(root.targetCrossfadeDuration, changeWallpaperTimerMs / 3 * 2);
        } else {
            return crossfadeMinDurationLast + crossfadeMinDurationCurrent;
        }
    }

    property bool primaryPlayer: true
    property VideoPlayer player: primaryPlayer ? videoPlayer1 : videoPlayer2
    property VideoPlayer otherPlayer: primaryPlayer ? videoPlayer2 : videoPlayer1
    readonly property alias player1: videoPlayer1
    readonly property alias player2: videoPlayer2

    function play() {
        player.play();
    }
    function pause() {
        player.pause();
    }
    function stop() {
        player.stop();
    }

    function prebufferInactivePlayer() {
        if (!root.prebufferNextVideo || !root.nextSource.filename) {
            return;
        }

        if (videoPlayer1.opacity > 0 && videoPlayer1.opacity < 1) {
            prebufferTimer.restart();
            return;
        }

        const inactive = root.otherPlayer;
        if (inactive.playerSource.filename === root.nextSource.filename) {
            return; // Already set
        }
        if (root.debugEnabled) {
            console.log("Prebuffering next video: ", root.nextSource.filename);
        }
        inactive.prebufferPending = true;
        inactive.playerSource = root.nextSource;
        // play() is called when source changes to trigger bufferring

    }

    function next(switchSource, forceSwitch) {
        const shouldSwitchSource = (switchSource && !currentSource.loop) || forceSwitch;

        if (root.prebufferNextVideo && shouldSwitchSource) {
            if (primaryPlayer) {
                videoPlayer2.prebufferPending = false;
                videoPlayer2.play();
                root.primaryPlayer = false;
                videoPlayer1.opacity = 0;
            } else {
                videoPlayer1.prebufferPending = false;
                videoPlayer1.play();
                root.primaryPlayer = true;
                videoPlayer1.opacity = 1;
            }
            // Signal to advance to next video in playlist
            setNextSource();
            return;
        }

        // Standard mode: no prebuffer or looping
        if (shouldSwitchSource) {
            setNextSource();
        }
        if (primaryPlayer) {
            videoPlayer2.playerSource = root.currentSource;
            videoPlayer2.play();
            root.primaryPlayer = false;
            videoPlayer1.opacity = 0;
        } else {
            videoPlayer1.playerSource = root.currentSource;
            videoPlayer1.play();
            root.primaryPlayer = true;
            videoPlayer1.opacity = 1;
        }
    }

    signal setNextSource

    PausableTimer {
        id: changeTimer
        running: root.changeWallpaperMode === Enum.ChangeWallpaperMode.OnATimer && root.player.playing
        interval: root.changeWallpaperTimerMs - (root.crossfadeEnabled ? root.crossfadeMinDurationCurrent : 0)
        repeat: true
        useNewIntervalImmediately: true
        onTriggered: {
            if (root.debugEnabled) {
                console.log("Timer triggered, changing wallpaper");
            }
            root.next(true);
        }
        onIntervalChanged: {
            if (root.debugEnabled) {
                console.log("Timer changed:", interval);
            }
        }
    }

    VideoPlayer {
        id: videoPlayer1
        objectName: "1"
        anchors.fill: parent
        property var playerSource: root.currentSource
        property int actualDuration: duration / playbackRate
        property bool prebufferPending: false
        playbackRate: {
            if (root.useAlternativePlaybackRate) {
                return playerSource.alternativePlaybackRate || root.alternativePlaybackRateGlobal;
            }
            return playerSource.playbackRate || root.playbackRate;
        }
        source: playerSource.filename ?? ""
        volume: root.volume
        muted: root.muted
        z: 2
        opacity: 1
        fillMode: root.fillMode
        fillBlur: root.fillBlur
        fillBlurRadius: root.fillBlurRadius
        loops: {
            if (!root.multipleVideos || (root.currentSource.loop && !root.crossfadeEnabled))
                return MediaPlayer.Infinite;
            else if (root.changeWallpaperMode === Enum.ChangeWallpaperMode.Slideshow)
                return 1;
            else
                return MediaPlayer.Infinite;
        }
        onPositionChanged: {
            if (prebufferPending && !root.primaryPlayer && position > 0) {
                if (root.debugEnabled) {
                    console.log("Player 1 prebuffer fallback: pausing at position ", position);
                }
                prebufferPending = false;
                videoPlayer1.pause();
                videoPlayer1.position = 0;
                return;
            }

            if (!root.primaryPlayer) {
                return;
            }
            if (!root.restoreLastPosition) {
                root.lastVideoPosition = position;
            }

            if (root.crossfadeEnabled) {
                if ((position / playbackRate) > (actualDuration - root.crossfadeMinDurationCurrent)) {
                    if (root.changeWallpaperMode === Enum.ChangeWallpaperMode.Slideshow) {
                        root.next(true);
                    } else if (root.changeWallpaperMode === Enum.ChangeWallpaperMode.Never) {
                        root.next(false);
                    }
                }
            }
        }
        onMediaStatusChanged: {
            if (mediaStatus == MediaPlayer.EndOfMedia) {
                if (root.crossfadeEnabled) {
                    return;
                } else if (root.changeWallpaperMode === Enum.ChangeWallpaperMode.Slideshow) {
                    root.next(true);
                }
            }

            if (mediaStatus == MediaPlayer.LoadedMedia && seekable) {
                if (root.restoreLastPosition && root.resumeLastVideo) {
                    if (root.lastVideoPosition < duration) {
                        console.error("RESTORE LAST POSITION:", root.lastVideoPosition);
                        videoPlayer1.position = root.lastVideoPosition;
                    }
                }
                root.restoreLastPosition = false;
            }

            if (prebufferPending && !root.primaryPlayer) {
                if (mediaStatus == MediaPlayer.LoadedMedia || mediaStatus == MediaPlayer.BufferedMedia) {
                    if (root.debugEnabled) {
                        console.log("Player 1 prebuffered, pausing at frame 0");
                    }
                    prebufferPending = false;
                    videoPlayer1.pause();
                    if (seekable) {
                        videoPlayer1.position = 0;
                    }
                }
            }
        }
        onLoopsChanged: {
            if (primaryPlayer) {
                // needed to correctly update player with new loops value
                let pos = videoPlayer1.position;
                videoPlayer1.stop();
                videoPlayer1.play();
                videoPlayer1.position = pos;
            }
        }
        onPlayingChanged: {
            if (playing) {
                if (root.debugEnabled) {
                    console.log("Player 1 playing");
                }
            }
        }
        onSourceChanged: {
            if (root.prebufferNextVideo && prebufferPending && !root.primaryPlayer && source) {
                videoPlayer1.play();
            }
        }
        onOpacityChanged: {
            if (opacity === 0 || opacity === 1) {
                // Reset other player source to empty to free resources
                if (!root.prebufferNextVideo) {
                    otherPlayer.playerSource = Utils.createVideo("");
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
        property bool prebufferPending: false
        playbackRate: {
            if (root.useAlternativePlaybackRate) {
                return playerSource.alternativePlaybackRate || root.alternativePlaybackRateGlobal;
            }
            return playerSource.playbackRate || root.playbackRate;
        }
        source: playerSource.filename ?? ""
        volume: root.volume
        muted: root.muted
        z: 1
        fillMode: root.fillMode
        fillBlur: root.fillBlur
        fillBlurRadius: root.fillBlurRadius
        loops: {
            if (!root.multipleVideos || (root.currentSource.loop && !root.crossfadeEnabled))
                return MediaPlayer.Infinite;
            else if (root.changeWallpaperMode === Enum.ChangeWallpaperMode.Slideshow)
                return 1;
            else
                return MediaPlayer.Infinite;
        }
        onPositionChanged: {
            if (prebufferPending && root.primaryPlayer && position > 0) {
                if (root.debugEnabled) {
                    console.log("Player 2 prebuffer fallback: pausing at position ", position);
                }
                prebufferPending = false;
                videoPlayer2.pause();
                videoPlayer2.position = 0;
                return;
            }

            if (root.primaryPlayer) {
                return;
            }
            root.lastVideoPosition = position;

            if (root.crossfadeEnabled) {
                if ((position / playbackRate) > (actualDuration - root.crossfadeMinDurationCurrent)) {
                    if (root.changeWallpaperMode === Enum.ChangeWallpaperMode.Slideshow) {
                        root.next(true);
                    } else if (root.changeWallpaperMode === Enum.ChangeWallpaperMode.Never) {
                        root.next(false);
                    }
                }
            }
        }
        onMediaStatusChanged: {
            if (mediaStatus == MediaPlayer.EndOfMedia) {
                if (root.crossfadeEnabled) {
                    return;
                } else if (root.changeWallpaperMode === Enum.ChangeWallpaperMode.Slideshow) {
                    root.next(true);
                }
            }

            if (prebufferPending && root.primaryPlayer) {
                if (mediaStatus == MediaPlayer.LoadedMedia || mediaStatus == MediaPlayer.BufferedMedia) {
                    if (root.debugEnabled) {
                        console.log("Player 2 prebuffered, pausing at frame 0");
                    }
                    prebufferPending = false;
                    videoPlayer2.pause();
                    if (seekable) {
                        videoPlayer2.position = 0;
                    }
                }
            }
        }
        onLoopsChanged: {
            if (!primaryPlayer) {
                // needed to correctly update player with new loops value
                let pos = videoPlayer2.position;
                videoPlayer2.stop();
                videoPlayer2.play();
                videoPlayer2.position = pos;
            }
        }
        onPlayingChanged: {
            if (playing) {
                if (root.debugEnabled) {
                    console.log("Player 2 playing");
                }
            }
        }
        onSourceChanged: {
            if (root.prebufferNextVideo && prebufferPending && root.primaryPlayer && source) {
                videoPlayer2.play();
            }
        }
    }

    onNextSourceChanged: {
        if (root.prebufferNextVideo) {
            prebufferInactivePlayer();
        }
    }

    onPrimaryPlayerChanged: {
        if (root.prebufferNextVideo) {
            prebufferTimer.restart();
        }
    }

    Timer {
        id: prebufferTimer
        interval: 100
        onTriggered: root.prebufferInactivePlayer()
    }

    onPrebufferNextVideoChanged: {
        if (root.prebufferNextVideo) {
            prebufferInactivePlayer();
        } else {
            videoPlayer1.prebufferPending = false;
            videoPlayer2.prebufferPending = false;
            root.otherPlayer.playerSource = Utils.createVideo("");
        }
    }
}

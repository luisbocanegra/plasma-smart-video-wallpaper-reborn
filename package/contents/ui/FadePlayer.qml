import QtQuick
import QtQuick.Layouts
import QtMultimedia
import org.kde.kirigami as Kirigami
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
    property int changeWallpaperTimerMinutes: 10
    property int changeWallpaperTimerHours: 0
    property int changeWallpaperTimerTime: (changeWallpaperTimerHours * 60 + changeWallpaperTimerMinutes) * 60 * 1000
    property bool resumeLastVideo: true

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
            return Math.min(root.targetCrossfadeDuration, changeWallpaperTimerTime / 3 * 2);
        } else {
            return crossfadeMinDurationLast + crossfadeMinDurationCurrent;
        }
    }

    property bool primaryPlayer: true
    property VideoPlayer player: primaryPlayer ? videoPlayer1 : videoPlayer2
    property VideoPlayer otherPlayer: primaryPlayer ? videoPlayer2 : videoPlayer1
    property VideoPlayer player1: videoPlayer1
    property VideoPlayer player2: videoPlayer2

    function play() {
        player.play();
    }
    function pause() {
        player.pause();
    }
    function stop() {
        player.stop();
    }
    function next(switchSource, forceSwitch) {
        if ((switchSource && !currentSource.loop) || forceSwitch) {
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

        if (root.changeWallpaperMode === Enum.ChangeWallpaperMode.OnATimer) {
            changeTimer.restart();
        }
    }
    signal setNextSource

    Timer {
        id: changeTimer
        running: root.changeWallpaperMode === Enum.ChangeWallpaperMode.OnATimer
        interval: !running ? 0 : changeWallpaperTimerTime - (root.crossfadeEnabled ? root.crossfadeMinDurationCurrent : 0)
        repeat: true
        onTriggered: {
            if (root.debugEnabled) {
                console.log("Timer triggered, changing wallpaper");
            }
            root.next(true);
        }
        onIntervalChanged: {
            if (running) {
                if (root.debugEnabled) {
                    console.log("Timer started. Interval:", interval);
                }
                changeTimer.restart();
            }
        }
    }

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
            if (!root.multipleVideos || (root.currentSource.loop && !root.crossfadeEnabled))
                return MediaPlayer.Infinite;
            else if (root.changeWallpaperMode === Enum.ChangeWallpaperMode.Slideshow)
                return 1;
            else
                return MediaPlayer.Infinite;
        }
        onPositionChanged: {
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
        onOpacityChanged: {
            if (opacity === 0 || opacity === 1) {
                // Reset other player source to empty to free resources
                otherPlayer.playerSource = Utils.createVideo("");
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
        loops: {
            if (!root.multipleVideos || (root.currentSource.loop && !root.crossfadeEnabled))
                return MediaPlayer.Infinite;
            else if (root.changeWallpaperMode === Enum.ChangeWallpaperMode.Slideshow)
                return 1;
            else
                return MediaPlayer.Infinite;
        }
        onPositionChanged: {
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
    }
}

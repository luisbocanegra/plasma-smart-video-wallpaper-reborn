pragma ComponentBehavior: Bound
import QtQuick
import QtMultimedia
import Qt5Compat.GraphicalEffects
import "code/utils.js" as Utils

Item {
    id: root
    property real globalVolume: 1.0
    property int fillBlurRadius: 32
    property bool fillBlur: true
    property string audioOutputDevice
    property var playerSource
    property bool crossfadeEnabled
    property int targetCrossfadeDuration
    property bool changeWallpaperMode
    property alias muted: audioOutput.muted
    property alias fillMode: videoOutput.fillMode
    property alias loops: player.loops
    property alias position: player.position
    property alias playbackRate: player.playbackRate
    property bool firstFrame: true
    property bool shouldPlay: false
    property int lastVideoPosition: 0
    property bool debugEnabled: false

    property int audioFadeInOutDuration: 5000
    property real fadeInOutRatio: {
        if (audioFadeInOutDuration === 0) {
            return 1;
        } else if (position < audioFadeInOutDuration) {
            return position / audioFadeInOutDuration;
        } else if (remaining < audioFadeInOutDuration) {
            return remaining / audioFadeInOutDuration;
        }
        return 1;
    }

    property real audioCrossfadeOutRatio: {
        if (crossfadeDuration === 0) {
            return 1;
        } else if (remaining < crossfadeDuration) {
            return remaining / crossfadeDuration;
        }
        return 1;
    }

    // Crossfade must not be longer than the shortest video or the fade becomes glitchy
    // we don't know the length until a video gets played, so the crossfade duration
    // will decrease below the configured duration if needed as videos get played
    readonly property int crossfadeDuration: {
        if (!root.crossfadeEnabled) {
            return 0;
        } else {
            return Math.min(targetCrossfadeDuration, actualDuration / 3);
        }
    }

    readonly property int actualDuration: player.duration / playbackRate
    readonly property alias mediaStatus: player.mediaStatus
    readonly property alias playing: player.playing
    readonly property alias seekable: player.seekable
    readonly property alias duration: player.duration
    readonly property alias videoHeight: videoOutput.contentRect.height
    readonly property alias videoWidth: videoOutput.contentRect.width
    readonly property int remaining: duration - position
    readonly property bool showFillBlur: root.fillBlur && root.fitScale !== 1
    readonly property string currentAudioDevice: audioOutput.device ? audioOutput.device.description : i18n("Unknown")
    readonly property alias volume: audioOutput.volume
    readonly property real fitScale: {
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

    function updatePlaybackState() {
        if (debugEnabled) {
            console.log("VideoPlayer.updatePlaybackState() shouldPlay", shouldPlay);
        }
        if (shouldPlay) {
            player.play();
        } else {
            player.pause();
        }
    }

    onShouldPlayChanged: {
        if (firstFrame)
            return;
        updatePlaybackState();
    }

    VideoOutput {
        id: videoOutput
        fillMode: VideoOutput.PreserveAspectCrop
        anchors.fill: parent
    }

    MediaDevices {
        id: mediaDevices
    }

    AudioOutput {
        id: audioOutput
        volume: root.opacity * root.globalVolume * Utils.easeOutCubic(root.fadeInOutRatio) * root.audioCrossfadeOutRatio
        device: {
            let output;
            if (root.audioOutputDevice !== "") {
                output = mediaDevices.audioOutputs.find(o => {
                    return o.id.toString() === root.audioOutputDevice;
                });
            }
            return output || mediaDevices.defaultAudioOutput;
        }
    }

    property bool ending: false
    signal aboutToFinish

    MediaPlayer {
        id: player
        videoOutput: videoOutput
        audioOutput: audioOutput
        source: root.playerSource?.filename ?? ""
        autoPlay: true

        onMediaStatusChanged: {
            if (root.debugEnabled) {
                let statusString = "";
                switch (mediaStatus) {
                case MediaPlayer.NoMedia:
                    statusString = `${MediaPlayer.NoMedia} MediaPlayer.NoMedia`;
                    break;
                case MediaPlayer.LoadingMedia:
                    statusString = `${MediaPlayer.LoadingMedia} MediaPlayer.LoadingMedia`;
                    break;
                case MediaPlayer.LoadedMedia:
                    statusString = `${MediaPlayer.LoadedMedia} MediaPlayer.LoadedMedia`;
                    break;
                case MediaPlayer.StalledMedia:
                    statusString = `${MediaPlayer.StalledMedia} MediaPlayer.StalledMedia`;
                    break;
                case MediaPlayer.BufferingMedia:
                    statusString = `${MediaPlayer.BufferingMedia} MediaPlayer.BufferingMedia`;
                    break;
                case MediaPlayer.BufferedMedia:
                    statusString = `${MediaPlayer.BufferedMedia} MediaPlayer.BufferedMedia`;
                    break;
                case MediaPlayer.EndOfMedia:
                    statusString = `${MediaPlayer.EndOfMedia} MediaPlayer.EndOfMedia`;
                    break;
                case MediaPlayer.InvalidMedia:
                    statusString = `${MediaPlayer.InvalidMedia} MediaPlayer.InvalidMedia`;
                    break;
                }
                console.log(this, "Media status:", statusString);
            }
            if (mediaStatus === MediaPlayer.EndOfMedia && !root.crossfadeEnabled && !root.ending) {
                root.aboutToFinish();
            }

            if (mediaStatus === MediaPlayer.LoadedMedia && seekable) {
                if (root.lastVideoPosition && root.lastVideoPosition < duration) {
                    if (root.debugEnabled) {
                        console.log("RESTORE LAST POSITION:", root.lastVideoPosition);
                    }
                    position = root.lastVideoPosition;
                }
            }

            if (mediaStatus === MediaPlayer.BufferedMedia && root.firstFrame) {
                // HACK: without this the next video may still play when paused
                play();
            }
        }

        onPositionChanged: position => {
            if (root.firstFrame && position > 0) {
                root.firstFrame = false;
                updatePlaybackStateTimer.start();
            }
            if (duration < 1 || position < 1 || root.ending || loops === MediaPlayer.Infinite) {
                return;
            }
            //FIXME: adding 500/200 reduces the chances of the background from showing between videos
            // this assumes the video will load during that window, which isn't always the case
            if (root.crossfadeEnabled ? root.remaining < root.crossfadeDuration + 500 : root.remaining < 200) {
                root.ending = true;
                root.aboutToFinish();
            }
        }
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

    Component {
        id: progress
        Item {
            Rectangle {
                height: 2
                width: parent.width
                color: "black"
                Rectangle {
                    height: 2
                    width: parent.width * player.position / player.duration
                }
            }
        }
    }
    Loader {
        anchors.fill: parent
        sourceComponent: progress
        active: root.debugEnabled
    }

    Timer {
        id: updatePlaybackStateTimer
        interval: 200
        onTriggered: {
            if (root.debugEnabled) {
                console.log("VideoPlayer.updateStateTimer.onTriggered");
            }
            root.updatePlaybackState();
        }
    }
}

import QtQuick
import QtMultimedia
import com.github.luisbocanegra.mpvitem

Item {
    id: root
    property real volume: 1.0
    property int actualDuration: mpv.durationMs / playbackRate
    property string source
    property bool muted
    property real playbackRate: 1
    property int fillMode: VideoOutput.PreserveAspectCrop
    property int loops: 1

    property alias position: mpv.positionMs
    readonly property int mediaStatus: mpv.mediaStatus
    readonly property bool playing: !mpv.pause
    readonly property bool seekable: true //TODO?
    readonly property alias duration: mpv.durationMs

    function play() {
        console.error("VideoPlayerMpvQt -> play()");
        mpv.pause = false;
    }
    function pause() {
        mpv.pause = true;
    }
    function stop() {
        mpv.pause = true;
    }

    property int pendingStartPosition: -1  // -1 means no pending position

    Timer {
        id: seekTimer
        interval: 100
        repeat: false
        property real positionToSeek: 0
        onTriggered: {
            mpv.setProperty(MpvProperties.Position, positionToSeek);
        }
    }

    MpvItem {
        id: mpv
        anchors.fill: parent
        readonly property int positionMs: position * 1000
        readonly property int durationMs: duration * 1000
        onReady: {
            loadFile([root.source]);
            mpv.pause = true;
            setPropertyAsync(MpvProperties.Mute, root.muted);
            if (root.loops === MediaPlayer.Infinite) {
                mpv.setPropertyAsync(MpvProperties.Loops, "inf");
            } else {
                mpv.setPropertyAsync(MpvProperties.Loops, "0");
            }
            root.applyFillMode();
        }
        property int mediaStatus
        onFileLoaded: {
            mediaStatus = MediaPlayer.LoadedMedia;

            // Apply pending position when file is loaded
            if (root.pendingStartPosition >= 0) {
                const posSeconds = root.pendingStartPosition / 1000.0;
                root.pendingStartPosition = -1;
                // Small delay to ensure MPV is ready to accept position changes
                seekTimer.positionToSeek = posSeconds;
                seekTimer.start();
            }
        }
        onEndFile: (reason) => {
            // Only treat as EndOfMedia if the video actually reached the end
            // MPV fires endFile for other reasons like 'stop', 'error', 'quit', etc.
            if (reason === "eof") {
                mediaStatus = MediaPlayer.EndOfMedia;
            }
        }
    }

    // Function to set position (needed for FadePlayer to restore/set position)
    function setPosition(newPositionMs) {
        // Store as pending - will be applied in onFileLoaded after a small delay
        root.pendingStartPosition = newPositionMs;
    }

    onSourceChanged: {
        mpv.loadFile([source]);
    }

    onPlaybackRateChanged: {
        console.error("VideoPlayerMpvQt -> playbackRate:", root.playbackRate);
        mpv.setPropertyAsync(MpvProperties.Speed, root.playbackRate);
    }
    onMutedChanged: {
        console.error("VideoPlayerMpvQt -> muted:", root.muted);
        mpv.setPropertyAsync(MpvProperties.Mute, root.muted);
    }

    onVolumeChanged: {
        console.error("VideoPlayerMpvQt -> volume:", root.volume);
        mpv.setPropertyAsync(MpvProperties.Volume, root.volume * 100);
    }

    onLoopsChanged: {
        if (root.loops === MediaPlayer.Infinite) {
            mpv.setPropertyAsync(MpvProperties.Loops, "inf");
        } else {
            mpv.setPropertyAsync(MpvProperties.Loops, "0");
        }
    }

    onFillModeChanged: {
        console.error("VideoPlayerMpvQt -> fillMode:", root.fillMode);
        applyFillMode();
    }

    function applyFillMode() {
        if (root.fillMode === VideoOutput.Stretch) {
            // Stretch: Force aspect ratio to match window
            const aspectRatio = root.width / root.height;
            mpv.setPropertyAsync(MpvProperties.VideoAspect, aspectRatio.toString());
            mpv.setPropertyAsync(MpvProperties.Panscan, 0);
        } else if (root.fillMode === VideoOutput.PreserveAspectFit) {
            // Keep Proportions: Letterbox/pillarbox to fit
            mpv.setPropertyAsync(MpvProperties.VideoAspect, "-1");
            mpv.setPropertyAsync(MpvProperties.Panscan, 0);
        } else if (root.fillMode === VideoOutput.PreserveAspectCrop) {
            // Scaled and Cropped: Fill window by cropping
            mpv.setPropertyAsync(MpvProperties.VideoAspect, "-1");
            mpv.setPropertyAsync(MpvProperties.Panscan, 1.0);
        }
    }
}

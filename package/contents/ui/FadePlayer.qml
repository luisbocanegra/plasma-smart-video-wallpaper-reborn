// based on https://github.com/KDE/plasma-workspace/blob/master/wallpapers/image/imagepackage/contents/ui/ImageStackView.qml
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtMultimedia
import "code/utils.js" as Utils
import "code/enum.js" as Enum

StackView {
    id: root
    property var currentSource
    property real globalVolume: 1.0
    property bool muted: true
    property real globalPlaybackRate: 1
    property int fillMode
    property bool crossfadeEnabled: false
    property int targetCrossfadeDuration: 1000
    property int audioFadeInOutDuration: 0
    property int loadAheadTime: 0
    property bool multipleVideos: false
    property bool resumeLastVideo: true
    property int lastVideoPosition: 0
    property bool _restoreLastPosition: true
    property bool debugEnabled: false
    property int changeWallpaperMode: Enum.ChangeWallpaperMode.Slideshow
    property int fillBlurRadius: 32
    property bool fillBlur: true
    property real alternativePlaybackRateGlobal: 0.5
    property bool useAlternativePlaybackRate: false
    property string audioOutputDevice
    property bool shouldPlay: true
    property real playbackRate: 1
    property int loops: {
        if ((changeWallpaperMode === Enum.ChangeWallpaperMode.Never || !multipleVideos) && !crossfadeEnabled) {
            return MediaPlayer.Infinite;
        }
        return 1;
    }
    function updatePlaybackRate() {
        let rate = 1;
        if (root.useAlternativePlaybackRate) {
            rate = currentSource?.alternativePlaybackRate || alternativePlaybackRateGlobal;
        } else {
            rate = currentSource?.playbackRate || globalPlaybackRate;
        }
        // Ignore very small values as it makes the video go crazy fast, stops
        // responding to this property and needs to be stopped to recover
        // TODO: Check if this has been reported to Qt
        playbackRate = Math.max(rate, 0.01);
    }

    property list<var> propertiesMonitor: [currentSource, globalVolume, muted, fillMode, targetCrossfadeDuration, loops, changeWallpaperMode, fillBlurRadius, fillBlur, audioOutputDevice, crossfadeEnabled, debugEnabled, useAlternativePlaybackRate, alternativePlaybackRateGlobal, globalPlaybackRate, audioFadeInOutDuration, loadAheadTime]

    onPropertiesMonitorChanged: {
        updatePlaybackRate();
        if (root.currentItem) {
            root.currentItem.globalVolume = root.globalVolume;
            root.currentItem.muted = root.muted;
            root.currentItem.fillMode = root.fillMode;
            root.currentItem.targetCrossfadeDuration = root.targetCrossfadeDuration;
            root.currentItem.loops = root.loops;
            root.currentItem.changeWallpaperMode = root.changeWallpaperMode;
            root.currentItem.fillBlurRadius = root.fillBlurRadius;
            root.currentItem.fillBlur = root.fillBlur;
            root.currentItem.audioOutputDevice = root.audioOutputDevice;
            root.currentItem.crossfadeEnabled = root.crossfadeEnabled;
            root.currentItem.debugEnabled = root.debugEnabled;
            root.currentItem.audioFadeInOutDuration = root.audioFadeInOutDuration;
            root.currentItem.loadAheadTime = loadAheadTime;
        }
    }

    property bool primaryPlayer: true
    property var player: root.currentItem

    signal setNextSource

    property Component videoComponent

    property var pendingVideo
    property bool doesSkipAnimation: true

    function createVideoComponent() {
        if (!videoComponent) {
            videoComponent = Qt.createComponent("VideoPlayer.qml");
        }
        return videoComponent;
    }

    function loadVideoImmediately() {
        loadVideo(true);
    }

    function loadVideo(skipAnimation) {
        if (pendingVideo) {
            pendingVideo.mediaStatusChanged.disconnect(replaceWhenLoaded);
            pendingVideo.destroy();
            pendingVideo = null;
        }

        doesSkipAnimation = root.currentItem == undefined;

        const baseVideo = createVideoComponent();
        const properties = {
            "playerSource": root.currentSource,
            "globalVolume": root.globalVolume,
            "loops": root.loops,
            "fillBlur": root.fillBlur,
            "fillBlurRadius": root.fillBlurRadius,
            "crossfadeEnabled": root.crossfadeEnabled,
            "targetCrossfadeDuration": root.targetCrossfadeDuration,
            "parent": root,
            "implicitWidth": root.width,
            "implicitHeight": root.height,
            "visible": false,
            "fillMode": root.fillMode,
            "muted": root.muted,
            "audioOutputDevice": root.audioOutputDevice,
            "playbackRate": Qt.binding(() => root.playbackRate),
            "changeWallpaperMode": root.changeWallpaperMode,
            "shouldPlay": Qt.binding(() => root.shouldPlay),
            "lastVideoPosition": root.resumeLastVideo && root._restoreLastPosition ? root.lastVideoPosition : 0,
            "debugEnabled": root.debugEnabled,
            "audioFadeInOutDuration": root.audioFadeInOutDuration,
            "loadAheadTime": root.loadAheadTime
        };
        pendingVideo = baseVideo.createObject(root, properties);

        if (!pendingVideo) {
            console.error("baseVideo.errorString()", videoComponent.errorString());
        }

        pendingVideo.mediaStatusChanged.connect(replaceWhenLoaded);
        replaceWhenLoaded();
    }

    onCurrentItemChanged: {
        if (debugEnabled) {
            console.log("FadePlayer.onCurrentItemChanged");
        }
        root.currentItem.aboutToFinish.connect(replaceAboutToFinish);
    }

    function replaceAboutToFinish() {
        if (debugEnabled) {
            console.log("replaceAboutToFinish()");
        }
        setNextSource();
        root.currentItem.mediaStatusChanged.disconnect(replaceAboutToFinish);
    }

    function replaceWhenLoaded() {
        if (pendingVideo.mediaStatus <= MediaPlayer.LoadingMedia) {
            return;
        }
        root._restoreLastPosition = false;
        pendingVideo.mediaStatusChanged.disconnect(replaceWhenLoaded);

        // onRemoved only fires when all transitions end. If a user switches wallpaper quickly this adds up
        // Given it's such a heavy item, try to cleanup as early as possible
        pendingVideo.StackView.onDeactivated.connect(pendingVideo.destroy);
        pendingVideo.StackView.onRemoved.connect(pendingVideo.destroy);
        root.replace(pendingVideo, {}, StackView.Transition);

        pendingVideo = null;
    }

    replaceEnter: Transition {
        NumberAnimation {
            id: replaceEnterOpacityAnimator
            property: "opacity"
            from: 0
            to: 1
            duration: root.currentItem.crossfadeDuration ?? 0
            easing.type: Easing.InOutCubic
        }
        enabled: root.crossfadeEnabled
    }
    // Keep the old video around till the new one is fully faded in
    // If we fade both at the same time you can see the background behind glimpse through
    replaceExit: Transition {
        PauseAnimation {
            // 500: The exit transition starts first and can be completed earlier than the enter transition
            duration: replaceEnterOpacityAnimator.duration + 500
        }
    }

    onCurrentSourceChanged: {
        if (debugEnabled) {
            console.log("FadePlayer.onCurrentSourceChanged", currentSource.filename);
        }
        // only reload the player when the video file changes
        if (root.currentItem && root.currentItem.playerSource?.filename === currentSource.filename) {
            return;
        }
        root.loadVideo();
    }

    initialItem: VideoPlayer {
        playerSource: Utils.createVideo("")
    }
}

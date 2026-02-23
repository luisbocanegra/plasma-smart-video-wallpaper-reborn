/*
 *  Copyright 2018 Rog131 <samrog131@hotmail.com>
 *  Copyright 2019 adhe   <adhemarks2@gmail.com>
 *  Copyright 2024 Luis Bocanegra <luisbocanegra17b@gmail.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg as KSvg
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid
import Qt5Compat.GraphicalEffects
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "code/utils.js" as Utils
import "code/enum.js" as Enum

WallpaperItem {
    id: main
    anchors.fill: parent
    property bool isLoading: true
    property string videoUrls: main.configuration.VideoUrls
    property var videosConfig: {
        const videos = getVideos();
        return randomMode ? Utils.shuffleArray(videos) : videos;
    }
    property int currentVideoIndex: 0
    property bool resumeLastVideo: main.configuration.ResumeLastVideo
    property var currentSource: {
        if (resumeLastVideo && main.configuration.LastVideo !== "") {
            return Utils.getVideoByFile(main.configuration.LastVideo, videosConfig);
        }
        return Utils.getVideoByIndex(currentVideoIndex, videosConfig);
    }
    property int pauseBatteryLevel: main.configuration.PauseBatteryLevel
    property bool shouldPlay: {
        if (lockScreenMode) {
            return true;
        }

        if (playbackOverride === Enum.PlaybackOverride.Play) {
            return true;
        } else if (playbackOverride === Enum.PlaybackOverride.Pause) {
            return false;
        }

        let play = false;
        switch (main.configuration.PauseMode) {
        case Enum.PauseMode.MaximizedOrFullScreen:
            play = !windowModel.maximizedExists;
            break;
        case Enum.PauseMode.ActiveWindowPresent:
            play = !windowModel.activeExists;
            break;
        case Enum.PauseMode.WindowVisible:
            play = !windowModel.visibleExists;
            break;
        case Enum.PauseMode.Never:
            play = true;
        }
        return play;
    }
    property bool playing: {
        return ((shouldPlay && !batteryPausesVideo && !screenLocked && !screenIsOff && !effectPauseVideo) || effectPlayVideo) && videosConfig.length !== 0;
    }
    property bool shouldBlur: {
        if (videosConfig.length == 0) {
            return false;
        }
        let blur = false;
        switch (main.configuration.BlurMode) {
        case Enum.BlurMode.MaximizedOrFullScreen:
            blur = windowModel.maximizedExists;
            break;
        case Enum.BlurMode.ActiveWindowPresent:
            blur = windowModel.activeExists;
            break;
        case Enum.BlurMode.WindowVisible:
            blur = windowModel.visibleExists;
            break;
        case Enum.BlurMode.VideoPaused:
            blur = !main.playing;
            break;
        case Enum.BlurMode.Always:
            blur = true;
            break;
        case Enum.BlurMode.Never:
            blur = false;
        }
        return blur;
    }
    property bool showBlur: (shouldBlur && !batteryDisablesBlur && !effectHideBlur) || effectShowBlur
    property bool screenLocked: screenModel.screenIsLocked
    property bool batteryPausesVideo: pauseBattery && main.configuration.BatteryPausesVideo
    property bool batteryDisablesBlur: pauseBattery && main.configuration.BatteryDisablesBlur

    property bool screenIsOff: screenModel.screenIsOff
    property bool screenOffPausesVideo: main.configuration.ScreenOffPausesVideo
    property bool lockScreenMode: false
    property bool debugEnabled: main.configuration.DebugEnabled

    property var activeEffects: effectsModel.activeEffects
    property var effectsHideBlur: main.configuration.EffectsHideBlur.split(",").filter(Boolean)
    property var effectsShowBlur: main.configuration.EffectsShowBlur.split(",").filter(Boolean)
    property var effectsAlternativeSpeed: main.configuration.EffectsAlternativeSpeed.split(",").filter(Boolean)
    property bool effectHideBlur: effectsHideBlur.some(item => activeEffects.includes(item))
    property bool effectShowBlur: effectsShowBlur.some(item => activeEffects.includes(item))
    property bool effectAlternativeSpeed: effectsAlternativeSpeed.some(item => activeEffects.includes(item))

    property var effectsPauseVideo: main.configuration.EffectsPauseVideo.split(",").filter(Boolean)
    property var effectsPlayVideo: main.configuration.EffectsPlayVideo.split(",").filter(Boolean)
    property bool effectPauseVideo: effectsPauseVideo.some(item => activeEffects.includes(item))
    property bool effectPlayVideo: effectsPlayVideo.some(item => activeEffects.includes(item))

    property int blurAnimationDuration: main.configuration.BlurAnimationDuration
    property bool crossfadeEnabled: main.configuration.CrossfadeEnabled
    property bool tick: true
    property real playbackRate: main.configuration.PlaybackRate
    property real volume: main.configuration.Volume
    property real volumeOutput2: 0
    property bool randomMode: main.configuration.RandomMode
    property int lastVideoPosition: main.configuration.LastVideoPosition
    property int changeWallpaperMode: main.configuration.ChangeWallpaperMode
    property int changeWallpaperTimerSeconds: main.configuration.ChangeWallpaperTimerSeconds
    property int changeWallpaperTimerMinutes: main.configuration.ChangeWallpaperTimerMinutes
    property int changeWallpaperTimerHours: main.configuration.ChangeWallpaperTimerHours
    property bool prebufferNextVideo: main.configuration.PrebufferNextVideo
    property bool prebufferEnabled: prebufferNextVideo && videosConfig.length > 1
    property var nextSource: Utils.createVideo("")
    property int nextVideoIndex: -1

    property bool muteAudio: {
        if (muteOverride === Enum.MuteOverride.Mute) {
            return true;
        } else if (muteOverride === Enum.MuteOverride.Unmute) {
            return false;
        }

        let mute = false;
        switch (main.configuration.MuteMode) {
        case Enum.MuteMode.MaximizedOrFullScreen:
            mute = windowModel.maximizedExists;
            break;
        case Enum.MuteMode.ActiveWindowPresent:
            mute = windowModel.activeExists;
            break;
        case Enum.MuteMode.WindowVisible:
            mute = windowModel.visibleExists;
            break;
        //  TODO other application playing audio
        // case Enum.MuteMode.AnotherAppPlayingAudio:
        //  break
        case Enum.MuteMode.Never:
            mute = false;
            break;
        case Enum.MuteMode.Always:
            mute = true;
        }
        return mute;
    }
    property bool useAlternativePlaybackRate: {
        if (lockScreenMode) {
            return false;
        }

        if (effectAlternativeSpeed) {
            return true;
        }

        let r = false;
        switch (main.configuration.AlternativePlaybackRateMode) {
        case Enum.PauseMode.MaximizedOrFullScreen:
            r = windowModel.maximizedExists;
            break;
        case Enum.PauseMode.ActiveWindowPresent:
            r = windowModel.activeExists;
            break;
        case Enum.PauseMode.WindowVisible:
            r = windowModel.visibleExists;
            break;
        case Enum.PauseMode.Never:
            r = false;
        }
        return r;
    }

    function getVideos() {
        return Utils.parseCompat(videoUrls).filter(video => video.enabled);
    }

    function updateNextSource() {
        if (prebufferEnabled) {
            nextSource = computeNextSource();
            return;
        }
        nextVideoIndex = -1;
        if (player && player.transitionBusy) {
            return;
        }
        nextSource = Utils.createVideo("");
    }

    function computeNextSource() {
        if (!prebufferEnabled || videosConfig.length === 0) {
            nextVideoIndex = -1;
            return Utils.createVideo("");
        }
        const nextIndex = (currentVideoIndex + 1) % videosConfig.length;
        nextVideoIndex = nextIndex;

        if (randomMode && nextIndex === 0) {
            const shuffledVideos = Utils.shuffleArray(videosConfig);
            return shuffledVideos[nextIndex];
        }
        return videosConfig[nextIndex];
    }

    function skipNextCandidate(failedFilename) {
        if (!prebufferEnabled || videosConfig.length === 0) {
            return;
        }

        if (videosConfig.length === 1) {
            nextVideoIndex = currentVideoIndex;
            nextSource = videosConfig[currentVideoIndex];
            return;
        }

        let probeIndex = nextVideoIndex >= 0 ? nextVideoIndex : currentVideoIndex;
        for (let attempt = 0; attempt < videosConfig.length; attempt++) {
            const candidateIndex = (probeIndex + 1) % videosConfig.length;
            let candidate;
            if (randomMode && candidateIndex === 0) {
                const shuffledVideos = Utils.shuffleArray(videosConfig);
                candidate = shuffledVideos[candidateIndex];
            } else {
                candidate = videosConfig[candidateIndex];
            }

            if (candidate.filename !== ""
                    && candidate.filename !== failedFilename
                    && candidate.filename !== currentSource.filename) {
                nextVideoIndex = candidateIndex;
                nextSource = candidate;
                printLog("- Replacement next target " + nextVideoIndex + ": " + nextSource.filename);
                return;
            }
            probeIndex = candidateIndex;
        }

        // Keep a deterministic fallback candidate so FadePlayer never gets stuck with <none>.
        const fallback = computeNextSource();
        nextSource = fallback;
        if (fallback.filename !== "") {
            printLog("- Fallback next target " + nextVideoIndex + ": " + nextSource.filename + " (after failed prebuffer: " + failedFilename + ")");
        } else {
            nextVideoIndex = -1;
            nextSource = Utils.createVideo("");
            printLog("- No fallback next target after failed prebuffer: " + failedFilename);
        }
    }

    onPlayingChanged: {
        playing && !isLoading ? main.play() : main.pause();
    }
    onVideoUrlsChanged: {
        if (isLoading)
            return;
        videosConfig = getVideos();
        const wasPlaying = player.player.playing;
        // console.error(videoUrls);
        if (videosConfig.length == 0) {
            main.stop();
            main.currentSource.filename = "";
        } else if (videosConfig.length == 1) {
            player.next(true, true);
            if (!wasPlaying) {
                main.pause();
            }
        }
        updateNextSource();
    }
    onPrebufferEnabledChanged: updateNextSource()
    onRandomModeChanged: updateNextSource()

    property QtObject pmSource: P5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: sources
        onSourceAdded: source => {
            disconnectSource(source);
            connectSource(source);
        }
        onSourceRemoved: source => {
            disconnectSource(source);
        }
    }

    property bool pauseBattery: {
        let result = false;
        if (pmSource.data.Battery["Has Cumulative"] && pmSource.data["Battery"]["State"] === "Discharging") {
            result = pauseBatteryLevel > pmSource.data.Battery.Percent;
        }
        return result;
    }

    TasksModel {
        id: windowModel
        screenGeometry: main.parent?.screenGeometry ?? null
    }

    ScreenModel {
        id: screenModel
        checkScreenLock: !main.lockScreenMode
        checkScreenState: main.screenOffPausesVideo && screenStateCmd !== ""
        screenStateCmd: main.configuration.ScreenStateCmd
        instanceId: Plasmoid.id ?? ""
    }

    EffectsModel {
        id: effectsModel
        monitorActive: {
            return [main.effectsPlayVideo, main.effectsPauseVideo, main.effectsShowBlur, main.effectsHideBlur].some(arr => arr.length > 0);
        }
    }

    function nextVideo() {
        printLog("- Video ended " + currentVideoIndex + ": " + currentSource.filename);

        if (prebufferEnabled && nextVideoIndex >= 0) {
            currentVideoIndex = nextVideoIndex;
            currentSource = nextSource;
        } else {
            currentVideoIndex = (currentVideoIndex + 1) % videosConfig.length;
            if (randomMode && currentVideoIndex === 0) {
                const shuffledVideos = Utils.shuffleArray(videosConfig);
                currentSource = shuffledVideos[currentVideoIndex];
            } else {
                currentSource = videosConfig[currentVideoIndex];
            }
        }
        printLog("- Next " + currentVideoIndex + ": " + currentSource.filename);
        updateNextSource();
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: videosConfig.length == 0 ? Kirigami.Theme.backgroundColor : main.configuration.BackgroundColor

        FadePlayer {
            id: player
            anchors.fill: parent
            muted: main.muteAudio
            lastVideoPosition: main.configuration.LastVideoPosition
            visible: main.videosConfig.length !== 0
            onSetNextSource: {
                main.nextVideo();
            }
            onRequestNextCandidate: function (failedFilename) {
                main.skipNextCandidate(failedFilename);
            }
            crossfadeEnabled: main.crossfadeEnabled
            multipleVideos: main.videosConfig.length > 1
            targetCrossfadeDuration: main.configuration.CrossfadeDuration
            debugEnabled: main.debugEnabled
            changeWallpaperMode: main.changeWallpaperMode
            changeWallpaperTimerSeconds: main.changeWallpaperTimerSeconds
            changeWallpaperTimerMinutes: main.changeWallpaperTimerMinutes
            changeWallpaperTimerHours: main.changeWallpaperTimerHours
            fillMode: main.configuration.FillMode
            fillBlur: main.configuration.FillBlur && !main.batteryDisablesBlur
            fillBlurRadius: main.configuration.FillBlurRadius
            volume: main.volume
            playbackRate: main.playbackRate
            useAlternativePlaybackRate: main.useAlternativePlaybackRate
            alternativePlaybackRateGlobal: main.configuration.AlternativePlaybackRate
            resumeLastVideo: main.configuration.ResumeLastVideo
            prebufferNextVideo: main.prebufferEnabled
            nextSource: main.nextSource
        }

        Connections {
            target: player
            function onTransitionBusyChanged() {
                if (!main.prebufferEnabled && !player.transitionBusy) {
                    main.updateNextSource();
                }
            }
        }
    }
    FastBlur {
        id: mainBlur
        source: background
        radius: main.showBlur ? main.configuration.BlurRadius : 0
        visible: radius !== 0
        anchors.fill: background
        Behavior on radius {
            NumberAnimation {
                duration: main.blurAnimationDuration
            }
        }
    }

    PlasmaExtras.PlaceholderMessage {
        visible: main.videosConfig.length == 0
        anchors.centerIn: parent
        width: parent.width - Kirigami.Units.gridUnit * 2
        iconName: "video-symbolic"
        text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "No video source \n" + main.videoUrls)
    }

    Item {
        visible: main.debugEnabled
        implicitWidth: debugArea.implicitWidth + debugArea.anchors.leftMargin + debugArea.anchors.rightMargin
        implicitHeight: debugArea.implicitHeight + debugArea.anchors.topMargin + debugArea.anchors.bottomMargin
        x: 40
        y: 100
        KSvg.FrameSvgItem {
            id: frameSvg
            imagePath: "widgets/background"
            anchors.fill: parent
        }
        ColumnLayout {
            id: debugArea
            anchors {
                fill: parent
                leftMargin: frameSvg.fixedMargins.left
                rightMargin: frameSvg.fixedMargins.right
                topMargin: frameSvg.fixedMargins.top
                bottomMargin: frameSvg.fixedMargins.bottom
            }
            PlasmaComponents.Label {
                Layout.margins: Kirigami.Units.largeSpacing
                text: {
                    let p1MediaStatusName = Object.keys(Enum.MediaStatus).find(key => Enum.MediaStatus[key] === player.player1.mediaStatus);
                    let p2MediaStatusName = Object.keys(Enum.MediaStatus).find(key => Enum.MediaStatus[key] === player.player2.mediaStatus);

                    let text = `filename: ${main.currentSource.filename}\n`;
                    text += `loops: ${main.currentSource.loop ?? false}\n`;
                    text += `currentVideoIndex: ${main.currentVideoIndex}\n`;
                    text += `changeWallpaperMode: ${main.changeWallpaperMode}\n`;
                    text += `crossfade: ${main.crossfadeEnabled}\n`;
                    text += `crossfadeDuration: ${player.crossfadeDuration} ${player.crossfadeMinDurationLast} ${player.crossfadeMinDurationCurrent}\n`;
                    text += `transitionState: ${player.transitionStateName}\n`;
                    text += `pendingTarget: ${player.pendingTargetFilename || "<none>"}\n`;
                    text += `pendingAdvance: ${player.pendingAdvancePlaylist}\n`;
                    text += `multipleVideos: ${player.multipleVideos}\n`;
                    text += `player: ${player.player.objectName}\n`;
                    text += `mediaStatus: ${player.player.mediaStatus}\n`;
                    text += `player1 media status: [${player.player1.mediaStatus}] ${p1MediaStatusName}\n`;
                    text += `player2 media status: [${player.player2.mediaStatus}] ${p2MediaStatusName}\n`;
                    text += `player1 prebuffer: pending=${player.player1.prebufferPending} ready=${player.player1.prebufferReady} readyPos=${player.player1.prebufferReadyPosition}\n`;
                    text += `player1 prebuffer target: ${player.player1.prebufferTargetFilename || "<none>"}\n`;
                    text += `player2 prebuffer: pending=${player.player2.prebufferPending} ready=${player.player2.prebufferReady} readyPos=${player.player2.prebufferReadyPosition}\n`;
                    text += `player2 prebuffer target: ${player.player2.prebufferTargetFilename || "<none>"}\n`;
                    text += `player1 playing: ${player.player1.playing}\n`;
                    text += `player2 playing: ${player.player2.playing}\n`;
                    text += `position: ${player.player.position}\n`;
                    text += `duration: ${player.player.duration}\n`;
                    text += `resumeLastVideo: ${player.resumeLastVideo}\n`;
                    text += `screenOffPausesVideo: ${main.screenOffPausesVideo} off ${main.screenIsOff}\n`;
                    text += `pauseBattery: below ${main.pauseBatteryLevel}% ${main.pauseBattery}\n`;
                    text += `playing: ${main.playing}\n`;
                    text += `inLockScreen: ${main.lockScreenMode}\n`;
                    text += `screenLocked: ${main.screenLocked}\n`;
                    text += `showBlur: ${main.showBlur}\n`;
                    text += `id: ${Plasmoid.id}`;
                    return text;
                }
            }
        }
    }

    function play() {
        pauseTimer.stop();
        playTimer.start();
    }
    function pause() {
        if (playing)
            return;
        playTimer.stop();
        pauseTimer.start();
    }
    function stop() {
        player.stop();
    }

    function updateState() {
        if (playing) {
            main.pause();
            main.play();
        } else {
            main.play();
            main.pause();
        }
    }

    Timer {
        id: pauseTimer
        interval: showBlur ? blurAnimationDuration : 10
        onTriggered: {
            player.pause();
        }
    }

    // Fixes video playing between active window changes
    Timer {
        id: playTimer
        interval: 10
        onTriggered: {
            player.play();
        }
    }

    Timer {
        id: startTimer
        interval: 100
        onTriggered: {
            isLoading = false;
            if (debugEnabled)
                Utils.dumpProps(main.configuration);
            updateState();
        }
    }

    function printLog(msg) {
        if (debugEnabled) {
            console.log(main.pluginName, msg);
        }
    }

    Timer {
        id: debugTimer
        running: debugEnabled
        repeat: true
        interval: 2000
        onTriggered: {
            printLog("------------------------");
            printLog("Videos: '" + JSON.stringify(videosConfig) + "'");
            printLog("Pause Battery: " + pauseBatteryLevel + "% " + pauseBattery);
            printLog("Pause Screen Off: " + screenOffPausesVideo + " Off: " + screenIsOff);
            printLog("Windows: " + main.shouldPlay + " Blur: " + main.showBlur);
            printLog("Video playing: " + playing + " Blur: " + showBlur);
        }
    }

    Component.onCompleted: {
        startTimer.start();
        Qt.callLater(() => {
            player.currentSource = Qt.binding(() => {
                return main.currentSource;
            });
            player.nextSource = Qt.binding(() => {
                return main.nextSource;
            });
        });
        updateNextSource();
    }

    function save() {
        // Save last video and position to resume from it on next login/lock
        main.configuration.LastVideo = main.currentSource.filename;
        main.configuration.LastVideoPosition = player.lastVideoPosition;
        main.configuration.writeConfig();
        printLog("Bye!");
    }

    Connections {
        target: Qt.application
        function onAboutToQuit() {
            main.save();
        }
    }
    Item {
        onWindowChanged: window => {
            if (!window)
                return;
            // https://github.com/KDE/plasma-desktop/blob/Plasma/6.3/desktoppackage/contents/views/Desktop.qml
            // https://github.com/KDE/plasma-desktop/blob/Plasma/6.3/desktoppackage/contents/lockscreen/LockScreen.qml
            main.lockScreenMode = "source" in window && window.source.toString().endsWith("LockScreen.qml");
        }
    }

    property int playbackOverride: Enum.PlaybackOverride.Default
    property int muteOverride: Enum.MuteOverride.Default

    contextualActions: [
        PlasmaCore.Action {
            text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Next Video")
            icon.name: "media-skip-forward"
            onTriggered: {
                player.next(true, true);
            }
            visible: player.multipleVideos
        },
        PlasmaCore.Action {
            text: {
                if (main.playbackOverride === Enum.PlaybackOverride.Play) {
                    return i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Pause");
                } else if (main.playbackOverride === Enum.PlaybackOverride.Pause) {
                    return i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Default");
                } else {
                    return i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Play");
                }
            }
            icon.name: main.playing ? "media-playback-start" : "media-playback-pause"
            onTriggered: main.playbackOverride = (main.playbackOverride + 1) % 3
        },
        PlasmaCore.Action {
            text: {
                if (main.muteOverride === Enum.MuteOverride.Mute) {
                    return i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Unmute");
                } else if (main.muteOverride === Enum.MuteOverride.Unmute) {
                    return i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Default");
                } else {
                    return i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Mute");
                }
            }
            icon.name: main.muteAudio ? "audio-volume-muted" : "audio-volume-high"
            onTriggered: main.muteOverride = (main.muteOverride + 1) % 3
        }
    ]
}

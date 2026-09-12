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
import QtMultimedia
import Qt5Compat.GraphicalEffects
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid
import "code/utils.js" as Utils
import "code/enum.js" as Enum

WallpaperItem {
    id: main
    anchors.fill: parent
    property bool isLoading: true
    property string videoUrls: main.configuration.VideoUrls
    property list<var> videosConfig: []

    property int videosCount: videosConfig.length || 0
    property bool hasVideos: videosCount > 0
    property bool videoUpdatePending: false
    property int currentVideoIndex: 0
    property string lastSelectedVideo: ""
    property bool resumeLastVideo: main.configuration.ResumeLastVideo
    property alias dayNightPhase: dayNightCycleController.currentPhase
    property bool dayNightPhaseHasChanged: false
    property var currentSource: {
        if (dayNightPhaseHasChanged) {
            let video = Utils.createVideo();
            if (isLoading) {
                return video;
            }
            if (resumeLastVideo) {
                video = Utils.getLastVideo(dayNightCycleEnabled, dayNightPhase, main.configuration, videosConfig);
            }
            if (!video.filename) {
                video = Utils.getVideoByFile(lastSelectedVideo, videosConfig);
            }
            // fall back to the first video of the new list
            return video.filename ? video : Utils.getVideoByIndex(0, videosConfig);
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
        return ((shouldPlay && !batteryPausesVideo && !screenLocked && !screenIsOff && !effectPauseVideo && isCurrentActivity) || effectPlayVideo) && hasVideos;
    }
    property bool shouldBlur: {
        if (!hasVideos) {
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
    property bool isCurrentActivity: {
        // lock and login screens have no activity
        if (Plasmoid.activity === undefined) {
            return true;
        }
        return Plasmoid.activity === windowModel.currentActivity;
    }
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
    property bool dayNightCycleEnabled: main.configuration.DayNightCycleMode !== Enum.DayNightCycleMode.Disabled
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
        filterByScreen: main.configuration.CheckWindowsActiveScreen
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

    DayNightCycleController {
        id: dayNightCycleController
        mode: main.configuration.DayNightCycleMode
        sunriseTime: main.configuration.DayNightCycleSunriseTime
        sunsetTime: main.configuration.DayNightCycleSunsetTime
        transitionDuration: main.configuration.DayNightCycleTransitionDuration
        onCurrentPhaseChanged: {
            main.dayNightPhaseHasChanged = true;
        }
        darkLightScheduleState: main.configuration.DarkLightScheduleState
        onDarkLightScheduleStateChanged: {
            if (main.configuration.DarkLightScheduleState != dayNightCycleController.darkLightScheduleState) {
                main.configuration.DarkLightScheduleState = dayNightCycleController.darkLightScheduleState;
                main.configuration.writeConfig();
            }
        }
    }

    function setNextSource() {
        printLog("- Prev " + currentVideoIndex + ": " + currentSource.filename);
        currentVideoIndex = (currentVideoIndex + 1) % videosConfig.length;
        printLog("- Next " + currentVideoIndex + ": " + currentSource.filename);
    }

    function skipNext() {
        player.player.ending = true;
        setNextSource();
    }

    function nextVideo(forceSwitch) {
        if (main.changeWallpaperMode === Enum.ChangeWallpaperMode.Never || currentSource.loop || main.videosConfig.length === 1) {
            player.player.ending = true;
            player.loadVideo();
        } else {
            setNextSource();
        }
    }
    // qmlformat off
    property int changeWallpaperTimerMs: {
        return ((main.changeWallpaperTimerHours * 60 * 60)
        + (main.changeWallpaperTimerMinutes * 60)
        + main.changeWallpaperTimerSeconds) * 1000
    }
    // qmlformat on

    PausableTimer {
        id: changeTimer
        running: main.changeWallpaperMode === Enum.ChangeWallpaperMode.OnATimer && player.player.playing && !main.currentSource.loop
        interval: main.changeWallpaperTimerMs
        repeat: true
        useNewIntervalImmediately: true
        onTriggered: {
            printLog("Timer triggered, changing wallpaper");
            main.skipNext();
        }
        onIntervalChanged: {
            printLog("Timer changed:", interval);
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: !main.hasVideos ? Kirigami.Theme.backgroundColor : main.configuration.BackgroundColor

        FadePlayer {
            id: player
            anchors.fill: parent
            muted: main.muteAudio
            lastVideoPosition: main.configuration.LastVideoPosition
            visible: main.videosConfig.length !== 0
            onSetNextSource: {
                printLog("main.player.onSetNextSource");
                main.nextVideo();
            }
            crossfadeEnabled: main.crossfadeEnabled
            multipleVideos: main.videosConfig.length > 1
            targetCrossfadeDuration: main.configuration.CrossfadeDuration
            debugEnabled: main.debugEnabled
            changeWallpaperMode: main.changeWallpaperMode
            fillMode: main.configuration.FillMode
            fillBlur: main.configuration.FillBlur && !main.batteryDisablesBlur
            fillBlurRadius: main.configuration.FillBlurRadius
            globalVolume: main.volume
            globalPlaybackRate: main.playbackRate
            useAlternativePlaybackRate: main.useAlternativePlaybackRate
            alternativePlaybackRateGlobal: main.configuration.AlternativePlaybackRate
            resumeLastVideo: main.configuration.ResumeLastVideo
            audioOutputDevice: main.configuration.AudioOutputDevice
            shouldPlay: main.playing
            audioFadeInOutDuration: main.configuration.AudioFadeInOutDuration * 1000
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
        visible: !main.hasVideos
        anchors.centerIn: parent
        width: parent.width - Kirigami.Units.gridUnit * 2
        iconName: "video-symbolic"
        text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "No video source \n" + main.videoUrls)
    }

    Component {
        id: debugOverlay
        Item {
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
                        let text = `player.filename: ${player.player.playerSource.filename}\n`;
                        text += `main.currentSource.filename: ${main.currentSource.filename}\n`;
                        text += `videos:\n${main.videosConfig.map(v => {
                            const filenameParts = v.filename.split("/");
                            return filenameParts[filenameParts.length - 1];
                        }).join("\n")}\n`;
                        text += `last: ${main.configuration.LastVideo}\n`;
                        text += `lastSunrise: ${main.configuration.LastVideoSunrise}\n`;
                        text += `lastDay: ${main.configuration.LastVideoDay}\n`;
                        text += `lastSunset: ${main.configuration.LastVideoSunset}\n`;
                        text += `lastNight: ${main.configuration.LastVideoNight}\n`;
                        text += `source.loop: ${main.currentSource.loop ?? false}\n`;
                        text += `player.loops: ${player.loops === MediaPlayer.Infinite}\n`;
                        text += `player.depth: ${player.depth}\n`;
                        text += `currentVideoIndex: ${main.currentVideoIndex}\n`;
                        text += `changeWallpaperMode: ${["Never", "Slideshow", `OnATimer time: ${changeTimer.interval}`][main.changeWallpaperMode]}\n`;
                        text += `crossfade: ${player.player.crossfadeEnabled}\n`;
                        text += `crossfadeDuration: ${player.targetCrossfadeDuration} current: ${player.player.crossfadeDuration}\n`;
                        text += `multipleVideos: ${player.multipleVideos}\n`;
                        text += `mediaStatus: ${["NoMedia", "LoadingMedia", "LoadedMedia", "StalledMedia", "BufferingMedia", "BufferedMedia", "EndOfMedia", "InvalidMedia"][player.player.mediaStatus]}\n`;
                        text += `shouldPlay: ${main.shouldPlay}\n`;
                        text += `playing: ${player.player.playing}\n`;
                        text += `position: ${player.player.position}\n`;
                        text += `duration: ${player.player.duration}\n`;
                        text += `playbackRate: ${player.player.playbackRate.toFixed(2)}\n`;
                        text += `useAlternativePlaybackRate: ${player.useAlternativePlaybackRate}\n`;
                        text += `resumeLastVideo: ${player.resumeLastVideo}\n`;
                        text += `screenOffPausesVideo: ${main.screenOffPausesVideo} off ${main.screenIsOff}\n`;
                        text += `pauseBattery: below ${main.pauseBatteryLevel}% ${main.pauseBattery}\n`;
                        text += `inLockScreen: ${main.lockScreenMode}\n`;
                        text += `screenLocked: ${main.screenLocked}\n`;
                        text += `showBlur: ${main.showBlur}\n`;
                        text += `dayNightPhase: ${main.dayNightPhase} (${["night", "sunrise", "day", "sunset", "unknown"][main.dayNightPhase]})\n`;
                        text += `dayNightCycleMode: ${["disabled", "dayNightCycle", "time", "plasmaStyle", "alwaysDay", "alwaysNight"][main.configuration.DayNightCycleMode]}\n`;
                        text += `id: ${Plasmoid.id}\n`;
                        text += `volume: ${player.player.volume.toFixed(2)}\n`;
                        text += `audioFadeInOutDuration: ${player.player.audioFadeInOutDuration}\n`;
                        text += `currentAudioDevice: ${player.player.currentAudioDevice}`;
                        return text;
                    }
                }
            }
        }
    }
    Loader {
        sourceComponent: debugOverlay
        active: main.debugEnabled
    }

    Timer {
        id: startTimer
        interval: 100
        onTriggered: {
            main.isLoading = false;
            if (main.debugEnabled)
                Utils.dumpProps(main.configuration);
        }
    }

    function printLog(msg) {
        if (debugEnabled) {
            console.log(main.pluginName, msg);
        }
    }

    function saveLastSource(filename, dayNightPhase) {
        if (filename === "") {
            return;
        }

        main.configuration.LastVideo = filename;
        if (dayNightCycleEnabled) {
            switch (dayNightPhase) {
            case Enum.DayNightPhase.Day:
                main.configuration.LastVideoDay = filename;
                break;
            case Enum.DayNightPhase.Night:
                main.configuration.LastVideoNight = filename;
                break;
            case Enum.DayNightPhase.Sunrise:
                main.configuration.LastVideoSunrise = filename;
                break;
            case Enum.DayNightPhase.Sunset:
                main.configuration.LastVideoSunset = filename;
                break;
            }
        }
    }

    function logPauseBattery() {
        printLog("Pause Battery: " + pauseBatteryLevel + "% " + pauseBattery);
    }

    function logPauseScreenOff() {
        printLog("Pause Screen Off: " + screenOffPausesVideo + " Off: " + screenIsOff);
    }

    function logShouldPlay() {
        printLog("Should Play: " + main.shouldPlay);
    }

    onPauseBatteryChanged: logPauseBattery()
    onPauseBatteryLevelChanged: logPauseBattery()
    onScreenOffPausesVideoChanged: logPauseScreenOff()
    onScreenIsOffChanged: logPauseScreenOff()
    onVideosConfigChanged: {
        if (isLoading) {
            return;
        }
        if (!dayNightPhaseHasChanged && Utils.getVideoByFile(currentSource.filename, videosConfig).filename === "") {
            printLog("main.videosConfig changed, currentSource no longer exists, skipping to next video");
            main.skipNext();
        }
        printLog("Videos: '" + JSON.stringify(videosConfig) + "'");
    }
    onShouldPlayChanged: logShouldPlay()
    onPlayingChanged: printLog("Video playing: " + playing)
    onShowBlurChanged: printLog("Blur: " + showBlur)
    onCurrentSourceChanged: {
        Qt.callLater(() => {
            const filename = main.currentSource.filename;
            if (!filename) {
                return;
            }
            // reset index for the current set of videos
            const index = Utils.getVideoIndex(filename, main.videosConfig);
            if (index !== -1) {
                main.currentVideoIndex = index;
            }
            main.lastSelectedVideo = filename;
            dayNightPhaseHasChanged = false;
            main.saveLastSource(filename, main.dayNightPhase);
        });
    }
    function updateVideosConfig() {
        const videos = Utils.getVideos(dayNightCycleEnabled, dayNightPhase, videoUrls);
        if (randomMode) {
            Utils.shuffleArray(videos);
        }
        videosConfig = videos;
    }

    onDayNightCycleEnabledChanged: {
        Qt.callLater(updateVideosConfig);
    }
    onDayNightPhaseChanged: {
        Qt.callLater(updateVideosConfig);
        printLog("DayNight phase changed: " + dayNightPhase);
    }
    onVideoUrlsChanged: {
        Qt.callLater(updateVideosConfig);
    }
    onRandomModeChanged: {
        Qt.callLater(updateVideosConfig);
        printLog("Random mode changed: " + main.randomMode);
    }

    Component.onCompleted: {
        startTimer.start();
        Qt.callLater(updateVideosConfig);
        Qt.callLater(() => {
            player.currentSource = Qt.binding(() => {
                return main.currentSource;
            });
        });
    }

    Connections {
        target: Qt.application
        function onAboutToQuit() {
            main.configuration.LastVideoPosition = player.player.position;
            main.configuration.writeConfig();
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
                main.skipNext();
            }
            visible: player.multipleVideos
        },
        PlasmaCore.Action {
            text: {
                if (main.playbackOverride === Enum.PlaybackOverride.Default) {
                    return main.playing ? i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Pause") : i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Play");
                } else {
                    return i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Default Playback");
                }
            }
            icon.name: {
                if (main.playbackOverride === Enum.PlaybackOverride.Default) {
                    return main.playing ? "media-playback-pause" : "media-playback-start";
                } else {
                    return "view-refresh";
                }
            }
            onTriggered: {
                if (main.playbackOverride === Enum.PlaybackOverride.Default) {
                    main.playbackOverride = main.playing ? Enum.PlaybackOverride.Pause : Enum.PlaybackOverride.Play;
                } else {
                    main.playbackOverride = Enum.PlaybackOverride.Default;
                }
            }
        },
        PlasmaCore.Action {
            text: {
                if (main.muteOverride === Enum.MuteOverride.Default) {
                    return main.muteAudio ? i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Unmute") : i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Mute");
                } else {
                    return i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Default Muting");
                }
            }
            icon.name: {
                if (main.muteOverride === Enum.MuteOverride.Default) {
                    return main.muteAudio ? "audio-volume-high" : "audio-volume-muted";
                } else {
                    return "view-refresh";
                }
            }
            onTriggered: {
                if (main.muteOverride === Enum.MuteOverride.Default) {
                    main.muteOverride = main.muteAudio ? Enum.MuteOverride.Unmute : Enum.MuteOverride.Mute;
                } else {
                    main.muteOverride = Enum.MuteOverride.Default;
                }
            }
        }
    ]
}

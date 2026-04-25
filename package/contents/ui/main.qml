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
import Qt5Compat.GraphicalEffects
import QtMultimedia
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
    property var videosConfig: {
        let videos = Utils.getVideos(dayNightCycleEnabled, isDay, videoUrls);
        if (randomMode && videos.length > 1) {
            Utils.shuffleArray(videos);
        }
        return videos;
    }

    property int videosCount: videosConfig.length || 0
    property bool hasVideos: videosCount > 0
    property bool videoUpdatePending: false
    property int currentVideoIndex: 0
    property string lastSelectedVideo: ""
    property bool resumeLastVideo: main.configuration.ResumeLastVideo
    property alias isDay: dayNightCycleController.isDay
    property var currentSource: Utils.createVideo("")
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
        return ((shouldPlay && !batteryPausesVideo && !screenLocked && !screenIsOff && !effectPauseVideo) || effectPlayVideo) && hasVideos && !isLoading;
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

    function setCurrentIndex() {
        if (!hasVideos) {
            currentVideoIndex = 0;
            return;
        }

        let preferredIndex = -1;

        if (resumeLastVideo) {
            preferredIndex = Utils.getLastVideoIndex(dayNightCycleEnabled, isDay, main.configuration, videosConfig);
        }

        if (preferredIndex === -1) {
            preferredIndex = Utils.getVideoIndex(lastSelectedVideo, videosConfig);
        }

        currentVideoIndex = preferredIndex !== -1 ? preferredIndex : 0;
    }

    function nextVideo() {
        if (!hasVideos) {
            return;
        }
        currentVideoIndex = (currentVideoIndex + 1) % videosCount;
        setCurrentSource();
    }

    function setCurrentSource() {
        if (!hasVideos) {
            stop();
            player.player1.playerSource = Utils.createVideo("");
            player.player2.playerSource = Utils.createVideo("");
            return;
        }
        currentSource = videosConfig[currentVideoIndex] ?? Utils.createVideo("");
        if (player.player.playerSource.filename !== currentSource.filename) {
            player.stop();
            player.player.playerSource = currentSource;
            player.player.position = 0;
            player.otherPlayer.playerSource = Utils.createVideo("");
        }

        if (playing) {
            updateState();
        } else {
            play();
            pauseWhenReady();
        }
    }

    function updateVideo() {
        if (videoUpdatePending || isLoading) {
            return;
        }
        videoUpdatePending = true;
        Qt.callLater(() => {
            videoUpdatePending = false;
            setCurrentIndex();
            setCurrentSource();
        });
    }

    Timer {
        id: updateVideoDebounce
        interval: 50
        onTriggered: main.updateVideo()
    }

    function pauseWhenReady() {
        pauseWhenReadyTimer.attempt = 0;
        pauseWhenReadyTimer.restart();
    }

    Timer {
        id: pauseWhenReadyTimer
        interval: 50
        repeat: true
        property int attempt: 0
        onTriggered: {
            const ready = player.player.mediaStatus === MediaPlayer.LoadedMedia || player.player.mediaStatus === MediaPlayer.BufferedMedia || player.player.position > 0;
            if (ready || attempt >= 20) {
                stop();
                Utils.delay(200, main.pause, main);
                return;
            }
            attempt++;
        }
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

    onPlayingChanged: {
        if (isLoading) {
            return;
        }
        playing ? play() : pause();
    }

    onVideosConfigChanged: {
        updateVideoDebounce.restart();
    }
    onCurrentSourceChanged: {
        if (currentSource.filename !== "") {
            lastSelectedVideo = currentSource.filename;
            main.saveLastSource(main.currentSource.filename, main.isDay);
        }
    }

    DayNightCycleController {
        id: dayNightCycleController
        enabled: main.dayNightCycleEnabled
        mode: main.configuration.DayNightCycleMode
        sunriseTime: main.configuration.DayNightCycleSunriseTime
        sunsetTime: main.configuration.DayNightCycleSunsetTime
        onIsDayChanged: {
            updateVideoDebounce.restart();
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: !main.hasVideos ? Kirigami.Theme.backgroundColor : main.configuration.BackgroundColor

        FadePlayer {
            id: player
            anchors.fill: parent
            currentSource: main.currentSource
            muted: main.muteAudio
            lastVideoPosition: main.configuration.LastVideoPosition
            visible: main.hasVideos
            onSetNextSource: {
                main.nextVideo();
            }
            crossfadeEnabled: main.crossfadeEnabled
            multipleVideos: main.videosCount > 1
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
            audioOutputDevice: main.configuration.AudioOutputDevice
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
                    let text = `filename: ${main.currentSource.filename}\n`;
                    text += `videos:\n${main.videosConfig.map(v => {
                        const filenameParts = v.filename.split("/");
                        return filenameParts[filenameParts.length - 1];
                    }).join("\n")}\n\n`;
                    text += `last: ${main.configuration.LastVideo}\n`;
                    text += `lastDay: ${main.configuration.LastVideoDay}\n`;
                    text += `lastNight: ${main.configuration.LastVideoNight}\n`;
                    text += `loops: ${main.currentSource.loop ?? false}\n`;
                    text += `currentVideoIndex: ${main.currentVideoIndex}\n`;
                    text += `changeWallpaperMode: ${main.changeWallpaperMode}\n`;
                    text += `crossfade: ${main.crossfadeEnabled}\n`;
                    text += `crossfadeDuration: ${player.crossfadeDuration} ${player.crossfadeMinDurationLast} ${player.crossfadeMinDurationCurrent}\n`;
                    text += `multipleVideos: ${player.multipleVideos}\n`;
                    text += `player: ${player.player.objectName}\n`;
                    text += `mediaStatus: ${player.player.mediaStatus}\n`;
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
                    text += `Audio Device: ${player.player1.currentAudioDevice}`;
                    text += `isDay: ${main.isDay}\n`;
                    text += `dayNightCycleEnabled: ${main.dayNightCycleEnabled}\n`;
                    text += `dayNightCycleMode: ${main.configuration.DayNightCycleMode}\n`;
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
            pause();
            play();
        } else {
            play();
            pause();
        }
    }

    Timer {
        id: pauseTimer
        interval: main.showBlur ? main.blurAnimationDuration : 10
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

    Component.onCompleted: {
        Utils.delay(100, () => {
            isLoading = false;
            updateVideoDebounce.restart();
        }, main);
    }

    function printLog(msg) {
        if (debugEnabled) {
            console.log(main.pluginName, msg);
        }
    }

    Timer {
        id: debugTimer
        running: main.debugEnabled
        repeat: true
        interval: 2000
        onTriggered: {
            main.printLog("------------------------");
            main.printLog("Videos: '" + JSON.stringify(main.videosConfig) + "'");
            main.printLog("Pause Battery: " + main.pauseBatteryLevel + "% " + main.pauseBattery);
            main.printLog("Pause Screen Off: " + main.screenOffPausesVideo + " Off: " + main.screenIsOff);
            main.printLog("Windows: " + main.shouldPlay + " Blur: " + main.showBlur);
            main.printLog("Video playing: " + main.playing + " Blur: " + main.showBlur);
        }
    }

    function saveLastSource(filename, cycleIsDay) {
        if (filename === "") {
            return;
        }

        main.configuration.LastVideo = filename;
        if (dayNightCycleEnabled) {
            if (cycleIsDay) {
                main.configuration.LastVideoDay = filename;
            } else {
                main.configuration.LastVideoNight = filename;
            }
        }
    }

    function saveLastPosition() {
        const currentFilename = currentSource.filename || lastSelectedVideo;
        if (currentFilename === "") {
            return;
        }

        main.configuration.LastVideoPosition = player.lastVideoPosition;
    }

    Connections {
        target: Qt.application
        function onAboutToQuit() {
            main.saveLastSource(main.currentSource.filename || main.lastSelectedVideo, main.isDay);
            main.saveLastPosition();
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
                player.next(true, true);
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

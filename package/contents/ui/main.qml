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
        return (shouldPlay && !batteryPausesVideo && !screenLocked && !screenIsOff && !effectPauseVideo) || effectPlayVideo;
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
    property bool effectHideBlur: effectsHideBlur.some(item => activeEffects.includes(item))
    property bool effectShowBlur: effectsShowBlur.some(item => activeEffects.includes(item))

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
    property int changeWallpaperTimerMinutes: main.configuration.ChangeWallpaperTimerMinutes
    property int changeWallpaperTimerHours: main.configuration.ChangeWallpaperTimerHours
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

    function getVideos() {
        return Utils.parseCompat(videoUrls).filter(video => video.enabled);
    }

    onPlayingChanged: {
        playing && !isLoading ? main.play() : main.pause();
    }
    onVideoUrlsChanged: {
        if (isLoading)
            return;
        videosConfig = getVideos();
        // console.error(videoUrls);
        if (videosConfig.length == 0) {
            main.stop();
            main.currentSource.filename = "";
        } else {
            player.play();
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
    }

    EffectsModel {
        id: effectsModel
        monitorActive: {
            return [main.effectsPlayVideo, main.effectsPauseVideo, main.effectsShowBlur, main.effectsHideBlur].some(arr => arr.length > 0);
        }
    }

    function nextVideo() {
        printLog("- Video ended " + currentVideoIndex + ": " + currentSource.filename);
        currentVideoIndex = (currentVideoIndex + 1) % videosConfig.length;
        if (randomMode && currentVideoIndex === 0) {
            const shuffledVideos = Utils.shuffleArray(videosConfig);
            currentSource = shuffledVideos[currentVideoIndex];
        } else {
            currentSource = videosConfig[currentVideoIndex];
        }
        printLog("- Next " + currentVideoIndex + ": " + currentSource.filename);
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
            onSetNextSource: {
                main.nextVideo();
            }
            crossfadeEnabled: main.crossfadeEnabled
            multipleVideos: main.videosConfig.length > 1
            targetCrossfadeDuration: main.configuration.CrossfadeDuration
            debugEnabled: main.debugEnabled
            changeWallpaperMode: main.changeWallpaperMode
            changeWallpaperTimerMinutes: main.changeWallpaperTimerMinutes
            changeWallpaperTimerHours: main.changeWallpaperTimerHours
            fillMode: main.configuration.FillMode
            volume: main.volume
            playbackRate: main.playbackRate
            resumeLastVideo: main.configuration.ResumeLastVideo
        }

        FastBlur {
            source: player
            radius: main.showBlur ? main.configuration.BlurRadius : 0
            visible: radius !== 0
            anchors.fill: parent
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
            text: i18n("No video source \n" + main.videoUrls)
        }

        ColumnLayout {
            id: root
            visible: main.debugEnabled
            Item {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 100
            }
            Kirigami.AbstractCard {
                Layout.margins: Kirigami.Units.largeSpacing
                contentItem: ColumnLayout {
                    id: content
                    PlasmaComponents.Label {
                        text: main.currentSource.filename
                    }
                    PlasmaComponents.Label {
                        text: "currentVideoIndex " + main.currentVideoIndex
                    }
                    PlasmaComponents.Label {
                        text: "changeWallpaperMode " + main.changeWallpaperMode
                    }
                    PlasmaComponents.Label {
                        text: "crossfade " + main.crossfadeEnabled
                    }
                    PlasmaComponents.Label {
                        text: "crossfadeDuration " + player.crossfadeDuration + " (" + player.crossfadeMinDurationLast + ", " + player.crossfadeMinDurationCurrent + ")"
                    }
                    PlasmaComponents.Label {
                        text: "multipleVideos " + player.multipleVideos
                    }
                    PlasmaComponents.Label {
                        text: "player " + player.player.objectName
                    }
                    PlasmaComponents.Label {
                        text: "media status " + player.player.mediaStatus
                    }
                    PlasmaComponents.Label {
                        text: "player1 playing " + player.player1.playing
                    }
                    PlasmaComponents.Label {
                        text: "player2 playing " + player.player2.playing
                    }
                    PlasmaComponents.Label {
                        text: "position " + player.player.position
                    }
                    PlasmaComponents.Label {
                        text: "duration " + player.player.duration
                    }
                    PlasmaComponents.Label {
                        text: "resumeLastVideo" + player.resumeLastVideo
                    }
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
        });
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
            text: i18n("Next Video")
            icon.name: "media-skip-forward"
            onTriggered: {
                player.next(true, true);
            }
            visible: player.multipleVideos
        },
        PlasmaCore.Action {
            text: {
                if (main.playbackOverride === Enum.PlaybackOverride.Play) {
                    return i18n("Pause");
                } else if (main.playbackOverride === Enum.PlaybackOverride.Pause) {
                    return i18n("Default");
                } else {
                    return i18n("Play");
                }
            }
            icon.name: main.playing ? "media-playback-start" : "media-playback-pause"
            onTriggered: main.playbackOverride = (main.playbackOverride + 1) % 3
        },
        PlasmaCore.Action {
            text: {
                if (main.muteOverride === Enum.MuteOverride.Mute) {
                    return i18n("Unmute");
                } else if (main.muteOverride === Enum.MuteOverride.Unmute) {
                    return i18n("Default");
                } else {
                    return i18n("Mute");
                }
            }
            icon.name: main.muteAudio ? "audio-volume-muted" : "audio-volume-high"
            onTriggered: main.muteOverride = (main.muteOverride + 1) % 3
        }
    ]
}

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
import QtMultimedia
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid
import Qt5Compat.GraphicalEffects
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import "code/utils.js" as Utils
import "code/enum.js" as Enum

WallpaperItem {
    anchors.fill: parent
    id: main
    property bool isLoading: true
    property string videoUrls: main.configuration.VideoUrls
    property var videosConfig: Utils.parseCompat(videoUrls)
    property int currentVideoIndex: main.configuration.LastVideoIndex < videosConfig.length ? main.configuration.LastVideoIndex : 0
    property var currentSource: videosConfig.length > 0 ? videosConfig[currentVideoIndex] : Utils.createVideo("")
    property int pauseBatteryLevel: main.configuration.PauseBatteryLevel
    property bool shouldPlay: {
        if (lockScreenMode) {
            return true
        }

        if (playbackOverride === Enum.PlaybackOverride.Play) {
            return true
        } else if (playbackOverride === Enum.PlaybackOverride.Pause) {
            return false
        }

        let play = false
        switch(main.configuration.PauseMode) {
            case 0:
                play = !windowModel.maximizedExists
                break
            case 1:
                play = !windowModel.activeExists
                break
            case 2:
                play = !windowModel.visibleExists
                break
            case 3:
                play = true
        }
        return play
    }
    property bool playing: {
        return (shouldPlay && !batteryPausesVideo && !screenLocked && !screenIsOff && !effectPauseVideo) || effectPlayVideo
    }
    property bool shouldBlur: {
        let blur = false
        switch(main.configuration.BlurMode) {
            case 0:
                blur = windowModel.maximizedExists
                break
            case 1:
                blur = windowModel.activeExists
                break
            case 2:
                blur = windowModel.visibleExists
                break
            case 3:
                blur = !main.playing
                break
            case 4:
                blur = true
                break
            case 5:
                blur = false
        }
        return blur
    }
    property bool showBlur: (shouldBlur && !batteryDisablesBlur && !effectHideBlur) || effectShowBlur
    property bool screenLocked: screenModel.screenIsLocked
    property bool batteryPausesVideo: pauseBattery && main.configuration.BatteryPausesVideo
    property bool batteryDisablesBlur: pauseBattery && main.configuration.BatteryDisablesBlur

    property bool screenIsOff: screenModel.screenIsOff
    property bool screenOffPausesVideo: main.configuration.ScreenOffPausesVideo
    property bool lockScreenMode: false
    property bool debugEnabled : main.configuration.DebugEnabled

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
    // Crossfade must not be longer than the shortest video or the fade becomes glitchy
    // we don't know the length until a video gets played, so the crossfade duration
    // will decrease below the configured duration if needed as videos get played
    property int crossfadeMinDuration: parseInt(Math.max(Math.min(player1.actualDuration, player2.actualDuration) / 3, 1) )
    property int crossfadeDuration: Math.min(main.configuration.CrossfadeDuration, crossfadeMinDuration)
    property bool crossfadeEnabled: main.configuration.CrossfadeEnabled
    property bool tick: true
    property real playbackRate: main.configuration.PlaybackRate
    property real volume: main.configuration.Volume
    property real volumeOutput2: 0
    property bool randomMode: main.configuration.RandomMode
    property int lastVideoPosition: main.configuration.LastVideoPosition
    property bool restoreLastPosition: true
    property bool muteAudio: {

        if (muteOverride === Enum.MuteOverride.Mute) {
            return true
        } else if (muteOverride === Enum.MuteOverride.Unmute) {
            return false
        }

        let mute = false
        switch(main.configuration.MuteMode) {
            case 0:
                mute = windowModel.maximizedExists
                break
            case 1:
                mute = windowModel.activeExists
                break
            case 2:
                mute = windowModel.visibleExists
                break
            // case 3:
            //  TODO other application playing audio
            //  break
            case 4:
                mute = false
                break
            case 5:
                mute = true
        }
        return mute
    }

    function getVideos() {
        let videos = Utils.parseCompat(videoUrls).filter(video => video.enabled)
        return videos
    }

    onPlayingChanged: {
        playing && !isLoading ? main.play() : main.pause()
    }
    onVideoUrlsChanged: {
        videosConfig = getVideos()
        if (isLoading) return
        // console.error(videoUrls);
        if (videosConfig.length == 0) {
            main.stop()
            main.currentSource.filename = ""
        } else {
            nextVideo()
            tick = true
            player2.pause()
            videoOutput.opacity = 1
            player1.playerSource = currentSource
            player1.play()
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
        let result = false
        if (pmSource.data.Battery["Has Cumulative"] && pmSource.data["Battery"]["State"] === "Discharging") {
            result = pauseBatteryLevel > pmSource.data.Battery.Percent
        }
        return result
    }

    TasksModel {
        id: windowModel
        screenGeometry: main.parent.screenGeometry
    }

    ScreenModel {
        id: screenModel
        checkScreenLock: !lockScreenMode
        checkScreenState: screenOffPausesVideo
    }

    EffectsModel {
        id: effectsModel
        active: {
            return [
                effectsPlayVideo, effectsPauseVideo,
                effectsShowBlur, effectsHideBlur
            ].some(arr => arr.length > 0)
        }
    }

    function nextVideo() {
        printLog("- Video ended " + currentVideoIndex + ": " + currentSource.filename)
        currentVideoIndex = (currentVideoIndex + 1) % videosConfig.length
        if (randomMode && currentVideoIndex === 0) {
            const shuffledVideos = Utils.shuffleArray(videosConfig)
            currentSource = shuffledVideos[currentVideoIndex]
        } else {
            currentSource = videosConfig[currentVideoIndex]
        }
        printLog("- Next " + currentVideoIndex + ": " + currentSource.filename)
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: videosConfig.length == 0 ?
            Kirigami.Theme.backgroundColor : main.configuration.BackgroundColor

        VideoOutput {
            id: videoOutput
            fillMode: main.configuration.FillMode
            anchors.fill: parent
            z: 2
            opacity: 1
            Behavior on opacity {
                NumberAnimation {
                    duration: crossfadeDuration
                }
            }
        }

        AudioOutput {
            id: audioOutput
            muted: main.muteAudio
            volume: videoOutput.opacity * main.volume
        }

        VideoOutput {
            id: videoOutput2
            fillMode: main.configuration.FillMode
            anchors.fill: parent
            z: 1
        }

        AudioOutput {
            id: audioOutput2
            muted: main.muteAudio
            volume: volumeOutput2 * main.volume
            Behavior on volume {
                NumberAnimation {
                    duration: crossfadeDuration
                }
            }
        }

        MediaPlayer {
            id: player1
            property var playerSource: main.currentSource
            property int actualDuration: duration / playbackRate
            source: playerSource.filename ?? ""
            videoOutput: videoOutput
            audioOutput: audioOutput
            playbackRate: playerSource.playbackRate || main.playbackRate
            loops: (videosConfig.length > 1) ?
                1 : crossfadeEnabled ?
                    1 : MediaPlayer.Infinite
            onPositionChanged: (position) => {
                main.lastVideoPosition = position
                if (!tick) return
                // BUG This doesn't seem to work the first time???
                if ((position / playbackRate) > actualDuration - crossfadeDuration) {
                    if (crossfadeEnabled) {
                        nextVideo()
                        printLog("player1 fading out");
                        videoOutput.opacity = 0
                        tick = false
                        player2.playerSource = currentSource
                        volumeOutput2 = 1
                        player2.play()
                    }
                }
            }
            onMediaStatusChanged: (status) => {
                if (status == MediaPlayer.EndOfMedia) {
                    if (crossfadeEnabled) return
                    nextVideo()
                    playerSource = currentSource
                    play()
                }
                if (status == MediaPlayer.LoadedMedia && player1.seekable) {
                    if (!main.restoreLastPosition) return
                    if (main.lastVideoPosition < player1.duration) {
                        player1.position = main.lastVideoPosition
                    }
                    main.restoreLastPosition = false
                }
            }
            onPlayingChanged: (playing) => {
                if(playing) {
                    if (videoOutput.opacity === 0) {
                        printLog("player1 fading in");
                        videoOutput.opacity = 1
                    }
                    printLog("player1 playing");
                }
            }
        }

        MediaPlayer {
            id: player2
            property var playerSource: main.currentSource
            property int actualDuration: duration / playbackRate
            source: playerSource.filename ?? ""
            videoOutput: videoOutput2
            audioOutput: audioOutput2
            playbackRate: playerSource.playbackRate || main.playbackRate
            loops: 1
            onPositionChanged: (position) => {
                main.lastVideoPosition = position
                if (tick) return
                if ((position / playbackRate) > actualDuration - crossfadeDuration) {
                    printLog("player1 fading in");
                    videoOutput.opacity = 1
                    nextVideo()
                    tick = true
                    volumeOutput2 = 0
                    player1.playerSource = currentSource
                    player1.play()
                }
            }
            onPlayingChanged: (playing) => {
                if(playing) printLog("player2 playing");
            }
        }

        PlasmaExtras.PlaceholderMessage {
            visible: videosConfig.length == 0
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit * 2
            iconName: "video-symbolic"
            text: i18n("No video source \n" + main.configuration.VideoUrls);
        }
    }

    FastBlur {
        source: videoOutput
        radius: showBlur ? main.configuration.BlurRadius : 0
        visible: radius !== 0
        opacity: videoOutput.opacity
        z: videoOutput.z
        anchors.fill: parent
        Behavior on radius {
            NumberAnimation {
                duration: blurAnimationDuration
            }
        }
    }

    FastBlur {
        source: videoOutput2
        radius: showBlur ? main.configuration.BlurRadius : 0
        visible: radius !== 0
        opacity: videoOutput2.opacity
        z: videoOutput2.z
        anchors.fill: parent
        Behavior on radius {
            NumberAnimation {
                duration: blurAnimationDuration
            }
        }
    }

    function play(){
        pauseTimer.stop();
        playTimer.start();
    }
    function pause(){
        if (playing) return
        playTimer.stop()
        pauseTimer.start();
    }
    function stop() {
        player1.stop()
        player2.stop()
    }

    function updateState() {
        if (playing) {
            main.pause()
            main.play()
        } else {
            main.play()
            main.pause()
        }
    }

    Timer {
        id: pauseTimer
        interval: showBlur ? blurAnimationDuration : 10
        onTriggered: {
            player1.pause()
            player2.pause()
        }
    }

    // Fixes video playing between active window changes
    Timer {
        id: playTimer
        interval: 10
        onTriggered: {
            player1.play()
            player2.play()
        }
    }

    Timer {
        id: startTimer
        interval: 100
        onTriggered: {
            isLoading = false
            if (debugEnabled) Utils.dumpProps(main.configuration)
            updateState()
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
            printLog("Player1 duration: " + player1.duration);
            printLog("Player2 duration: " + player2.duration);
            printLog("Crossfade max duration: " + crossfadeMinDuration);
            printLog("Crossfade actual duration: " + crossfadeDuration);
            printLog("------------------------")
            printLog("Videos: '" + JSON.stringify(videosConfig)+"'")
            printLog("Pause Battery: " + pauseBatteryLevel + "% " + pauseBattery)
            printLog("Pause Screen Off: " + screenOffPausesVideo + " Off: " + screenIsOff)
            printLog("Windows: " + main.shouldPlay + " Blur: " + main.showBlur)
            printLog("Video playing: " + playing + " Blur: " + showBlur)
        }
    }

    Component.onCompleted: {
        videosConfig = getVideos()
        startTimer.start()
    }

    function save() {
        // Save last video and position to resume from it on next login/lock
        main.configuration.LastVideoIndex = main.currentVideoIndex
        main.configuration.LastVideoPosition = main.lastVideoPosition
        main.configuration.writeConfig()
        printLog("Bye!")
    }

    Connections {
        target: Qt.application
        function onAboutToQuit() {
            main.save()
        }
    }
    Item {
        onWindowChanged: (window) => {
            if (!window) return
            // https://github.com/KDE/plasma-desktop/blob/Plasma/6.3/desktoppackage/contents/views/Desktop.qml
            // https://github.com/KDE/plasma-desktop/blob/Plasma/6.3/desktoppackage/contents/lockscreen/LockScreen.qml
            main.lockScreenMode = "source" in window && window.source.toString().endsWith("LockScreen.qml")
        }
    }

    property int playbackOverride: Enum.PlaybackOverride.Default
    property int muteOverride: Enum.MuteOverride.Default

    contextualActions: [
        PlasmaCore.Action {
            text: i18n("Next Video")
            icon.name: "media-skip-forward"
            onTriggered: {
                nextVideo()
                tick = true
                player2.pause()
                videoOutput.opacity = 1
                player1.playerSource = currentSource
                player1.play()
            }
        },
        PlasmaCore.Action {
            text: {
                if (main.playbackOverride === Enum.PlaybackOverride.Play) {
                    return i18n("Pause")
                } else if (main.playbackOverride === Enum.PlaybackOverride.Pause) {
                    return i18n("Default")
                } else {
                    return i18n("Play")
                }
            }
            icon.name: main.playing ? "media-playback-start" : "media-playback-pause"
            onTriggered: main.playbackOverride = (main.playbackOverride + 1) % 3
        },
        PlasmaCore.Action {
            text: {
                if (main.muteOverride === Enum.MuteOverride.Mute) {
                    return i18n("Unmute")
                } else if (main.muteOverride === Enum.MuteOverride.Unmute) {
                    return i18n("Default")
                } else {
                    return i18n("Mute")
                }
            }
            icon.name: main.muteAudio ? "audio-volume-muted" : "audio-volume-high"
            onTriggered: main.muteOverride = (main.muteOverride + 1) % 3
        }
    ]
}

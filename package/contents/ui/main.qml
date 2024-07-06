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
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid
import Qt5Compat.GraphicalEffects
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

WallpaperItem {
    anchors.fill: parent
    id: main
    property bool isLoading: true
    property string videoUrls: main.configuration.VideoUrls
    property var videosList: []
    property int currentVideoIndex: 0
    property string currentSource: videosList[currentVideoIndex]
    property int pauseBatteryLevel: main.configuration.PauseBatteryLevel
    property bool playing: (windowModel.playVideoWallpaper && !batteryPausesVideo && !screenLocked && !screenIsOff && !effectPauseVideo) || effectPlayVideo
    property bool showBlur: (windowModel.showBlur && !batteryDisablesBlur && !effectHideBlur) || effectShowBlur
    property bool screenLocked: screenModel.screenIsLocked
    property bool batteryPausesVideo: pauseBattery && main.configuration.BatteryPausesVideo
    property bool batteryDisablesBlur: pauseBattery && main.configuration.BatteryDisablesBlur

    property bool screenIsOff: screenModel.screenIsOff
    property bool screenLockedPausesVideo: main.configuration.ScreenLockedPausesVideo && !lockScreenMode
    property bool screenOffPausesVideo: main.configuration.ScreenOffPausesVideo
    property bool lockScreenMode: main.configuration.LockScreenMode
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
    property int crossfadeMinDuration: parseInt(Math.max(Math.min(player1.duration, player2.duration) / 3, 1) )
    property int crossfadeDuration: Math.min(main.configuration.CrossfadeDuration, crossfadeMinDuration)
    property bool crossfadeEnabled: main.configuration.CrossfadeEnabled
    property bool tick: true
    property real playbackRate: main.configuration.PlaybackRate
    property real volume: main.configuration.Volume
    property real volumeOutput2: 0

    onPlayingChanged: {
        playing && !isLoading ? main.play() : main.pause()
    }
    onVideoUrlsChanged: {
        videosList = videoUrls.trim().split("\n").filter(Boolean)
        if (isLoading) return
        // console.error(videoUrls);
        if (videosList.length == 0) {
            main.stop()
        } else {
            nextVideo()
            tick = true
            player2.pause()
            videoOutput.opacity = 1
            player1.source = currentSource
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

    WindowModel {
        id: windowModel
        screenGeometry: main.parent.screenGeometry
        videoIsPlaying: main.playing
        lockScreenMode: main.lockScreenMode
    }

    ScreenModel {
        id: screenModel
        checkScreenLock: screenLockedPausesVideo
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
        printLog("- Video ended " + currentVideoIndex + ": " + currentSource)
        currentVideoIndex = (currentVideoIndex + 1) % videosList.length
        currentSource = videosList[currentVideoIndex] || ''
        printLog("- Next " + currentVideoIndex + ": " + currentSource)
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: videosList.length == 0 ?
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
            muted: main.configuration.MuteAudio
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
            muted: main.configuration.MuteAudio
            volume: volumeOutput2 * main.volume
            Behavior on volume {
                NumberAnimation {
                    duration: crossfadeDuration
                }
            }
        }

        MediaPlayer {
            id: player1
            source: currentSource
            videoOutput: videoOutput
            audioOutput: audioOutput
            playbackRate: main.playbackRate
            loops: (videosList.length > 1) ?
                1 : crossfadeEnabled ?
                    1 : MediaPlayer.Infinite
            onPositionChanged: (position) => {
                if (!tick) return
                // BUG This doesn't seem to work the first time???
                if (position > duration - crossfadeDuration) {
                    if (crossfadeEnabled) {
                        nextVideo()
                        printLog("player1 fading out");
                        videoOutput.opacity = 0
                        tick = false
                        player2.source = currentSource
                        volumeOutput2 = 1
                        player2.play()
                    }
                }
            }
            onMediaStatusChanged: (status) => {
                if (status == MediaPlayer.EndOfMedia) {
                    if (crossfadeEnabled) return
                    nextVideo()
                    source = currentSource
                    play()
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
            videoOutput: videoOutput2
            audioOutput: audioOutput2
            playbackRate: main.playbackRate
            loops: 1
            onPositionChanged: (position) => {
                if (tick) return
                if (position > duration - crossfadeDuration) {
                    printLog("player1 fading in");
                    videoOutput.opacity = 1
                    nextVideo()
                    tick = true
                    volumeOutput2 = 0
                    player1.source = currentSource
                    player1.play()
                }
            }
            onPlayingChanged: (playing) => {
                if(playing) printLog("player2 playing");
            }
        }

        PlasmaExtras.PlaceholderMessage {
            visible: videosList.length == 0
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit * 2
            iconName: "video-symbolic"
            text: i18n("No video source")
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
        player1.source = ""
        player2.source = ""
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
            if (debugEnabled) dumpProps(main.configuration)
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
            printLog("Videos: '" + videosList+"'")
            printLog("Pause Battery: " + pauseBatteryLevel + "% " + pauseBattery)
            printLog("Pause Locked: " + screenLockedPausesVideo + " Locked: " + screenLocked)
            printLog("Pause Screen Off: " + screenOffPausesVideo + " Off: " + screenIsOff)
            printLog("Windows: " + windowModel.playVideoWallpaper + " Blur: " + windowModel.showBlur)
            printLog("Video playing: " + playing + " Blur: " + showBlur)
        }
    }

    function dumpProps(obj) {
        printLog("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
        for (var k of Object.keys(obj)) {
            const val = obj[k]
            if (typeof val === 'function') continue
            if (k === 'metaData') continue
            printLog(k + "=" + val + "\n")
        }
    }

    Component.onCompleted: {
        videosList = videoUrls.trim().split("\n").filter(Boolean)
        startTimer.start()
    }
}

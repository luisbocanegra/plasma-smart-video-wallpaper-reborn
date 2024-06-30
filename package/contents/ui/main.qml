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
    property var blurItem: null
    property int blurRadius: main.configuration.BlurRadius

    onPlayingChanged: {
        playing && !isLoading ? main.play() : main.pause()
    }
    onVideoUrlsChanged: {
        videosList = videoUrls.trim().split("\n").filter(Boolean)
        if (isLoading) return
        // console.error(videoUrls);
        if (videosList.length == 0) return
        updateState()
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

    Rectangle {
        id: background
        anchors.fill: parent
        color: videosList.length == 0 ?
            Kirigami.Theme.backgroundColor : wallpaper.configuration.BackgroundColor

        VideoOutput {
            id: videoOutput
            fillMode: VideoOutput.PreserveAspectCrop
            anchors.fill: parent
        }

        AudioOutput {
            id: audioOutput
            muted: wallpaper.configuration.MuteAudio
        }

        MediaPlayer {
            id: player
            source: videosList[currentVideoIndex] || ''
            videoOutput: videoOutput
            audioOutput: audioOutput
            loops: (videosList.length > 1) ? 1 : MediaPlayer.Infinite
            // onPositionChanged: (position) => {
            //     if (position == duration) {
            onMediaStatusChanged: (status) => {
                if (status == MediaPlayer.EndOfMedia) {
                    printLog("- Video ended " + currentVideoIndex + ": " + source)
                    currentVideoIndex = (currentVideoIndex + 1) % videosList.length
                    source = videosList[currentVideoIndex] || ''
                    printLog("- Playing " + currentVideoIndex + ": " + source)
                    if (source) play()
                }
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

    function updateBlur() {
        if (showBlur && blurRadius > 0) {
            if (blurItem !== null) return
            blurItem = blurComponent.createObject(main)
        } else {
            if (blurItem !== null) blurItem.radius = 0
        }
    }

    onShowBlurChanged: {
        updateBlur()
    }

    onBlurRadiusChanged: {
        updateBlur()
    }

    property Component blurComponent: FastBlur {
        source: videoOutput
        radius: 0
        anchors.fill: parent

        Component.onCompleted: {
            radius = blurRadius
        }

        onRadiusChanged: {
            if (radius === 0) {
                this.destroy()
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: 300
            }
        }
    }

    function play(){
        pauseTimer.stop();
        player.play();
    }
    function pause(){
        pauseTimer.start();
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
        interval: 300
        onTriggered: {
            player.pause()
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

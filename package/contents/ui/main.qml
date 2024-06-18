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

WallpaperItem {
    anchors.fill: parent
    id: main
    property bool isLoading: true
    property string videoUrls: main.configuration.VideoUrls
    property var videosList: []
    property int currentVideoIndex: 0
    property int pauseBatteryLevel: main.configuration.PauseBatteryLevel
    property bool playing: windowModel.playVideoWallpaper && !batteryPausesVideo && !screenLocked && !screenIsOff
    property bool showBlur: windowModel.showBlur && !batteryDisablesBlur
    property bool screenLocked: screenModel.screenIsLocked
    property bool batteryPausesVideo: pauseBattery && main.configuration.BatteryPausesVideo
    property bool batteryDisablesBlur: pauseBattery && main.configuration.BatteryDisablesBlur

    property bool screenIsOff: screenModel.screenIsOff
    property bool screenLockedPausesVideo: main.configuration.ScreenLockedPausesVideo && !lockScreenMode
    property bool screenOffPausesVideo: main.configuration.ScreenOffPausesVideo
    property bool lockScreenMode: main.configuration.LockScreenMode
    property bool debugEnabled : main.configuration.DebugEnabled

    onPlayingChanged: {
        playing && !isLoading ? main.play() : main.pause()
    }
    onVideoUrlsChanged: {
        videosList = videoUrls.trim().split("\n")
        currentVideoIndex = 0
        if (isLoading) return
        // console.error(videoUrls);
        player.position = player.duration
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

    Rectangle {
        id: background
        anchors.fill: parent
        color: main.configuration.BackgroundColor

        Video {
            id: player
            source: videosList[currentVideoIndex]
            loops: MediaPlayer.Infinite
            fillMode: main.configuration.FillMode
            anchors.fill: parent
            volume: main.configuration.MuteAudio ? 0.0 : 1
            onPositionChanged: {
                if (position == duration) {
                    const lastIndex = currentVideoIndex
                    currentVideoIndex = (currentVideoIndex + 1) % videosList.length
                    source = videosList[currentVideoIndex]
                    play()
                }
            }
        }
    }

    FastBlur {
        source: player
        radius: showBlur ? main.configuration.BlurRadius : 0
        anchors.fill: parent
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
            updateState()
        }
    }

    Component.onCompleted: {
        videosList = videoUrls.trim().split("\n")
        startTimer.start()
    }
}

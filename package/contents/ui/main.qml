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
import org.kde.plasma.core as Plasmacore
import QtMultimedia
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid

WallpaperItem {
    anchors.fill: parent
    id: main
    property string videoWallpaperBackgroundVideo: wallpaper.configuration.VideoWallpaperBackgroundVideo
    property bool playing: windowModel.playVideoWallpaper && !pauseBattery
    property bool isLoading: true
    property int pauseBatteryLevel: wallpaper.configuration.PauseBatteryLevel

    onPlayingChanged: {
        playing && !isLoading ? main.play() : main.pause()
    }
    onVideoWallpaperBackgroundVideoChanged: {
        if (isLoading) return
        updateState()
    }

    property QtObject pmSource: P5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: sources
        onSourceAdded: source => {
            disconnectSource(source);
            connectSource(source);
            dumpProps(pmSource.connectedSources)
        }
        onSourceRemoved: source => {
            disconnectSource(source);
            dumpProps(pmSource.connectedSources)
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
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: wallpaper.configuration.BackgroundColor

        Video {
            id: player
            source: wallpaper.configuration.VideoWallpaperBackgroundVideo
            loops: MediaPlayer.Infinite
            fillMode: wallpaper.configuration.FillMode
            anchors.fill: parent
            volume: wallpaper.configuration.MuteAudio ? 0.0 : 1
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
        interval: 3000
        onTriggered: {
            isLoading = false
            updateState()
        }
    }

    Component.onCompleted: {
        startTimer.start()
    }
}

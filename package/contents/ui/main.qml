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
import org.kde.plasma.wallpapers.image as Wallpaper
import org.kde.plasma.plasmoid
import QtMultimedia

WallpaperItem {
    anchors.fill: parent
    id: main

    Rectangle {
        id: background
        anchors.fill: parent
        color: wallpaper.configuration.BackgroundColor
        property string videoWallpaperBackgroundVideo: wallpaper.configuration.VideoWallpaperBackgroundVideo
        property bool playing: windowModel.playVideoWallpaper
        onPlayingChanged: background.playing ? playlistplayer.play() : playlistplayer.pause()

        onVideoWallpaperBackgroundVideoChanged: {
            if (playing) {
                playlistplayer.pause()
                playlistplayer.play()
            }
        }
        

        WindowModel {
            id: windowModel
            screenGeometry: main.parent.screenGeometry
        }

        MediaPlayer {
            id: playlistplayer
            autoPlay: false
            activeAudioTrack: -1 //muted: wallpaper.configuration.MuteAudio
            // playlist: Playlist {
            //     id: playlist
            //     playbackMode: Playlist.Loop
            //     property var videoList: addItem( wallpaper.configuration.VideoWallpaperBackgroundVideo )
            // }
            source: wallpaper.configuration.VideoWallpaperBackgroundVideo
            videoOutput: videoView
            loops: MediaPlayer.Infinite
        }

        VideoOutput {
            id: videoView
            fillMode: wallpaper.configuration.FillMode
            anchors.fill: parent
        }
    }

    function dumpProps(obj) {
        console.error("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
        for (var k of Object.keys(obj)) {
            print(k + "=" + obj[k]+"\n")
        }
    }

    // Timer {
    //     id: debugTimer
    //     interval: 1000
    //     repeat: true
    //     running: true
    //     onTriggered: {
    //         // 
    //     }
    // }
}

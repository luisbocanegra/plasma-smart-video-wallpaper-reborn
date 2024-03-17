/*
 *  Copyright 2018 Rog131 <samrog131@hotmail.com>
 *  Copyright 2019 adhe   <adhemarks2@gmail.com>
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

//http://doc.qt.io/qt-5/qml-qtmultimedia-video.html
//https://doc.qt.io/qt-5/qml-qtmultimedia-playlist.html

import QtQuick 2.7
import QtMultimedia 5.8

import org.kde.plasma.core 2.0 as PlasmaCore

Rectangle {
    id: background
    anchors.fill: parent
    color: wallpaper.configuration.BackgroundColor

    property bool playing: windowModel.playVideoWallpaper

    onPlayingChanged: background.playing ? playlistplayer.play() : playlistplayer.pause()
   
    WindowModel {
        id: windowModel
    }

// Double -> 
    property var doublePlayerStatus: wallpaper.configuration.DoublePlayer
    onDoublePlayerStatusChanged: stopgap()

    MediaPlayer {
        id: playlistplayer2
        autoPlay: false
        muted: true
        playlist: Playlist {
            id: playlist2
            playbackMode: Playlist.Loop
            property var videoList2: addItem( wallpaper.configuration.VideoWallpaperBackgroundVideo )
        }
    }

    VideoOutput {
        id: videoView2
        fillMode: wallpaper.configuration.FillMode
        anchors.fill: parent
        source: playlistplayer2
        Timer {
            id: videoGuard2
            interval: 1000; running: true; repeat: true
            onTriggered: {
                if ( wallpaper.configuration.DoublePlayer ) {
                    if ( playlist2.itemCount > 1 ) {
                        playlistplayer2.stop()
                        playlist2.next()
                        playlist2.removeItem(0)
                        stopgap()
                    }
                }
            }
        }
    }
    
    function stopgap() {
        if ( wallpaper.configuration.DoublePlayer ) {
            playlistplayer2.play()
            playlistplayer2.seek(0)
            playlistplayer2.pause()
        } else {
            playlistplayer2.stop()
        }
    }

    MediaPlayer {
        id: playlistplayer
        autoPlay: false
        muted: wallpaper.configuration.MuteAudio
        playlist: Playlist {
            id: playlist
            playbackMode: Playlist.Loop
            property var videoList: addItem( wallpaper.configuration.VideoWallpaperBackgroundVideo )
        }
    }
// <- Double

    VideoOutput {
        id: videoView
        //visible: false
        fillMode: wallpaper.configuration.FillMode
        anchors.fill: parent
        source: playlistplayer
        Timer {
            id: videoGuard
            interval: 1000; running: true; repeat: true
            onTriggered: {
              if ( playlist.itemCount > 1 ) {
                  playlistplayer.stop()
                  playlist.next()
                  playlist.removeItem(0)
                  playlistplayer.play()
              }
            }
        }
    }
    Component.onCompleted: {
        playlistplayer.play()       
        if ( wallpaper.configuration.DoublePlayer ) {
            playlistplayer2.play()
            playlistplayer2.seek(0)
            playlistplayer2.pause()
        }
    }
}

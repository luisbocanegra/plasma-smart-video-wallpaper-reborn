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

import QtQuick 2.7
import QtMultimedia 5.8

import org.kde.plasma.core 2.0 as PlasmaCore

Rectangle {
    id: background
    anchors.fill: parent
    color: cfg_BackgroundColor

    property var playButtonPressed: 0
    
    MediaPlayer {
        id: mediaplayer
        autoPlay: false
        autoLoad: true
        loops: MediaPlayer.Infinite
        muted: cfg_MuteAudio
        source: cfg_VideoWallpaperBackgroundVideo
        
        onSourceChanged: { 
            seeker()
        }
    }

    VideoOutput {
        id: videoView
        fillMode: cfg_FillMode
        anchors.fill: parent
        source: mediaplayer
        
       

        Rectangle {
            id: actionStripe
            color: actionArea.containsMouse ? "#4d000000" : "transparent" | buttonArea.containsMouse ? "#4d000000" : "transparent"
            width: parent.width
            height: Math.max(32, implicitHeight)
            anchors.left: videoView.left; 
            anchors.top:  videoView.top;
            
            MouseArea {
                id: actionArea
                hoverEnabled: true
                anchors.fill: parent
                PlasmaCore.ToolTipArea {
                    anchors.fill: parent
                    subText: "LMB: Seek"
                }
                onPressed:  { 
                    mediaplayer.play()
                    mediaplayer.seek( Math.floor ((mouse.x - actionStripe.height) / ( background.width - actionStripe.height ) * mediaplayer.duration ))
                    if ( playButtonPressed == 0 ) { mediaplayer.pause() }
                }
            }
        }

        Rectangle {
            id: seekStripe
            color: actionArea.containsMouse ? "#3daee9" : "transparent" | buttonArea.containsMouse ? "#3daee9" : "transparent"
            width: ( parent.width - actionStripe.height ) * mediaplayer.position / mediaplayer.duration
            height: actionStripe.height / 5
            radius: height / 2
            anchors.left: playButton.right; 
            anchors.verticalCenter: actionStripe.verticalCenter;
        }

        Image {
            id: playButton
            source: actionArea.containsMouse ? "media-playback-start.svg" : "media-playback-start.svg" | buttonArea.containsMouse ? "media-playback-start.svg" : "media-playback-start.svg"
            width: actionStripe.height
            height: width
            anchors.left: videoView.left; 
            anchors.top: videoView.top;

            MouseArea {
                id: buttonArea
                acceptedButtons:  Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                anchors.fill: parent
                PlasmaCore.ToolTipArea {
                    anchors.fill: parent
                    subText: "LMB: Play/Pause\nRMB: Jump to start"
                }
                onPressed: {
                    if (mouse.button == Qt.LeftButton) {
                        if ( playButtonPressed == 1 ) { 
                            mediaplayer.pause() 
                            playButtonPressed = 0
                            playButton.source = "media-playback-start.svg"
                        } else {
                            mediaplayer.play() 
                            playButtonPressed = 1
                            playButton.source = "media-playback-pause.svg"
                        }
                    }
                    if (mouse.button == Qt.RightButton) {
                        mediaplayer.seek(0)
                    }
                }
            }
        }    

        Rectangle {
            id: infoText
            color: "#4d000000"
            width: childrenRect.width
            height: childrenRect.height
            anchors.top: playButton.bottom
            anchors.right: videoView.right; 

            Text { 
                font.pointSize: 12
                color: "white"
                text: msToHMS(mediaplayer.position) + "/" + msToHMS(mediaplayer.duration)
            }
        }    
    }
    
    function seeker () {
        mediaplayer.play()
        delay.start()
    }
    Timer {
        id: delay
        interval: 500; running: false
        onTriggered: {
            mediaplayer.seek(0)
            mediaplayer.pause()
        }
    }

    function msToHMS(ms) {
        var H = Math.floor(ms / 3600000);
        var M = Math.floor((ms - H * 3600000) / 60000);
        var S = ((ms % 60000) / 1000).toFixed(0);
        return H + ":" + M + ":" + (S < 10 ? '0' : '') + S;
    }
}

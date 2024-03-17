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
import QtQuick.Controls 1.4

ApplicationWindow {
    id: root
    width: 640
    height: 480

    TextArea {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        text: "The change between smart and busy mode work after press the OK button. \n\nDescription\n\nVideo wallpaper is a KDE plasma wallpaper / lock screen background plugin to play video files as background. The Video wallpaper plugin started as a KDE forums answer /1/. \n\nNotes\n\nThe Video wallpaper will need gstreamer plugins to play video/audio. To get possible error messages launch the plasmashell or the lockscreen from the terminal /2/.\n\nThe CPU load will decrease if you use less compressed video format and use smaller resolution videos.\n\nThe Qt is lacking gapless media player /3/. The realod of the media can be hide by using two media players /4/ - option 'Use double player'.\n\nWith the latest plasma (post 5.10) the lock screen doesn't have the audio with the video wallpaper /5/. \n\nLinks\n\n[1] https://forum.kde.org/viewtopic.php?f=289&t=131783\n[2] https://forum.kde.org/viewtopic.php?f=289&t=131783&start=45#p382975\n[3] https://bugreports.qt.io/browse/QTBUG-49446\n[4] https://forum.kde.org/viewtopic.php?f=289&t=131783&start=15#p365313\n[5] https://forum.kde.org/viewtopic.php?f=289&t=131783&start=45#p383041"
    }
}

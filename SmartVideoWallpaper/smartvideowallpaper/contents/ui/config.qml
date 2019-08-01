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
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.2
import QtMultimedia 5.8

import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: root
    property string cfg_VideoWallpaperBackgroundVideo
    property string cfg_BackgroundColor: "black"
    property int cfg_FillMode: 2
    property bool cfg_MuteAudio:    true
    property bool cfg_DoublePlayer: true
    //anchors.fill: parent

    RowLayout {
        id: videoPath
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        Layout.fillWidth:true

        Label {
                text: "Video path: "
            }
        TextField {
            id: videoPathLine
            Layout.fillWidth:true
            Layout.maximumWidth: previewArea.width - 150
            Layout.minimumWidth: previewArea.width * 0.5
            placeholderText: "Video"
            text: cfg_VideoWallpaperBackgroundVideo
            readOnly : true
        }

        Button {
            id: imageButton
            implicitWidth: height
            PlasmaCore.IconItem {
                anchors.fill: parent
                source: "folder-videos-symbolic"
                PlasmaCore.ToolTipArea {
                    anchors.fill: parent
                    subText: "Pick video"
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {fileDialog.open() }
            }
        }
    }

    RowLayout {
        id: fillModeRow
        anchors.top: videoPath.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        Label {
                text: "Video fill mode: "
                Layout.alignment: Qt.AlignLeft
            }
        ComboBox {
            id: videoFillMode
            model: [
                {
                    'label': "Stretch",
                    'fillMode': VideoOutput.Stretch
                },
                {
                    'label': "Scaled, Keep Proportions",
                    'fillMode': VideoOutput.PreserveAspectFit
                },
                {
                    'label': "Scaled and Cropped",
                    'fillMode': VideoOutput.PreserveAspectCrop
                }
            ]
            textRole: "label"
            onCurrentIndexChanged: cfg_FillMode = model[currentIndex]["fillMode"]
            Component.onCompleted: setMethod();

            function setMethod() {
                for (var i = 0; i < model.length; i++) {
                    if (model[i]["fillMode"] == wallpaper.configuration.FillMode) {
                        videoFillMode.currentIndex = i;
                    }
                }
            }
        }
        Label {
            text: "Background Color: "
                Layout.alignment: Qt.AlignLeft
        }
        Button {
            id: colorButton
            implicitWidth: height
            Rectangle {
                id: colorRect
                anchors.fill: parent
                border.color: "lightgray"
                border.width: 1
                radius: 4
                color: cfg_BackgroundColor
            }
            MouseArea {
                anchors.fill: parent
                onClicked: colorDialog.open()
            }
        }
    }

    RowLayout {
        id: radioRow
        anchors.top: fillModeRow.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        RadioButton {
            id: muteRadio
            text: "Mute audio"
            checked: cfg_MuteAudio
            onCheckedChanged: {
                    if (checked) { 
                        cfg_MuteAudio = true
                    } else { 
                        cfg_MuteAudio = false
                    }
            }
        }
        RadioButton {
            id: doubleRadio
            text: "Use double player"
            checked: cfg_DoublePlayer
            onCheckedChanged: {
                    if (checked) { 
                        cfg_DoublePlayer = true
                    } else { 
                        cfg_DoublePlayer = false
                    }
            }
        }
        Button {
            id: readmeButton
            text: "Read me"

            onClicked: {
                var component = Qt.createComponent("ReadMe.qml")
                var window    = component.createObject(root)
                window.show()
            }
        }
    }

    Rectangle {
        id: previewArea
        width: parent.width
        height: width / 1.778
        anchors.top: radioRow.bottom
        //anchors.bottom: parent.bottom
        color: "transparent"
        border.color: "lightgray"
        border.width: 2
        Loader { 
            id: videoPreviewLoader
            anchors.fill: parent
        }
    }

    ColorDialog {
        id: colorDialog
        title: "Select Background Color"
        onAccepted: {
            cfg_BackgroundColor = colorDialog.color
        }
    }

    FileDialog {
        id: fileDialog
        selectMultiple : false
        title: "Pick a video file"
        nameFilters: [ "Video files (*.mp4 *.mpg *.ogg *.mov *.webm *.flv *.matroska *.avi *wmv)", "All files (*)" ]
        onAccepted: {
            cfg_VideoWallpaperBackgroundVideo = fileDialog.fileUrls[0]
            videoPreviewLoader.source = "preview/QuickPreview.qml"
        }
    }

    onCfg_VideoWallpaperBackgroundVideoChanged: {
        videoPathLine.text = cfg_VideoWallpaperBackgroundVideo
        videoPreviewLoader.source = "preview/QuickPreview.qml"
    }
}

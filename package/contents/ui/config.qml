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
import QtQuick.Controls
import org.kde.kquickcontrols as KQuickControls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtMultimedia
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols 2.0 as KQuickControls
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami


Kirigami.FormLayout {
    id: root
    twinFormLayouts: parentLayout
    property alias formLayout: root

    property alias cfg_VideoWallpaperBackgroundVideo: videoPathLine.text
    property int cfg_FillMode: videoFillMode.currentIndex
    property bool cfg_MuteAudio: muteRadio.checked
    property int cfg_PauseMode: wallpaper.configuration.PauseMode
    property alias cfg_BackgroundColor: colorButton.color
    property int cfg_PauseBatteryLevel: pauseBatteryLevel.value
    property bool cfg_BatteryPausesVideo: batteryPausesVideo.checked
    property int cfg_BlurMode: wallpaper.configuration.BlurMode
    property bool cfg_BatteryDisablesBlur: wallpaper.configuration.BatteryDisablesBlur
    property int cfg_BlurRadius: wallpaper.configuration.BlurRadius

    RowLayout {
        Layout.fillWidth:true
        Kirigami.FormData.label: i18nd("@label:video_file", "Video path:")
        TextField {
            id: videoPathLine
            Layout.fillWidth:true
            placeholderText: i18nd("@text:placeholder_video_file", "/media/videos/waves.mp4")
            text: cfg_VideoWallpaperBackgroundVideo
            // readOnly : true
        }
        Button {
            id: imageButton
            Kirigami.Icon {
                anchors.fill: parent
                source: "folder-videos-symbolic"
                PlasmaCore.ToolTipArea {
                    anchors.fill: parent
                    subText: i18nd("@tooltip","Pick video")
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {fileDialog.open() }
            }
        }
    }

    ComboBox {
        Kirigami.FormData.label: i18nd("@option:video_fill_mode", "Fill mode:")
        id: videoFillMode
        model: [
            {
                'label': i18nd("@option:video_stretch", "Stretch"),
                'fillMode': VideoOutput.Stretch
            },
            {
                'label': i18nd("@option:video_scaled", "Scaled, Keep Proportions"),
                'fillMode': VideoOutput.PreserveAspectFit
            },
            {
                'label': i18nd("@option:video_scaled_cropped", "Scaled and Cropped"),
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

    KQuickControls.ColorButton {
        id: colorButton
        Kirigami.FormData.label: i18nd("@button:background_color", "Background:")
        visible: cfg_FillMode === VideoOutput.PreserveAspectFit
        dialogTitle: i18nd("@dialog:background_color_title", "Select Background Color")
    }

    CheckBox {
        id: muteRadio
        Kirigami.FormData.label: i18nd("@checkbox:mute_audio", "Mute audio:")
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
        id: maximizedPauseRadioButtton
        Kirigami.FormData.label: i18nd("@buttonGroup:pause_mode", "Pause video:")
        text: i18n("When there are maximized or full-screen windows")
        ButtonGroup.group: pauseModeGroup
        property int index: 0
        checked: wallpaper.configuration.PauseMode === index
    }
    RadioButton {
        id: activePauseRadioButton
        text: i18n("When an active window is shown")
        ButtonGroup.group: pauseModeGroup
        property int index: 1
        checked: wallpaper.configuration.PauseMode === index
    }
    RadioButton {
        id: visiblePauseRadioButton
        text: i18n("When a window is shown")
        ButtonGroup.group: pauseModeGroup
        property int index: 2
        checked: wallpaper.configuration.PauseMode === index
    }
    RadioButton {
        id: neverPauseRadioButton
        text: i18n("Never")
        ButtonGroup.group: pauseModeGroup
        property int index: 3
        checked: wallpaper.configuration.PauseMode === index
    }
    ButtonGroup {
        id: pauseModeGroup
        onCheckedButtonChanged: {
            if (checkedButton) {
                cfg_PauseMode = checkedButton.index
            }
        }
    }


    RadioButton {
        id: maximizedBlurRadioButtton
        Kirigami.FormData.label: i18nd("@buttonGroup:blur_mode", "Blur video:")
        text: i18n("When there are maximized or full-screen windows")
        ButtonGroup.group: blurModeGroup
        property int index: 0
        checked: wallpaper.configuration.BlurMode === index
    }
    RadioButton {
        id: busyBlurRadioButton
        text: i18n("When an active window is shown")
        ButtonGroup.group: blurModeGroup
        property int index: 1
        checked: wallpaper.configuration.BlurMode === index
    }
    RadioButton {
        id: visibleBlurRadioButton
        text: i18n("When a window is shown")
        ButtonGroup.group: blurModeGroup
        property int index: 2
        checked: wallpaper.configuration.BlurMode === index
    }
    RadioButton {
        id: pausedBlurRadioButton
        text: i18n("When video is paused")
        ButtonGroup.group: blurModeGroup
        property int index: 3
        checked: wallpaper.configuration.BlurMode === index
    }
    RadioButton {
        id: alwaysBlurRadioButton
        text: i18n("Always")
        ButtonGroup.group: blurModeGroup
        property int index: 4
        checked: wallpaper.configuration.BlurMode === index
    }
    RadioButton {
        id: neverBlurRadioButton
        text: i18n("Never")
        ButtonGroup.group: blurModeGroup
        property int index: 5
        checked: wallpaper.configuration.BlurMode === index
    }
    ButtonGroup {
        id: blurModeGroup
        onCheckedButtonChanged: {
            if (checkedButton) {
                cfg_BlurMode = checkedButton.index
            }
        }
    }

    SpinBox {
        Kirigami.FormData.label: i18nd("@checkGroup:battery_mode", "Blur radius")
        id: blurRadiusSpinBox
        from: 0
        to: 145
        value: cfg_BlurRadius
        onValueChanged: {
            cfg_BlurRadius = value
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18nd("@checkGroup:battery_mode", "On Battery below:")
        SpinBox {
            id: pauseBatteryLevel
            from: 0
            to: 100
            value: cfg_PauseBatteryLevel
            onValueChanged: {
                cfg_PauseBatteryLevel = value
            }
        }
        Label {
            text: "%"
        }
    }

    CheckBox {
        text: i18n("Pause video")
        checked: cfg_BatteryPausesVideo
        onCheckedChanged: {
            cfg_BatteryPausesVideo = checked
        }
    }

    CheckBox {
        text: i18n("Disable blur")
        checked: cfg_BatteryDisablesBlur
        onCheckedChanged: {
            cfg_BatteryDisablesBlur = checked
        }
    }

    FileDialog {
        id: fileDialog
        fileMode : FileDialog.OpenFile
        title: i18nd("@dialog_title:pick_video", "Pick a video file")
        nameFilters: [ "Video files (*.mp4 *.mpg *.ogg *.mov *.webm *.flv *.matroska *.avi *wmv)", "All files (*)" ]
        onAccepted: {
            cfg_VideoWallpaperBackgroundVideo = fileDialog.selectedFile
        }
    }
}

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
    twinFormLayouts: parentLayout // required by parent
    property alias formLayout: root // required by parent

    property alias cfg_VideoWallpaperBackgroundVideo: videoPathLine.text
    property alias cfg_FillMode: videoFillMode.currentIndex
    property alias cfg_MuteAudio: muteRadio.checked
    property alias cfg_PauseMode: pauseModeCombo.currentIndex
    property alias cfg_BackgroundColor: colorButton.color
    property alias cfg_PauseBatteryLevel: pauseBatteryLevel.value
    property alias cfg_BatteryPausesVideo: batteryPausesVideoCheckBox.checked
    property alias cfg_BlurMode: blurModeCombo.currentIndex
    property alias cfg_BatteryDisablesBlur: batteryDisablesBlurCheckBox.checked
    property alias cfg_BlurRadius: blurRadiusSpinBox.value
    property alias cfg_QdbusExecName: qdbusExecTextField.text
    property alias cfg_ScreenLockedPausesVideo: screenLockPausesVideoCheckbox.checked

    RowLayout {
        Layout.fillWidth:true
        Kirigami.FormData.label: i18nd("@label:video_file", "Video path:")
        TextField {
            id: videoPathLine
            Layout.fillWidth:true
            placeholderText: i18nd("@text:placeholder_video_file", "/media/videos/waves.mp4")
            text: cfg_VideoWallpaperBackgroundVideo
            readOnly : true
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

    ComboBox {
        Kirigami.FormData.label: i18nd("@buttonGroup:pause_mode", "Pause video:")
        id: pauseModeCombo
        model: [
            {
                'label': i18nd("@option:pause_mode", "Maximized or full-screen windows")
            },
            {
                'label': i18nd("@option:pause_mode", "Active window is present")
            },
            {
                'label': i18nd("@option:pause_mode", "At least one window is shown")
            },
            {
                'label': i18nd("@option:pause_mode", "Never")
            }
        ]
        textRole: "label"
        onCurrentIndexChanged: cfg_PauseMode = currentIndex
        currentIndex: cfg_PauseMode
    }

    ComboBox {
        Kirigami.FormData.label: i18nd("@buttonGroup:pause_mode", "Blur video:")
        id: blurModeCombo
        model: [
            {
                'label': i18nd("@option:blur_mode", "Maximized or full-screen windows")
            },
            {
                'label': i18nd("@option:blur_mode", "Active window is present")
            },
            {
                'label': i18nd("@option:blur_mode", "At least one window is shown")
            },
            {
                'label': i18nd("@option:blur_mode", "Video is paused")
            },
            {
                'label': i18nd("@option:blur_mode", "Always")
            },
            {
                'label': i18nd("@option:blur_mode", "Never")
            }
        ]
        textRole: "label"
        onCurrentIndexChanged: cfg_BlurMode = currentIndex
        currentIndex: cfg_BlurMode
    }

    SpinBox {
        Kirigami.FormData.label: i18nd("@checkBox:blur_strength", "Blur radius:")
        id: blurRadiusSpinBox
        from: 0
        to: 145
        value: cfg_BlurRadius
        onValueChanged: {
            cfg_BlurRadius = value
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18nd("@checkGroup:battery_mode", "On battery below:")
        SpinBox {
            id: pauseBatteryLevel
            from: 0
            to: 100
            value: cfg_PauseBatteryLevel
            onValueChanged: {
                cfg_PauseBatteryLevel = value
            }
        }
    }

    CheckBox {
        id: batteryPausesVideoCheckBox
        text: i18n("Pause video")
        checked: cfg_BatteryPausesVideo
        onCheckedChanged: {
            cfg_BatteryPausesVideo = checked
        }
    }

    CheckBox {
        id: batteryDisablesBlurCheckBox
        text: i18n("Disable blur")
        checked: cfg_BatteryDisablesBlur
        onCheckedChanged: {
            cfg_BatteryDisablesBlur = checked
        }
    }

    CheckBox {
        Kirigami.FormData.label: i18nd("@checkBox:lock_pause_video", "Screen lock pauses video:")
        id: screenLockPausesVideoCheckbox
        text: i18n("Uncheck if using as lock screen wallpaper!")
        checked: cfg_ScreenLockedPausesVideo
        onCheckedChanged: {
            cfg_ScreenLockedPausesVideo = checked
        }
    }

    TextField {
        Kirigami.FormData.label: i18nd("@label:video_file", "Qdbus executable:")
        id: qdbusExecTextField
        placeholderText: i18nd("@text:placeholder_video_file", "qdbus6")
        text: cfg_QdbusExecName
        Layout.maximumWidth: 300
    }

    Label {
        text: i18n("This used to detect when the screen is locked.")
        opacity: 0.7
        wrapMode: Text.Wrap
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

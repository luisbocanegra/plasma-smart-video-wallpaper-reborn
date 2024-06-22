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
    property alias cfg_FillMode: videoFillMode.currentIndex
    property alias cfg_MuteAudio: muteRadio.checked
    property alias cfg_PauseMode: pauseModeCombo.currentIndex
    property alias cfg_BackgroundColor: colorButton.color
    property alias cfg_PauseBatteryLevel: pauseBatteryLevel.value
    property alias cfg_BatteryPausesVideo: batteryPausesVideoCheckBox.checked
    property alias cfg_BlurMode: blurModeCombo.currentIndex
    property alias cfg_BlurModeLocked: blurModeLockedCombo.currentIndex
    property alias cfg_BatteryDisablesBlur: batteryDisablesBlurCheckBox.checked
    property alias cfg_BlurRadius: blurRadiusSpinBox.value
    property alias cfg_QdbusExecName: qdbusExecTextField.text
    property alias cfg_ScreenLockedPausesVideo: screenLockPausesVideoCheckbox.checked
    property string cfg_VideoUrls
    property var currentFiles: []
    property bool isLoading: false
    property alias cfg_ScreenOffPausesVideo: screenOffPausesVideoCheckbox.checked
    property alias cfg_ScreenStateCmd: screenStateCmdTextField.text
    property bool showWarningMessage: false
    property bool cfg_CheckWindowsActiveScreen: activeScreenOnlyCheckbx.checked
    property alias cfg_LockScreenMode: screenLockModeCheckbox.checked
    property alias cfg_DebugEnabled: debugEnabledCheckbox.checked

    ListModel {
        id: videoUrls
        Component.onCompleted: {
            updateVidsModel()
        }
    }

    function updateVidsModel(){
        isLoading = true
        videoUrls.clear()
        let currentFiles = cfg_VideoUrls.trim().split("\n")
        for (let i = 0; i < currentFiles.length; i++) {
            const video = currentFiles[i]
            if (video.length > 0) {
                videoUrls.append({"url": currentFiles[i]})
            }
        }
        isLoading = false
    }

    function updateVidsString() {
        let newUrls = ""
        for (let i = 0; i < videoUrls.count; i++) {
            newUrls += videoUrls.get(i).url + "\n"
        }
        cfg_VideoUrls = newUrls
    }

    Connections {
        target: videoUrls
        function onCountChanged() {
            if (isLoading) return
            updateVidsString()
        }
    }

    RowLayout {
        Button {
            id: imageButton
            icon.name: "folder-videos-symbolic"
            text: i18nd("@button:toggle_show_videos", "Add new videos")
            onClicked: {
                fileDialog.open()
            }
        }
        Button {
            icon.name: "visibility-symbolic"
            text: i18nd("@button:toggle_show_videos", videosList.visible ? "Hide videos list" : "Show videos list")
            checkable: true
            checked: videosList.visible
            onClicked: {
                videosList.visible = !videosList.visible
            }
        }
    }

    ColumnLayout {
        id: videosList
        visible: false
        Repeater {
            model: videoUrls
            RowLayout {
                Button{
                    icon.name: "edit-delete-remove"
                    onClicked: {
                        videoUrls.remove(index)
                    }
                }
                Label {
                    text: index.toString() +" "+ modelData
                    wrapMode: Text.Wrap
                    Layout.maximumWidth: 300
                    font: Kirigami.Theme.smallFont
                }
            }
        }
    }

    Button {
        icon.name: "dialog-information-symbolic"
        text: i18nd("@button:toggle_show_warning", "Warning! Please read before applying (click to show)")
        checkable: true
        checked: showWarningMessage
        onClicked: {
            showWarningMessage = !showWarningMessage
        }
        highlighted: true
        Kirigami.Theme.inherit: false
        Kirigami.Theme.textColor: Kirigami.Theme.neutralTextColor
        Kirigami.Theme.highlightColor: Kirigami.Theme.neutralTextColor
        icon.color: Kirigami.Theme.neutralTextColor
    }

    Kirigami.InlineMessage {
        id: warningResources
        Layout.fillWidth: true
        type: Kirigami.MessageType.Warning
        text: qsTr("Videos are loaded in Memory, bigger files will use more Memory and system resources!")
        visible: showWarningMessage
    }
    Kirigami.InlineMessage {
        id: warningCrashes
        Layout.fillWidth: true
        type: Kirigami.MessageType.Warning
        text: qsTr("Crashes/Black screen? Try changing the Qt Media Backend to gstreamer.<br>To recover from crash remove the videos from the configuration using this command below in terminal/tty then reboot:<br><strong><code>sed -i 's/^VideoUrls=.*$/VideoUrls=/g' $HOME/.config/plasma-org.kde.plasma.desktop-appletsrc $HOME/.config/kscreenlockerrc</code></strong>")
        visible: showWarningMessage
        actions: [
            Kirigami.Action {
                icon.name: "view-readermode-symbolic"
                text: "Qt Media backend instructions"
                onTriggered: {
                    Qt.openUrlExternally("https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn?tab=readme-ov-file#black-video-or-plasma-crashes")
                }
            }
        ]
    }
    Kirigami.InlineMessage {
        id: warningHwAccel
        Layout.fillWidth: true
        text: qsTr("Make sure to enable Hardware video acceleration in your system to reduce CPU usage and save power.")
        visible: showWarningMessage
        actions: [
            Kirigami.Action {
                icon.name: "view-readermode-symbolic"
                text: "Learn how"
                onTriggered: {
                    Qt.openUrlExternally("https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn?tab=readme-ov-file#improve-performance-by-enabling-hardware-video-acceleration")
                }
            }
        ]
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
            cfg_MuteAudio = checked
        }
    }

    CheckBox {
        Kirigami.FormData.label: i18nd("@checkBox:lock_screen_mode", "Lock screen mode:")
        id: screenLockModeCheckbox
        text: i18n("Disables windows and lock screen detection")
        checked: cfg_LockScreenMode
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
        visible: !screenLockModeCheckbox.checked
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
        visible: !screenLockModeCheckbox.checked
    }

    ComboBox {
        Kirigami.FormData.label: i18nd("@buttonGroup:pause_mode", "Blur video:")
        id: blurModeLockedCombo
        model: [
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
        onCurrentIndexChanged: cfg_BlurModeLocked = currentIndex
        currentIndex: cfg_BlurModeLocked
        visible: screenLockModeCheckbox.checked
    }

    CheckBox {
        id: activeScreenOnlyCheckbx
        Kirigami.FormData.label: i18nd("@checkbox:mute_audio", "Filter:")
        checked: cfg_CheckWindowsActiveScreen
        text: i18n("Only check for windows in active screen")
        onCheckedChanged: {
            cfg_CheckWindowsActiveScreen = checked
        }
        visible: !screenLockModeCheckbox.checked
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
        visible: (screenLockModeCheckbox.checked && cfg_BlurModeLocked !== 2) ||
                    (blurModeCombo.visible && cfg_BlurMode !== 5)
    }

    Kirigami.InlineMessage {
        Layout.fillWidth: true
        type: Kirigami.MessageType.Warning
        visible: blurRadiusSpinBox.visible && cfg_BlurRadius > 64
        text: qsTr("Quality of the blur is reduced if value exceeds 64. Higher values may cause the blur to stop working!")
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
            visible: blurRadiusSpinBox.visible
        }
    }

    CheckBox {
        Kirigami.FormData.label: i18nd("@checkBox:lock_pause_video", "Screen lock pauses video:")
        id: screenLockPausesVideoCheckbox
        checked: cfg_ScreenLockedPausesVideo
        onCheckedChanged: {
            cfg_ScreenLockedPausesVideo = checked
        }
        visible: !screenLockModeCheckbox.checked
    }

    TextField {
        Kirigami.FormData.label: i18nd("@label:video_file", "Qdbus executable:")
        id: qdbusExecTextField
        placeholderText: i18nd("@text:placeholder_video_file", "qdbus6")
        text: cfg_QdbusExecName
        Layout.maximumWidth: 300
        visible: !screenLockModeCheckbox.checked && screenLockPausesVideoCheckbox.checked
    }

    Label {
        text: i18n("This used to detect when the screen is locked.")
        opacity: 0.75
        wrapMode: Text.Wrap
        visible: qdbusExecTextField.visible
    }
    function dumpProps(obj) {
        console.error("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
        for (var k of Object.keys(obj)) {
            print(k + "=" + obj[k]+"\n")
        }
    }

    CheckBox {
        Kirigami.FormData.label: i18nd("@checkBox:screenOff_pause_video", "Screen Off pauses video:")
        id: screenOffPausesVideoCheckbox
        text: i18n("Requires setting up command below!")
        checked: cfg_ScreenOffPausesVideo
        onCheckedChanged: {
            cfg_ScreenOffPausesVideo = checked
        }
    }

    TextField {
        Kirigami.FormData.label: i18nd("@label:screen_state_cmd", "Screen state command:")
        id: screenStateCmdTextField
        placeholderText: i18nd("@text:placeholder_video_file", "cat /sys/class/backlight/intel_backlight/actual_brightness")
        text: cfg_ScreenStateCmd
        Layout.maximumWidth: 300
        visible: screenOffPausesVideoCheckbox.checked
    }

    Label {
        text: i18n("The command/script must return 0 (zero) when the screen is Off!")
        opacity: 0.75
        wrapMode: Text.Wrap
        visible: screenOffPausesVideoCheckbox.checked
    }

    CheckBox {
        Kirigami.FormData.label: i18n("Enable debug:")
        text: i18n("Print debug messages to the system log")
        id: debugEnabledCheckbox
        checked: cfg_DebugEnabled
        onCheckedChanged: {
            cfg_DebugEnabled = checked
        }
    }

    FileDialog {
        id: fileDialog
        fileMode : FileDialog.OpenFiles
        title: i18nd("@dialog_title:pick_video", "Pick a video file")
        nameFilters: [ "Video files (*.mp4 *.mpg *.ogg *.mov *.webm *.flv *.matroska *.avi *wmv)", "All files (*)" ]
        onAccepted: {
            let newFiles
            let currentFiles = cfg_VideoUrls.trim().split("\n")
            // console.log(currentFiles);
            for (let file of fileDialog.selectedFiles) {
                if (!currentFiles.includes(file.toString())) {
                    cfg_VideoUrls+=file+"\n"
                }
            }
            updateVidsModel()
        }
    }
}

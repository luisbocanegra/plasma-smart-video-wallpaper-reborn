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
    property alias cfg_EffectsPlayVideo: effectsPlayVideoInput.text
    property alias cfg_EffectsPauseVideo: effectsPauseVideoInput.text
    property alias cfg_EffectsShowBlur: effectsShowBlurInput.text
    property alias cfg_EffectsHideBlur: effectsHideBlurInput.text
    property alias cfg_BlurAnimationDuration: blurAnimationDurationSpinBox.value
    property alias cfg_CrossfadeEnabled: crossfadeEnabledCheckbox.checked
    property alias cfg_CrossfadeDuration: crossfadeDurationSpinBox.value
    property alias cfg_PlaybackRate: playbackRateSlider.value
    property alias cfg_Volume: volumeSlider.value

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
            text: i18n("Add new videos")
            onClicked: {
                fileDialog.open()
            }
        }
        Button {
            icon.name: "visibility-symbolic"
            text: i18n(videosList.visible ? "Hide videos list" : "Show videos list")
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
                CheckBox {id: vidEnabled}
                TextField {
                    text: modelData
                    // wrapMode: Text.Wrap
                    // Layout.maximumWidth: 400
                    Layout.preferredWidth: 300
                    // font: Kirigami.Theme.smallFont
                    // maxLines: 1
                }
                RowLayout {
                    enabled: vidEnabled.checked
                    SpinBox {
                        from: 0
                        to: 3600
                        value: 60
                    }
                    Button{
                        icon.name: "go-up-symbolic"
                    }
                    Button{
                        icon.name: "go-down-symbolic"
                    }
                }
                Button{
                    icon.name: "edit-delete-remove"
                    // text: "Remove"
                    onClicked: {
                        videoUrls.remove(index)
                    }
                }
            }
        }
    }

    Button {
        icon.name: "dialog-warning-symbolic"
        text: i18n("Warning! Please read before applying (click to show)")
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
        text: i18n("Videos are loaded in Memory, bigger files will use more Memory and system resources!")
        visible: showWarningMessage
    }
    Kirigami.InlineMessage {
        id: warningCrashes
        Layout.fillWidth: true
        type: Kirigami.MessageType.Warning
        text: i18n("Crashes/Black screen? Try changing the Qt Media Backend to gstreamer.<br>To recover from crash remove the videos from the configuration using this command below in terminal/tty then reboot:<br><strong><code>sed -i 's/^VideoUrls=.*$/VideoUrls=/g' $HOME/.config/plasma-org.kde.plasma.desktop-appletsrc $HOME/.config/kscreenlockerrc</code></strong>")
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
        text: i18n("Make sure to enable Hardware video acceleration in your system to reduce CPU/GPU usage when videos are playing.")
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
        Kirigami.FormData.label: i18n("Fill mode:")
        id: videoFillMode
        model: [
            {
                'label': i18n("Stretch"),
                'fillMode': VideoOutput.Stretch
            },
            {
                'label': i18n("Keep Proportions"),
                'fillMode': VideoOutput.PreserveAspectFit
            },
            {
                'label': i18n("Scaled and Cropped"),
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
        Kirigami.FormData.label: i18n("Background:")
        visible: cfg_FillMode === VideoOutput.PreserveAspectFit
        dialogTitle: i18n("Select Background Color")
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Playback speed:")
        Slider {
            id: playbackRateSlider
            from: 0
            value: cfg_PlaybackRate
            to: 2
            onValueChanged: {
                cfg_PlaybackRate = value
            }
        }
        Label {
            text: parseFloat(playbackRateSlider.value).toFixed(2)
        }
        Button {
            icon.name: "edit-undo-symbolic"
            flat: true
            onClicked: {
                playbackRateSlider.value = 1.0
            }
            ToolTip.text: i18n("Reset to default")
            ToolTip.visible: hovered
        }
    }

    

    RowLayout {
        Kirigami.FormData.label: i18n("Mute audio:")
        CheckBox {
            id: muteRadio
            checked: cfg_MuteAudio
            onCheckedChanged: {
                cfg_MuteAudio = checked
            }
        }
        RowLayout {
            enabled: !muteRadio.checked
            opacity: enabled ? 1 : 0
            Label {
                text: i18n("Volume:")
            }
            Slider {
                id: volumeSlider
                from: 0
                value: cfg_Volume
                to: 1
                onValueChanged: {
                    cfg_Volume = value
                }
            }
            Label {
                text: parseFloat(volumeSlider.value).toFixed(2)
            }
            Button {
                icon.name: "edit-undo-symbolic"
                flat: true
                onClicked: {
                    volumeSlider.value = 1.0
                }
                ToolTip.text: i18n("Reset to default")
                ToolTip.visible: hovered
            }
        }
    }


    RowLayout {
        Kirigami.FormData.label: i18n("Crossfade (Beta):")
        CheckBox {
            id: crossfadeEnabledCheckbox
            checked: cfg_CrossfadeEnabled
            onCheckedChanged: {
                cfg_CrossfadeEnabled = checked
            }
        }
        Label {
            text: i18n("Duration:")
        }
        SpinBox {
            enabled: crossfadeEnabledCheckbox.checked
            id: crossfadeDurationSpinBox
            from: 0
            to: 2000000000
            stepSize: 100
            value: cfg_CrossfadeDuration
            onValueChanged: {
                cfg_CrossfadeDuration = value
            }
        }
        Button {
            icon.name: "dialog-information-symbolic"
            ToolTip.text: i18n("Adds a smooth transition between videos. <strong>Uses additional Memory and may cause playback isues when enabled.</strong>")
            highlighted: true
            hoverEnabled: true
            ToolTip.visible: hovered
            Kirigami.Theme.inherit: false
            flat: true
        }
    }


    CheckBox {
        Kirigami.FormData.label: i18n("Lock screen mode:")
        id: screenLockModeCheckbox
        text: i18n("Disables windows and lock screen detection")
        checked: cfg_LockScreenMode
    }

    ComboBox {
        Kirigami.FormData.label: i18n("Pause video:")
        id: pauseModeCombo
        model: [
            {
                'label': i18n("Maximized or full-screen windows")
            },
            {
                'label': i18n("Active window is present")
            },
            {
                'label': i18n("At least one window is shown")
            },
            {
                'label': i18n("Never")
            }
        ]
        textRole: "label"
        onCurrentIndexChanged: cfg_PauseMode = currentIndex
        currentIndex: cfg_PauseMode
        visible: !screenLockModeCheckbox.checked
    }

    ComboBox {
        Kirigami.FormData.label: i18n("Blur video:")
        id: blurModeCombo
        model: [
            {
                'label': i18n("Maximized or full-screen windows")
            },
            {
                'label': i18n("Active window is present")
            },
            {
                'label': i18n("At least one window is shown")
            },
            {
                'label': i18n("Video is paused")
            },
            {
                'label': i18n("Always")
            },
            {
                'label': i18n("Never")
            }
        ]
        textRole: "label"
        onCurrentIndexChanged: cfg_BlurMode = currentIndex
        currentIndex: cfg_BlurMode
        visible: !screenLockModeCheckbox.checked
    }

    ComboBox {
        Kirigami.FormData.label: i18n("Blur video:")
        id: blurModeLockedCombo
        model: [
            {
                'label': i18n("Video is paused")
            },
            {
                'label': i18n("Always")
            },
            {
                'label': i18n("Never")
            }
        ]
        textRole: "label"
        onCurrentIndexChanged: cfg_BlurModeLocked = currentIndex
        currentIndex: cfg_BlurModeLocked
        visible: screenLockModeCheckbox.checked
    }

    CheckBox {
        id: activeScreenOnlyCheckbx
        Kirigami.FormData.label: i18n("Filter:")
        checked: cfg_CheckWindowsActiveScreen
        text: i18n("Only check for windows in active screen")
        onCheckedChanged: {
            cfg_CheckWindowsActiveScreen = checked
        }
        visible: !screenLockModeCheckbox.checked
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Blur radius:")
        visible: (screenLockModeCheckbox.checked && cfg_BlurModeLocked !== 2) ||
                        (blurModeCombo.visible && cfg_BlurMode !== 5)
        SpinBox {
            id: blurRadiusSpinBox
            from: 0
            to: 145
            value: cfg_BlurRadius
            onValueChanged: {
                cfg_BlurRadius = value
            }
        }
        Button {
            visible: blurRadiusSpinBox.visible && cfg_BlurRadius > 64
            icon.name: "dialog-information-symbolic"
            ToolTip.text: i18n("Quality of the blur is reduced if value exceeds 64. Higher values may cause the blur to stop working!")
            hoverEnabled: true
            flat: true
            ToolTip.visible: hovered
            Kirigami.Theme.inherit: false
            Kirigami.Theme.textColor: Kirigami.Theme.neutralTextColor
            Kirigami.Theme.highlightColor: Kirigami.Theme.neutralTextColor
            icon.color: Kirigami.Theme.neutralTextColor
        }
        Label {
            text: i18n("Animation duration:")
        }
        SpinBox {
            id: blurAnimationDurationSpinBox
            from: 0
            to: 2000000000
            stepSize: 100
            value: cfg_BlurAnimationDuration
            onValueChanged: {
                cfg_BlurAnimationDuration = value
            }
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("On battery below:")
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
        Kirigami.FormData.label: i18n("Screen lock pauses video:")
        id: screenLockPausesVideoCheckbox
        checked: cfg_ScreenLockedPausesVideo
        onCheckedChanged: {
            cfg_ScreenLockedPausesVideo = checked
        }
        visible: !screenLockModeCheckbox.checked
    }

    function dumpProps(obj) {
        console.error("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
        for (var k of Object.keys(obj)) {
            print(k + "=" + obj[k]+"\n")
        }
    }

    CheckBox {
        Kirigami.FormData.label: i18n("Screen Off pauses video:")
        id: screenOffPausesVideoCheckbox
        text: i18n("Requires setting up command below!")
        checked: cfg_ScreenOffPausesVideo
        onCheckedChanged: {
            cfg_ScreenOffPausesVideo = checked
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Screen state command:")
        visible: screenOffPausesVideoCheckbox.checked
        TextField {
            id: screenStateCmdTextField
            placeholderText: i18n("cat /sys/class/backlight/intel_backlight/actual_brightness")
            text: cfg_ScreenStateCmd
            Layout.maximumWidth: 300
        }
        Button {
            icon.name: "dialog-information-symbolic"
            ToolTip.text: i18n("The command/script must return 0 (zero) when the screen is Off.")
            highlighted: true
            hoverEnabled: true
            flat: true
            ToolTip.visible: hovered
            Kirigami.Theme.inherit: false
            Kirigami.Theme.textColor: Kirigami.Theme.highlightColor
            icon.color: Kirigami.Theme.highlightColor
            display: AbstractButton.IconOnly
        }
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

    Kirigami.Separator {
        Kirigami.FormData.label: i18n("Desktop Effects")
        Layout.fillWidth: true
    }

    TextEdit {
        wrapMode: Text.Wrap
        Layout.maximumWidth: 400
        readOnly: true
        textFormat: TextEdit.RichText
        text: "Comma separated list of effects (e.g. overview,cube). To get the currently enabled effects run:<br><strong><code>gdbus call --session --dest org.kde.KWin.Effect.WindowView1 --object-path /Effects --method org.freedesktop.DBus.Properties.Get org.kde.kwin.Effects loadedEffects</code></strong>"
        color: Kirigami.Theme.textColor
        selectedTextColor: Kirigami.Theme.highlightedTextColor
        selectionColor: Kirigami.Theme.highlightColor
    }

    // TODO select from loaded effects instead of typing them

    TextField {
        Kirigami.FormData.label: i18n("Play in:")
        id: effectsPlayVideoInput
        Layout.maximumWidth: 300
    }

    TextField {
        Kirigami.FormData.label: i18n("Pause in:")
        id: effectsPauseVideoInput
        Layout.maximumWidth: 300
    }

    TextField {
        Kirigami.FormData.label: i18n("Show blur in:")
        id: effectsShowBlurInput
        Layout.maximumWidth: 300
    }

    TextField {
        Kirigami.FormData.label: i18n("Hide blur in:")
        id: effectsHideBlurInput
        Layout.maximumWidth: 300
    }

    FileDialog {
        id: fileDialog
        fileMode : FileDialog.OpenFiles
        title: i18n("Pick a video file")
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

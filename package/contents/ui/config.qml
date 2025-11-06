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
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtMultimedia
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols 2.0 as KQuickControls
import "code/utils.js" as Utils
import "code/enum.js" as Enum
import "components" as Components

Kirigami.FormLayout {
    id: root
    twinFormLayouts: parentLayout // required by parent
    property alias formLayout: root // required by parent
    property alias cfg_FillMode: videoFillMode.currentValue
    property alias cfg_PauseMode: pauseModeCombo.currentValue
    property alias cfg_BackgroundColor: colorButton.color
    property alias cfg_PauseBatteryLevel: pauseBatteryLevel.value
    property alias cfg_BatteryPausesVideo: batteryPausesVideoCheckBox.checked
    property alias cfg_BlurMode: blurModeCombo.currentValue
    property alias cfg_BatteryDisablesBlur: batteryDisablesBlurCheckBox.checked
    property alias cfg_BlurRadius: blurRadiusSpinBox.value
    property string cfg_VideoUrls
    property var videosConfig: Utils.parseCompat(cfg_VideoUrls)
    property bool isLoading: false
    property alias cfg_ScreenOffPausesVideo: screenOffPausesVideoCheckbox.checked
    property alias cfg_ScreenStateCmd: screenStateCmdTextField.text
    property bool showWarningMessage: false
    property alias cfg_CheckWindowsActiveScreen: activeScreenOnlyCheckbx.checked
    property alias cfg_DebugEnabled: debugEnabledCheckbox.checked
    property alias cfg_EffectsPlayVideo: effectsPlayVideoInput.text
    // property string cfg_EffectsPlayVideo
    property alias cfg_EffectsPauseVideo: effectsPauseVideoInput.text
    property alias cfg_EffectsShowBlur: effectsShowBlurInput.text
    property alias cfg_EffectsHideBlur: effectsHideBlurInput.text
    property alias cfg_BlurAnimationDuration: blurAnimationDurationSpinBox.value
    property alias cfg_CrossfadeEnabled: crossfadeEnabledCheckbox.checked
    property alias cfg_CrossfadeDuration: crossfadeDurationSpinBox.value
    property alias cfg_PlaybackRate: playbackRateSlider.value
    property alias cfg_Volume: volumeSlider.value
    property alias cfg_RandomMode: randomModeCheckbox.checked
    property alias cfg_ResumeLastVideo: resumeLastVideoCheckbox.checked
    property alias cfg_ChangeWallpaperMode: changeWallpaperModeComboBox.currentValue
    property alias cfg_ChangeWallpaperTimerMinutes: changeWallpaperTimerMinutesSpinBox.value
    property alias cfg_ChangeWallpaperTimerHours: changeWallpaperTimerHoursSpinBox.value
    property int currentTab
    property bool showVideosList: false
    property var isLockScreenSettings: null
    property alias cfg_MuteMode: muteModeCombo.currentValue
    property int editingIndex: -1

    Components.Header {
        Layout.leftMargin: Kirigami.Units.mediumSpacing
        Layout.rightMargin: Kirigami.Units.mediumSpacing
    }

    Kirigami.NavigationTabBar {
        Layout.preferredWidth: 400
        maximumContentWidth: {
            const minDelegateWidth = Kirigami.Units.gridUnit * 6;
            // Always have at least the width of 5 items, so that small amounts of actions look natural.
            return minDelegateWidth * Math.max(visibleActions.length, 5);
        }
        actions: [
            Kirigami.Action {
                icon.name: "folder-video-symbolic"
                text: i18n("Videos")
                checked: currentTab === 0
                onTriggered: currentTab = 0
            },
            Kirigami.Action {
                icon.name: "media-playback-start-symbolic"
                text: i18n("Playback")
                checked: currentTab === 1
                onTriggered: currentTab = 1
            },
            // Kirigami.Action {
            //     icon.name: "battery-low-symbolic"
            //     text: "Power"
            //     checked: currentTab === 2
            //     onTriggered: currentTab = 2
            // },
            Kirigami.Action {
                icon.name: "star-shape-symbolic"
                text: i18n("Desktop Effects")
                checked: currentTab === 3
                onTriggered: currentTab = 3
            }
        ]
    }

    RowLayout {
        visible: currentTab === 0
        Button {
            id: imageButton
            icon.name: "folder-videos-symbolic"
            text: i18n("Add new videos")
            onClicked: {
                root.editingIndex = -1;
                fileDialog.open();
            }
        }
        Button {
            icon.name: "visibility-symbolic"
            text: showVideosList ? i18n("Hide videos list") : i18n("Show videos list")
            checkable: true
            checked: showVideosList
            onClicked: {
                if (currentTab !== 0) {
                    showVideosList = false;
                } else {
                    showVideosList = !showVideosList;
                }
            }
        }
    }

    ColumnLayout {
        id: videosList
        visible: showVideosList && currentTab === 0
        Repeater {
            model: Object.keys(videosConfig)
            RowLayout {
                required property var modelData
                required property int index
                CheckBox {
                    id: vidEnabled
                    checked: videosConfig[modelData].enabled
                    onCheckedChanged: {
                        videosConfig[modelData].enabled = checked;
                        Utils.updateConfig();
                    }
                }
                TextField {
                    text: videosConfig[modelData].filename
                    Layout.preferredWidth: 300
                    onTextChanged: {
                        videosConfig[modelData].filename = text;
                        Utils.updateConfig();
                    }
                }
                Button {
                    icon.name: "document-open"
                    ToolTip.delay: 1000
                    ToolTip.visible: hovered
                    ToolTip.text: "Pick a file"
                    onClicked: {
                        editingIndex = index;
                        fileDialog.open();
                    }
                }
                RowLayout {
                    enabled: vidEnabled.checked
                    // SpinBox {
                    //     from: 0
                    //     to: 3600
                    //     value: videosConfig[modelData].duration
                    //     onValueChanged: {
                    //         videosConfig[modelData].duration = value
                    //         Utils.updateConfig()
                    //     }
                    // }
                    Button {
                        icon.name: "go-up-symbolic"
                        enabled: index > 0
                        onClicked: {
                            const swapIndex = index - 1;
                            const swapItem = videosConfig[swapIndex];
                            videosConfig[swapIndex] = videosConfig[index];
                            videosConfig[index] = swapItem;
                            Utils.updateConfig();
                        }
                    }
                    Button {
                        icon.name: "go-down-symbolic"
                        enabled: index < videosConfig.length - 1
                        onClicked: {
                            const swapIndex = index + 1;
                            const swapItem = videosConfig[swapIndex];
                            videosConfig[swapIndex] = videosConfig[index];
                            videosConfig[index] = swapItem;
                            Utils.updateConfig();
                        }
                    }
                    Button {
                        icon.name: "preferences-other"
                        enabled: true
                        onClicked: {
                            videoConfigDialog.playbackRate = videosConfig[modelData].playbackRate;
                            videoConfigDialog.loop = videosConfig[modelData].loop ?? false;
                            videoConfigDialog.index = index;
                            videoConfigDialog.open();
                        }
                    }
                }
                Button {
                    icon.name: "edit-delete-remove"
                    onClicked: {
                        videosConfig.splice(index, 1);
                        Utils.updateConfig();
                    }
                }
            }
        }
    }

    Button {
        visible: currentTab === 0
        icon.name: "dialog-warning-symbolic"
        text: i18n("Warning! Please read before applying (click to show)")
        checkable: true
        checked: showWarningMessage
        onClicked: {
            showWarningMessage = !showWarningMessage;
        }
        highlighted: true
        Kirigami.Theme.inherit: false
        Kirigami.Theme.textColor: root.Kirigami.Theme.neutralTextColor
        Kirigami.Theme.highlightColor: root.Kirigami.Theme.neutralTextColor
        icon.color: Kirigami.Theme.neutralTextColor
    }

    Kirigami.InlineMessage {
        id: warningResources
        Layout.fillWidth: true
        type: Kirigami.MessageType.Warning
        text: i18n("Videos are loaded in RAM, bigger files will use more system resources!")
        visible: showWarningMessage && currentTab === 0
    }
    Kirigami.InlineMessage {
        id: warningCrashes
        Layout.fillWidth: true
        type: Kirigami.MessageType.Warning
        text: i18n("Crashes/Black screen? Try changing the Qt Media Backend to gstreamer.<br>To recover from crash remove the videos from the configuration using this command below in terminal/tty then reboot:<br><strong><code>sed -i 's/^VideoUrls=.*$/VideoUrls=/g' $HOME/.config/plasma-org.kde.plasma.desktop-appletsrc $HOME/.config/kscreenlockerrc</code></strong>")
        visible: showWarningMessage && currentTab === 0
        actions: [
            Kirigami.Action {
                icon.name: "view-readermode-symbolic"
                text: i18n("Qt Media backend instructions")
                onTriggered: {
                    Qt.openUrlExternally("https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn?tab=readme-ov-file#black-video-or-plasma-crashes");
                }
            }
        ]
    }
    Kirigami.InlineMessage {
        id: warningHwAccel
        Layout.fillWidth: true
        text: i18n("Make sure to enable Hardware video acceleration in your system to reduce CPU/GPU usage when videos are playing.")
        visible: showWarningMessage && currentTab === 0
        actions: [
            Kirigami.Action {
                icon.name: "view-readermode-symbolic"
                text: i18n("Learn how")
                onTriggered: {
                    Qt.openUrlExternally("https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn?tab=readme-ov-file#improve-performance-by-enabling-hardware-video-acceleration");
                }
            }
        ]
    }

    ComboBox {
        id: videoFillMode
        Kirigami.FormData.label: i18n("Positioning:")
        model: [
            {
                text: i18n("Stretch"),
                value: VideoOutput.Stretch
            },
            {
                text: i18n("Keep Proportions"),
                value: VideoOutput.PreserveAspectFit
            },
            {
                text: i18n("Scaled and Cropped"),
                value: VideoOutput.PreserveAspectCrop
            }
        ]
        textRole: "text"
        valueRole: "value"
        visible: currentTab === 0
    }

    KQuickControls.ColorButton {
        id: colorButton
        Kirigami.FormData.label: i18n("Background:")
        visible: cfg_FillMode === VideoOutput.PreserveAspectFit && currentTab === 0
        dialogTitle: i18n("Select Background Color")
    }

    RowLayout {
        visible: currentTab === 1
        Kirigami.FormData.label: i18n("Change Wallpaper:")
        ComboBox {
            id: changeWallpaperModeComboBox
            model: [
                {
                    text: i18n("Never"),
                    value: Enum.ChangeWallpaperMode.Never
                },
                {
                    text: i18n("Slideshow"),
                    value: Enum.ChangeWallpaperMode.Slideshow
                },
                {
                    text: i18n("On a Timer"),
                    value: Enum.ChangeWallpaperMode.OnATimer
                }
            ]
            textRole: "text"
            valueRole: "value"
        }
        Kirigami.ContextualHelpButton {
            toolTipText: i18n("Automatically play the next video using the selected strategy. You can also change the wallpaper manually using <strong>Next Video</strong> from the Desktop right click menu.")
        }
    }

    RowLayout {
        visible: currentTab === 1 && changeWallpaperModeComboBox.currentIndex === Enum.ChangeWallpaperMode.OnATimer
        Label {
            text: i18n("Hours:")
        }
        SpinBox {
            id: changeWallpaperTimerHoursSpinBox
            from: 0
            to: 12
            stepSize: 1
        }
        Label {
            text: i18n("Minutes:")
        }
        SpinBox {
            id: changeWallpaperTimerMinutesSpinBox
            from: changeWallpaperTimerHoursSpinBox.value > 0 ? 0 : 1
            to: 59
            stepSize: 1
        }
    }

    CheckBox {
        id: randomModeCheckbox
        Kirigami.FormData.label: i18n("Random order:")
        visible: currentTab === 1
    }

    CheckBox {
        id: resumeLastVideoCheckbox
        Kirigami.FormData.label: i18n("Resume last video on startup:")
        visible: currentTab === 1
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Speed:")
        visible: currentTab === 1
        Layout.preferredWidth: 300
        Slider {
            id: playbackRateSlider
            from: 0
            value: cfg_PlaybackRate
            to: 2
            stepSize: 0.05
            Layout.fillWidth: true
        }
        Label {
            text: parseFloat(playbackRateSlider.value).toFixed(2) + "x"
        }
        Button {
            icon.name: "edit-undo-symbolic"
            flat: true
            onClicked: {
                playbackRateSlider.value = 1.0;
            }
            ToolTip.text: i18n("Reset to default")
            ToolTip.visible: hovered
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Crossfade (Beta):")
        visible: currentTab === 1
        CheckBox {
            id: crossfadeEnabledCheckbox
        }
        Label {
            text: i18n("Duration:")
        }
        SpinBox {
            id: crossfadeDurationSpinBox
            enabled: crossfadeEnabledCheckbox.checked
            from: 0
            to: 99999
            stepSize: 100
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
        id: activeScreenOnlyCheckbx
        Kirigami.FormData.label: i18n("Filter windows:")
        text: i18n("This screen only")
        visible: !root.isLockScreenSettings && currentTab === 1
    }

    ComboBox {
        id: pauseModeCombo
        Kirigami.FormData.label: i18n("Pause:")
        model: [
            {
                text: i18n("Maximized or full-screen windows"),
                value: Enum.PauseMode.MaximizedOrFullScreen
            },
            {
                text: i18n("Active window"),
                value: Enum.PauseMode.ActiveWindowPresent
            },
            {
                text: i18n("At least one window is visible"),
                value: Enum.PauseMode.WindowVisible
            },
            {
                text: i18n("Never"),
                value: Enum.PauseMode.Never
            }
        ]
        textRole: "text"
        valueRole: "value"
        visible: !root.isLockScreenSettings && currentTab === 1
    }

    property var muteModeModel: {
        // options for desktop and lock screen
        let model = [
            // TODO implement detection
            // {
            //     text: i18n("Other application is playing audio"),
            //     value: 3
            // },
            {
                text: i18n("Never"),
                value: Enum.MuteMode.Never
            },
            {
                text: i18n("Always"),
                value: Enum.MuteMode.Always
            },
        ];
        // options exclusive to desktop mode
        const desktopOptions = [
            {
                text: i18n("Maximized or full-screen windows"),
                value: Enum.MuteMode.MaximizedOrFullScreen
            },
            {
                text: i18n("Active window"),
                value: Enum.MuteMode.ActiveWindowPresent
            },
            {
                text: i18n("At least one window is visible"),
                value: Enum.MuteMode.WindowVisible
            }
        ];
        if (!isLockScreenSettings) {
            model.unshift(...desktopOptions);
        }
        return model;
    }

    ComboBox {
        id: muteModeCombo
        Kirigami.FormData.label: i18n("Mute:")
        model: muteModeModel
        textRole: "text"
        valueRole: "value"
        visible: currentTab === 1
    }

    RowLayout {
        visible: currentTab === 1 && cfg_MuteMode !== 5
        Label {
            text: i18n("Volume:")
        }
        Slider {
            id: volumeSlider
            from: 0
            to: 1
        }
        Label {
            text: parseFloat(volumeSlider.value).toFixed(2)
        }
        Button {
            icon.name: "edit-undo-symbolic"
            flat: true
            onClicked: {
                volumeSlider.value = 1.0;
            }
            ToolTip.text: i18n("Reset to default")
            ToolTip.visible: hovered
        }
    }

    property var blurModeModel: {
        // options for desktop and lock screen
        let model = [
            {
                text: i18n("Video is paused"),
                value: Enum.BlurMode.VideoPaused
            },
            {
                text: i18n("Always"),
                value: Enum.BlurMode.Always
            },
            {
                text: i18n("Never"),
                value: Enum.BlurMode.Never
            }
        ];
        // options exclusive to desktop mode
        const desktopOptions = [
            {
                text: i18n("Maximized or full-screen windows"),
                value: Enum.BlurMode.MaximizedOrFullScreen
            },
            {
                text: i18n("Active window"),
                value: Enum.BlurMode.ActiveWindowPresent
            },
            {
                text: i18n("At least one window is visible"),
                value: Enum.BlurMode.WindowVisible
            }
        ];
        if (!isLockScreenSettings) {
            model.unshift(...desktopOptions);
        }

        return model;
    }

    ComboBox {
        id: blurModeCombo
        Kirigami.FormData.label: i18n("Blur:")
        model: blurModeModel
        textRole: "text"
        valueRole: "value"
        visible: currentTab === 1
    }

    RowLayout {
        visible: currentTab === 1 && cfg_BlurMode !== 5
        Label {
            text: i18n("Radius:")
        }
        SpinBox {
            id: blurRadiusSpinBox
            from: 0
            to: 145
        }
        Button {
            visible: blurRadiusSpinBox.visible && cfg_BlurRadius > 64
            icon.name: "dialog-information-symbolic"
            ToolTip.text: i18n("Quality of the blur is reduced if value exceeds 64. Higher values may cause the blur to stop working!")
            hoverEnabled: true
            flat: true
            ToolTip.visible: hovered
            Kirigami.Theme.inherit: false
            Kirigami.Theme.textColor: root.Kirigami.Theme.neutralTextColor
            Kirigami.Theme.highlightColor: root.Kirigami.Theme.neutralTextColor
            icon.color: Kirigami.Theme.neutralTextColor
        }
        Label {
            text: i18n("Animation duration:")
        }
        SpinBox {
            id: blurAnimationDurationSpinBox
            from: 0
            to: 9999
            stepSize: 100
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("On battery below:")
        visible: currentTab === 1
        SpinBox {
            id: pauseBatteryLevel
            from: 0
            to: 100
        }
        CheckBox {
            id: batteryPausesVideoCheckBox
            text: i18n("Pause video")
        }

        CheckBox {
            id: batteryDisablesBlurCheckBox
            text: i18n("Disable blur")
            visible: blurRadiusSpinBox.visible
        }
    }

    CheckBox {
        id: screenOffPausesVideoCheckbox
        Kirigami.FormData.label: i18n("Pause on screen off:")
        text: i18n("Requires setting up command below!")
        visible: currentTab === 1
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Screen state command:")
        visible: screenOffPausesVideoCheckbox.checked && currentTab === 1
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
            display: AbstractButton.IconOnly
        }
    }

    CheckBox {
        id: debugEnabledCheckbox
        Kirigami.FormData.label: i18n("Enable debug:")
        text: i18n("Print debug messages to the system log")
        visible: currentTab === 0
    }

    EffectsModel {
        id: effects
        monitorActive: true
        monitorLoaded: true
        monitorActiveInterval: 500
    }

    TextEdit {
        wrapMode: Text.Wrap
        Layout.maximumWidth: 400
        readOnly: true
        textFormat: TextEdit.RichText
        text: i18n("Control how the Desktop Effects (e.g Overview or Peek at Desktop) affect the wallpaper when they become active. Comma separated names.")
        color: Kirigami.Theme.textColor
        selectedTextColor: Kirigami.Theme.highlightedTextColor
        selectionColor: Kirigami.Theme.highlightColor
        visible: root.currentTab === 3
    }

    Components.CheckableValueListView {
        id: effectsPlayVideoInput
        Kirigami.FormData.label: i18n("Play in:")
        visible: root.currentTab === 3
        model: effects.loadedEffects
    }

    Components.CheckableValueListView {
        id: effectsPauseVideoInput
        Layout.preferredWidth: 400
        Kirigami.FormData.label: i18n("Pause in:")
        visible: root.currentTab === 3
        model: effects.loadedEffects
    }

    Components.CheckableValueListView {
        id: effectsShowBlurInput
        Layout.preferredWidth: 400
        Kirigami.FormData.label: i18n("Show blur in:")
        visible: root.currentTab === 3
        model: effects.loadedEffects
    }

    Components.CheckableValueListView {
        id: effectsHideBlurInput
        Layout.preferredWidth: 400
        Kirigami.FormData.label: i18n("Hide blur in:")
        visible: root.currentTab === 3
        model: effects.loadedEffects
    }

    Label {
        text: i18n("Currently enabled and <u><strong><font color='%1'>active</font></strong></u> Desktop Effects:", Kirigami.Theme.positiveTextColor)
        visible: root.currentTab === 3
    }

    Kirigami.AbstractCard {
        visible: root.currentTab === 3
        Layout.maximumWidth: 400
        Layout.preferredWidth: 400
        contentItem: ColumnLayout {
            Label {
                text: i18n("Select to copy")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                color: Kirigami.Theme.disabledTextColor
            }
            Flow {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                Repeater {
                    model: effects.loadedEffects.sort()
                    Kirigami.SelectableLabel {
                        required property int index
                        required property string modelData
                        text: modelData
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        font.weight: effects.activeEffects.includes(modelData) ? Font.Bold : Font.Normal
                        font.underline: effects.activeEffects.includes(modelData)
                        color: effects.activeEffects.includes(modelData) ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
                        selectedTextColor: Kirigami.Theme.highlightedTextColor
                        selectionColor: Kirigami.Theme.highlightColor
                        rightPadding: Kirigami.Units.smallSpacing
                    }
                }
            }
        }
    }

    FileDialog {
        id: fileDialog
        fileMode: root.editingIndex === -1 ? FileDialog.OpenFiles : FileDialog.OpenFile
        title: i18n("Pick a video file")
        nameFilters: [i18n("Video files") + " (*.mp4 *.mpg *.ogg *.mov *.webm *.flv *.matroska *.avi *wmv *.gif)", i18n("All files") + " (*)"]
        onAccepted: {
            let currentFiles = root.cfg_VideoUrls.trim().split("\n");
            for (let file of fileDialog.selectedFiles) {
                console.log(file);
                if (root.videosConfig.filter(video => video.filename === file).length === 0) {
                    if (root.editingIndex !== -1) {
                        root.videosConfig[root.editingIndex] = Utils.createVideo(file);
                        root.editingIndex = -1;
                    } else {
                        root.videosConfig.push(Utils.createVideo(file));
                    }
                }
            }
            console.log(JSON.stringify(root.videosConfig));
            Utils.updateConfig();
        }
    }

    Components.VideoSettingsDialog {
        id: videoConfigDialog
        onAccepted: {
            root.videosConfig[index].playbackRate = playbackRate;
            root.videosConfig[index].loop = loop;
            Utils.updateConfig();
        }
    }

    Component.onCompleted: {
        let candidate = root.parent;
        while (candidate) {
            if (candidate && candidate.hasOwnProperty("configDialog")) {
                root.isLockScreenSettings = candidate.configDialog.toString().includes("ScreenLockerKcm");
                break;
            }
            candidate = candidate.parent;
        }
    }
}

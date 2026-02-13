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
import "code/enum.js" as Enum
import "components" as Components

/**
 * For proper alignment, an ancestor **MUST** have id "appearanceRoot" and property "parentLayout"
 */
ColumnLayout {
    id: root
    spacing: 0
    property var parentLayout
    property alias cfg_FillMode: videoFillMode.currentValue
    property alias cfg_PauseMode: pauseModeCombo.currentValue
    property alias cfg_AlternativePlaybackRateMode: alternativePlaybackRateMode.currentValue
    property alias cfg_BackgroundColor: colorButton.color
    property alias cfg_PauseBatteryLevel: pauseBatteryLevel.value
    property alias cfg_BatteryPausesVideo: batteryPausesVideoCheckBox.checked
    property alias cfg_BlurMode: blurModeCombo.currentValue
    property alias cfg_BatteryDisablesBlur: batteryDisablesBlurCheckBox.checked
    property alias cfg_BlurRadius: blurRadiusSpinBox.value
    property string cfg_VideoUrls
    property bool isLoading: false
    property alias cfg_ScreenOffPausesVideo: screenOffPausesVideoCheckbox.checked
    property alias cfg_ScreenStateCmd: screenStateCmdTextField.text
    property string cfg_ScreenStateCmdDefault
    property alias showWarningMessage: showWarning.checked
    property alias cfg_CheckWindowsActiveScreen: activeScreenOnlyCheckbx.checked
    property alias cfg_DebugEnabled: debugEnabledCheckbox.checked
    property alias cfg_EffectsPlayVideo: effectsPlayVideoInput.text
    // property string cfg_EffectsPlayVideo
    property alias cfg_EffectsPauseVideo: effectsPauseVideoInput.text
    property alias cfg_EffectsShowBlur: effectsShowBlurInput.text
    property alias cfg_EffectsHideBlur: effectsHideBlurInput.text
    property alias cfg_EffectsAlternativeSpeed: effectsAlternativeSpeedInput.text
    property alias cfg_BlurAnimationDuration: blurAnimationDurationSpinBox.value
    property alias cfg_CrossfadeEnabled: crossfadeEnabledCheckbox.checked
    property alias cfg_CrossfadeDuration: crossfadeDurationSpinBox.value
    property alias cfg_PrebufferNextVideo: prebufferNextVideoCheckbox.checked
    property real cfg_PlaybackRate
    property real cfg_AlternativePlaybackRate
    property alias cfg_Volume: volumeSlider.value
    property alias cfg_RandomMode: randomModeCheckbox.checked
    property alias cfg_ResumeLastVideo: resumeLastVideoCheckbox.checked
    property alias cfg_ChangeWallpaperMode: changeWallpaperModeComboBox.currentValue
    property alias cfg_ChangeWallpaperTimerSeconds: wallpaperTimerSeconds.value
    property alias cfg_ChangeWallpaperTimerMinutes: wallpaperTimerMinutes.value
    property alias cfg_ChangeWallpaperTimerHours: wallpaperTimerHours.value
    property alias cfg_FillBlur: blurRadioButton.checked
    property alias cfg_FillBlurRadius: fillBlurRadius.value
    property alias currentTab: tabBar.currentIndex
    property bool showVideosList: false
    property var isLockScreenSettings: null
    property alias cfg_MuteMode: muteModeCombo.currentValue
    property int editingIndex: -1
    property var validDropExtensions: [".mp4", ".mpg", ".ogg", ".mov", ".webm", ".flv", ".mkv", ".avi", ".wmv", ".gif"]

    readonly property int seconds: (wallpaperTimerHours.value * 60 * 60) + (wallpaperTimerMinutes.value * 60) + wallpaperTimerSeconds.value

    property var muteModeModel: {
        // options for desktop and lock screen
        let model = [
            // TODO implement detection
            // {
            //     text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Other application is playing audio"),
            //     value: 3
            // },
            {
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Never"),
                value: Enum.MuteMode.Never
            },
            {
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Always"),
                value: Enum.MuteMode.Always
            },
        ];
        // options exclusive to desktop mode
        const desktopOptions = [
            {
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Maximized or full-screen windows"),
                value: Enum.MuteMode.MaximizedOrFullScreen
            },
            {
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Active window"),
                value: Enum.MuteMode.ActiveWindowPresent
            },
            {
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "At least one window is visible"),
                value: Enum.MuteMode.WindowVisible
            }
        ];
        if (!isLockScreenSettings) {
            model.unshift(...desktopOptions);
        }
        return model;
    }

    property var blurModeModel: {
        // options for desktop and lock screen
        let model = [
            {
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Video is paused"),
                value: Enum.BlurMode.VideoPaused
            },
            {
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Always"),
                value: Enum.BlurMode.Always
            },
            {
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Never"),
                value: Enum.BlurMode.Never
            }
        ];
        // options exclusive to desktop mode
        const desktopOptions = [
            {
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Maximized or full-screen windows"),
                value: Enum.BlurMode.MaximizedOrFullScreen
            },
            {
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Active window"),
                value: Enum.BlurMode.ActiveWindowPresent
            },
            {
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "At least one window is visible"),
                value: Enum.BlurMode.WindowVisible
            }
        ];
        if (!isLockScreenSettings) {
            model.unshift(...desktopOptions);
        }

        return model;
    }

    function updateConfig() {
        let videos = new Array();
        for (let i = 0; i < videosModel.model.count; i++) {
            let item = videosModel.model.get(i);
            if (!item.filename) {
                continue;
            }
            videos.push({
                filename: item.filename,
                enabled: item.enabled,
                duration: item.duration,
                customDuration: item.customDuration,
                playbackRate: item.playbackRate,
                alternativePlaybackRate: item.alternativePlaybackRate,
                loop: item.loop
            });
        }
        cfg_VideoUrls = JSON.stringify(videos);
    }

    EffectsModel {
        id: effects
        monitorActive: true
        monitorLoaded: true
        monitorActiveInterval: 500
    }

    VideosModel {
        id: videosModel
        onUpdated: () => {
            root.updateConfig();
        }
    }

    Component.onCompleted: {
        videosModel.initModel(cfg_VideoUrls);
    }

    Kirigami.FormLayout {
        RowLayout {
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Version:")
            Components.Header {
                Layout.fillHeight: true
            }
            Button {
                id: showWarning
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Warning")
                icon.name: "dialog-warning"
                hoverEnabled: true
                ToolTip.text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Click to show")
                ToolTip.visible: hovered
                Kirigami.Theme.inherit: false
                Kirigami.Theme.textColor: root.Kirigami.Theme.neutralTextColor
                Kirigami.Theme.highlightColor: root.Kirigami.Theme.neutralTextColor
                icon.color: Kirigami.Theme.neutralTextColor
                checkable: true
                font.bold: true
                font.weight: Font.Bold
            }
        }
        Component.onCompleted: {
            // align with parent form from wallpaper config page
            if (typeof appearanceRoot !== "undefined") {
                twinFormLayouts.push(appearanceRoot.parentLayout);
            }
        }
    }

    Kirigami.NavigationTabBar {
        id: tabBar
        Layout.fillWidth: true
        currentIndex: 0
        onCurrentIndexChanged: {
            root.currentTab = currentIndex;
        }

        actions: [
            Kirigami.Action {
                icon.name: "emblem-videos-symbolic"
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Videos")
                checked: tabBar.currentIndex === 0
            },
            Kirigami.Action {
                icon.name: "media-playback-start-symbolic"
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Playback")
                checked: tabBar.currentIndex === 1
            },
            Kirigami.Action {
                icon.name: "star-shape-symbolic"
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Desktop Effects")
                checked: tabBar.currentIndex === 2
            },
            Kirigami.Action {
                icon.name: "emblem-favorite-symbolic"
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Donate")
                checked: tabBar.currentIndex === 3
            }
        ]
    }

    Kirigami.FormLayout {
        Item {
            Kirigami.FormData.isSection: true
        }

        Kirigami.InlineMessage {
            id: warningResources
            Layout.fillWidth: true
            type: Kirigami.MessageType.Warning
            text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Videos are loaded in RAM, bigger files will use more system resources!")
            visible: root.showWarningMessage
        }
        Kirigami.InlineMessage {
            id: warningCrashes
            Layout.fillWidth: true
            type: Kirigami.MessageType.Warning
            text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Crashes/Black screen? Try changing the Qt Media Backend to gstreamer.<br>To recover from crash remove the videos from the configuration using the command below in a terminal/tty then reboot:<br><strong><code>sed -i 's/^VideoUrls=.*$/VideoUrls=/g' $HOME/.config/plasma-org.kde.plasma.desktop-appletsrc $HOME/.config/kscreenlockerrc</code></strong>")
            visible: root.showWarningMessage
            actions: [
                Kirigami.Action {
                    icon.name: "view-readermode-symbolic"
                    text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Qt Media backend instructions")
                    onTriggered: {
                        Qt.openUrlExternally("https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn?tab=readme-ov-file#black-video-or-plasma-crashes");
                    }
                }
            ]
        }
        Kirigami.InlineMessage {
            id: warningHwAccel
            Layout.fillWidth: true
            text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Make sure to enable Hardware video acceleration in your system to reduce CPU/GPU usage when videos are playing.")
            visible: root.showWarningMessage
            actions: [
                Kirigami.Action {
                    icon.name: "view-readermode-symbolic"
                    text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Learn how")
                    onTriggered: {
                        Qt.openUrlExternally("https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn?tab=readme-ov-file#improve-performance-by-enabling-hardware-video-acceleration");
                    }
                }
            ]
        }

        RowLayout {
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Positioning:")
            visible: root.currentTab === 0
            ComboBox {
                id: videoFillMode
                model: [
                    {
                        text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Stretch"),
                        value: VideoOutput.Stretch
                    },
                    {
                        text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Keep Proportions"),
                        value: VideoOutput.PreserveAspectFit
                    },
                    {
                        text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Scaled and Cropped"),
                        value: VideoOutput.PreserveAspectCrop
                    }
                ]
                textRole: "text"
                valueRole: "value"
            }
        }
        // RowLayout {
        ButtonGroup {
            id: backgroundGroup
        }

        RowLayout {
            visible: root.currentTab === 0 && root.cfg_FillMode === VideoOutput.PreserveAspectFit
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Background:")
            RadioButton {
                id: blurRadioButton
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Blur")
                ButtonGroup.group: backgroundGroup
            }
            SpinBox {
                id: fillBlurRadius
                from: 0
                to: 145
                editable: true
                font.features: {
                    "tnum": 1
                }
                readonly property regexp reExtractNum: /\D*?(-?\d*\.?\d*)\D*$/

                validator: RegularExpressionValidator {
                    regularExpression: fillBlurRadius.reExtractNum
                }

                textFromValue: function (value, locale) {
                    return i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "radius: %1px", value);
                }
                valueFromText: function (text, locale) {
                    return Number.fromLocaleString(locale, reExtractNum.exec(text)[1]);
                }
            }
            Button {
                visible: root.cfg_FillBlurRadius > 64
                icon.name: "dialog-warning"
                ToolTip.text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Quality of the blur is reduced if value exceeds 64. Higher values may cause the blur to stop working!")
                hoverEnabled: true
                flat: true
                ToolTip.visible: hovered
                Kirigami.Theme.inherit: false
                Kirigami.Theme.textColor: root.Kirigami.Theme.neutralTextColor
                Kirigami.Theme.highlightColor: root.Kirigami.Theme.neutralTextColor
                icon.color: Kirigami.Theme.neutralTextColor
            }
        }
        RowLayout {
            visible: root.currentTab === 0 && root.cfg_FillMode === VideoOutput.PreserveAspectFit
            RadioButton {
                id: colorRadioButton
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Solid color")
                ButtonGroup.group: backgroundGroup
                checked: !root.cfg_FillBlur
            }
            KQuickControls.ColorButton {
                id: colorButton
                dialogTitle: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Select Background Color")
                ButtonGroup.group: backgroundGroup
            }
        }
        // }

        RowLayout {
            visible: root.currentTab === 1
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Change Wallpaper:")
            ComboBox {
                id: changeWallpaperModeComboBox
                model: [
                    {
                        text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Never"),
                        value: Enum.ChangeWallpaperMode.Never
                    },
                    {
                        text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Slideshow"),
                        value: Enum.ChangeWallpaperMode.Slideshow
                    },
                    {
                        text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "On a Timer"),
                        value: Enum.ChangeWallpaperMode.OnATimer
                    }
                ]
                textRole: "text"
                valueRole: "value"
            }
            Kirigami.ContextualHelpButton {
                toolTipText: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Automatically play the next video using the selected strategy. You can also change the wallpaper manually using <strong>Next Video</strong> from the Desktop right click menu.")
            }
        }

        RowLayout {
            visible: root.currentTab === 1 && changeWallpaperModeComboBox.currentIndex === Enum.ChangeWallpaperMode.OnATimer
            SpinBox {
                id: wallpaperTimerHours
                from: 0
                to: 12
                stepSize: 1
                editable: true
                font.features: {
                    "tnum": 1
                }
                readonly property regexp reExtractNum: /\D*?(-?\d*\.?\d*)\D*$/

                validator: RegularExpressionValidator {
                    regularExpression: wallpaperTimerHours.reExtractNum
                }
                textFromValue: function (value, locale) {
                    return i18np("%1 hour", "%1 hours", value);
                }
                valueFromText: function (text, locale) {
                    return Number.fromLocaleString(locale, reExtractNum.exec(text)[1]);
                }
            }
            SpinBox {
                id: wallpaperTimerMinutes
                from: 0
                to: 59
                stepSize: 1
                editable: true
                font.features: {
                    "tnum": 1
                }
                readonly property regexp reExtractNum: /\D*?(-?\d*\.?\d*)\D*$/

                validator: RegularExpressionValidator {
                    regularExpression: wallpaperTimerMinutes.reExtractNum
                }
                textFromValue: function (value, locale) {
                    return i18np("%1 minute", "%1 minutes", value);
                }
                valueFromText: function (text, locale) {
                    return parseInt(text);
                }
            }
            SpinBox {
                id: wallpaperTimerSeconds
                from: root.seconds > 0 ? 0 : 1
                to: 59
                stepSize: 1
                editable: true
                font.features: {
                    "tnum": 1
                }
                readonly property regexp reExtractNum: /\D*?(-?\d*\.?\d*)\D*$/

                validator: RegularExpressionValidator {
                    regularExpression: wallpaperTimerSeconds.reExtractNum
                }
                textFromValue: function (value, locale) {
                    return i18np("%1 second", "%1 seconds", value);
                }
                valueFromText: function (text, locale) {
                    return Number.fromLocaleString(locale, reExtractNum.exec(text)[0]);
                }
            }
        }

        CheckBox {
            id: randomModeCheckbox
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Random order:")
            visible: root.currentTab === 1
        }

        CheckBox {
            id: resumeLastVideoCheckbox
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Resume last video on startup:")
            visible: root.currentTab === 1
        }

        RowLayout {
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Speed:")
            visible: root.currentTab === 1
            Components.DoubleSpinBox {
                id: playbackRateGlobal
                from: 0.01 * multiplier
                to: 2 * multiplier
                value: root.cfg_PlaybackRate * multiplier
                stepSize: 0.01 * multiplier
                font.features: {
                    "tnum": 1
                }
                onValueModified: {
                    root.cfg_PlaybackRate = value / playbackRateGlobal.multiplier;
                }
            }
            Button {
                icon.name: "edit-undo-symbolic"
                flat: true
                onClicked: {
                    root.cfg_PlaybackRate = 1.0;
                }
                ToolTip.text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Reset to default")
                ToolTip.visible: hovered
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Crossfade (Beta):")
            visible: root.currentTab === 1
            CheckBox {
                id: crossfadeEnabledCheckbox
            }
            Label {
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Duration:")
            }
            SpinBox {
                id: crossfadeDurationSpinBox
                enabled: crossfadeEnabledCheckbox.checked
                from: 0
                to: 99999
                stepSize: 100
                font.features: {
                    "tnum": 1
                }
                readonly property regexp reExtractNum: /\D*?(-?\d*\.?,?\d*)\D*$/

                validator: RegularExpressionValidator {
                    regularExpression: crossfadeDurationSpinBox.reExtractNum
                }

                textFromValue: function (value, locale) {
                    return i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "%1ms", value);
                }
                valueFromText: function (text, locale) {
                    return Number.fromLocaleString(locale, reExtractNum.exec(text)[1]);
                }
            }
            Button {
                icon.name: "dialog-information-symbolic"
                ToolTip.text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Adds a smooth transition between videos. <strong>Uses additional Memory and may cause playback isues when enabled.</strong>")
                highlighted: true
                hoverEnabled: true
                ToolTip.visible: hovered
                Kirigami.Theme.inherit: false
                flat: true
            }
        }

        CheckBox {
            id: prebufferNextVideoCheckbox
            Kirigami.FormData.label: i18n("Preload next video:")
            text: i18n("Minimize loading of a 2nd video")
            visible: root.currentTab === 1
            ToolTip.text: i18n("Loads a 2nd video into memory for an instant transition")
            ToolTip.visible: hovered
        }

        CheckBox {
            id: activeScreenOnlyCheckbx
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Filter windows:")
            text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "This screen only")
            visible: !root.isLockScreenSettings && root.currentTab === 1
        }

        ComboBox {
            id: pauseModeCombo
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Pause:")
            model: [
                {
                    text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Maximized or full-screen windows"),
                    value: Enum.PauseMode.MaximizedOrFullScreen
                },
                {
                    text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Active window"),
                    value: Enum.PauseMode.ActiveWindowPresent
                },
                {
                    text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "At least one window is visible"),
                    value: Enum.PauseMode.WindowVisible
                },
                {
                    text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Never"),
                    value: Enum.PauseMode.Never
                }
            ]
            textRole: "text"
            valueRole: "value"
            visible: !root.isLockScreenSettings && root.currentTab === 1
        }

        ComboBox {
            id: muteModeCombo
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Mute:")
            model: root.muteModeModel
            textRole: "text"
            valueRole: "value"
            visible: root.currentTab === 1
        }

        RowLayout {
            visible: root.currentTab === 1 && root.cfg_MuteMode !== 5
            Label {
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Volume:")
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
                ToolTip.text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Reset to default")
                ToolTip.visible: hovered
            }
        }

        ComboBox {
            id: blurModeCombo
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Blur:")
            model: root.blurModeModel
            textRole: "text"
            valueRole: "value"
            visible: root.currentTab === 1
        }

        RowLayout {
            visible: root.currentTab === 1 && root.cfg_BlurMode !== 5
            Label {
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Radius:")
            }
            SpinBox {
                id: blurRadiusSpinBox
                from: 0
                to: 145
                font.features: {
                    "tnum": 1
                }
                readonly property regexp reExtractNum: /\D*?(-?\d*\.?\d*)\D*$/

                validator: RegularExpressionValidator {
                    regularExpression: blurRadiusSpinBox.reExtractNum
                }

                textFromValue: function (value, locale) {
                    return i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "%1px", value);
                }
                valueFromText: function (text, locale) {
                    return Number.fromLocaleString(locale, reExtractNum.exec(text)[1]);
                }
            }
            Button {
                visible: blurRadiusSpinBox.visible && root.cfg_BlurRadius > 64
                icon.name: "dialog-warning"
                ToolTip.text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Quality of the blur is reduced if value exceeds 64. Higher values may cause the blur to stop working!")
                hoverEnabled: true
                flat: true
                ToolTip.visible: hovered
                Kirigami.Theme.inherit: false
                Kirigami.Theme.textColor: root.Kirigami.Theme.neutralTextColor
                Kirigami.Theme.highlightColor: root.Kirigami.Theme.neutralTextColor
                icon.color: Kirigami.Theme.neutralTextColor
            }
            Label {
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Animation duration:")
            }
            SpinBox {
                id: blurAnimationDurationSpinBox
                from: 0
                to: 9999
                stepSize: 100
                font.features: {
                    "tnum": 1
                }

                readonly property regexp reExtractNum: /\D*?(-?\d*\.?\d*)\D*$/

                validator: RegularExpressionValidator {
                    regularExpression: blurAnimationDurationSpinBox.reExtractNum
                }

                textFromValue: function (value, locale) {
                    return i18nc("animation duration", "%1ms", value);
                }
                valueFromText: function (text, locale) {
                    return Number.fromLocaleString(locale, reExtractNum.exec(text)[1]);
                }
            }
        }

        ComboBox {
            id: alternativePlaybackRateMode
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Alternative speed:")
            model: [
                {
                    text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Maximized or full-screen windows"),
                    value: Enum.PauseMode.MaximizedOrFullScreen
                },
                {
                    text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Active window"),
                    value: Enum.PauseMode.ActiveWindowPresent
                },
                {
                    text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "At least one window is visible"),
                    value: Enum.PauseMode.WindowVisible
                },
                {
                    text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Never"),
                    value: Enum.PauseMode.Never
                }
            ]
            textRole: "text"
            valueRole: "value"
            visible: !root.isLockScreenSettings && root.currentTab === 1
        }

        RowLayout {
            visible: root.currentTab === 1 && root.cfg_AlternativePlaybackRateMode !== 3
            Label {
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Speed:")
            }
            Components.DoubleSpinBox {
                from: 0.01 * multiplier
                to: 2 * multiplier
                value: root.cfg_AlternativePlaybackRate * multiplier
                stepSize: 0.01 * multiplier
                font.features: {
                    "tnum": 1
                }
                onValueModified: {
                    root.cfg_AlternativePlaybackRate = value / multiplier;
                }
            }
            Button {
                icon.name: "edit-undo-symbolic"
                flat: true
                onClicked: {
                    root.cfg_AlternativePlaybackRate = 1.0;
                }
                ToolTip.text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Reset to default")
                ToolTip.visible: hovered
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "On battery below:")
            visible: root.currentTab === 1
            SpinBox {
                id: pauseBatteryLevel
                from: 0
                to: 100
                font.features: {
                    "tnum": 1
                }
                readonly property regexp reExtractNum: /\D*?(-?\d*\.?\d*)\D*$/

                validator: RegularExpressionValidator {
                    regularExpression: pauseBatteryLevel.reExtractNum
                }

                textFromValue: function (value, locale) {
                    return i18nc("battery level e.g 10%", "%1%", value);
                }
                valueFromText: function (text, locale) {
                    return Number.fromLocaleString(locale, reExtractNum.exec(text)[1]);
                }
            }
            CheckBox {
                id: batteryPausesVideoCheckBox
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Pause video")
            }

            CheckBox {
                id: batteryDisablesBlurCheckBox
                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Disable blur")
            }
        }

        CheckBox {
            id: screenOffPausesVideoCheckbox
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Pause on screen off:")
            visible: root.currentTab === 1
        }

        RowLayout {
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Screen state command:")
            visible: screenOffPausesVideoCheckbox.checked && root.currentTab === 1
            TextField {
                id: screenStateCmdTextField
                placeholderText: root.cfg_ScreenStateCmdDefault
                text: root.cfg_ScreenStateCmd
                Layout.maximumWidth: 300
            }
            Button {
                icon.name: "dialog-information-symbolic"
                ToolTip.text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "The command/script must return '0' (zero) or 'off' when the screen is off")
                highlighted: true
                hoverEnabled: true
                flat: true
                ToolTip.visible: hovered
                display: AbstractButton.IconOnly
            }
        }

        CheckBox {
            id: debugEnabledCheckbox
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Enable debug:")
            text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Print debug messages to the system log")
            visible: root.currentTab === 1
        }

        TextEdit {
            wrapMode: Text.Wrap
            Layout.maximumWidth: 400
            readOnly: true
            textFormat: TextEdit.RichText
            text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Control how the Desktop Effects (e.g Overview or Peek at Desktop) affect the wallpaper when they become active. Comma separated names.")
            color: Kirigami.Theme.textColor
            selectedTextColor: Kirigami.Theme.highlightedTextColor
            selectionColor: Kirigami.Theme.highlightColor
            visible: root.currentTab === 2
        }

        Components.CheckableValueListView {
            id: effectsPlayVideoInput
            Layout.maximumWidth: 400
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Play in:")
            visible: root.currentTab === 2
            model: effects.loadedEffects
        }

        Components.CheckableValueListView {
            id: effectsPauseVideoInput
            Layout.maximumWidth: 400
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Pause in:")
            visible: root.currentTab === 2
            model: effects.loadedEffects
        }

        Components.CheckableValueListView {
            id: effectsShowBlurInput
            Layout.maximumWidth: 400
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Show blur in:")
            visible: root.currentTab === 2
            model: effects.loadedEffects
        }

        Components.CheckableValueListView {
            id: effectsHideBlurInput
            Layout.maximumWidth: 400
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Hide blur in:")
            visible: root.currentTab === 2
            model: effects.loadedEffects
        }

        Components.CheckableValueListView {
            id: effectsAlternativeSpeedInput
            Layout.maximumWidth: 400
            Kirigami.FormData.label: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Alternative speed in:")
            visible: root.currentTab === 2
            model: effects.loadedEffects
        }

        Label {
            text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Currently enabled and <u><strong><font color='%1'>active</font></strong></u> Desktop Effects:", Kirigami.Theme.positiveTextColor)
            visible: root.currentTab === 2
        }

        Kirigami.AbstractCard {
            visible: root.currentTab === 2
            Layout.maximumWidth: 400
            Layout.preferredWidth: 400
            contentItem: ColumnLayout {
                Label {
                    text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Select to copy")
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

        Component.onCompleted: {
            // align with parent form from wallpaper config page
            if (typeof appearanceRoot !== "undefined") {
                twinFormLayouts.push(appearanceRoot.parentLayout);
            }

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

    Components.Donate {
        visible: root.currentTab === 3
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: Kirigami.Units.gridUnit
    }

    Item {
        Layout.fillHeight: true
        visible: root.currentTab !== 0
    }

    Kirigami.Separator {
        Layout.fillWidth: true
        visible: root.currentTab === 0
    }

    Component {
        id: inlineMessageComponent
        Kirigami.InlineMessage {
            visible: true
            width: dropArea.width
            type: Kirigami.MessageType.Information
            showCloseButton: true
            Timer {
                running: true
                interval: 5000
                onTriggered: parent.destroy()
            }
        }
    }

    DropArea {
        id: dropArea
        onEntered: drag => {
            if (drag.hasUrls) {
                drag.accept();
            }
        }
        onDropped: drop => {
            const validUrls = drop.urls.filter(url => {
                url = url.toString();
                const isValid = validDropExtensions.some(ext => url.endsWith(ext));
                if (!isValid) {
                    inlineMessageComponent.createObject(messagesList, {
                        text: `${url.toString()} invalid extension`,
                        type: Kirigami.MessageType.Warning
                    });
                }
                return isValid;
            });
            validUrls.forEach(function (url) {
                url = url.toString();
                if (videosModel.fileExists(url)) {
                    inlineMessageComponent.createObject(messagesList, {
                        text: `${url.toString()} already exists`
                    });
                } else {
                    videosModel.addItem(url);
                }
            });
        }
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.currentTab === 0
        Rectangle {
            anchors.fill: parent
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            color: Kirigami.Theme.backgroundColor
        }
        Kirigami.PlaceholderMessage {
            visible: videosModel.model.count === 0
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit * 2
            icon.name: "edit-none"
            text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "No items found \n add or drop some files")
        }
        ColumnLayout {
            id: messagesList
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            z: 2
        }
        ScrollView {
            anchors.fill: parent
            ListView {
                id: list
                model: videosModel.model
                clip: true
                spacing: 0
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                Kirigami.Theme.inherit: false
                headerPositioning: ListView.OverlayHeader
                header: Kirigami.InlineViewHeader {
                    width: list.width
                    text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Videos")
                    ToolButton {
                        icon.name: "view-list-details-symbolic"
                        text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Actions…")
                        onPressed: actionsMenu.opened ? actionsMenu.close() : actionsMenu.open()
                        Menu {
                            id: actionsMenu
                            y: parent.height
                            MenuItem {
                                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Disable all")
                                icon.name: "window-close-symbolic"
                                onClicked: videosModel.disableAll()
                            }
                            MenuItem {
                                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Enable all")
                                icon.name: "checkmark-symbolic"
                                onClicked: videosModel.enableAll()
                            }
                            MenuItem {
                                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Swap enabled state")
                                icon.name: "media-playlist-shuffle-symbolic"
                                onClicked: videosModel.toggleAll()
                            }
                            MenuItem {
                                text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Remove all")
                                icon.name: "list-remove-all-symbolic"
                                onClicked: {
                                    confirmationDialog.title = i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Remove all media?");
                                    confirmationDialog.callback = () => {
                                        videosModel.clear();
                                    };
                                    confirmationDialog.open();
                                }
                            }
                        }
                    }
                    ToolButton {
                        text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Pick a file…")
                        icon.name: "document-open"
                        onClicked: fileDialog.open()
                    }
                    ToolButton {
                        text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Enter path or url")
                        icon.name: "document-import-symbolic"
                        onClicked: videosModel.addItem()
                    }
                }
                delegate: Item {
                    id: itemDelegate
                    readonly property var view: ListView.view
                    required property int index
                    required property string filename
                    required property bool enabled
                    required property real playbackRate
                    required property real alternativePlaybackRate
                    required property bool loop
                    implicitWidth: ListView.view.width
                    implicitHeight: delegate.height
                    ItemDelegate {
                        id: delegate
                        implicitWidth: itemDelegate.implicitWidth
                        // There's no need for a list item to ever be selected
                        down: false
                        highlighted: false
                        background: Item {}
                        contentItem: RowLayout {
                            Kirigami.ListItemDragHandle {
                                visible: itemDelegate.view.count > 1
                                listItem: delegate
                                listView: itemDelegate.view
                                onMoveRequested: (oldIndex, newIndex) => {
                                    videosModel.moveItem(oldIndex, newIndex, 1);
                                }
                            }
                            Button {
                                icon.name: itemDelegate.enabled ? "checkmark-symbolic" : "dialog-close-symbolic"
                                checkable: true
                                checked: itemDelegate.enabled
                                highlighted: itemDelegate.enabled
                                icon.color: itemDelegate.enabled ? root.Kirigami.Theme.highlightColor : root.Kirigami.Theme.textColor
                                onCheckedChanged: videosModel.updateItem(itemDelegate.index, "enabled", checked)
                                Layout.fillHeight: true
                                Layout.preferredWidth: height
                                Kirigami.Theme.colorSet: root.Kirigami.Theme.View
                                Kirigami.Theme.textColor: itemDelegate.enabled ? root.Kirigami.Theme.highlightColor : root.Kirigami.Theme.textColor
                                Kirigami.Theme.highlightColor: itemDelegate.enabled ? root.Kirigami.Theme.highlightColor : root.Kirigami.Theme.highlightColor
                                ToolTip.delay: 1000
                                ToolTip.visible: hovered
                                ToolTip.text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Whether or not this video will be played")
                            }
                            RowLayout {
                                enabled: itemDelegate.enabled
                                HoverHandler {
                                    id: filenameHoverHandler
                                    enabled: itemDelegate.enabled
                                }
                                Label {
                                    id: filenamePreview
                                    text: itemDelegate.filename
                                    elide: Text.ElideRight
                                    color: Kirigami.Theme.textColor
                                    visible: (!filenameHoverHandler.hovered && !filenameTextField.cursorVisible) && itemDelegate.filename !== ""
                                    Layout.fillWidth: true
                                    Layout.leftMargin: filenameTextField.padding ?? 6
                                }
                                TextField {
                                    id: filenameTextField
                                    text: itemDelegate.filename
                                    placeholderText: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Local file or static url")
                                    visible: !filenamePreview.visible
                                    onTextChanged: videosModel.updateItem(itemDelegate.index, "filename", text)
                                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                                    Layout.fillWidth: true
                                    ToolTip.delay: 1000
                                    ToolTip.visible: hovered
                                    ToolTip.text: placeholderText
                                    Component.onCompleted: {
                                        if (!text) {
                                            filenameTextField.forceActiveFocus();
                                        }
                                    }
                                }
                            }

                            Components.DoubleSpinBox {
                                id: playbackRate
                                from: 0
                                to: 2 * multiplier
                                value: itemDelegate.playbackRate * multiplier
                                stepSize: 0.01 * multiplier
                                enabled: itemDelegate.enabled
                                font.features: {
                                    "tnum": 1
                                }
                                onValueModified: {
                                    videosModel.updateItem(itemDelegate.index, "playbackRate", value / playbackRate.multiplier);
                                }
                                ToolTip.delay: 1000
                                ToolTip.visible: hovered
                                ToolTip.text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Playback speed for this video. Minimum accepted is 0.01, set to 0.0 to ignore this setting.")
                            }

                            Components.DoubleSpinBox {
                                from: 0
                                to: 2 * multiplier
                                value: itemDelegate.alternativePlaybackRate * multiplier
                                stepSize: 0.01 * multiplier
                                enabled: itemDelegate.enabled
                                font.features: {
                                    "tnum": 1
                                }
                                onValueModified: {
                                    videosModel.updateItem(itemDelegate.index, "alternativePlaybackRate", value / multiplier);
                                }
                                ToolTip.delay: 1000
                                ToolTip.visible: hovered
                                ToolTip.text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Alternative playback speed for this video. Minimum accepted is 0.01, set to 0.0 to ignore this setting.")
                            }
                            Button {
                                icon.name: "media-repeat-single-symbolic"
                                checkable: true
                                checked: itemDelegate.loop
                                enabled: itemDelegate.enabled
                                highlighted: itemDelegate.loop
                                icon.color: itemDelegate.loop ? Kirigami.Theme.highlightColor : root.Kirigami.Theme.textColor
                                onCheckedChanged: videosModel.updateItem(itemDelegate.index, "loop", checked)
                                Layout.fillHeight: true
                                Layout.preferredWidth: height
                                Kirigami.Theme.colorSet: Kirigami.Theme.View
                                Kirigami.Theme.textColor: itemDelegate.loop ? Kirigami.Theme.highlightColor : root.Kirigami.Theme.textColor
                                Kirigami.Theme.highlightColor: itemDelegate.loop ? Kirigami.Theme.highlightColor : root.Kirigami.Theme.highlightColor
                                ToolTip.delay: 1000
                                ToolTip.visible: hovered
                                ToolTip.text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "If enabled the video will repeat instead of playing the next one.<br>Use <strong>Next Video</strong> from the Desktop right click menu to play the next video in the list.")
                            }
                            Button {
                                icon.name: "document-open"
                                enabled: itemDelegate.enabled
                                onClicked: {
                                    root.editingIndex = itemDelegate.index;
                                    fileDialog.open();
                                }
                                Layout.fillHeight: true
                                Layout.preferredWidth: height
                                Kirigami.Theme.colorSet: Kirigami.Theme.View
                                ToolTip.delay: 1000
                                ToolTip.visible: hovered
                                ToolTip.text: "Pick a file"
                            }
                            Button {
                                icon.name: "overflow-menu-symbolic"
                                onPressed: mediaMenu.opened ? mediaMenu.close() : mediaMenu.open()
                                Layout.fillHeight: true
                                Layout.preferredWidth: height
                                Kirigami.Theme.colorSet: Kirigami.Theme.View
                                ToolTip.delay: 1000
                                ToolTip.visible: hovered
                                ToolTip.text: "More actions"
                                Menu {
                                    id: mediaMenu
                                    y: parent.height
                                    MenuItem {
                                        text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Preview…")
                                        icon.name: "document-preview-symbolic"
                                        onClicked: {
                                            Qt.openUrlExternally(itemDelegate.filename);
                                        }
                                    }
                                    MenuItem {
                                        text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Open containing folder")
                                        icon.name: "document-open-folder-symbolic"
                                        onClicked: {
                                            dbusOpenContainingFolder.arguments = [itemDelegate.filename, ""];
                                            dbusOpenContainingFolder.call();
                                        }
                                    }
                                    MenuItem {
                                        text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Play this file only (disable all others)")
                                        icon.name: "media-playback-start-symbolic"
                                        onClicked: videosModel.disableAllOthers(itemDelegate.index)
                                    }
                                }
                            }
                            Button {
                                icon.name: "list-remove-symbolic"
                                icon.color: Kirigami.Theme.negativeTextColor
                                onClicked: {
                                    confirmationDialog.title = i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Remove media?");
                                    confirmationDialog.callback = () => {
                                        videosModel.removeItem(itemDelegate.index, 1);
                                    };
                                    confirmationDialog.open();
                                }
                                Layout.fillHeight: true
                                Layout.preferredWidth: height
                                Kirigami.Theme.colorSet: Kirigami.Theme.View
                                ToolTip.delay: 1000
                                ToolTip.visible: hovered
                                ToolTip.text: "Remove from list"
                            }
                        }
                    }
                }
            }
        }
    }

    FileDialog {
        id: fileDialog
        fileMode: root.editingIndex === -1 ? FileDialog.OpenFiles : FileDialog.OpenFile
        title: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Pick a video file")
        nameFilters: [i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "Video files") + " (*.mp4 *.mpg *.ogg *.mov *.webm *.flv *.matroska *.avi *wmv *.gif)", i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "All files") + " (*)"]
        onAccepted: {
            for (let file of fileDialog.selectedFiles) {
                file = file.toString();
                if (videosModel.fileExists(file)) {
                    continue;
                }

                if (root.editingIndex !== -1) {
                    videosModel.updateItem(root.editingIndex, "filename", file);
                    root.editingIndex = -1;
                } else {
                    videosModel.addItem(file);
                }
            }
        }
    }

    Kirigami.PromptDialog {
        id: confirmationDialog
        title: "Remove all media?"
        property var callback
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: {
            callback();
        }
    }

    DBusMethodCall {
        id: dbusOpenContainingFolder
        service: "org.freedesktop.FileManager1"
        iface: "org.freedesktop.FileManager1"
        objectPath: "/org/freedesktop/FileManager1"
        method: "ShowItems"
    }
}

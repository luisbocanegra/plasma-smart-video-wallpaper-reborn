import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.Dialog {
    id: root
    standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
    title: i18n("Video Settings")
    padding: Kirigami.Units.largeSpacing

    property int index
    property real playbackRate
    property bool loop
    property string filename: ""

    Kirigami.FormLayout {
        Label {
            text: root.filename
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Playback speed:")
            Slider {
                id: dialogPlaybackRateSpeed
                from: 0
                to: 2
                stepSize: 0.05
                value: root.playbackRate
                onValueChanged: {
                    root.playbackRate = value;
                }
                Layout.preferredWidth: 200
            }
            Label {
                text: parseFloat(dialogPlaybackRateSpeed.value).toFixed(2) + "x"
                font.features: {
                    "tnum": 1
                }
            }
            Button {
                icon.name: "edit-undo-symbolic"
                flat: true
                onClicked: {
                    dialogPlaybackRateSpeed.value = 0.0;
                }
                ToolTip.text: i18n("Reset to default")
                ToolTip.visible: hovered
            }
            Kirigami.ContextualHelpButton {
                toolTipText: i18n("Playback speed for this video. Set 0.0 to disable")
            }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Loop:")
            CheckBox {
                checked: root.loop
                onCheckedChanged: root.loop = checked
            }
            Kirigami.ContextualHelpButton {
                toolTipText: i18n("If enabled the video will loop continuously instead of playing the next one.<br>Use the <strong>Next Video</strong> option to play the next video in the list.")
            }
        }
    }
}

import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    required property string label
    property int value

    Label {
        text: root.label
    }
    SpinBox {
        id: hours
        from: 0
        to: 23
        value: Math.floor(root.value / 60)
        editable: true
        textFromValue: (value) => value.toString().padStart(2, '0')
        valueFromText: (text) => parseInt(text, 10)
        onValueModified: {
            root.value = hours.value * 60 + minutes.value
        }
    }
    SpinBox {
        id: minutes
        from: 0
        to: 59
        value: root.value % 60
        editable: true
        textFromValue: (value) => value.toString().padStart(2, '0')
        valueFromText: (text) => parseInt(text, 10)
        onValueModified: {
            root.value = hours.value * 60 + minutes.value
        }
    }
}

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root
    Layout.preferredWidth: 400
    property var model: []
    property var selectedValues: []
    property string text
    property bool showList: false
    Component.onCompleted: selectedValues = text.split(",")
    function update() {
        text = selectedValues.join(",");
    }

    RowLayout {
        TextField {
            id: field
            text: root.text
            Layout.fillWidth: true
            color: field.text !== "" ? (isValid ? Kirigami.Theme.textColor : Kirigami.Theme.negativeTextColor) : Kirigami.Theme.disabledTextColor
            property bool isValid: true
            onTextChanged: {
                checkValid();
                if (isValid) {
                    root.selectedValues = text.split(",");
                    root.update();
                }
            }
            function checkValid() {
                isValid = field.text === "" || field.text.split(",").every(item => model.includes(item));
            }
            Component.onCompleted: {
                root.modelChanged.connect(() => {
                    checkValid();
                });
            }
            placeholderText: i18n("Not configured")
        }
        Button {
            icon.name: root.showList ? "arrow-up" : "arrow-down"
            onClicked: {
                root.showList = !root.showList;
            }
            checkable: true
            checked: root.showList
        }
    }

    Kirigami.AbstractCard {
        visible: root.showList
        Layout.preferredHeight: Math.min(implicitHeight + 20, 200)
        contentItem: ScrollView {
            Layout.fillWidth: true
            ListView {
                id: listView
                model: root.model.sort()
                Layout.preferredWidth: Math.min(width + 50, 100)
                reuseItems: true
                clip: true
                focus: true
                activeFocusOnTab: true
                keyNavigationEnabled: true
                delegate: ItemDelegate {
                    id: delegateItem
                    width: ListView.view.width
                    focus: true
                    required property var modelData
                    contentItem: CheckBox {
                        id: presetCheckbox
                        checked: root.selectedValues.includes(delegateItem.modelData)
                        Layout.rightMargin: Kirigami.Units.smallSpacing * 4
                        Layout.fillWidth: true
                        text: delegateItem.modelData
                        onClicked: {
                            if (!root.selectedValues.includes(delegateItem.modelData)) {
                                root.selectedValues.push(delegateItem.modelData);
                            } else {
                                root.selectedValues = root.selectedValues.filter(p => p !== delegateItem.modelData);
                            }
                            root.update();
                        }
                    }
                    onClicked: {
                        if (!root.selectedValues.includes(delegateItem.modelData)) {
                            root.selectedValues.push(delegateItem.modelData);
                        } else {
                            root.selectedValues = root.selectedValues.filter(p => p !== delegateItem.modelData);
                        }
                        root.update();
                    }
                }
                highlight: Item {}
                highlightMoveDuration: 0
                highlightResizeDuration: 0
            }
        }
    }
}

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import SdlGamepadKeyNavigation 1.0

NavigableDialog {
    id: keyboard
    font.pixelSize: 18 * window.uiScale
    title: qsTr("On-screen keyboard")
    width: Math.min(window.width - 40, 1000 * window.uiScale)
    property var targetField
    property string draft: ""
    property bool numericOnly: false
    property bool uppercase: false
    property bool previousNavMode: false
    property var keys: numericOnly ? "1234567890.:".split("") : "1234567890qwertyuiopasdfghjkl-zxcvbnm._:".split("")
    function edit(field, numeric) {
        targetField = field
        draft = field.text
        numericOnly = numeric
        uppercase = false
        open()
    }
    function move(index, delta) {
        var next = index + delta
        if (next >= keys.length) doneButton.forceActiveFocus()
        else if (next >= 0) keyButtons.itemAt(next).forceActiveFocus()
    }
    onAboutToShow: {
        previousNavMode = SdlGamepadKeyNavigation.getUiNavMode()
        SdlGamepadKeyNavigation.setUiNavMode(false)
    }
    onOpened: keyButtons.itemAt(0).forceActiveFocus()
    onClosed: {
        SdlGamepadKeyNavigation.setUiNavMode(previousNavMode)
        if (targetField) targetField.forceActiveFocus()
    }
    contentItem: ColumnLayout {
        spacing: 12 * window.uiScale
        Label {
            Layout.fillWidth: true
            text: keyboard.draft.length ? keyboard.draft : qsTr("Select characters with the D-pad and A")
            font.pixelSize: 24 * window.uiScale
            wrapMode: Text.WrapAnywhere
        }
        GridLayout {
            columns: 10
            Layout.fillWidth: true
            Repeater {
                id: keyButtons
                model: keyboard.keys
                HandheldButton {
                    text: keyboard.uppercase ? modelData.toUpperCase() : modelData
                    Layout.fillWidth: true
                    implicitWidth: 65 * window.uiScale
                    implicitHeight: 48 * window.uiScale
                    onClicked: {
                        if (keyboard.draft.length < keyboard.targetField.maximumLength)
                            keyboard.draft += text
                    }
                    Keys.onLeftPressed: keyboard.move(index, -1)
                    Keys.onRightPressed: keyboard.move(index, 1)
                    Keys.onUpPressed: keyboard.move(index, -10)
                    Keys.onDownPressed: keyboard.move(index, 10)
                }
            }
        }
        RowLayout {
            HandheldButton { text: qsTr("Backspace"); onClicked: keyboard.draft = keyboard.draft.slice(0, -1) }
            HandheldButton { text: qsTr("Clear"); onClicked: keyboard.draft = "" }
            HandheldButton { text: qsTr("Space"); visible: !keyboard.numericOnly; onClicked: keyboard.draft += " " }
            HandheldButton { text: qsTr("Shift"); visible: !keyboard.numericOnly; onClicked: keyboard.uppercase = !keyboard.uppercase }
            HandheldButton {
                id: doneButton
                objectName: "keyboardDone"
                text: qsTr("Done")
                onClicked: { keyboard.targetField.text = keyboard.draft; keyboard.close() }
                Keys.onUpPressed: keyButtons.itemAt(keyboard.keys.length - 1).forceActiveFocus()
            }
            HandheldButton { text: qsTr("Cancel"); onClicked: keyboard.close() }
        }
    }
}

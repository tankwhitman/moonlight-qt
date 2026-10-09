import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import SdlGamepadKeyNavigation 1.0

NavigableDialog {
    id: dialog
    font.pixelSize: 18 * window.uiScale
    title: qsTr("Host connection")
    width: Math.min(window.width - 40, 760 * window.uiScale)
    property int selectedMode: 0
    property string errorText: ""
    property var editTarget: lanField
    signal saveRequested(int mode, string lan, string tailscale)

    function loadSettings(config) {
        selectedMode = config.mode
        lanField.text = config.lan === "<NULL>" ? "" : config.lan
        tailscaleField.text = config.tailscale
        errorText = ""
        autoButton.forceActiveFocus()
    }
    onAboutToShow: SdlGamepadKeyNavigation.setUiNavMode(true)
    onClosed: SdlGamepadKeyNavigation.setUiNavMode(false)

    contentItem: ColumnLayout {
        spacing: 8 * window.uiScale
        Label {
            Layout.fillWidth: true
            text: qsTr("Choose a route for this paired PC. An unavailable route stays offline.")
            wrapMode: Text.WordWrap
        }
        RowLayout {
            Repeater {
                model: [qsTr("Automatic"), qsTr("LAN"), qsTr("Tailscale")]
                HandheldButton {
                    id: modeButton
                    text: modelData
                    highlighted: dialog.selectedMode === index
                    Layout.fillWidth: true
                    onClicked: dialog.selectedMode = index
                    Component.onCompleted: { if (index === 0) autoButton = modeButton }
                }
            }
        }
        Label { text: qsTr("LAN IPv4 address (optional :port)") }
        TextField {
            id: lanField
            Layout.fillWidth: true
            placeholderText: "192.168.1.10:47989"
            onActiveFocusChanged: if (activeFocus) dialog.editTarget = lanField
        }
        Label { text: qsTr("Tailscale IPv4 address (optional :port)") }
        TextField {
            id: tailscaleField
            Layout.fillWidth: true
            placeholderText: "100.100.1.10:47989"
            onActiveFocusChanged: if (activeFocus) dialog.editTarget = tailscaleField
        }
        RowLayout {
            HandheldButton {
                text: qsTr("Edit LAN")
                Layout.fillWidth: true
                onClicked: { dialog.editTarget = lanField; keypad.itemAt(0).forceActiveFocus() }
            }
            HandheldButton {
                text: qsTr("Edit Tailscale")
                Layout.fillWidth: true
                onClicked: { dialog.editTarget = tailscaleField; keypad.itemAt(0).forceActiveFocus() }
            }
        }
        Label { text: dialog.editTarget === lanField ? qsTr("Keypad → LAN") : qsTr("Keypad → Tailscale") }
        GridLayout {
            columns: 7
            Layout.fillWidth: true
            Repeater {
                id: keypad
                model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", ".", ":", "⌫", qsTr("Clear")]
                HandheldButton {
                    text: modelData
                    Layout.fillWidth: true
                    implicitWidth: 55 * window.uiScale
                    onClicked: {
                        if (index === 12) dialog.editTarget.text = dialog.editTarget.text.slice(0, -1)
                        else if (index === 13) dialog.editTarget.clear()
                        else dialog.editTarget.text += modelData
                    }
                }
            }
        }
        Label {
            Layout.fillWidth: true
            visible: dialog.errorText.length > 0
            text: dialog.errorText
            color: "#ffb4ab"
            wrapMode: Text.WordWrap
        }
        RowLayout {
            HandheldButton {
                text: qsTr("Save connection")
                Layout.fillWidth: true
                onClicked: dialog.saveRequested(dialog.selectedMode, lanField.text, tailscaleField.text)
            }
            HandheldButton {
                text: qsTr("Cancel")
                Layout.fillWidth: true
                onClicked: dialog.close()
            }
        }
    }
    property var autoButton
}

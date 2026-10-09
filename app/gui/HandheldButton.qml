import QtQuick 2.9
import QtQuick.Controls 2.2

Button {
    implicitHeight: 48 * window.uiScale
    background: Rectangle {
        radius: 8
        color: parent.highlighted ? "#275b6c" : parent.down ? "#30475e" : "#233449"
        border.width: parent.activeFocus ? 3 : 1
        border.color: parent.activeFocus ? "#66d9ef" : "#3a5068"
    }
    contentItem: Text {
        text: parent.text
        color: "#f0f4fa"
        font.pixelSize: 18 * window.uiScale
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    focusPolicy: Qt.StrongFocus
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    Keys.onLeftPressed: nextItemInFocusChain(false).forceActiveFocus(Qt.TabFocusReason)
    Keys.onRightPressed: nextItemInFocusChain(true).forceActiveFocus(Qt.TabFocusReason)
}

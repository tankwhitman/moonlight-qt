import QtQuick 2.0
import QtQuick.Controls 2.5

Dialog {
    modal: true
    background: Rectangle { color: "#172232"; radius: 16; border.color: "#34485f" }
    Overlay.modal: Rectangle { color: "#b3000000" }
    anchors.centerIn: Overlay.overlay

    onClosed: {
        // We must force focus back to the last item. If we don't,
        // gamepad and keyboard navigation will break after a
        // dialog appears.
        stackView.forceActiveFocus()
    }
}

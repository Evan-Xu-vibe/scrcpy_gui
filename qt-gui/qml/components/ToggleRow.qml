import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ScrcpyGui

RowLayout {
    id: root
    property string title: ""
    property string description: ""
    property bool checked: false
    signal toggled(bool checked)
    spacing: 24
    implicitHeight: 62

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Label { text: root.title; color: Theme.text; font.weight: Font.DemiBold; font.pixelSize: 14 }
        Label { text: root.description; color: Theme.muted; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
    }
    Switch {
        id: toggle
        checked: root.checked
        enabled: root.enabled
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        implicitWidth: 42
        implicitHeight: 24
        indicator: Rectangle {
            implicitWidth: 42
            implicitHeight: 24
            x: toggle.leftPadding
            y: parent.height / 2 - height / 2
            radius: 12
            color: !toggle.enabled ? Theme.border : (toggle.checked ? Theme.blue : Theme.borderStrong)
            Rectangle {
                width: 18
                height: 18
                radius: 9
                anchors.verticalCenter: parent.verticalCenter
                x: toggle.checked ? parent.width - width - 3 : 3
                color: "white"
                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            }
        }
        onToggled: root.toggled(checked)
    }
}

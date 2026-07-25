import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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
        Label { text: root.title; font.weight: Font.DemiBold; color: palette.text }
        Label { text: root.description; color: palette.mid; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
    }
    Switch {
        checked: root.checked
        enabled: root.enabled
        onToggled: root.toggled(checked)
    }
}

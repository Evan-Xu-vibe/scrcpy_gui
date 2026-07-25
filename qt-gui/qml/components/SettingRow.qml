import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    property string title: ""
    property string description: ""
    default property alias control: controlSlot.data
    spacing: 28
    implicitHeight: 78

    ColumnLayout {
        Layout.fillWidth: true
        Layout.preferredWidth: 2
        spacing: 5
        Label { text: root.title; font.weight: Font.DemiBold; color: palette.text }
        Label { text: root.description; color: palette.mid; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
    }
    Item {
        id: controlSlot
        Layout.preferredWidth: 360
        Layout.maximumWidth: 420
        Layout.fillWidth: true
        implicitHeight: childrenRect.height
    }
}

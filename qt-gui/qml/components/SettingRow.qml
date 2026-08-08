import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ScrcpyGui

RowLayout {
    id: root
    property string title: ""
    property string description: ""
    default property alias control: controlSlot.data
    spacing: 32
    implicitHeight: 78

    ColumnLayout {
        Layout.fillWidth: true
        Layout.preferredWidth: 2
        spacing: 5
        Label { text: root.title; color: Theme.text; font.weight: Font.DemiBold; font.pixelSize: 14 }
        Label { text: root.description; color: Theme.muted; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
    }
    Item {
        id: controlSlot
        Layout.minimumWidth: 300
        Layout.preferredWidth: Math.min(440, Math.max(300, root.width * 0.52))
        Layout.maximumWidth: Math.min(440, Math.max(300, root.width * 0.52))
        Layout.fillWidth: false
        Layout.alignment: Qt.AlignRight
        implicitHeight: childrenRect.height
    }
}

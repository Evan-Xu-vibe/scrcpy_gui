import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ScrcpyGui

Rectangle {
    id: root
    property string selectedSerial: ""
    signal selectDevice(string serial)
    signal requestWireless()
    color: Theme.surface
    border.color: Theme.border
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 24
        anchors.bottomMargin: 14
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Label { text: "设备"; font.pixelSize: 19; font.weight: Font.DemiBold; color: Theme.text }
            Rectangle {
                width: 24; height: 24; radius: 12; color: Theme.surfaceSoft
                Label { anchors.centerIn: parent; text: app.devices.count; color: Theme.muted; font.pixelSize: 12; font.weight: Font.DemiBold }
            }
            Item { Layout.fillWidth: true }
        }

        ListView {
            id: deviceList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: app.devices
            spacing: 4
            clip: true
            delegate: Rectangle {
                id: delegateRoot
                required property string serial
                required property string state
                required property string modelName
                required property string connection
                width: ListView.view.width
                height: 68
                radius: Theme.radius
                property bool selected: serial === root.selectedSerial
                property bool hovered: mouseArea.containsMouse
                color: selected ? Theme.blueSoft : (hovered ? Theme.surfaceSoft : "transparent")
                border.color: selected ? Theme.blue : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    Rectangle { width: 8; height: 8; radius: 4; color: delegateRoot.state === "device" ? Theme.green : Theme.warning }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Label { text: delegateRoot.modelName || delegateRoot.serial; elide: Label.ElideRight; Layout.fillWidth: true; font.weight: Font.DemiBold; color: Theme.text; font.pixelSize: 13 }
                        Label { text: delegateRoot.connection === "wireless" ? "无线连接" : (delegateRoot.state === "device" ? "已连接" : delegateRoot.state); color: Theme.muted; font.pixelSize: 12 }
                    }
                }
                MouseArea { id: mouseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.selectDevice(delegateRoot.serial) }
            }
            footer: Item {
                width: deviceList.width
                height: app.devices.count ? 0 : 132
                Column {
                    anchors.centerIn: parent
                    spacing: 9
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: "未发现设备"; font.weight: Font.DemiBold; color: Theme.text }
                    Label { text: "连接手机并开启 USB 调试"; color: Theme.muted; font.pixelSize: 12 }
                }
            }
            ScrollBar.vertical: ScrollBar { }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
        Button {
            text: "无线连接"
            Layout.fillWidth: true
            implicitHeight: 42
            onClicked: root.requestWireless()
            contentItem: Label { text: parent.text; color: Theme.text; font: parent.font; horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter; leftPadding: 10 }
            background: Rectangle { color: parent.hovered ? Theme.surfaceSoft : "transparent"; radius: Theme.radius }
        }
    }
}

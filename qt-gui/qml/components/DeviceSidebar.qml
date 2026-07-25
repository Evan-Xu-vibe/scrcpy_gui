import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property string selectedSerial: ""
    signal selectDevice(string serial)
    signal requestWireless()
    color: palette.window
    border.color: palette.midlight
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12
        RowLayout {
            Label { text: "设备"; font.pixelSize: 19; font.weight: Font.DemiBold; color: palette.text }
            Rectangle { width: 24; height: 24; radius: 12; color: "#f1f3f6"; Label { anchors.centerIn: parent; text: app.devices.count; color: "#6d7480"; font.pixelSize: 12 } }
            Item { Layout.fillWidth: true }
        }
        ListView {
            id: deviceList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: app.devices
            spacing: 6
            clip: true
            delegate: Rectangle {
                width: ListView.view.width
                height: 72
                radius: 7
                color: serial === root.selectedSerial ? "#eaf3ff" : "transparent"
                border.color: serial === root.selectedSerial ? "#91baeF" : "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    Rectangle { width: 9; height: 9; radius: 5; color: state === "device" ? "#139b55" : "#e0a21a" }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label { text: modelName || serial; elide: Label.ElideRight; Layout.fillWidth: true; font.weight: Font.DemiBold; color: "#20242b" }
                        Label { text: connection === "wireless" ? "无线" : (state === "device" ? "已连接" : state); color: "#6d7480"; font.pixelSize: 12 }
                    }
                }
                MouseArea { anchors.fill: parent; onClicked: root.selectDevice(serial) }
            }
            footer: Item {
                width: deviceList.width
                height: app.devices.rowCount() ? 0 : 120
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: "未发现设备"; font.weight: Font.DemiBold; color: palette.text }
                    Label { text: "连接手机并开启 USB 调试"; color: palette.mid; font.pixelSize: 12 }
                }
            }
        }
        Button { text: "无线连接"; Layout.fillWidth: true; onClicked: root.requestWireless() }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ScrcpyGui
import "components"
import "pages"

ApplicationWindow {
    id: root
    width: 1240
    height: 780
    minimumWidth: 900
    minimumHeight: 620
    visible: true
    title: "scrcpy GUI"
    color: darkTheme ? "#181b20" : "#f6f7f9"

    property string selectedSerial: ""
    property bool darkTheme: Boolean(app.setting("darkTheme"))
    property color surface: darkTheme ? "#20242a" : "#ffffff"
    property color surfaceSoft: darkTheme ? "#292e35" : "#f1f3f6"
    property color textColor: darkTheme ? "#f0f2f5" : "#20242b"
    property color mutedColor: darkTheme ? "#a7afb9" : "#6d7480"
    property color borderColor: darkTheme ? "#343a43" : "#dde1e7"
    property color blue: darkTheme ? "#4b91f1" : "#1769db"

    function selectDefaultDevice() {
        if (selectedSerial.length === 0 && app.devices.count > 0)
            selectedSerial = app.devices.firstSerial()
    }

    Connections {
        target: app.devices
        function onCountChanged() { root.selectDefaultDevice() }
    }

    header: ToolBar {
        height: 54
        background: Rectangle { color: root.surface; border.color: root.borderColor; border.width: 1 }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            Label { text: "scrcpy GUI"; color: root.textColor; font.pixelSize: 17; font.weight: Font.DemiBold }
            Item { Layout.fillWidth: true }
            ToolButton { text: "刷新"; onClicked: app.refreshDevices() }
            ToolButton { text: "日志"; onClicked: logDrawer.open() }
            ToolButton {
                text: root.darkTheme ? "浅色" : "深色"
                onClicked: { root.darkTheme = !root.darkTheme; app.setSetting("darkTheme", root.darkTheme) }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        DeviceSidebar {
            Layout.preferredWidth: 260
            Layout.fillHeight: true
            selectedSerial: root.selectedSerial
            onSelectDevice: root.selectedSerial = serial
            onRequestWireless: wirelessDialog.open()
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 28
                spacing: 8
                Label {
                    text: root.selectedSerial.length ? "设备配置" : "等待设备"
                    color: root.textColor
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                }
                Label {
                    text: root.selectedSerial.length ? root.selectedSerial : "连接手机后即可配置并启动投屏"
                    color: root.mutedColor
                    font.pixelSize: 13
                }
            }

            TabBar {
                id: tabs
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                TabButton { text: "画面" }
                TabButton { text: "控制" }
                TabButton { text: "音频" }
                TabButton { text: "录制" }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 28
                currentIndex: tabs.currentIndex
                DisplayPage { }
                ControlPage { }
                AudioPage { }
                RecordingPage { }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: root.borderColor }
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 68
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Label { text: app.notice; color: root.mutedColor; Layout.fillWidth: true }
                Button {
                    text: app.running ? "停止投屏" : "开始投屏"
                    enabled: app.running || root.selectedSerial.length > 0
                    highlighted: !app.running
                    onClicked: app.running ? app.stopScrcpy() : app.startScrcpy(root.selectedSerial)
                }
            }
        }
    }

    footer: Rectangle {
        height: 28
        color: root.surface
        border.color: root.borderColor
        border.width: 1
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            Label { text: "Qt Quick 原生界面"; color: root.mutedColor; font.pixelSize: 11 }
            Item { Layout.fillWidth: true }
            Label { text: "ADB"; color: root.mutedColor; font.pixelSize: 11 }
            Label { text: "scrcpy"; color: root.mutedColor; font.pixelSize: 11 }
        }
    }

    Dialog {
        id: wirelessDialog
        title: "无线连接"
        modal: true
        standardButtons: Dialog.Cancel
        anchors.centerIn: parent
        ColumnLayout {
            width: 360
            spacing: 14
            Label { text: "输入 IP 地址和端口，例如 192.168.1.8:5555"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            TextField { id: wirelessAddress; Layout.fillWidth: true; placeholderText: "IP 地址:端口"; focus: true }
            Button {
                text: "连接"
                Layout.alignment: Qt.AlignRight
                enabled: wirelessAddress.text.trim().length > 0
                onClicked: { app.connectWireless(wirelessAddress.text); wirelessDialog.close() }
            }
        }
    }

    LogDrawer { id: logDrawer }
}

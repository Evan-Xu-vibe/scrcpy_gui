import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
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
    color: Theme.bg
    font.family: Theme.fontFamily
    Material.theme: Theme.dark ? Material.Dark : Material.Light
    Material.accent: Theme.blue
    Material.primary: Theme.blue

    property string selectedSerial: ""

    Component.onCompleted: {
        Theme.dark = Boolean(app.setting("darkTheme"))
        console.info("UI font:", font.family)
    }

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
        padding: 0
        background: Rectangle {
            color: Theme.surface
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: Theme.border }
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 8
            Rectangle {
                width: 30; height: 30; radius: 7; color: Theme.blue
                Label { anchors.centerIn: parent; text: "SC"; color: "white"; font.pixelSize: 11; font.weight: Font.Bold }
            }
            Label { text: "scrcpy GUI"; color: Theme.text; font.pixelSize: 16; font.weight: Font.DemiBold }
            Item { Layout.fillWidth: true }
            ToolButton {
                text: "刷新设备"
                onClicked: app.refreshDevices()
                contentItem: Label { text: parent.text; color: parent.hovered ? Theme.blue : Theme.muted; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { radius: Theme.radius; color: parent.hovered ? Theme.surfaceSoft : "transparent" }
            }
            ToolButton {
                text: "查看日志"
                onClicked: logDrawer.open()
                contentItem: Label { text: parent.text; color: parent.hovered ? Theme.blue : Theme.muted; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { radius: Theme.radius; color: parent.hovered ? Theme.surfaceSoft : "transparent" }
            }
            ToolButton {
                text: Theme.dark ? "浅色主题" : "深色主题"
                onClicked: { Theme.dark = !Theme.dark; app.setSetting("darkTheme", Theme.dark) }
                contentItem: Label { text: parent.text; color: parent.hovered ? Theme.blue : Theme.muted; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { radius: Theme.radius; color: parent.hovered ? Theme.surfaceSoft : "transparent" }
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
                Layout.leftMargin: 38
                Layout.rightMargin: 38
                Layout.topMargin: 30
                Layout.bottomMargin: 10
                spacing: 5
                Label {
                    text: root.selectedSerial.length ? "设备配置" : "等待设备"
                    color: Theme.text
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                }
                Label {
                    text: root.selectedSerial.length ? root.selectedSerial : "连接手机后即可配置并启动投屏"
                    color: Theme.muted
                    font.pixelSize: 13
                }
            }

            TabBar {
                id: tabs
                Layout.fillWidth: true
                Layout.leftMargin: 38
                Layout.rightMargin: 38
                height: 48
                background: Rectangle {
                    color: "transparent"
                    Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: Theme.border }
                }
                Repeater {
                    model: ["画面", "控制", "音频", "录制"]
                    TabButton {
                        required property string modelData
                        text: modelData
                        width: 70
                        contentItem: Label {
                            text: parent.text
                            color: parent.checked ? Theme.blue : Theme.muted
                            font.weight: parent.checked ? Font.DemiBold : Font.Normal
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: "transparent"
                            Rectangle { visible: parent.parent.checked; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 3; radius: 2; color: Theme.blue }
                        }
                    }
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 38
                Layout.rightMargin: 38
                Layout.topMargin: 18
                Layout.bottomMargin: 12
                currentIndex: tabs.currentIndex
                DisplayPage { }
                ControlPage { }
                AudioPage { }
                RecordingPage { }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 78
                Layout.leftMargin: 38
                Layout.rightMargin: 38
                spacing: 16
                Rectangle { width: 8; height: 8; radius: 4; color: app.running ? Theme.green : Theme.faint }
                Label { text: app.notice; color: Theme.muted; Layout.fillWidth: true; elide: Label.ElideRight }
                PrimaryButton {
                    text: app.running ? "停止投屏" : "开始投屏"
                    danger: app.running
                    enabled: app.running || root.selectedSerial.length > 0
                    onClicked: app.running ? app.stopScrcpy() : app.startScrcpy(root.selectedSerial)
                }
            }
        }
    }

    footer: Rectangle {
        height: 28
        color: Theme.surface
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            Item { Layout.fillWidth: true }
            Label { text: "ADB"; color: Theme.muted; font.pixelSize: 11 }
            Label { text: "scrcpy"; color: Theme.muted; font.pixelSize: 11 }
        }
        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 1; color: Theme.border }
    }

    Dialog {
        id: wirelessDialog
        title: "无线连接"
        modal: true
        anchors.centerIn: parent
        width: 440
        padding: 24
        background: Rectangle { color: Theme.surfaceRaised; radius: 8; border.color: Theme.border }
        header: Label {
            text: parent.title
            color: Theme.text
            font.pixelSize: 18
            font.weight: Font.DemiBold
            leftPadding: 24
            rightPadding: 24
            topPadding: 24
            bottomPadding: 12
        }
        contentItem: ColumnLayout {
            implicitWidth: 392
            spacing: 14
            Label { text: "输入 IP 地址和端口，例如 192.168.1.8:5555"; color: Theme.muted; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            TextField { id: wirelessAddress; Layout.fillWidth: true; implicitHeight: Theme.controlHeight; placeholderText: "IP 地址:端口"; focus: true }
        }
        footer: Item {
            implicitHeight: 78
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                anchors.topMargin: 10
                anchors.bottomMargin: 20
                Item { Layout.fillWidth: true }
                Button { text: "取消"; onClicked: wirelessDialog.close() }
                PrimaryButton {
                    text: "连接"
                    implicitWidth: 88
                    enabled: wirelessAddress.text.trim().length > 0
                    onClicked: { app.connectWireless(wirelessAddress.text); wirelessDialog.close() }
                }
            }
        }
    }

    LogDrawer { id: logDrawer }
}

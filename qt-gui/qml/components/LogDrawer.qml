import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Drawer {
    id: root
    edge: Qt.RightEdge
    width: Math.min(520, parent.width * .48)
    height: parent.height
    modal: true
    padding: 18

    ColumnLayout {
        anchors.fill: parent
        RowLayout {
            Label { text: "运行日志"; font.pixelSize: 18; font.weight: Font.DemiBold }
            Item { Layout.fillWidth: true }
            ToolButton { text: "清除"; onClicked: app.clearLogs() }
            ToolButton { text: "关闭"; onClicked: root.close() }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: palette.midlight }
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: app.logs
            clip: true
            delegate: Label {
                required property string modelData
                width: ListView.view.width
                text: modelData
                color: palette.text
                font.family: "Consolas"
                font.pixelSize: 12
                wrapMode: Text.WrapAnywhere
                padding: 5
            }
            ScrollBar.vertical: ScrollBar { }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ScrcpyGui

Drawer {
    id: root
    edge: Qt.RightEdge
    width: Math.min(520, parent.width * .48)
    height: parent.height
    modal: true
    padding: 0
    background: Rectangle { color: Theme.surface; border.color: Theme.border }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14
        RowLayout {
            Layout.fillWidth: true
            Label { text: "运行日志"; color: Theme.text; font.pixelSize: 18; font.weight: Font.DemiBold }
            Item { Layout.fillWidth: true }
            ToolButton { text: "清除"; onClicked: app.clearLogs() }
            ToolButton { text: "关闭"; onClicked: root.close() }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: app.logs
            clip: true
            delegate: Label {
                required property string modelData
                width: ListView.view.width
                text: modelData
                color: Theme.text
                font.family: "Consolas"
                font.pixelSize: 12
                wrapMode: Text.WrapAnywhere
                padding: 5
            }
            ScrollBar.vertical: ScrollBar { }
        }
    }
}

import QtQuick
import QtQuick.Controls
import ScrcpyGui

ToolButton {
    id: root

    property url iconSource
    property string tooltipText: ""

    implicitWidth: 40
    implicitHeight: 40
    padding: 0
    hoverEnabled: true

    icon.source: root.iconSource
    icon.width: 20
    icon.height: 20
    icon.color: root.hovered ? Theme.blue : Theme.muted

    background: Rectangle {
        radius: Theme.radius
        color: root.hovered ? Theme.surfaceSoft : "transparent"
    }

    ToolTip.visible: root.hovered && root.tooltipText.length > 0
    ToolTip.text: root.tooltipText
    ToolTip.delay: 450
}

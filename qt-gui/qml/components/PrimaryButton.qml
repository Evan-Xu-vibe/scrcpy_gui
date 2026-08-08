import QtQuick
import QtQuick.Controls
import ScrcpyGui

Button {
    id: root
    property bool danger: false
    implicitHeight: 46
    implicitWidth: 144
    font.weight: Font.DemiBold

    contentItem: Label {
        text: root.text
        color: root.enabled ? "white" : Theme.faint
        font: root.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: Theme.radius
        border.color: !root.enabled ? Theme.border : (root.danger ? Theme.red : Theme.blue)
        color: !root.enabled ? Theme.surfaceSoft
              : (root.down ? (root.danger ? "#b83737" : Theme.blueHover)
                 : (root.hovered ? (root.danger ? "#bd3d3d" : Theme.blueHover)
                    : (root.danger ? Theme.red : Theme.blue)))
    }
}

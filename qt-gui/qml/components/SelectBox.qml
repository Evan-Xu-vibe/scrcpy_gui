import QtQuick
import QtQuick.Controls
import ScrcpyGui

ComboBox {
    id: root
    implicitHeight: Theme.controlHeight
    font.family: Theme.fontFamily
    font.pixelSize: 13
    leftPadding: 12
    rightPadding: 34

    contentItem: Label {
        leftPadding: root.leftPadding
        rightPadding: root.rightPadding
        text: root.displayText
        color: root.enabled ? Theme.text : Theme.faint
        font: root.font
        elide: Label.ElideRight
        verticalAlignment: Text.AlignVCenter
    }
    indicator: Label {
        x: root.width - width - 12
        y: root.topPadding + (root.availableHeight - height) / 2
        text: "⌄"
        color: root.enabled ? Theme.muted : Theme.faint
        font.pixelSize: 16
    }
    background: Rectangle {
        radius: Theme.radius
        color: root.enabled ? Theme.surfaceRaised : Theme.surfaceSoft
        border.color: root.activeFocus ? Theme.blue : Theme.borderStrong
        border.width: root.activeFocus ? 2 : 1
    }
    delegate: ItemDelegate {
        id: option
        required property int index
        required property var modelData
        width: ListView.view ? ListView.view.width : root.width
        height: 38
        highlighted: root.highlightedIndex === index
        contentItem: Label {
            text: option.modelData
            color: option.highlighted ? Theme.blue : Theme.text
            font: root.font
            leftPadding: 10
            rightPadding: 10
            verticalAlignment: Text.AlignVCenter
            elide: Label.ElideRight
        }
        background: Rectangle {
            radius: 4
            color: option.highlighted ? Theme.blueSoft : "transparent"
        }
    }
    popup: Popup {
        y: root.height + 4
        width: root.width
        implicitHeight: Math.min(contentItem.implicitHeight + 8, 240)
        padding: 4
        background: Rectangle {
            radius: Theme.radius
            color: Theme.surfaceRaised
            border.color: Theme.borderStrong
        }
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.delegateModel
            currentIndex: root.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator { }
        }
    }
}

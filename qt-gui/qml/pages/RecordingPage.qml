import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ScrcpyGui
import "../components"

Flickable {
    contentWidth: width
    contentHeight: content.implicitHeight + 16
    clip: true
    ColumnLayout {
        id: content
        width: parent.width
        spacing: 0
        ToggleRow { title: "录制投屏"; description: "将投屏内容保存到本地文件"; checked: Boolean(app.setting("recordEnabled")); onToggled: app.setSetting("recordEnabled", checked) }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
        SettingRow { title: "录制文件"; description: "使用 MP4 或 MKV 文件扩展名"; TextField { width: parent.width; enabled: Boolean(app.setting("recordEnabled")); text: app.setting("recordPath"); onEditingFinished: app.setSetting("recordPath", text) } }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
        SettingRow { title: "录制格式"; description: "与文件容器保持一致"; SelectBox { width: parent.width; enabled: Boolean(app.setting("recordEnabled")); model: ["MP4", "MKV"]; currentIndex: ["mp4", "mkv"].indexOf(app.setting("recordFormat")); onActivated: app.setSetting("recordFormat", ["mp4", "mkv"][currentIndex]) } }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
        ToggleRow { title: "仅录制，不显示投屏窗口"; description: "适用于后台录制"; enabled: Boolean(app.setting("recordEnabled")); checked: Boolean(app.setting("noPlayback")); onToggled: app.setSetting("noPlayback", checked) }
    }
    ScrollBar.vertical: ScrollBar { }
}

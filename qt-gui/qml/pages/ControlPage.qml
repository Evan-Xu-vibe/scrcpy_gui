import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Flickable {
    contentWidth: width
    contentHeight: content.implicitHeight + 16
    clip: true
    ColumnLayout {
        id: content
        width: parent.width
        spacing: 0
        SettingRow { title: "键盘模式"; description: "SDK 兼容性最佳，UHID 模拟物理键盘"; ComboBox { width: parent.width; model: ["sdk", "uhid", "disabled"]; currentIndex: model.indexOf(app.setting("keyboardMode")); onActivated: app.setSetting("keyboardMode", currentValue) } }
        Rectangle { Layout.fillWidth: true; height: 1; color: palette.midlight }
        SettingRow { title: "鼠标模式"; description: "选择鼠标事件注入方式"; ComboBox { width: parent.width; model: ["sdk", "uhid", "disabled"]; currentIndex: model.indexOf(app.setting("mouseMode")); onActivated: app.setSetting("mouseMode", currentValue) } }
        Rectangle { Layout.fillWidth: true; height: 1; color: palette.midlight }
        SettingRow { title: "手柄模式"; description: "UHID 将电脑手柄模拟为 Android 物理手柄"; ComboBox { width: parent.width; model: ["disabled", "uhid"]; currentIndex: model.indexOf(app.setting("gamepadMode")); onActivated: app.setSetting("gamepadMode", currentValue) } }
        Rectangle { Layout.fillWidth: true; height: 1; color: palette.midlight }
        ToggleRow { title: "显示手机物理触点"; description: "仅显示手指直接触摸手机屏幕的位置"; checked: Boolean(app.setting("showTouches")); onToggled: app.setSetting("showTouches", checked) }
        Rectangle { Layout.fillWidth: true; height: 1; color: palette.midlight }
        ToggleRow { title: "全屏启动"; description: "投屏窗口打开后立即进入全屏"; checked: Boolean(app.setting("fullscreen")); onToggled: app.setSetting("fullscreen", checked) }
        Rectangle { Layout.fillWidth: true; height: 1; color: palette.midlight }
        ToggleRow { title: "窗口置顶"; description: "让投屏窗口保持在其他窗口上方"; checked: Boolean(app.setting("alwaysOnTop")); onToggled: app.setSetting("alwaysOnTop", checked) }
        Rectangle { Layout.fillWidth: true; height: 1; color: palette.midlight }
        ToggleRow { title: "无边框窗口"; description: "隐藏投屏窗口的标题栏和边框"; checked: Boolean(app.setting("borderless")); onToggled: app.setSetting("borderless", checked) }
        Rectangle { Layout.fillWidth: true; height: 1; color: palette.midlight }
        ToggleRow { title: "投屏工具栏"; description: "在投屏窗口右侧显示返回、主页、音量等快捷控制"; checked: Boolean(app.setting("toolbar")); onToggled: app.setSetting("toolbar", checked) }
    }
}

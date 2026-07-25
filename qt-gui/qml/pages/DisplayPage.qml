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
        SettingRow {
            title: "分辨率"
            description: "限制视频较长边，降低可减少延迟"
            ComboBox {
                width: parent.width
                model: [0, 2560, 1920, 1600, 1280, 1024]
                textRole: "display"
                currentIndex: Math.max(0, model.indexOf(Number(app.setting("maxSize"))))
                displayText: currentValue === 0 ? "设备原始分辨率" : currentValue
                onActivated: app.setSetting("maxSize", currentValue)
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: palette.midlight }
        SettingRow {
            title: "帧率"
            description: "设备性能不足时会自动降低"
            SpinBox { width: parent.width; from: 1; to: 240; value: Number(app.setting("maxFps")); onValueModified: app.setSetting("maxFps", value) }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: palette.midlight }
        SettingRow {
            title: "视频编码"
            description: "H.264 具有最佳兼容性"
            ComboBox { width: parent.width; model: ["h264", "h265", "av1"]; currentIndex: model.indexOf(app.setting("videoCodec")); onActivated: app.setSetting("videoCodec", currentValue) }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: palette.midlight }
        SettingRow {
            title: "码率"
            description: "更高码率会提升画质和带宽占用"
            Slider { width: parent.width; from: 1; to: 40; stepSize: 1; value: Number(app.setting("bitrateMbps")); onMoved: app.setSetting("bitrateMbps", value) }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: palette.midlight }
        ToggleRow { title: "关闭手机屏幕"; description: "投屏启动后关闭设备物理屏幕"; checked: Boolean(app.setting("turnScreenOff")); onToggled: app.setSetting("turnScreenOff", checked) }
        Rectangle { Layout.fillWidth: true; height: 1; color: palette.midlight }
        ToggleRow { title: "保持唤醒"; description: "连接期间防止设备自动休眠"; checked: Boolean(app.setting("stayAwake")); onToggled: app.setSetting("stayAwake", checked) }
    }
}

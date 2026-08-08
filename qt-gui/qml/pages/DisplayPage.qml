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
        SettingRow {
            title: "画面尺寸"
            description: "按最长边限制画面，保持原始比例；较小尺寸可降低延迟"
            SelectBox {
                width: parent.width
                property var values: [0, 2560, 1920, 1600, 1280, 1024]
                model: [
                    "原始画面（不限制）",
                    "超清（最长边 2560 像素）",
                    "高清（最长边 1920 像素）",
                    "均衡（最长边 1600 像素）",
                    "流畅（最长边 1280 像素）",
                    "省带宽（最长边 1024 像素）"
                ]
                currentIndex: Math.max(0, values.indexOf(Number(app.setting("maxSize"))))
                onActivated: app.setSetting("maxSize", values[currentIndex])
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
        SettingRow {
            title: "帧率"
            description: "设备性能不足时会自动降低"
            SpinBox { width: parent.width; implicitHeight: Theme.controlHeight; from: 1; to: 240; value: Number(app.setting("maxFps")); onValueModified: app.setSetting("maxFps", value) }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
        SettingRow {
            title: "视频编码"
            description: "H.264 具有最佳兼容性"
            SelectBox { width: parent.width; model: ["H.264", "H.265", "AV1"]; currentIndex: ["h264", "h265", "av1"].indexOf(app.setting("videoCodec")); onActivated: app.setSetting("videoCodec", ["h264", "h265", "av1"][currentIndex]) }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
        SettingRow {
            title: "码率"
            description: "更高码率会提升画质和带宽占用"
            Slider { width: parent.width; from: 1; to: 40; stepSize: 1; value: Number(app.setting("bitrateMbps")); onMoved: app.setSetting("bitrateMbps", value) }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
        ToggleRow { title: "关闭手机屏幕"; description: "投屏启动后关闭设备物理屏幕"; checked: Boolean(app.setting("turnScreenOff")); onToggled: app.setSetting("turnScreenOff", checked) }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
        ToggleRow { title: "保持唤醒"; description: "连接期间防止设备自动休眠"; checked: Boolean(app.setting("stayAwake")); onToggled: app.setSetting("stayAwake", checked) }
    }
    ScrollBar.vertical: ScrollBar { }
}

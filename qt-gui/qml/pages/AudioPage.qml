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
        ToggleRow { title: "启用音频"; description: "接收并播放设备音频"; checked: Boolean(app.setting("audioEnabled")); onToggled: app.setSetting("audioEnabled", checked) }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
        SettingRow { title: "音频源"; description: "输出、设备播放或麦克风"; SelectBox { width: parent.width; enabled: Boolean(app.setting("audioEnabled")); model: ["输出", "设备播放", "麦克风"]; currentIndex: ["output", "playback", "mic"].indexOf(app.setting("audioSource")); onActivated: app.setSetting("audioSource", ["output", "playback", "mic"][currentIndex]) } }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
        SettingRow { title: "音频编码"; description: "Opus 提供低延迟和高兼容性"; SelectBox { width: parent.width; enabled: Boolean(app.setting("audioEnabled")); model: ["Opus", "AAC", "FLAC"]; currentIndex: ["opus", "aac", "flac"].indexOf(app.setting("audioCodec")); onActivated: app.setSetting("audioCodec", ["opus", "aac", "flac"][currentIndex]) } }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
        SettingRow { title: "音频码率"; description: "FLAC 不使用码率设置"; SpinBox { width: parent.width; enabled: Boolean(app.setting("audioEnabled")) && app.setting("audioCodec") !== "flac"; from: 32; to: 512; stepSize: 16; value: Number(app.setting("audioBitrateKbps")); onValueModified: app.setSetting("audioBitrateKbps", value) } }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
        ToggleRow { title: "播放流复制"; description: "仅在 playback 音频源下可用"; enabled: app.setting("audioSource") === "playback"; checked: Boolean(app.setting("audioDup")); onToggled: app.setSetting("audioDup", checked) }
    }
    ScrollBar.vertical: ScrollBar { }
}

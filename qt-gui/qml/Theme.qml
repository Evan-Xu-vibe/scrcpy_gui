pragma Singleton

import QtQuick

QtObject {
    property bool dark: false

    readonly property string fontFamily: "Microsoft YaHei UI"

    readonly property color bg: dark ? "#181b20" : "#f6f7f9"
    readonly property color surface: dark ? "#20242a" : "#ffffff"
    readonly property color surfaceRaised: dark ? "#272c33" : "#ffffff"
    readonly property color surfaceSoft: dark ? "#292e35" : "#f1f3f6"
    readonly property color text: dark ? "#f0f2f5" : "#20242b"
    readonly property color muted: dark ? "#a7afb9" : "#6d7480"
    readonly property color faint: dark ? "#7f8791" : "#939aa5"
    readonly property color border: dark ? "#343a43" : "#dde1e7"
    readonly property color borderStrong: dark ? "#454c56" : "#cdd2da"
    readonly property color blue: dark ? "#4b91f1" : "#1769db"
    readonly property color blueHover: dark ? "#63a0f3" : "#0f5fcf"
    readonly property color blueSoft: dark ? "#253a56" : "#eaf3ff"
    readonly property color green: dark ? "#42c77c" : "#139b55"
    readonly property color warning: "#e0a21a"
    readonly property color red: dark ? "#f06b6b" : "#d14343"

    readonly property int radius: 7
    readonly property int compactHeight: 40
    readonly property int controlHeight: 42
}

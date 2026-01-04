pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // Colors - dark minimal theme
    readonly property color bg: "#1a1a1a"
    readonly property color bgAlt: "#252525"
    readonly property color fg: "#e0e0e0"
    readonly property color fgDim: "#808080"
    readonly property color accent: "#7aa2f7"
    readonly property color urgent: "#f7768e"
    readonly property color success: "#9ece6a"
    readonly property color warning: "#e0af68"

    // Dimensions
    readonly property int barHeight: 30
    readonly property int padding: 8
    readonly property int spacing: 12
    readonly property int radius: 4

    // Font
    readonly property string fontFamily: "monospace"
    readonly property int fontSize: 14
}

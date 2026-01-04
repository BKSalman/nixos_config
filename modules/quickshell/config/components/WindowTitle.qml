import QtQuick
import Quickshell.Hyprland
import ".." as Root

Text {
    property int maxWidth: 300

    text: {
        let w = Hyprland.focusedMonitor?.activeWorkspace?.lastWindow
        if (!w) return ""
        let title = w.title || w.class || ""
        if (title.length > 40) title = title.substring(0, 37) + "..."
        return title
    }

    font.family: Root.Theme.fontFamily
    font.pixelSize: Root.Theme.fontSize
    color: Root.Theme.fg
    elide: Text.ElideRight
    width: Math.min(implicitWidth, maxWidth)
}

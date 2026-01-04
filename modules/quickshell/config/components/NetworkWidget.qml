import QtQuick
import QtQuick.Layouts
import "../services" as Services
import ".." as Root

RowLayout {
    spacing: 4

    Text {
        text: Services.Network.icon
        font.family: Root.Theme.fontFamily
        font.pixelSize: 14
        color: Services.Network.connected ? Root.Theme.fg : Root.Theme.fgDim
    }

    Text {
        text: Services.Network.status
        font.family: Root.Theme.fontFamily
        font.pixelSize: Root.Theme.fontSize
        color: Services.Network.connected ? Root.Theme.fg : Root.Theme.fgDim
        visible: Services.Network.connected
    }
}

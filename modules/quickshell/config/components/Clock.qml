import QtQuick
import "../services" as Services
import ".." as Root

Row {
    spacing: Root.Theme.spacing

    Text {
        text: Services.Time.time
        font.family: Root.Theme.fontFamily
        font.pixelSize: Root.Theme.fontSize
        color: Root.Theme.fg
    }

    Text {
        text: Services.Time.date
        font.family: Root.Theme.fontFamily
        font.pixelSize: Root.Theme.fontSize
        color: Root.Theme.fgDim
    }
}

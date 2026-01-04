import QtQuick
import QtQuick.Layouts
import "../services" as Services
import ".." as Root

RowLayout {
    visible: Services.Media.available
    spacing: 6

    Text {
        text: "󰒮"
        font.family: Root.Theme.fontFamily
        font.pixelSize: 12
        color: Root.Theme.fg
        MouseArea {
            anchors.fill: parent
            onClicked: Services.Media.previous()
        }
    }

    Text {
        text: Services.Media.icon
        font.family: Root.Theme.fontFamily
        font.pixelSize: 14
        color: Root.Theme.accent
        MouseArea {
            anchors.fill: parent
            onClicked: Services.Media.playPause()
        }
    }

    Text {
        text: "󰒭"
        font.family: Root.Theme.fontFamily
        font.pixelSize: 12
        color: Root.Theme.fg
        MouseArea {
            anchors.fill: parent
            onClicked: Services.Media.next()
        }
    }

    Text {
        text: Services.Media.display
        font.family: Root.Theme.fontFamily
        font.pixelSize: Root.Theme.fontSize
        color: Root.Theme.fg
        elide: Text.ElideRight
        Layout.maximumWidth: 200
    }
}

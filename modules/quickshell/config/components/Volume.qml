import QtQuick
import QtQuick.Layouts
import "../services" as Services
import ".." as Root

Item {
    id: volumeWidget

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: event => {
            if (event.button === Qt.LeftButton) {
                mixerPopup.toggle()
            } else if (event.button === Qt.RightButton) {
                Services.Audio.toggleMute()
            }
        }
        onWheel: wheel => {
            let delta = wheel.angleDelta.y > 0 ? 5 : -5
            Services.Audio.setVolume(Services.Audio.volume + delta)
        }
    }

    RowLayout {
        id: row
        spacing: 4

        Text {
            text: Services.Audio.icon
            font.family: Root.Theme.fontFamily
            font.pixelSize: 14
            color: Services.Audio.muted ? Root.Theme.fgDim : Root.Theme.fg
        }

        Text {
            text: Services.Audio.volume + "%"
            font.family: Root.Theme.fontFamily
            font.pixelSize: Root.Theme.fontSize
            color: Services.Audio.muted ? Root.Theme.fgDim : Root.Theme.fg
            Layout.preferredWidth: 32
        }

        Mixer {
            id: mixerPopup
            anchorItem: volumeWidget
        }
    }
}

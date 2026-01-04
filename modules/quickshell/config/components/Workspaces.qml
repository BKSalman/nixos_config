import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import ".." as Root

RowLayout {
    id: root
    required property var monitor
    spacing: 4

    WheelHandler {
        id: wheel
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

        onWheel: event => {
            const dy = event.angleDelta.y

            if (dy < 0) {
                if (monitor?.activeWorkspace) {
                    Hyprland.dispatch("workspace " + Math.min(monitor?.activeWorkspace?.id + 1, 10))
                }
            } else if (dy > 0) {
                if (monitor?.activeWorkspace) {
                    Hyprland.dispatch("workspace " + Math.max(monitor?.activeWorkspace?.id - 1, 0))
                }
            }
        }
    }

    Repeater {
        model: 10

        Rectangle {
            required property int index
            property int wsId: index + 1
            property HyprlandWorkspace ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
            property bool active: monitor?.activeWorkspace?.id === wsId
            property bool occupied: ws !== null && ws.windows > 0

            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            radius: Root.Theme.radius
            color: active ? Root.Theme.accent : (occupied ? Root.Theme.bgAlt : "transparent")
            border.width: occupied && !active ? 1 : 0
            border.color: Root.Theme.fgDim

            Text {
                anchors.centerIn: parent
                text: parent.wsId
                font.family: Root.Theme.fontFamily
                font.pixelSize: 10
                color: parent.active ? Root.Theme.bg : (parent.occupied ? Root.Theme.fg : Root.Theme.fgDim)
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + wsId)
            }
        }
    }
}

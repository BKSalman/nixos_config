import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import ".." as Root

RowLayout {
    id: root
    required property var monitor
    spacing: 4

    property real scrollAccumulator: 0

    WheelHandler {
        id: wheel
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

        onWheel: event => {
            const dy = event.angleDelta.y
            if ((root.scrollAccumulator > 0 && dy < 0) || (root.scrollAccumulator < 0 && dy > 0))
                root.scrollAccumulator = 0
            root.scrollAccumulator += dy
            const threshold = 120

            while (Math.abs(root.scrollAccumulator) >= threshold) {
                if (root.scrollAccumulator >= threshold) {
                    root.scrollAccumulator -= threshold
                    if (root.monitor?.activeWorkspace) {
                        Hyprland.dispatch("hl.dsp.focus({ workspace = \"%1\" })".arg(Math.max(root.monitor?.activeWorkspace?.id - 1, 1)))
                    }
                } else if (root.scrollAccumulator <= -threshold) {
                    root.scrollAccumulator += threshold
                    if (root.monitor?.activeWorkspace) {
                        Hyprland.dispatch("hl.dsp.focus({ workspace = \"%1\" })".arg(Math.min(root.monitor?.activeWorkspace?.id + 1, 10)))
                    }
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
            property bool active: root.monitor?.activeWorkspace?.id === wsId
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
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = \"%1\" })".arg(parent.wsId))
            }
        }
    }
}

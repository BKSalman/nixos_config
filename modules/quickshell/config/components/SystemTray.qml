import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.SystemTray

RowLayout {
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignRight
    spacing: 4

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: trayItem
            required property SystemTrayItem modelData

            Layout.preferredWidth: 18
            Layout.preferredHeight: 18

            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            hoverEnabled: true

            onClicked: event => {
                if (event.button === Qt.LeftButton) {
                    // Close menu if open, otherwise activate
                    if (trayMenu.visible) {
                        trayMenu.close()
                    } else {
                        modelData.activate()
                    }
                } else if (event.button === Qt.MiddleButton) {
                    modelData.secondaryActivate()
                } else if (event.button === Qt.RightButton) {
                    trayMenu.toggle()
                }
            }

            onWheel: event => {
                event.accepted = true
                const points = event.angleDelta.y / 120
                modelData.scroll(points, false)
            }

            IconImage {
                anchors.fill: parent
                source: trayItem.modelData.icon
            }

            TrayMenu {
                id: trayMenu
                trayItem: trayItem.modelData
                anchorItem: trayItem
            }
        }
    }
}

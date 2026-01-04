import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "components"

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            property var hyprMonitor: Hyprland.monitorFor(modelData)

            screen: modelData
            anchors {
                bottom: true
                left: true
                right: true
            }
            implicitHeight: Theme.barHeight
            color: Theme.bg

            // Left section
            RowLayout {
                anchors.left: parent.left
                anchors.leftMargin: Theme.padding
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing

                Workspaces {
                    monitor: bar.hyprMonitor
                }

                Rectangle {
                    width: 1
                    height: 16
                    color: Theme.fgDim
                }

                WindowTitle {}
            }

            // Center
            Clock {
                anchors.centerIn: parent
            }

            // Right section
            RowLayout {
                anchors.right: parent.right
                anchors.rightMargin: Theme.padding
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing

                MediaControls {
                    id: mediaControls
                }

                Rectangle {
                    width: 1
                    height: 16
                    color: Theme.fgDim
                    visible: mediaControls.visible
                }

                NetworkWidget {}

                Volume {}

                Battery {}

                Rectangle {
                    width: 1
                    height: 16
                    color: Theme.fgDim
                    visible: systemTray.visible
                }

                SystemTray {
                    id: systemTray
                }
            }
        }
    }
}

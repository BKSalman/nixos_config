import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services" as Services
import ".." as Root

Scope {
    id: root

    // Guard to skip the initial property binding on startup
    property bool ready: false
    property bool showOsd: false

    Component.onCompleted: readyTimer.start()

    Timer {
        id: readyTimer
        interval: 500
        onTriggered: root.ready = true
    }

    Connections {
        target: Services.Audio

        function onMicMutedChanged() {
            if (!root.ready) return;
            root.showOsd = true;
            dismissTimer.restart();
        }
    }

    Timer {
        id: dismissTimer
        interval: 1500
        onTriggered: root.showOsd = false
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: osdWindow

            property var modelData
            screen: modelData

            color: "transparent"
            mask: Region {}

            anchors {
                right: true
                bottom: true
            }

            margins {
                right: 20
                bottom: 50
            }

            implicitWidth: 160
            implicitHeight: 50

            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore

            Rectangle {
                id: osdRect
                width: row.implicitWidth + Root.Theme.padding * 3
                height: row.implicitHeight + Root.Theme.padding * 2
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                radius: Root.Theme.radius
                color: Root.Theme.bgAlt
                opacity: 0
                y: 10

                states: [
                    State {
                        name: "visible"
                        when: root.showOsd
                        PropertyChanges {
                            target: osdRect
                            opacity: 1
                            y: 0
                        }
                    }
                ]

                transitions: [
                    Transition {
                        to: "visible"
                        ParallelAnimation {
                            NumberAnimation {
                                property: "opacity"
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                property: "y"
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    },
                    Transition {
                        from: "visible"
                        to: ""
                        ParallelAnimation {
                            NumberAnimation {
                                property: "opacity"
                                duration: 200
                                easing.type: Easing.InCubic
                            }
                            NumberAnimation {
                                property: "y"
                                duration: 200
                                easing.type: Easing.InCubic
                            }
                        }
                    }
                ]

                RowLayout {
                    id: row
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: Services.Audio.micIcon
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 20
                        color: Services.Audio.micMuted ? Root.Theme.urgent : Root.Theme.success
                    }

                    Text {
                        text: Services.Audio.micMuted ? "Muted" : "Unmuted"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSize
                        color: Root.Theme.fg
                    }
                }
            }
        }
    }
}

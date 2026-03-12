import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import ".." as Root

PanelWindow {
    id: popup

    required property Item anchorItem

    visible: false
    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-mixer"

    // Use the same screen as the bar
    screen: anchorItem?.QsWindow?.window?.screen ?? null

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    mask: Region { item: mixerContent }

    HyprlandFocusGrab {
        windows: [popup]
        active: popup.visible
        onCleared: popup.close()
    }

    function toggle() {
        if (visible) {
            close();
        } else {
            open();
        }
    }

    function open() {
        visible = true;
    }

    function close() {
        visible = false;
    }

    Rectangle {
        id: mixerContent

        width: Math.max(content.implicitWidth + 20, 300)
        height: Math.min(content.implicitHeight + 20, 400)
        color: Root.Theme.bg
        radius: Root.Theme.radius

        // Position relative to the anchor item within the bar
        x: {
            if (!popup.anchorItem) return 0;
            const barWin = popup.anchorItem.QsWindow?.window;
            if (!barWin) return 0;
            barWin.windowTransform;
            const pos = barWin.itemPosition(popup.anchorItem);
            const ideal = pos.x + popup.anchorItem.width / 2 - width / 2;
            return Math.max(0, Math.min(ideal, popup.width - width));
        }

        // Place above the bar
        y: parent.height - Root.Theme.barHeight - height - 4

        ScrollView {
            anchors.fill: parent
            contentWidth: availableWidth

            ColumnLayout {
                id: content

                anchors.fill: parent
                anchors.margins: 10

                PwNodeLinkTracker {
                    id: linkTracker
                    node: Pipewire.defaultAudioSink
                }

                MixerEntry {
                    node: Pipewire.defaultAudioSink
                }

                Rectangle {
                    Layout.fillWidth: true
                    color: palette.active.text
                    implicitHeight: 1
                }

                Repeater {
                    model: linkTracker.linkGroups

                    MixerEntry {
                        required property PwLinkGroup modelData
                        node: modelData.source
                    }
                }
            }
        }
    }
}

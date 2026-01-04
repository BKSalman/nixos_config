import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import ".." as Root

PopupWindow {
    id: popup

    required property Item anchorItem

    visible: false
    color: Root.Theme.bg

    anchor.window: anchorItem?.QsWindow?.window ?? null
    anchor.adjustment: PopupAdjustment.Flip

    anchor.onAnchoring: {
        if (!anchorItem) return;
        const window = anchorItem.QsWindow.window;
        if (!window) return;
        const mapped = window.contentItem.mapFromItem(
            anchorItem, 0, - anchorItem.height - popup.implicitHeight,
            anchorItem.width, anchorItem.height
        );
        popup.anchor.rect = mapped;
    }

    implicitWidth: Math.max(content.implicitWidth + 20, 300)
    implicitHeight: Math.min(content.implicitHeight + 20, 400)

    HyprlandFocusGrab {
        windows: [popup]
        active: popup.visible
        onCleared: popup.close()
    }

    function toggle() {
        visible = !visible;
    }

    function open() {
        visible = true;
    }

    function close() {
        visible = false;
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: 10

            // get a list of nodes that output to the default sink
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
                    // Each link group contains a source and a target.
                    // Since the target is the default sink, we want the source.
                    node: modelData.source
                }
            }
        }
    }
}

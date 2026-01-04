// components/MixerEntry.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire
import "../" as Root

ColumnLayout {
    id: entry

    required property PwNode node

    // Null-safe accessors
    readonly property bool hasNode: node !== null
    readonly property var audio: node?.audio ?? null
    readonly property bool muted: audio?.muted ?? false
    readonly property real volume: audio?.volume ?? 0
    readonly property var props: node?.properties ?? ({})

    visible: hasNode

    // Bind the node so we can read its properties
    PwObjectTracker {
        objects: hasNode ? [node] : []
    }

    RowLayout {
        id: labelParent
        Layout.fillWidth: true

        Image {
            visible: source != "" && entry.hasNode
            source: {
                if (!entry.hasNode) return "";
                const icon = entry.props["application.icon-name"] ?? "";
                return icon !== "" ? `image://icon/${icon}` : "";
            }

            sourceSize.width: 20
            sourceSize.height: 20
        }

        Label {
            text: {
                if (!entry.hasNode) return "";
                const app = entry.props["application.name"] 
                    ?? (node.description !== "" ? node.description : node.name);
                const media = entry.props["media.name"];
                return media !== undefined ? `${app} - ${media}` : app;
            }
            color: entry.muted ? Root.Theme.fgDim : Root.Theme.fg
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Button {
            visible: entry.audio !== null
            text: entry.muted ? "unmute" : "mute"
            onClicked: {
                if (entry.audio) {
                    entry.audio.muted = !entry.audio.muted;
                }
            }
            Layout.alignment: Qt.AlignRight
        }
    }

    RowLayout {
        visible: entry.audio !== null

        Label {
            Layout.preferredWidth: 50
            text: `${Math.floor(entry.volume * 100)}%`
            color: Root.Theme.fgDim
        }

        Slider {
            id: slider
            Layout.fillWidth: true
            from: 0
            to: 1
            value: entry.volume

            onMoved: {
                if (entry.audio) {
                    entry.audio.volume = value;
                }
            }
        }
    }
}

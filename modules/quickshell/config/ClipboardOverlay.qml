import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: overlay

    visible: false
    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // Directory for decoded image thumbnails
    readonly property string thumbDir: "/tmp/.cliphist-thumbs"
    // Full clipboard history: [{ id, preview, isImage }, ...]
    property var entries: []
    // Bumped once image thumbnails have been decoded, used to (re)load Images
    property int thumbGen: 0

    function activate() {
        searchField.text = "";
        overlay.entries = [];
        listModel.clear();
        listProcess.running = true;
        overlay.visible = true;
        searchField.forceActiveFocus();
    }

    function close() {
        overlay.visible = false;
    }

    function toggle() {
        if (overlay.visible) {
            overlay.close();
        } else {
            overlay.activate();
        }
    }

    function rebuild() {
        listModel.clear();
        const q = searchField.text.toLowerCase();
        for (let i = 0; i < overlay.entries.length; i++) {
            const e = overlay.entries[i];
            if (q === "" || e.preview.toLowerCase().indexOf(q) !== -1) {
                listModel.append({ entryId: e.id, preview: e.preview, isImage: e.isImage });
            }
        }
        list.currentIndex = listModel.count > 0 ? 0 : -1;
    }

    function copySelected() {
        if (list.currentIndex < 0 || list.currentIndex >= listModel.count) return;
        const id = listModel.get(list.currentIndex).entryId;
        copyProcess.command = ["sh", "-c", "cliphist decode " + id + " | wl-copy"];
        copyProcess.running = true;
        overlay.close();
    }

    Process {
        id: listProcess
        command: ["cliphist", "list"]

        stdout: SplitParser {
            onRead: line => {
                // Format: "<id>\t<preview>"
                const tab = line.indexOf("\t");
                if (tab === -1) return;
                const id = line.substring(0, tab);
                const preview = line.substring(tab + 1);
                // cliphist renders images as: [[ binary data 12 KiB png 800x600 ]]
                const isImage = /^\[\[\s*binary data .*(png|jpe?g|bmp|gif|webp)/i.test(preview);
                overlay.entries.push({ id: id, preview: preview, isImage: isImage });
            }
        }
        onExited: {
            overlay.rebuild();
            // Decode all image entries to temp files so we can show thumbnails
            let ids = [];
            for (let i = 0; i < overlay.entries.length; i++) {
                if (overlay.entries[i].isImage) ids.push(overlay.entries[i].id);
            }
            if (ids.length > 0) {
                const script = "mkdir -p " + overlay.thumbDir + "; "
                    + "for id in " + ids.join(" ") + "; do "
                    + "cliphist decode $id > " + overlay.thumbDir + "/$id 2>/dev/null; done";
                thumbProcess.command = ["sh", "-c", script];
                thumbProcess.running = true;
            }
        }
    }

    Process {
        id: thumbProcess
        onExited: overlay.thumbGen++
    }

    Process {
        id: copyProcess
    }

    // Dim background; click to dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: overlay.close()

        Rectangle {
            anchors.fill: parent
            color: Theme.bg
            opacity: 0.7
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 640
        height: 480
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Theme.fgDim

        // Swallow clicks so they don't dismiss the overlay
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.padding
            spacing: Theme.padding

            // Search input
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: Theme.radius
                color: Theme.bgAlt
                border.width: 1
                border.color: searchField.activeFocus ? Theme.accent : Theme.fgDim

                TextInput {
                    id: searchField
                    anchors.fill: parent
                    anchors.margins: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    clip: true
                    focus: true

                    onTextChanged: overlay.rebuild()

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            overlay.close();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            overlay.copySelected();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            if (list.currentIndex < listModel.count - 1) list.currentIndex++;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            if (list.currentIndex > 0) list.currentIndex--;
                            event.accepted = true;
                        }
                    }
                }

                Text {
                    anchors.fill: parent
                    anchors.margins: 8
                    verticalAlignment: Text.AlignVCenter
                    text: "Search clipboard…"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    visible: searchField.text.length === 0
                }
            }

            // History list
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: ListModel { id: listModel }
                currentIndex: -1
                boundsBehavior: Flickable.StopAtBounds

                highlight: Rectangle {
                    color: Theme.bgAlt
                    radius: Theme.radius
                }
                highlightMoveDuration: 0

                delegate: Rectangle {
                    width: list.width
                    height: model.isImage ? 88 : 36
                    color: "transparent"

                    // Thumbnail for image entries
                    Image {
                        id: thumb
                        visible: model.isImage
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        height: 72
                        width: 96
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: false
                        // thumbGen bump forces a reload once decoding finishes
                        source: model.isImage
                            ? "file://" + overlay.thumbDir + "/" + model.entryId + "?g=" + overlay.thumbGen
                            : ""
                    }

                    Text {
                        anchors.left: model.isImage ? thumb.right : parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        verticalAlignment: Text.AlignVCenter
                        text: model.preview
                        color: model.isImage ? Theme.fgDim : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            list.currentIndex = index;
                            overlay.copySelected();
                        }
                    }
                }

                // Empty state
                Text {
                    anchors.centerIn: parent
                    visible: listModel.count === 0
                    text: "Clipboard is empty"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: overlay

    property var socket: null

    visible: false
    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    function activate(sock) {
        socket = sock;
        freezeProcess.running = true;
        geomRect.selH = 0;
        geomRect.selW = 0;
        geomRect.visible = true;
    }

    Process {
        id: freezeProcess
        command: ["grim", "-t", "png", "/tmp/.screenshot-freeze.png"]
        onExited: {
            freezeImage.source = "";
            freezeImage.source = "file:///tmp/.screenshot-freeze.png";
            overlay.visible = true;
        }
    }

    Image {
        id: freezeImage
        anchors.fill: parent
        cache: false
    }

    Rectangle {
        id: geomRect
        anchors.fill: parent

        color: "transparent"
        visible: false

        property int startX: 0
        property int startY: 0
        property int selX: 0
        property int selY: 0
        property int selW: 0
        property int selH: 0

        property int borderWidth: 6

        onSelXChanged: canvas.requestPaint()
        onSelYChanged: canvas.requestPaint()
        onSelWChanged: canvas.requestPaint()
        onSelHChanged: canvas.requestPaint()

        Canvas {
            id: canvas
            anchors.fill: parent

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();

                // Dim background
                ctx.globalAlpha = 0.8;
                ctx.fillStyle = Theme.bg;
                ctx.fillRect(0, 0, width, height);

                // Clear selection
                ctx.globalAlpha = 1;
                ctx.clearRect(geomRect.selX, geomRect.selY, geomRect.selW, geomRect.selH);

                // Border
                ctx.strokeStyle = Theme.accent;
                ctx.lineWidth = 6;
                ctx.strokeRect(geomRect.selX, geomRect.selY, geomRect.selW, geomRect.selH);
            }
        }
    }

    Rectangle {
        visible: geomRect.visible && geomRect.selW > 0 && geomRect.selH > 0
        x: geomRect.selX + geomRect.selW / 2 - width / 2
        y: geomRect.selY + geomRect.selH + 8
        width: sizeLabel.implicitWidth + 16
        height: sizeLabel.implicitHeight + 8
        radius: 4
        color: Theme.bg

        Text {
            id: sizeLabel
            anchors.centerIn: parent
            text: `${geomRect.selW} × ${geomRect.selH}`
            color: Theme.fg
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.CrossCursor

        onPressed: mouse => {
            geomRect.visible = true;
            geomRect.startX = mouse.x;
            geomRect.startY = mouse.y;
            geomRect.selX = mouse.x;
            geomRect.selY = mouse.y;
            geomRect.selW = 0;
            geomRect.selH = 0;
        }

        onPositionChanged: mouse => {
            geomRect.selX = Math.min(geomRect.startX, mouse.x);
            geomRect.selY = Math.min(geomRect.startY, mouse.y);
            geomRect.selW = Math.abs(mouse.x - geomRect.startX);
            geomRect.selH = Math.abs(mouse.y - geomRect.startY);
        }

        onReleased: {
            overlay.visible = false;
            geomRect.visible = false;

            if (overlay.socket && geomRect.selW > 0 && geomRect.selH > 0) {
                const geom = `${geomRect.selX},${geomRect.selY} ${geomRect.selW}x${geomRect.selH}`;
                overlay.socket.write(geom + "\n");
                overlay.socket.flush();
            } else if (overlay.socket) {
                overlay.socket.write("\n");
                overlay.socket.flush();
            }
            overlay.socket = null;
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            overlay.visible = false;
            geomRect.visible = false;
            if (overlay.socket) {
                overlay.socket.write("\n");
                overlay.socket.flush();
            }
            overlay.socket = null;
        }
    }
}

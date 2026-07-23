import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: overlay

    visible: false
    color: "transparent"
    property bool committing: false
    property var grabResult: null   // MUST keep the async result alive until saved

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors { top: true; left: true; right: true; bottom: true }

    function activate() {
        geomRect.selX = 0; geomRect.selY = 0;
        geomRect.selW = 0; geomRect.selH = 0;
        geomRect.frozen = false;
        freeze.captureSource = overlay.screen;  // triggers the single capture
        overlay.visible = true;                 // window is transparent until frozen
    }

    function commit() {
        committing = true;            // reshapes cropWrap to the selection
        Qt.callLater(grabSelection);  // let that geometry change apply first
    }

    function grabSelection() {
        const dpr = overlay.screen.devicePixelRatio;
        cropWrap.grabToImage(function(result) {
            overlay.grabResult = result;                 // hold the ref
            const ts = Qt.formatDateTime(new Date(), "yyyyMMdd-hhmmss");
            const path = `${Quickshell.env("HOME")}/Pictures/Screenshots/screenshot-${ts}.png`;
            result.saveToFile(path);                     // native save, no grim
            copyProc.command = ["sh", "-c", `wl-copy --type image/png < "${path}"`];
            copyProc.running = true;
            overlay.teardown();                          // safe: saveToFile is synchronous
        }, Qt.size(Math.round(geomRect.selW * dpr), Math.round(geomRect.selH * dpr)));
    }

    function teardown() {
        overlay.visible = false;
        committing = false;
        grabResult = null;
        geomRect.frozen = false;
        freeze.captureSource = null;
    }

    Process { id: copyProc; running: false }
    Process { id: mkdirProc; running: false
        command: ["mkdir", "-p", `${Quickshell.env("HOME")}/Pictures/Screenshots`] }

    Item {
        id: cropWrap
        clip: true
        // identity (full screen) normally; selection window while committing
        x:      overlay.committing ? geomRect.selX : 0
        y:      overlay.committing ? geomRect.selY : 0
        width:  overlay.committing ? geomRect.selW : overlay.width
        height: overlay.committing ? geomRect.selH : overlay.height

        ScreencopyView {
            id: freeze
            live: false
            paintCursor: false
            x: -cropWrap.x            // cancel the wrapper offset → content stays at screen origin
            y: -cropWrap.y
            width: overlay.width
            height: overlay.height
            onHasContentChanged: if (hasContent) geomRect.frozen = true
        }
    }

    Item {
        id: geomRect
        anchors.fill: parent

        property bool frozen: false
        property int startX: 0
        property int startY: 0
        property int selX: 0
        property int selY: 0
        property int selW: 0
        property int selH: 0
        property int borderWidth: 1

        onFrozenChanged: canvas.requestPaint()
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
                if (!geomRect.frozen || overlay.commiting) return;   // never draw the dim into the captured frame

                ctx.globalAlpha = 0.8;
                ctx.fillStyle = Theme.bg;
                ctx.fillRect(0, 0, width, height);

                ctx.globalAlpha = 1;
                ctx.clearRect(geomRect.selX, geomRect.selY, geomRect.selW, geomRect.selH);

                ctx.strokeStyle = Theme.accent;
                ctx.lineWidth = geomRect.borderWidth;
                ctx.strokeRect(geomRect.selX, geomRect.selY, geomRect.selW, geomRect.selH);
            }
        }
    }

    Rectangle {
        visible: geomRect.frozen && geomRect.selW > 0 && geomRect.selH > 0
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
        enabled: geomRect.frozen   // ignore clicks until the freeze is up

        onPressed: mouse => {
            geomRect.startX = mouse.x; geomRect.startY = mouse.y;
            geomRect.selX = mouse.x;   geomRect.selY = mouse.y;
            geomRect.selW = 0;         geomRect.selH = 0;
        }
        onPositionChanged: mouse => {
            geomRect.selX = Math.min(geomRect.startX, mouse.x);
            geomRect.selY = Math.min(geomRect.startY, mouse.y);
            geomRect.selW = Math.abs(mouse.x - geomRect.startX);
            geomRect.selH = Math.abs(mouse.y - geomRect.startY);
        }
        onReleased: {
            if (geomRect.selW > 0 && geomRect.selH > 0) {
                overlay.commit();
            } else {
                overlay.teardown();
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: overlay.teardown()
    }
}

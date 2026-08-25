import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

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

    readonly property string terminal: "kitty"
    readonly property int rowHeight: 44
    readonly property int maxRows: 8

    // Secondary fields (comment, keywords, …) only count when the match is
    // reasonably strong. Without a floor, a stray subsequence in some app's
    // description matches nearly every query.
    readonly property int minWeakScore: 0

    // Cached $PATH executables, loaded lazily the first time shell mode is used
    // as [{ kind, label, lower, sub, icon }, ...]
    property var binaries: []
    property bool binariesLoaded: false

    // Prebuilt application index, rebuilt only when the entries themselves
    // change. Matching a keystroke against plain JS strings costs nothing;
    // reading DesktopEntry properties and resolving icon paths costs a lot.
    property var appIndex: []

    // Current results: [{ kind, label, sub, icon, entry }, ...]
    // kind is one of "app", "bin", "raw"
    property var results: []

    // Assigned together by setQuery rather than bound to searchField.text:
    // a binding is not guaranteed to have re-evaluated by the time the
    // onTextChanged handler runs, which left matching a keystroke behind.
    property string query: ""
    property bool shellMode: false
    property string command: ""

    function setQuery(text) {
        overlay.query = text;
        overlay.shellMode = text.startsWith(">");
        overlay.command = overlay.shellMode ? text.substring(1).trim() : "";
        overlay.rebuild();
    }

    // Ctrl+W, matching the shell's unix-word-rubout: skip any whitespace
    // directly behind the cursor, then delete back to the next whitespace.
    // The `>` prefix is treated as a boundary so rubbing out the last word
    // doesn't silently drop you back into application mode.
    function deleteWordBackward() {
        const text = searchField.text;
        const end = searchField.cursorPosition;
        let start = end;

        while (start > 0 && /\s/.test(text[start - 1])) start--;
        while (start > 0 && !/\s/.test(text[start - 1])) start--;
        if (start === 0 && text.startsWith(">") && end > 0) start = 1;

        if (start >= end) return;
        searchField.text = text.substring(0, start) + text.substring(end);
        searchField.cursorPosition = start;
    }

    function activate() {
        searchField.text = "";
        overlay.setQuery("");
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

    // ---------------------------------------------------------------- matching

    // Subsequence match with bonuses for prefixes, word boundaries and runs of
    // consecutive characters. Returns -Infinity when `n` is not a subsequence.
    // Both needle and haystack are passed pre-lowercased; `haystack` keeps its
    // original case only for the camelCase check.
    function fuzzyScore(n, haystack, h) {
        if (!h) return -Infinity;
        if (n.length === 0) return 0;
        if (n.length > h.length) return -Infinity;

        let score = 0;
        let cursor = 0;
        let prev = -2;

        for (let i = 0; i < n.length; i++) {
            const at = h.indexOf(n[i], cursor);
            if (at === -1) return -Infinity;

            if (at === prev + 1) score += 8;
            if (at === 0) {
                score += 12;
            } else {
                const before = h[at - 1];
                if (before === " " || before === "-" || before === "_" || before === "." || before === "/") {
                    score += 10;
                } else if (haystack[at] !== h[at] && before === haystack[at - 1].toLowerCase()) {
                    score += 8; // camelCase boundary
                }
            }
            score -= Math.min(at - cursor, 6); // gap penalty

            prev = at;
            cursor = at + 1;
        }

        if (h === n) score += 40;
        else if (h.startsWith(n)) score += 25;
        else if (h.indexOf(n) !== -1) score += 12;

        return score - Math.floor(haystack.length / 12);
    }

    // Best score across an entry's indexed fields, weaker fields penalised.
    function scoreItem(needle, item) {
        let best = -Infinity;

        for (let i = 0; i < item.hay.length; i++) {
            const field = item.hay[i];
            const raw = overlay.fuzzyScore(needle, field[0], field[1]);
            if (raw === -Infinity) continue;

            const score = raw - field[2];
            if (field[2] > 0 && score < overlay.minWeakScore) continue;
            if (score > best) best = score;
        }

        return best;
    }

    // Icon names are turned into provider URLs without touching the disk;
    // Quickshell.iconPath() resolves eagerly and costs ~9ms per lookup, which
    // is far too slow to do for every entry on every keystroke.
    function iconSource(icon) {
        if (!icon) return "";
        if (icon.startsWith("/")) return "file://" + icon;
        if (icon.startsWith("file:") || icon.startsWith("image:")) return icon;
        return "image://icon/" + icon + "?fallback=application-x-executable";
    }

    function buildAppIndex() {
        const apps = DesktopEntries.applications.values;
        let index = [];

        for (let i = 0; i < apps.length; i++) {
            const entry = apps[i];
            if (entry.noDisplay) continue;

            // [text, lowercased text, score penalty]. execString is deliberately
            // not indexed: Nix store paths are noise that make almost every
            // entry match a short query.
            const keywords = (entry.keywords || []).join(" ");
            let hay = [[entry.name, entry.name.toLowerCase(), 0]];
            if (entry.genericName) hay.push([entry.genericName, entry.genericName.toLowerCase(), 12]);
            if (keywords) hay.push([keywords, keywords.toLowerCase(), 18]);
            if (entry.id) hay.push([entry.id, entry.id.toLowerCase(), 20]);
            if (entry.comment) hay.push([entry.comment, entry.comment.toLowerCase(), 28]);

            index.push({
                kind: "app",
                label: entry.name,
                sub: entry.genericName || entry.comment || "",
                icon: overlay.iconSource(entry.icon) || "image://icon/application-x-executable",
                entry: entry,
                hay: hay
            });
        }

        index.sort((a, b) => a.label.localeCompare(b.label));
        overlay.appIndex = index;
    }

    function rebuild() {
        overlay.results = overlay.shellMode ? overlay.shellResults() : overlay.appResults();
        list.currentIndex = overlay.results.length > 0 ? 0 : -1;
    }

    function appResults() {
        const needle = overlay.query.trim().toLowerCase();
        if (needle.length === 0) return overlay.appIndex; // already sorted by name

        let scored = [];
        for (let i = 0; i < overlay.appIndex.length; i++) {
            const item = overlay.appIndex[i];
            const score = overlay.scoreItem(needle, item);
            if (score === -Infinity) continue;
            scored.push({ item: item, score: score });
        }

        scored.sort((a, b) => b.score - a.score || a.item.label.localeCompare(b.item.label));
        return scored.map(s => s.item);
    }

    function shellResults() {
        const cmd = overlay.command;
        let out = [];

        if (cmd.length > 0) {
            out.push({
                kind: "raw",
                label: cmd,
                sub: "Run shell command",
                icon: "",
                entry: null
            });
        }

        // Only offer completions while a single bare word is being typed
        if (cmd.length > 0 && !/\s/.test(cmd)) {
            if (!overlay.binariesLoaded) overlay.loadBinaries();

            const needle = cmd.toLowerCase();
            let scored = [];
            for (let i = 0; i < overlay.binaries.length; i++) {
                const item = overlay.binaries[i];
                if (item.label === cmd) continue; // already the raw entry
                const score = overlay.fuzzyScore(needle, item.label, item.lower);
                if (score === -Infinity) continue;
                scored.push({ item: item, score: score });
            }

            scored.sort((a, b) => b.score - a.score || a.item.label.localeCompare(b.item.label));
            out = out.concat(scored.slice(0, 50).map(s => s.item));
        }

        return out;
    }

    function loadBinaries() {
        overlay.binariesLoaded = true;
        binaryProcess.running = true;
    }

    // --------------------------------------------------------------- launching

    function launch(inTerminal) {
        if (list.currentIndex < 0 || list.currentIndex >= overlay.results.length) {
            // No selection: in shell mode still run whatever was typed
            if (overlay.shellMode && overlay.command.length > 0) {
                overlay.runShell(overlay.command, inTerminal);
                overlay.close();
            }
            return;
        }

        const item = overlay.results[list.currentIndex];

        if (item.kind === "app") {
            overlay.launchEntry(item.entry, inTerminal);
        } else {
            overlay.runShell(item.label, inTerminal);
        }

        overlay.close();
    }

    function launchEntry(entry, inTerminal) {
        // Field codes (%f, %U, …) are dropped; nothing is being passed to them
        let cmd = (entry.command || []).filter(arg => !/^%[a-zA-Z]$/.test(arg));
        if (cmd.length === 0) {
            if (!entry.execString) return;
            cmd = ["sh", "-c", entry.execString];
        }

        if (inTerminal || entry.runInTerminal) {
            cmd = [overlay.terminal, "-e"].concat(cmd);
        }

        if (entry.workingDirectory) {
            Quickshell.execDetached({ command: cmd, workingDirectory: entry.workingDirectory });
        } else {
            Quickshell.execDetached(cmd);
        }
    }

    function runShell(cmd, inTerminal) {
        if (inTerminal) {
            Quickshell.execDetached([overlay.terminal, "--hold", "-e", "sh", "-c", cmd]);
        } else {
            Quickshell.execDetached(["sh", "-c", cmd]);
        }
    }

    function move(delta) {
        if (overlay.results.length === 0) return;
        const next = list.currentIndex + delta;
        list.currentIndex = Math.max(0, Math.min(next, overlay.results.length - 1));
    }

    // ---------------------------------------------------------------- processes

    Process {
        id: binaryProcess
        command: ["sh", "-c", "IFS=:; for d in $PATH; do [ -d \"$d\" ] && ls \"$d\"; done | sort -u"]

        stdout: StdioCollector {
            onStreamFinished: {
                overlay.binaries = text.split("\n").filter(line => line.length > 0).map(name => ({
                    kind: "bin",
                    label: name,
                    lower: name.toLowerCase(),
                    sub: "",
                    icon: "",
                    entry: null
                }));
                if (overlay.visible && overlay.shellMode) overlay.rebuild();
            }
        }
    }

    // Entries load asynchronously after startup, so the index is built off the
    // back of this rather than on first open, and rebuilt if anything changes.
    // The signal fires once per entry while they load, hence the debounce.
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            indexTimer.restart();
        }
    }

    Timer {
        id: indexTimer
        interval: 50
        onTriggered: {
            overlay.buildAppIndex();
            if (overlay.visible && !overlay.shellMode) overlay.rebuild();
        }
    }

    Component.onCompleted: overlay.buildAppIndex()

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            overlay.toggle();
        }

        function open(): void {
            overlay.activate();
        }

        function close(): void {
            overlay.close();
        }
    }

    // -------------------------------------------------------------------- view

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
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter

        y: Math.round((parent.height / 3) + header.height)

        width: 640
        height: header.height + 1 + listArea.height + footer.height
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Theme.fgDim

        Behavior on height {
            NumberAnimation {
                duration: 80
                easing.type: Easing.OutQuad
            }
        }

        // Swallow clicks so they don't dismiss the overlay
        MouseArea {
            anchors.fill: parent
        }

        // Prompt
        Item {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 46

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.padding
                anchors.rightMargin: Theme.padding
                spacing: Theme.padding

                // Mode chip
                Rectangle {
                    Layout.preferredWidth: modeLabel.implicitWidth + Theme.padding * 2
                    Layout.preferredHeight: 22
                    radius: Theme.radius
                    color: Theme.bgAlt

                    Text {
                        id: modeLabel
                        anchors.centerIn: parent
                        text: overlay.shellMode ? "run" : "apps"
                        color: overlay.shellMode ? Theme.warning : Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                    }
                }

                TextInput {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.bg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    clip: true
                    focus: true

                    onTextChanged: overlay.setQuery(text)

                    Keys.onPressed: event => {
                        const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
                        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;

                        if (event.key === Qt.Key_Escape) {
                            overlay.close();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            overlay.launch(shift);
                            event.accepted = true;
                        } else if (ctrl && event.key === Qt.Key_W) {
                            overlay.deleteWordBackward();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_J)) {
                            overlay.move(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_K)) {
                            overlay.move(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_PageDown) {
                            overlay.move(overlay.maxRows);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_PageUp) {
                            overlay.move(-overlay.maxRows);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Home && !shift) {
                            overlay.move(-overlay.results.length);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_End && !shift) {
                            overlay.move(overlay.results.length);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Tab) {
                            // Complete the prompt with the highlighted binary
                            if (overlay.shellMode && list.currentIndex >= 0) {
                                const item = overlay.results[list.currentIndex];
                                if (item.kind === "bin") searchField.text = "> " + item.label;
                                searchField.cursorPosition = searchField.text.length;
                            }
                            event.accepted = true;
                        }
                    }
                }

                Text {
                    visible: overlay.results.length > 0
                    text: overlay.results.length
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Theme.padding * 2 + modeLabel.implicitWidth + Theme.padding * 2
                anchors.verticalCenter: parent.verticalCenter
                text: "Search applications…    > runs a shell command"
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                visible: searchField.text.length === 0
            }
        }

        Rectangle {
            id: separator
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Theme.fgDim
            opacity: 0.5
        }

        Item {
            id: listArea
            anchors.top: separator.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: overlay.results.length === 0
                ? overlay.rowHeight
                : Math.min(overlay.results.length, overlay.maxRows) * overlay.rowHeight

            ListView {
                id: list
                anchors.fill: parent
                anchors.margins: 4
                clip: true
                model: overlay.results
                currentIndex: -1
                boundsBehavior: Flickable.StopAtBounds

                // Last cursor position seen, so rows scrolling under a
                // stationary pointer don't steal the keyboard selection
                property point lastMouse: Qt.point(-1, -1)

                highlight: Rectangle {
                    color: Theme.bgAlt
                    radius: Theme.radius
                }
                highlightMoveDuration: 60

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index

                    width: list.width
                    height: overlay.rowHeight

                    // Accent bar on the selection
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: parent.height - 12
                        radius: 1
                        color: Theme.accent
                        visible: list.currentIndex === row.index
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.padding + 4
                        anchors.rightMargin: Theme.padding
                        spacing: Theme.padding

                        // Fixed slot so the row doesn't shift while an icon loads
                        Item {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24

                            IconImage {
                                anchors.fill: parent
                                visible: row.modelData.icon !== ""
                                source: row.modelData.icon
                                asynchronous: true
                            }

                            // Shell entries have no icon of their own
                            Text {
                                anchors.centerIn: parent
                                visible: row.modelData.icon === ""
                                text: "$"
                                color: Theme.warning
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.label
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: row.modelData.sub !== ""
                                text: row.modelData.sub
                                color: Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 3
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onPositionChanged: mouse => {
                            const at = mapToItem(list, mouse.x, mouse.y);
                            if (at.x === list.lastMouse.x && at.y === list.lastMouse.y) return;
                            list.lastMouse = at;
                            list.currentIndex = row.index;
                        }
                        onClicked: {
                            list.currentIndex = row.index;
                            overlay.launch(false);
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: overlay.results.length === 0
                text: overlay.shellMode ? "Type a command" : "No matching applications"
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
        }

        Item {
            id: footer
            anchors.top: listArea.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 24

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Theme.padding
                anchors.verticalCenter: parent.verticalCenter
                text: "↑↓ move   ⏎ launch   ⇧⏎ terminal   esc close"
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 4
            }
        }
    }
}

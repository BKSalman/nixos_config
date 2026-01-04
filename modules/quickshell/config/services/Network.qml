pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string ssid: ""
    property bool connected: false

    readonly property string icon: connected ? "󰤨" : "󰤭"
    readonly property string status: connected ? ssid : "Disconnected"

    Process {
        id: nmcli
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID", "dev", "wifi"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("yes:")) {
                    root.ssid = line.substring(4)
                    root.connected = true
                }
            }
        }
        onExited: {
            if (!root.ssid) root.connected = false
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: nmcli.running = true
    }
}

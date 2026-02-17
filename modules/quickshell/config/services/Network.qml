pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string ssid: ""
    property bool connected: false
    property string connectionType: "" // "wifi", "ethernet", or ""

    readonly property string icon: {
        if (!connected) return "󰤭";
        if (connectionType === "ethernet") return "󰈁";
        return "󰤨";
    }
    readonly property string status: {
        if (!connected) return "Disconnected";
        if (connectionType === "ethernet") return "Ethernet";
        return ssid;
    }

    Process {
        id: nmcli
        command: ["nmcli", "-t", "-f", "TYPE,STATE,NAME", "connection", "show", "--active"]
        running: true

        property bool foundConnection: false
        property bool foundWifi: false
        property string foundSsid: ""

        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(":");
                if (parts.length < 3) return;
                const type = parts[0];
                const state = parts[1];
                const name = parts.slice(2).join(":");

                if (state !== "activated") return;

                if (type === "802-3-ethernet") {
                    nmcli.foundConnection = true;
                } else if (type === "802-11-wireless") {
                    nmcli.foundConnection = true;
                    nmcli.foundWifi = true;
                    nmcli.foundSsid = name;
                }
            }
        }
        onExited: {
            if (nmcli.foundWifi) {
                root.connectionType = "wifi";
                root.ssid = nmcli.foundSsid;
                root.connected = true;
            } else if (nmcli.foundConnection) {
                root.connectionType = "ethernet";
                root.ssid = "";
                root.connected = true;
            } else {
                root.connectionType = "";
                root.ssid = "";
                root.connected = false;
            }
            nmcli.foundConnection = false;
            nmcli.foundWifi = false;
            nmcli.foundSsid = "";
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: nmcli.running = true
    }
}

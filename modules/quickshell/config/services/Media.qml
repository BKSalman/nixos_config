pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property MprisPlayer player: Mpris.players.values[0] ?? null
    readonly property bool available: player !== null
    readonly property bool playing: available && player.playbackState === MprisPlaybackState.Playing

    readonly property string title: available ? (player.trackTitle || "Unknown") : ""
    readonly property string artist: available ? (player.trackArtist || "") : ""
    readonly property string display: {
        if (!available) return ""
        if (artist) return artist + " - " + title
        return title
    }

    readonly property string icon: playing ? "󰏤" : "󰐊"

    function playPause() { if (available) player.togglePlaying() }
    function next() { if (available) player.next() }
    function previous() { if (available) player.previous() }
}

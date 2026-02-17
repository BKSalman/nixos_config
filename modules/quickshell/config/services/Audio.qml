pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property int volume: sink?.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: sink?.audio ? sink.audio.muted : false

    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property int micVolume: source?.audio ? Math.round(source.audio.volume * 100) : 0
    readonly property bool micMuted: source?.audio ? source.audio.muted : true

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio

        function onVolumeChanged() {
        }
    }

    readonly property string icon: {
        if (muted || volume === 0)
            return "󰝟";
        if (volume < 33)
            return "󰕿";
        if (volume < 66)
            return "󰖀";
        return "󰕾";
    }

    readonly property string micIcon: micMuted ? "󰍭" : "󰍬"

    function setVolume(val) {
        if (sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(1, val / 100));
    }

    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleMicMute() {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }
}

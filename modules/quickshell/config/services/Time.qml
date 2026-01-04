pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property string time: Qt.formatDateTime(clock.date, "hh:mm")
    readonly property string date: Qt.formatDateTime(clock.date, "ddd MMM d")
    readonly property string full: Qt.formatDateTime(clock.date, "hh:mm:ss")

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}

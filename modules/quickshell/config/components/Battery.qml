import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import ".." as Root

RowLayout {
    id: batteryWidget

    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property bool available: battery && battery.isPresent
    readonly property int percent: available ? Math.round(battery.percentage) : 0
    readonly property bool charging: available && battery.state === UPowerDeviceState.Charging

    readonly property string icon: {
        if (!available) return "󰂃"
        if (charging) return "󰂄"
        if (percent > 90) return "󰁹"
        if (percent > 70) return "󰂀"
        if (percent > 50) return "󰁾"
        if (percent > 30) return "󰁼"
        if (percent > 10) return "󰁺"
        return "󰂃"
    }

    readonly property color iconColor: {
        if (charging) return Root.Theme.success
        if (percent > 30) return Root.Theme.fg
        if (percent > 15) return Root.Theme.warning
        return Root.Theme.urgent
    }

    visible: available
    spacing: 4

    Text {
        text: batteryWidget.icon
        font.family: Root.Theme.fontFamily
        font.pixelSize: 14
        color: batteryWidget.iconColor
    }

    Text {
        text: batteryWidget.percent + "%"
        font.family: Root.Theme.fontFamily
        font.pixelSize: Root.Theme.fontSize
        color: batteryWidget.iconColor
    }
}

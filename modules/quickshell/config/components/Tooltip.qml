import QtQuick
import Quickshell
import ".." as Root

PopupWindow {
    id: tooltip

    property Item relativeItem: null
    property int offset: 8

    visible: relativeItem !== null
    anchor.window: relativeItem?.QsWindow?.window ?? null
    anchor.adjustment: PopupAdjustment.Flip

    // Position above the item by default
    anchor.onAnchoring: {
        if (!relativeItem) return;
        const window = relativeItem.QsWindow.window;
        if (!window) return;

        const mapped = window.contentItem.mapFromItem(
            relativeItem,
            0,
            -tooltip.height - offset,
            relativeItem.width,
            relativeItem.height
        );
        tooltip.anchor.rect = mapped;
    }

    color: Root.Theme.bgAlt

    default property alias content: container.data

    implicitWidth: container.childrenRect.width + Root.Theme.padding * 2
    implicitHeight: container.childrenRect.height + Root.Theme.padding

    Item {
        id: container
        anchors.fill: parent
        anchors.margins: Root.Theme.padding / 2
    }
}

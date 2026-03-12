import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import ".." as Root

PanelWindow {
    id: popup

    required property var trayItem
    required property Item anchorItem

    visible: false
    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-traymenu"

    // Use the same screen as the bar
    screen: anchorItem?.QsWindow?.window?.screen ?? null

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // Only the menu content area is clickable
    mask: Region { item: menuContent }

    HyprlandFocusGrab {
        windows: [popup]
        active: popup.visible
        onCleared: popup.close()
    }

    function toggle() {
        if (visible) {
            close();
        } else {
            open();
        }
    }

    function open() {
        visible = true;
    }

    function close() {
        visible = false;
        Qt.callLater(() => menuStack.pop(null));
    }

    Rectangle {
        id: menuContent

        width: menuStack.implicitWidth
        height: menuStack.implicitHeight
        color: Root.Theme.bg
        radius: Root.Theme.radius

        // Position relative to the anchor item within the bar
        x: {
            if (!popup.anchorItem) return 0;
            const barWin = popup.anchorItem.QsWindow?.window;
            if (!barWin) return 0;
            barWin.windowTransform;
            const pos = barWin.itemPosition(popup.anchorItem);
            const ideal = pos.x + popup.anchorItem.width / 2 - width / 2;
            return Math.max(0, Math.min(ideal, popup.width - width));
        }

        // Place above the bar
        y: parent.height - Root.Theme.barHeight - height - 4

        StackView {
            id: menuStack
            anchors.fill: parent

            implicitWidth: currentItem?.implicitWidth ?? 200
            implicitHeight: currentItem?.implicitHeight ?? 100

            initialItem: SubMenu {
                handle: popup.trayItem.menu
            }

            pushEnter: Transition { NumberAnimation { duration: 0 } }
            pushExit: Transition { NumberAnimation { duration: 0 } }
            popEnter: Transition { NumberAnimation { duration: 0 } }
            popExit: Transition { NumberAnimation { duration: 0 } }
        }
    }

    component SubMenu: Column {
        id: menu

        required property var handle
        property bool isSubMenu: false

        padding: 6
        spacing: 2

        QsMenuOpener {
            id: menuOpener
            menu: menu.handle
        }

        // Back button for submenus
        Loader {
            active: menu.isSubMenu
            width: 180

            sourceComponent: Rectangle {
                height: 24
                radius: 4
                color: backArea.containsMouse ? Root.Theme.bgAlt : "transparent"

                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: menuStack.pop()
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    spacing: 4

                    Text {
                        text: "\u2039"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSize
                        color: Root.Theme.fg
                    }
                    Text {
                        text: "Back"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: Root.Theme.fontSize
                        color: Root.Theme.fg
                    }
                }
            }
        }

        Repeater {
            model: menuOpener.children

            Rectangle {
                id: menuItem

                required property QsMenuEntry modelData

                width: 180
                height: modelData.isSeparator ? 9 : 24
                radius: 4
                color: !modelData.isSeparator && itemArea.containsMouse && modelData.enabled
                       ? Root.Theme.bgAlt : "transparent"

                // Separator
                Rectangle {
                    visible: menuItem.modelData.isSeparator
                    anchors.centerIn: parent
                    width: parent.width - 12
                    height: 1
                    color: Root.Theme.fgDim
                }

                // Menu item content
                MouseArea {
                    id: itemArea
                    anchors.fill: parent
                    visible: !menuItem.modelData.isSeparator
                    hoverEnabled: true
                    enabled: menuItem.modelData.enabled
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: event => {
                        if (menuItem.modelData.hasChildren) {
                            menuStack.push(subMenuComp.createObject(null, {
                                handle: menuItem.modelData,
                                isSubMenu: true
                            }));
                        } else {
                            menuItem.modelData.triggered();
                            popup.close();
                        }
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 6

                        // Icon
                        IconImage {
                            visible: menuItem.modelData.icon !== ""
                            source: menuItem.modelData.icon
                            implicitSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Label
                        Text {
                            text: menuItem.modelData.text
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSize
                            color: menuItem.modelData.enabled ? Root.Theme.fg : Root.Theme.fgDim
                            elide: Text.ElideRight
                            width: parent.width - (menuItem.modelData.icon !== "" ? 20 : 0) - (menuItem.modelData.hasChildren ? 16 : 0)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Submenu arrow
                        Text {
                            visible: menuItem.modelData.hasChildren
                            text: "\u203A"
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: Root.Theme.fontSize
                            color: menuItem.modelData.enabled ? Root.Theme.fg : Root.Theme.fgDim
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }

    Component {
        id: subMenuComp
        SubMenu {}
    }
}

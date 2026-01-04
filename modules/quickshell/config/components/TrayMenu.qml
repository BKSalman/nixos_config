import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import ".." as Root

PopupWindow {
    id: popup

    required property var trayItem
    required property Item anchorItem

    visible: false
    anchor.window: anchorItem?.QsWindow?.window ?? null
    anchor.adjustment: PopupAdjustment.Flip

    anchor.onAnchoring: {
        if (!anchorItem) return;
        const window = anchorItem.QsWindow.window;
        if (!window) return;
        const mapped = window.contentItem.mapFromItem(
            anchorItem, 0, - anchorItem.height - popup.height + 4,
            anchorItem.width, anchorItem.height
        );
        popup.anchor.rect = mapped;
    }

    color: Root.Theme.bg

    implicitWidth: menuStack.implicitWidth
    implicitHeight: menuStack.implicitHeight

    HyprlandFocusGrab {
        id: focusGrab
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
        // Delay stack reset to avoid visual glitch
        Qt.callLater(() => menuStack.pop(null));
    }

    // Catch clicks on the background to close
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        propagateComposedEvents: true
        z: -1

        onClicked: event => {
            event.accepted = false; // Let it propagate to children
        }
    }

    StackView {
        id: menuStack

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
                        text: "‹"
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
                            text: "›"
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

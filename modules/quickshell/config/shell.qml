//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io
import Quickshell.Wayland
import "components"

ShellRoot {
    ActivateLinux {}
    Bar {}
    MicMuteOSD {}

    // Notification server - enables notifications to be received
    // You can build a notification popup UI using NotificationServer.notifications
    NotificationServer {
        id: notificationServer

        onNotification: notification => {
            // Notifications are available in notificationServer.notifications
            // For a minimal setup, we just track them; you can add a popup UI later
            console.log("Notification:", notification.summary);
        }
    }

    ScreenshotOverlay {
        id: screenshotOverlay
    }

    ClipboardOverlay {
        id: clipboardOverlay
    }

    LockScreen {
        id: lockScreen
    }

    IpcHandler {
        target: "shell"

        function lock(): void {
            lockScreen.lock();
        }
    }

    PanelWindow {
        color: "transparent"
        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background

        Image {
            source: "background.png"
            anchors.fill: parent
        }
    }

    SocketServer {
        active: true
        path: "/tmp/quickshell.sock"

        handler: Socket {
            id: handler

            parser: SplitParser {
                onRead: msg => {
                    if (msg === "screenshot") {
                        screenshotOverlay.activate(handler);
                    } else if (msg === "clipboard") {
                        clipboardOverlay.toggle();
                    }
                }
            }
        }
    }
}

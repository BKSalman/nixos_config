//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io

ShellRoot {
    ActivateLinux {}
    Bar {}

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

    SocketServer {
        active: true
        path: "/tmp/quickshell-screenshot.sock"

        handler: Socket {
            id: handler

            onConnectedChanged: {
                console.log(connected ? "new connection!" : "connection dropped!");
            }

            parser: SplitParser {
                onRead: msg => {
                    if (msg === "screenshot") {
                        screenshotOverlay.activate(handler);
                    }
                }
            }
        }
    }
}

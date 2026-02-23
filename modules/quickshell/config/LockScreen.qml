import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "services" as Services

Scope {
    id: root

    property bool isLocked: lock.locked

    function lock() {
        lock.locked = true;
    }

    // Auto-lock after 10 minutes of inactivity
    IdleMonitor {
        timeout: 600
        onIsIdleChanged: {
            if (isIdle && !lock.locked && !Services.Media.playing) {
                lock.locked = true;
            }
        }
    }

    WlSessionLock {
        id: lock

        surface: Component {
            WlSessionLockSurface {
                id: surface
                color: Theme.bg

                // Background wallpaper
                Image {
                    anchors.fill: parent
                    source: "background.png"
                    fillMode: Image.PreserveAspectCrop
                }

                // Dark overlay for readability
                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    opacity: 0.5
                }

                // PAM authentication
                property string pendingPassword: ""
                property bool unlockInProgress: false

                function tryUnlock() {
                    if (passwordField.text === "") return;
                    pendingPassword = passwordField.text;
                    passwordField.text = "";
                    unlockInProgress = true;
                    pam.start();
                }

                PamContext {
                    id: pam
                    config: "quickshell-lock"

                    onPamMessage: {
                        if (this.responseRequired) {
                            this.respond(surface.pendingPassword);
                        }
                    }

                    onCompleted: result => {
                        surface.unlockInProgress = false;
                        if (result === PamResult.Success) {
                            surface.pendingPassword = "";
                            passwordContainer.visible = false;
                            errorText.visible = false;
                            lock.locked = false;
                        } else {
                            surface.pendingPassword = "";
                            errorText.text = "Authentication failed";
                            errorText.visible = true;
                            errorTimer.restart();
                        }
                    }
                }

                // Main content
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        passwordContainer.visible = true;
                        passwordField.forceActiveFocus();
                    }
                }

                // Capture any keypress to show the password field
                Keys.onPressed: event => {
                    if (!passwordContainer.visible) {
                        passwordContainer.visible = true;
                        passwordField.forceActiveFocus();
                    }
                }

                Item {
                    focus: true
                    anchors.fill: parent

                    Keys.onPressed: event => {
                        if (!passwordContainer.visible) {
                            passwordContainer.visible = true;
                            passwordField.forceActiveFocus();
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 16

                        // Clock - time
                        Text {
                            text: Services.Time.time
                            font.family: Theme.fontFamily
                            font.pixelSize: 72
                            font.bold: true
                            color: Theme.fg
                            Layout.alignment: Qt.AlignHCenter
                        }

                        // Clock - date
                        Text {
                            text: Services.Time.date
                            font.family: Theme.fontFamily
                            font.pixelSize: 24
                            color: Theme.fgDim
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Item { Layout.preferredHeight: 32 }

                        // Password input container
                        Rectangle {
                            id: passwordContainer
                            visible: false
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 300
                            Layout.preferredHeight: 40
                            radius: Theme.radius
                            color: Theme.bgAlt
                            border.width: 2
                            border.color: passwordField.activeFocus ? Theme.accent : Theme.fgDim

                            TextInput {
                                id: passwordField
                                anchors.fill: parent
                                anchors.margins: 8
                                verticalAlignment: TextInput.AlignVCenter
                                echoMode: TextInput.Password
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                clip: true

                                onAccepted: surface.tryUnlock()
                            }

                            // Placeholder text
                            Text {
                                anchors.fill: parent
                                anchors.margins: 8
                                verticalAlignment: Text.AlignVCenter
                                text: "Password"
                                color: Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                visible: passwordField.text.length === 0 && !passwordField.activeFocus
                            }
                        }

                        // Error message
                        Text {
                            id: errorText
                            visible: false
                            text: ""
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: Theme.urgent
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Timer {
                            id: errorTimer
                            interval: 3000
                            onTriggered: errorText.visible = false
                        }
                    }
                }

                // Reset state when the surface becomes visible
                onVisibleChanged: {
                    if (visible) {
                        passwordContainer.visible = false;
                        passwordField.text = "";
                        pendingPassword = "";
                        unlockInProgress = false;
                        errorText.visible = false;
                    }
                }
            }
        }
    }
}

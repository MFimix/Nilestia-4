// =============================================================================
//  Nilestia-4 — Lockscreen
//  Adapted from Caelestia Shell's lock module (modules/lock/)
//  Uses Quickshell's WlSessionLock for proper Wayland lockscreen behavior.
//  systemd-logind integration is handled by nilestia-lock.sh + systemd unit.
// =============================================================================
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

WlSessionLock {
    id: sessionLock

    // Called by loginctl lock-session via systemd-logind hook
    // (nilestia-lock.sh sends SIGUSR1 or uses `qs ipc call lockToggle`)
    locked: false

    function activate() {
        sessionLock.locked = true;
    }

    IpcHandler {
        target: "lockToggle"
        function onMessage(message: string): void {
            sessionLock.activate();
        }
    }

    // One lock surface per screen
    Variants {
        model: sessionLock.surfaces

        LockSurface {
            required property WlSessionLockSurface modelData
            lockSurface: modelData
        }
    }
}

// ── Per-Screen Lock Surface ────────────────────────────────────────────────────
component LockSurface: WlSessionLockSurface {
    id: surface

    // ── PAM authenticator ──────────────────────────────────────────────────
    PamAuthenticator {
        id: pam
        service: "hyprlock"   // uses /etc/pam.d/hyprlock config

        onAuthSucceeded: {
            sessionLock.locked = false;
        }

        onAuthFailed: {
            passwordInput.text = "";
            shakeAnim.start();
            failLabel.visible = true;
            failTimer.restart();
        }
    }

    Timer {
        id: failTimer
        interval: 2500
        onTriggered: failLabel.visible = false
    }

    // ── Background ─────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        // Read wallpaper set by Matugen/Hyprpaper
        color: "#0F0D13"  // dark Material You surface fallback

        // Blurred wallpaper effect (if available)
        Image {
            anchors.fill: parent
            source: {
                const wpath = Process.getenv("NILESTIA_WALLPAPER") || "";
                return wpath ? ("file://" + wpath) : "";
            }
            fillMode: Image.PreserveAspectCrop
            opacity: 0.25
        }
    }

    // ── Clock & lock UI ─────────────────────────────────────────────────────
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 28

        // Clock
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            Text {
                id: clockTime
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatTime(new Date(), "hh:mm")
                font.pixelSize: 80
                font.weight: Font.Light
                color: "#E6E1E5"

                Timer {
                    interval: 30000; repeat: true; running: true
                    onTriggered: clockTime.text = Qt.formatTime(new Date(), "hh:mm")
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(new Date(), "dddd, MMMM d")
                font.pixelSize: 18
                color: "#CAC4D0"
                font.weight: Font.Light
            }
        }

        // ── Password input ───────────────────────────────────────────────────
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            Rectangle {
                id: inputBox
                Layout.alignment: Qt.AlignHCenter
                width: 320; height: 52
                radius: 26
                color: Qt.rgba(1, 1, 1, 0.10)
                border.color: Qt.rgba(1, 1, 1, inputFocus.activeFocus ? 0.5 : 0.15)
                border.width: 1.5

                // Shake animation on wrong password
                SequentialAnimation {
                    id: shakeAnim
                    NumberAnimation { target: inputBox; property: "x"; from: 0; to: -10; duration: 50 }
                    NumberAnimation { target: inputBox; property: "x"; from: -10; to: 10; duration: 60 }
                    NumberAnimation { target: inputBox; property: "x"; from: 10; to: -8; duration: 60 }
                    NumberAnimation { target: inputBox; property: "x"; from: -8; to: 8; duration: 60 }
                    NumberAnimation { target: inputBox; property: "x"; from: 8; to: 0; duration: 50 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Image {
                        source: "image://icon/changes-prevent-symbolic"
                        width: 18; height: 18
                        opacity: 0.6
                    }

                    TextField {
                        id: passwordInput
                        Layout.fillWidth: true
                        echoMode: TextInput.Password
                        placeholderText: "Password…"
                        font.pixelSize: 16
                        color: "#E6E1E5"
                        background: Item {}
                        focus: true

                        onAccepted: {
                            pam.tryAuthenticate(passwordInput.text);
                        }

                        FocusScope {
                            id: inputFocus
                            anchors.fill: parent
                        }
                    }
                }
            }

            // Wrong password label
            Text {
                id: failLabel
                Layout.alignment: Qt.AlignHCenter
                text: "Incorrect password"
                color: "#CF6679"
                font.pixelSize: 13
                visible: false
            }

            // Hint
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Press Enter to unlock"
                color: Qt.rgba(1,1,1,0.35)
                font.pixelSize: 12
            }
        }

        // ── User info ────────────────────────────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            // User avatar
            Rectangle {
                width: 40; height: 40
                radius: 20
                color: "#7965AF"

                Image {
                    anchors.fill: parent
                    source: "file:///var/lib/AccountsService/icons/" + Process.getenv("USER")
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: true
                    layer.effect: ShaderEffect {
                        // circular clip
                    }
                }
            }

            Text {
                text: Process.getenv("USER") || "user"
                color: "#E6E1E5"
                font.pixelSize: 14
                font.weight: Font.Medium
            }
        }
    }
}

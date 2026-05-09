// =============================================================================
//  Nilestia-4 — Top Menu (Caelestia Dark Mode Port)
//  Triggered by: hovering/dragging mouse to the top 2px of the screen
//  Features: App launcher shortcuts, system info, quick toggles
// =============================================================================
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemInformation

// ── Top Menu Root: one instance per screen ────────────────────────────────────
Variants {
    model: Quickshell.screens

    Scope {
        id: scope
        required property ShellScreen modelData

        // ── Hot Zone: 2px invisible strip at screen top ───────────────────────
        PanelWindow {
            id: hotZone
            screen: scope.modelData
            visible: true
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 2

            // Edge detection region
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: menuTimer.restart()
                onExited: menuTimer.stop()
            }
        }

        // ── Auto-show timer ───────────────────────────────────────────────────
        Timer {
            id: menuTimer
            interval: 80   // 80ms dwell before menu appears
            onTriggered: topMenu.visible = true
        }

        // ── Top Menu Window ───────────────────────────────────────────────────
        PanelWindow {
            id: topMenu
            screen: scope.modelData
            visible: false
            color: Qt.rgba(0.08, 0.08, 0.10, 0.95)

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: menuRow.implicitHeight + 16

            // Auto-hide on mouse leave (with a small delay)
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onExited: hideTimer.restart()
                onEntered: hideTimer.stop()
            }

            Timer {
                id: hideTimer
                interval: 400
                onTriggered: topMenu.visible = false
            }

            // ── Slide-in animation ───────────────────────────────────────────
            layer.enabled: true
            opacity: topMenu.visible ? 1.0 : 0.0
            transform: Translate { y: topMenu.visible ? 0 : -topMenu.height }

            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on transform { }

            // ── Bottom border ────────────────────────────────────────────────
            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 1
                color: Qt.rgba(1, 1, 1, 0.10)
            }

            // ── Content ──────────────────────────────────────────────────────
            RowLayout {
                id: menuRow
                anchors {
                    left: parent.left; right: parent.right
                    top: parent.top
                    margins: 12
                    topMargin: 8
                }
                spacing: 8
                height: 40

                // ── Left: Logo + App Shortcuts ────────────────────────────────
                // Nilestia / distro logo
                Rectangle {
                    width: 32; height: 32; radius: 8
                    color: Qt.rgba(0.44, 0.37, 0.80, 0.3)

                    Image {
                        anchors.centerIn: parent
                        source: "image://icon/distributor-logo-archlinux-symbolic"
                        width: 18; height: 18
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            topMenu.visible = false;
                            // Open the end-4 dashboard / left sidebar
                            Quickshell.ipc("ii", "sidebarLeftToggle");
                        }
                    }
                }

                // Separator
                Rectangle { width: 1; height: 24; color: Qt.rgba(1,1,1,0.1) }

                // App shortcuts
                Repeater {
                    model: [
                        { label: "Terminal",    icon: "utilities-terminal-symbolic",     cmd: "$TERM" },
                        { label: "Browser",     icon: "web-browser-symbolic",            cmd: "xdg-open https://" },
                        { label: "Files",       icon: "system-file-manager-symbolic",    cmd: "nautilus" },
                        { label: "Settings",    icon: "preferences-system-symbolic",     cmd: "gnome-control-center" },
                        { label: "Htop",        icon: "utilities-system-monitor-symbolic", cmd: "$TERM -e btop" },
                    ]

                    delegate: TopMenuButton {
                        required property var modelData
                        icon: modelData.icon
                        tooltip: modelData.label
                        onClicked: {
                            topMenu.visible = false;
                            Process.startDetached("sh", ["-c", modelData.cmd]);
                        }
                    }
                }

                // ── Center: System info ticker ────────────────────────────────
                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 14

                    // CPU
                    TopInfoChip {
                        icon: "computer-symbolic"
                        value: Math.round(SystemInformation.cpu ?? 0) + "%"
                        label: "CPU"
                    }

                    // RAM
                    TopInfoChip {
                        icon: "memory-symbolic"
                        value: Math.round(((SystemInformation.memoryUsed ?? 0) /
                               (SystemInformation.memoryTotal ?? 1)) * 100) + "%"
                        label: "RAM"
                    }

                    // Time
                    Text {
                        text: Qt.formatTime(new Date(), "hh:mm")
                        color: "#E6E1E5"
                        font.pixelSize: 14
                        font.weight: Font.Medium

                        Timer {
                            interval: 30000
                            repeat: true
                            running: true
                            onTriggered: parent.text = Qt.formatTime(new Date(), "hh:mm")
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // ── Right: Quick toggles ───────────────────────────────────────
                Rectangle { width: 1; height: 24; color: Qt.rgba(1,1,1,0.1) }

                // Audio toggle
                TopMenuButton {
                    icon: "audio-volume-high-symbolic"
                    tooltip: "Audio Manager"
                    onClicked: {
                        topMenu.visible = false;
                        Quickshell.ipc("nilestia", "nilestiaAudioToggle");
                    }
                }

                // WiFi toggle
                TopMenuButton {
                    icon: "network-wireless-symbolic"
                    tooltip: "WiFi"
                    onClicked: {
                        topMenu.visible = false;
                        Quickshell.ipc("nilestia", "nilestiaWifiToggle");
                    }
                }

                // Bluetooth toggle
                TopMenuButton {
                    icon: "bluetooth-active-symbolic"
                    tooltip: "Bluetooth"
                    onClicked: {
                        topMenu.visible = false;
                        Quickshell.ipc("nilestia", "nilestiaBluetoothToggle");
                    }
                }

                // Session
                TopMenuButton {
                    icon: "system-shutdown-symbolic"
                    tooltip: "Session"
                    onClicked: {
                        topMenu.visible = false;
                        Quickshell.ipc("ii", "sessionToggle");
                    }
                }
            }
        }
    }
}

// ── Reusable top menu icon button ─────────────────────────────────────────────
component TopMenuButton: Rectangle {
    id: btn

    required property string icon
    property string tooltip: ""
    signal clicked()

    width: 32; height: 32
    radius: 8
    color: mouseArea.containsMouse ? Qt.rgba(1,1,1,0.12) : "transparent"

    Image {
        anchors.centerIn: parent
        source: "image://icon/" + btn.icon
        width: 18; height: 18
        fillMode: Image.PreserveAspectFit
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()

        ToolTip.visible: containsMouse && btn.tooltip !== ""
        ToolTip.text: btn.tooltip
        ToolTip.delay: 600
    }

    Behavior on color { ColorAnimation { duration: 100 } }
}

// ── System info chip ──────────────────────────────────────────────────────────
component TopInfoChip: RowLayout {
    required property string icon
    required property string value
    required property string label

    spacing: 5

    Image {
        source: "image://icon/" + parent.icon
        width: 14; height: 14
        fillMode: Image.PreserveAspectFit
        opacity: 0.7
    }

    Text {
        text: parent.label + ": " + parent.value
        color: "#CAC4D0"
        font.pixelSize: 12
    }
}

// =============================================================================
//  Nilestia-4 — Monitor Management Hub
//  Mapped to: Super + Ctrl + M
//  Allows configuring connected displays (resolution, position, scale, etc.)
// =============================================================================
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

Item {
    id: monitorRoot

    function toggle() { monitorWin.visible = !monitorWin.visible; }

    PanelWindow {
        id: monitorWin
        visible: false
        color: Qt.rgba(0.08, 0.08, 0.10, 0.93)

        contentItem: MonitorHubContent {
            onClosed: monitorWin.visible = false
        }
    }
}

component MonitorHubContent: Rectangle {
    id: content

    signal closed()

    color: "transparent"
    radius: 16

    // Pull monitor list from Quickshell
    property var monitors: Quickshell.screens ?? []
    property int selectedIdx: 0
    property var selected: monitors[selectedIdx] ?? null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        // ── Header ────────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Image {
                source: "image://icon/video-display-symbolic"
                width: 24; height: 24
            }

            Text {
                text: "Monitor Hub"
                font.pixelSize: 22
                font.weight: Font.Medium
                color: "#E6E1E5"
            }

            Item { Layout.fillWidth: true }

            RoundButton {
                icon.name: "window-close-symbolic"
                flat: true
                onClicked: content.closed()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.08)
        }

        // ── Monitor Tabs ──────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: content.monitors

                delegate: Rectangle {
                    required property ShellScreen modelData
                    required property int index

                    height: 36
                    width: monTabText.width + 28
                    radius: 8
                    color: content.selectedIdx === index
                           ? Qt.rgba(0.44, 0.37, 0.80, 0.35)
                           : Qt.rgba(1, 1, 1, 0.07)

                    Text {
                        id: monTabText
                        anchors.centerIn: parent
                        text: modelData.name || ("Display " + (index + 1))
                        color: content.selectedIdx === index ? "#D0BCFF" : "#CAC4D0"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: content.selectedIdx = index
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        // ── Monitor Visual Preview ────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 160
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.04)
            clip: true

            // Simple preview of monitor arrangement
            Repeater {
                model: content.monitors

                delegate: Rectangle {
                    required property ShellScreen modelData
                    required property int index

                    property real scaleX: 140 / (content.monitors.reduce((acc, m) =>
                        Math.max(acc, m.width + (m.x ?? 0)), 1))

                    x: (modelData.x ?? (index * (modelData.width + 20) / 10)) * scaleX + 20
                    y: 20
                    width: modelData.width * scaleX
                    height: modelData.height * scaleX * 0.6

                    radius: 4
                    color: content.selectedIdx === index
                           ? Qt.rgba(0.44, 0.37, 0.80, 0.4)
                           : Qt.rgba(1, 1, 1, 0.10)
                    border.color: content.selectedIdx === index ? "#7965AF" : "#49454F"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData.name || ("D" + (index + 1))
                        color: "#E6E1E5"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: content.selectedIdx = index
                    }
                }
            }
        }

        // ── Selected Monitor Properties ───────────────────────────────────────
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 16
            rowSpacing: 10

            visible: content.selected !== null

            // Resolution
            Text { text: "Resolution"; color: "#CAC4D0"; font.pixelSize: 13 }
            Text {
                text: content.selected ? (content.selected.width + " × " + content.selected.height) : "—"
                color: "#E6E1E5"
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            // Refresh rate
            Text { text: "Refresh Rate"; color: "#CAC4D0"; font.pixelSize: 13 }
            Text {
                text: content.selected ? (Math.round(content.selected.refreshRate || 60) + " Hz") : "—"
                color: "#E6E1E5"
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            // Scale
            Text { text: "Scale"; color: "#CAC4D0"; font.pixelSize: 13 }
            RowLayout {
                spacing: 8
                Slider {
                    id: scaleSlider
                    from: 1.0; to: 3.0
                    stepSize: 0.25
                    value: content.selected?.devicePixelRatio ?? 1.0
                    implicitWidth: 160

                    background: Rectangle {
                        y: scaleSlider.topPadding + scaleSlider.availableHeight / 2 - height / 2
                        width: scaleSlider.availableWidth; height: 4
                        radius: 2; color: "#49454F"

                        Rectangle {
                            width: scaleSlider.visualPosition * parent.width
                            height: parent.height; radius: 2; color: "#D0BCFF"
                        }
                    }

                    handle: Rectangle {
                        x: scaleSlider.leftPadding + scaleSlider.visualPosition * (scaleSlider.availableWidth - width)
                        y: scaleSlider.topPadding + scaleSlider.availableHeight / 2 - height / 2
                        width: 16; height: 16; radius: 8; color: "#D0BCFF"
                    }
                }
                Text {
                    text: "×" + scaleSlider.value.toFixed(2)
                    color: "#E6E1E5"; font.pixelSize: 13; width: 44
                }
            }

            // Rotation (Hyprland transform)
            Text { text: "Rotation"; color: "#CAC4D0"; font.pixelSize: 13 }
            RowLayout {
                spacing: 6
                Repeater {
                    model: ["0°", "90°", "180°", "270°"]
                    delegate: Rectangle {
                        required property string modelData
                        required property int index
                        property bool isSelected: index === 0 // TODO: read real transform

                        width: 44; height: 28; radius: 7
                        color: isSelected ? Qt.rgba(0.44, 0.37, 0.80, 0.35) : Qt.rgba(1,1,1,0.07)

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: isSelected ? "#D0BCFF" : "#CAC4D0"
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                // Apply via hyprctl
                                const transforms = [0, 1, 2, 3];
                                const mon = content.selected?.name ?? "";
                                if (mon)
                                    Qt.callLater(() => Process.startDetached("hyprctl",
                                        ["keyword", "monitor", mon + ",transform," + transforms[index]]));
                            }
                        }
                    }
                }
            }
        }

        // ── Apply Button ──────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 42
            radius: 10
            color: Qt.rgba(0.44, 0.37, 0.80, 0.35)

            Text {
                anchors.centerIn: parent
                text: "Apply Changes via hyprctl"
                color: "#D0BCFF"
                font.pixelSize: 14
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    const mon = content.selected?.name ?? "";
                    const w = content.selected?.width ?? 1920;
                    const h = content.selected?.height ?? 1080;
                    const rr = Math.round(content.selected?.refreshRate ?? 60);
                    const scale = scaleSlider.value.toFixed(2);
                    if (mon) {
                        Qt.callLater(() => Process.startDetached("hyprctl",
                            ["keyword", "monitor",
                             mon + "," + w + "x" + h + "@" + rr + ",auto," + scale]));
                    }
                }
            }
        }

        // Open arandr / wdisplays for advanced config
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Open wdisplays for advanced layout"
            color: "#7965AF"
            font.pixelSize: 12

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Process.startDetached("wdisplays", [])
            }
        }

        Item { Layout.fillHeight: true }
    }
}

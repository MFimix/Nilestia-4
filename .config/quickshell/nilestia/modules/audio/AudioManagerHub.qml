// =============================================================================
//  Nilestia-4 — Audio Manager Hub
//  Adapted from Caelestia Shell AudioPane (QML)
//  Shown as a floating window on Win + A
// =============================================================================
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

// Exported as a component — shell.qml instantiates this
Item {
    id: root

    property bool visible: false

    function toggle() {
        audioWin.visible = !audioWin.visible;
    }

    PanelWindow {
        id: audioWin

        visible: false
        // Let Hyprland rules handle size/position (class: nilestia-audio)
        WlrLayerShellV1.layer: WlrLayerShellV1.Layer.Overlay

        // Dark background matching Material You surface container
        color: Qt.rgba(0.08, 0.08, 0.10, 0.92)

        contentItem: AudioManagerContent {}
    }
}

// ── AudioManagerContent ────────────────────────────────────────────────────────
component AudioManagerContent: Rectangle {
    id: content

    color: "transparent"
    radius: 16

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // ── Header ────────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Audio Manager"
                font.pixelSize: 22
                font.weight: Font.Medium
                color: "#E6E1E5"
            }
            Item { Layout.fillWidth: true }
            RoundButton {
                icon.name: "window-close-symbolic"
                flat: true
                onClicked: audioWin.visible = false
            }
        }

        // ── Output Devices ────────────────────────────────────────────────────
        SectionLabel { text: "Output Devices" }

        Repeater {
            model: PwObjectTracker {
                objects: Pipewire.nodes.values.filter(n =>
                    n.isStream === false && n.audio !== null && !n.isSink === false)
            }

            delegate: DeviceRow {
                required property PwNode modelData
                icon: "audio-speakers-symbolic"
                label: modelData.description || modelData.name || "Unknown"
                isDefault: Pipewire.defaultAudioSink?.id === modelData.id
                onActivated: Pipewire.preferredDefaultAudioSink = modelData
            }
        }

        // ── Output Volume ─────────────────────────────────────────────────────
        SectionLabel { text: "Output Volume" }

        VolumeRow {
            Layout.fillWidth: true
            icon: Pipewire.defaultAudioSink?.audio?.muted ? "audio-volume-muted-symbolic"
                                                           : "audio-volume-high-symbolic"
            vol: Pipewire.defaultAudioSink?.audio?.volume ?? 0
            muted: Pipewire.defaultAudioSink?.audio?.muted ?? false
            onVolumeChanged: v => {
                if (Pipewire.defaultAudioSink?.audio)
                    Pipewire.defaultAudioSink.audio.volume = v;
            }
            onMuteToggled: {
                if (Pipewire.defaultAudioSink?.audio)
                    Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
            }
        }

        // ── Input Devices ─────────────────────────────────────────────────────
        SectionLabel { text: "Input Devices" }

        Repeater {
            model: PwObjectTracker {
                objects: Pipewire.nodes.values.filter(n =>
                    n.isStream === false && n.audio !== null && n.isSink === true)
            }

            delegate: DeviceRow {
                required property PwNode modelData
                icon: "audio-input-microphone-symbolic"
                label: modelData.description || modelData.name || "Unknown"
                isDefault: Pipewire.defaultAudioSource?.id === modelData.id
                onActivated: Pipewire.preferredDefaultAudioSource = modelData
            }
        }

        // ── Input Volume ──────────────────────────────────────────────────────
        SectionLabel { text: "Mic Volume" }

        VolumeRow {
            Layout.fillWidth: true
            icon: Pipewire.defaultAudioSource?.audio?.muted ? "microphone-sensitivity-muted-symbolic"
                                                             : "microphone-sensitivity-high-symbolic"
            vol: Pipewire.defaultAudioSource?.audio?.volume ?? 0
            muted: Pipewire.defaultAudioSource?.audio?.muted ?? false
            onVolumeChanged: v => {
                if (Pipewire.defaultAudioSource?.audio)
                    Pipewire.defaultAudioSource.audio.volume = v;
            }
            onMuteToggled: {
                if (Pipewire.defaultAudioSource?.audio)
                    Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted;
            }
        }

        // ── Application Streams ───────────────────────────────────────────────
        SectionLabel { text: "Applications" }

        Repeater {
            model: PwObjectTracker {
                objects: Pipewire.nodes.values.filter(n => n.isStream === true && n.audio !== null)
            }

            delegate: VolumeRow {
                required property PwNode modelData
                Layout.fillWidth: true
                icon: "application-x-executable-symbolic"
                label: modelData.description || modelData.name || "App"
                vol: modelData.audio?.volume ?? 0
                muted: modelData.audio?.muted ?? false
                onVolumeChanged: v => {
                    if (modelData.audio) modelData.audio.volume = v;
                }
                onMuteToggled: {
                    if (modelData.audio) modelData.audio.muted = !modelData.audio.muted;
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}

// ── Reusable sub-components ───────────────────────────────────────────────────

component SectionLabel: Text {
    font.pixelSize: 13
    font.weight: Font.Medium
    color: "#CAC4D0"
    topPadding: 4
}

component DeviceRow: Rectangle {
    id: deviceRow

    required property string icon
    required property string label
    required property bool isDefault
    signal activated()

    Layout.fillWidth: true
    height: 48
    radius: 10
    color: isDefault ? Qt.rgba(0.45, 0.38, 0.80, 0.25) : Qt.rgba(1, 1, 1, 0.05)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Image {
            source: "image://icon/" + deviceRow.icon
            width: 20; height: 20
            fillMode: Image.PreserveAspectFit
        }
        Text {
            Layout.fillWidth: true
            text: deviceRow.label
            color: "#E6E1E5"
            font.pixelSize: 14
            elide: Text.ElideRight
        }
        Rectangle {
            width: 8; height: 8
            radius: 4
            color: "#7965AF"
            visible: deviceRow.isDefault
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: deviceRow.activated()
    }

    Behavior on color {
        ColorAnimation { duration: 150 }
    }
}

component VolumeRow: Rectangle {
    id: volRow

    required property string icon
    property string label: ""
    required property real vol
    required property bool muted

    signal volumeChanged(real v)
    signal muteToggled()

    Layout.fillWidth: true
    height: label ? 64 : 52
    radius: 10
    color: Qt.rgba(1, 1, 1, 0.05)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 4

        Text {
            visible: volRow.label !== ""
            text: volRow.label
            color: "#CAC4D0"
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        RowLayout {
            spacing: 10

            Image {
                source: "image://icon/" + volRow.icon
                width: 18; height: 18
                fillMode: Image.PreserveAspectFit
                opacity: volRow.muted ? 0.4 : 1
            }

            Slider {
                id: slider
                Layout.fillWidth: true
                from: 0; to: 1
                value: volRow.vol
                enabled: !volRow.muted
                opacity: enabled ? 1.0 : 0.4

                background: Rectangle {
                    x: slider.leftPadding
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    implicitWidth: 200; implicitHeight: 4
                    width: slider.availableWidth; height: implicitHeight
                    radius: 2
                    color: "#49454F"

                    Rectangle {
                        width: slider.visualPosition * parent.width
                        height: parent.height
                        radius: 2
                        color: "#D0BCFF"
                    }
                }

                handle: Rectangle {
                    x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    width: 16; height: 16
                    radius: 8
                    color: "#D0BCFF"
                }

                onMoved: volRow.volumeChanged(value)
            }

            Text {
                text: Math.round(volRow.vol * 100) + "%"
                color: "#CAC4D0"
                font.pixelSize: 12
                width: 36
                horizontalAlignment: Text.AlignRight
                opacity: volRow.muted ? 0.4 : 1
            }

            Rectangle {
                width: 32; height: 32
                radius: 8
                color: volRow.muted ? "#625B71" : Qt.rgba(1,1,1,0.08)

                Image {
                    anchors.centerIn: parent
                    source: "image://icon/" + (volRow.muted ? "audio-volume-muted-symbolic" : volRow.icon)
                    width: 16; height: 16
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: volRow.muteToggled()
                }
            }
        }
    }
}

// =============================================================================
//  Nilestia-4 — Network Hub Base
//  Shared base for WiFi, Bluetooth, and Ethernet floating hub windows.
//  Uses a dark Material You palette. Each hub is a separate PanelWindow.
// =============================================================================
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.NetworkManager
import Quickshell.Bluetooth

// ══════════════════════════════════════════════════════════════════════════════
//  WiFi Hub
// ══════════════════════════════════════════════════════════════════════════════
Item {
    id: wifiRoot

    function toggle() { wifiWin.visible = !wifiWin.visible; }

    PanelWindow {
        id: wifiWin
        visible: false
        color: Qt.rgba(0.08, 0.08, 0.10, 0.93)

        contentItem: HubFrame {
            title: "WiFi"
            iconName: "network-wireless-symbolic"
            onClosed: wifiWin.visible = false

            contentComponent: Component {
                WifiContent {}
            }
        }
    }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Bluetooth Hub
// ══════════════════════════════════════════════════════════════════════════════
Item {
    id: btRoot

    function toggle() { btWin.visible = !btWin.visible; }

    PanelWindow {
        id: btWin
        visible: false
        color: Qt.rgba(0.08, 0.08, 0.10, 0.93)

        contentItem: HubFrame {
            title: "Bluetooth"
            iconName: "bluetooth-active-symbolic"
            onClosed: btWin.visible = false

            contentComponent: Component {
                BluetoothContent {}
            }
        }
    }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Ethernet Hub
// ══════════════════════════════════════════════════════════════════════════════
Item {
    id: ethernetRoot

    function toggle() { ethernetWin.visible = !ethernetWin.visible; }

    PanelWindow {
        id: ethernetWin
        visible: false
        color: Qt.rgba(0.08, 0.08, 0.10, 0.93)

        contentItem: HubFrame {
            title: "Wired Connection"
            iconName: "network-wired-symbolic"
            onClosed: ethernetWin.visible = false

            contentComponent: Component {
                EthernetContent {}
            }
        }
    }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Shared Hub Frame
// ══════════════════════════════════════════════════════════════════════════════
component HubFrame: Rectangle {
    id: frame

    required property string title
    required property string iconName
    required property Component contentComponent
    signal closed()

    color: "transparent"
    radius: 16

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Image {
                source: "image://icon/" + frame.iconName
                width: 24; height: 24
                fillMode: Image.PreserveAspectFit
            }
            Text {
                text: frame.title
                font.pixelSize: 22
                font.weight: Font.Medium
                color: "#E6E1E5"
            }
            Item { Layout.fillWidth: true }
            RoundButton {
                icon.name: "window-close-symbolic"
                flat: true
                onClicked: frame.closed()
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.08)
        }

        // Content
        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: frame.contentComponent
        }
    }
}

// ══════════════════════════════════════════════════════════════════════════════
//  WiFi Content
// ══════════════════════════════════════════════════════════════════════════════
component WifiContent: Item {
    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // Status row
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: NetworkManager.connectivity === NetworkManager.Full
                      ? "Connected" : "Disconnected"
                color: NetworkManager.connectivity === NetworkManager.Full
                       ? "#A8D5A2" : "#CF6679"
                font.pixelSize: 14
                font.weight: Font.Medium
            }

            Item { Layout.fillWidth: true }

            // WiFi toggle switch
            Switch {
                checked: NetworkManager.wirelessEnabled
                onToggled: NetworkManager.wirelessEnabled = checked

                indicator: Rectangle {
                    implicitWidth: 44
                    implicitHeight: 22
                    radius: 11
                    color: parent.checked ? "#7965AF" : "#49454F"

                    Rectangle {
                        x: parent.parent.checked ? parent.width - width - 2 : 2
                        y: 2
                        width: 18; height: 18
                        radius: 9
                        color: "#E6E1E5"
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                }

                contentItem: Item {}
            }
        }

        // Current connection
        Rectangle {
            Layout.fillWidth: true
            height: 56
            radius: 12
            color: Qt.rgba(0.44, 0.37, 0.80, 0.2)
            visible: NetworkManager.primaryConnection !== null

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Image {
                    source: "image://icon/network-wireless-signal-excellent-symbolic"
                    width: 20; height: 20
                }
                ColumnLayout {
                    spacing: 2
                    Text {
                        text: NetworkManager.primaryConnection?.id ?? "Unknown"
                        color: "#E6E1E5"
                        font.pixelSize: 14
                        font.weight: Font.Medium
                    }
                    Text {
                        text: "Connected"
                        color: "#A8D5A2"
                        font.pixelSize: 12
                    }
                }
            }
        }

        // Available networks
        Text {
            text: "Available Networks"
            color: "#CAC4D0"
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4

            model: NetworkManager.devices.filter(d =>
                d.deviceType === NetworkManagerDevice.Wifi &&
                d.accessPoints !== undefined
            ).flatMap(d => d.accessPoints)

            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height: 50
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.05)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Image {
                        property int sig: modelData?.strength ?? 0
                        source: "image://icon/" + (
                            sig > 75 ? "network-wireless-signal-excellent-symbolic" :
                            sig > 50 ? "network-wireless-signal-good-symbolic" :
                            sig > 25 ? "network-wireless-signal-ok-symbolic" :
                                       "network-wireless-signal-weak-symbolic"
                        )
                        width: 18; height: 18
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData?.ssid ?? "Hidden Network"
                        color: "#E6E1E5"
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }

                    Image {
                        visible: (modelData?.flags & 0x1) !== 0
                        source: "image://icon/changes-prevent-symbolic"
                        width: 14; height: 14
                        opacity: 0.6
                    }

                    Text {
                        text: modelData?.strength + "%"
                        color: "#CAC4D0"
                        font.pixelSize: 12
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // Trigger NM connection attempt
                        NetworkManager.activateConnection(
                            modelData.ssid, modelData.bssid
                        );
                    }
                }
            }
        }
    }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Bluetooth Content
// ══════════════════════════════════════════════════════════════════════════════
component BluetoothContent: Item {
    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // BT toggle
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: BluetoothManager.adapters.length > 0
                      ? (BluetoothManager.adapters[0]?.powered ? "Enabled" : "Disabled")
                      : "No Adapter"
                color: (BluetoothManager.adapters[0]?.powered ?? false) ? "#A8D5A2" : "#CAC4D0"
                font.pixelSize: 14
                font.weight: Font.Medium
            }

            Item { Layout.fillWidth: true }

            Switch {
                checked: BluetoothManager.adapters[0]?.powered ?? false
                enabled: BluetoothManager.adapters.length > 0
                onToggled: {
                    if (BluetoothManager.adapters.length > 0)
                        BluetoothManager.adapters[0].powered = checked;
                }

                indicator: Rectangle {
                    implicitWidth: 44
                    implicitHeight: 22
                    radius: 11
                    color: parent.checked ? "#7965AF" : "#49454F"

                    Rectangle {
                        x: parent.parent.checked ? parent.width - width - 2 : 2
                        y: 2
                        width: 18; height: 18
                        radius: 9
                        color: "#E6E1E5"
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                }

                contentItem: Item {}
            }
        }

        // Scan button
        Rectangle {
            Layout.fillWidth: true
            height: 40
            radius: 10
            color: Qt.rgba(0.44, 0.37, 0.80, 0.3)

            Text {
                anchors.centerIn: parent
                text: BluetoothManager.adapters[0]?.discovering ? "Scanning…" : "Scan for Devices"
                color: "#E6E1E5"
                font.pixelSize: 14
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (BluetoothManager.adapters.length > 0) {
                        if (BluetoothManager.adapters[0].discovering)
                            BluetoothManager.adapters[0].stopDiscovery();
                        else
                            BluetoothManager.adapters[0].startDiscovery();
                    }
                }
            }
        }

        // Paired / Available devices
        Text {
            text: "Devices"
            color: "#CAC4D0"
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4

            model: BluetoothManager.devices

            delegate: Rectangle {
                required property BluetoothDevice modelData
                width: ListView.view.width
                height: 56
                radius: 10
                color: modelData.connected ? Qt.rgba(0.44, 0.37, 0.80, 0.2)
                                          : Qt.rgba(1, 1, 1, 0.05)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Image {
                        source: "image://icon/bluetooth-symbolic"
                        width: 20; height: 20
                        opacity: modelData.connected ? 1 : 0.5
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: modelData.name || modelData.address
                            color: "#E6E1E5"
                            font.pixelSize: 14
                            font.weight: modelData.connected ? Font.Medium : Font.Normal
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.connected ? "Connected" :
                                  modelData.paired ? "Paired" : "Available"
                            color: modelData.connected ? "#A8D5A2" :
                                   modelData.paired ? "#CAC4D0" : "#7965AF"
                            font.pixelSize: 11
                        }
                    }

                    // Battery if available
                    Text {
                        visible: modelData.battery > 0
                        text: modelData.battery + "%"
                        color: "#CAC4D0"
                        font.pixelSize: 12
                    }

                    // Connect/Disconnect button
                    Rectangle {
                        width: 72; height: 30
                        radius: 8
                        color: modelData.connected ? Qt.rgba(0.81, 0.18, 0.35, 0.3)
                                                   : Qt.rgba(0.44, 0.37, 0.80, 0.3)

                        Text {
                            anchors.centerIn: parent
                            text: modelData.connected ? "Disconnect" : "Connect"
                            color: "#E6E1E5"
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (modelData.connected)
                                    modelData.disconnect();
                                else
                                    modelData.connect();
                            }
                        }
                    }
                }
            }
        }
    }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Ethernet Content
// ══════════════════════════════════════════════════════════════════════════════
component EthernetContent: Item {
    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Text {
            text: "Wired Connections"
            color: "#CAC4D0"
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6

            model: NetworkManager.devices.filter(d =>
                d.deviceType === NetworkManagerDevice.Ethernet)

            delegate: Rectangle {
                required property NetworkManagerDevice modelData
                width: ListView.view.width
                height: 70
                radius: 12
                color: modelData.state === NetworkManagerDevice.Activated
                       ? Qt.rgba(0.44, 0.37, 0.80, 0.2)
                       : Qt.rgba(1, 1, 1, 0.05)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    RowLayout {
                        spacing: 10

                        Image {
                            source: "image://icon/network-wired-symbolic"
                            width: 20; height: 20
                        }

                        Text {
                            text: modelData.interfaceName || "eth0"
                            color: "#E6E1E5"
                            font.pixelSize: 15
                            font.weight: Font.Medium
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: modelData.state === NetworkManagerDevice.Activated
                                  ? "Connected" : "Disconnected"
                            color: modelData.state === NetworkManagerDevice.Activated
                                   ? "#A8D5A2" : "#CAC4D0"
                            font.pixelSize: 12
                        }
                    }

                    Text {
                        text: modelData.ip4Config?.addresses[0]?.address ?? "No IP"
                        color: "#CAC4D0"
                        font.pixelSize: 12
                        leftPadding: 30
                    }
                }
            }
        }

        // Add connection button
        Rectangle {
            Layout.fillWidth: true
            height: 42
            radius: 10
            color: Qt.rgba(0.44, 0.37, 0.80, 0.25)

            Text {
                anchors.centerIn: parent
                text: "+ Configure New Connection"
                color: "#D0BCFF"
                font.pixelSize: 13
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Qt.openUrlExternally("nm-connection-editor")
            }
        }
    }
}

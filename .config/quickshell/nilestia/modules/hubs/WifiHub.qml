// WifiHub.qml — re-exports the WiFi hub from NetworkHubs
import "."
import QtQuick

// This file simply instantiates the WifiHub component from NetworkHubs.qml
// so shell.qml can do: WifiHub { id: wifiHub }
Item {
    id: root
    function toggle() { wifiHubInstance.toggle(); }

    WifiHub { id: wifiHubInstance }
}

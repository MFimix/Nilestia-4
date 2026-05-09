// =============================================================================
//  Nilestia-4 — Sidebar Override
//  Intercepts right-clicks on WiFi and Bluetooth icons in the end-4 sidebar
//  to open the respective Nilestia hubs.
//
//  How it works:
//    The end-4 sidebar fires quickshell IPC events on its button clicks.
//    We register companion MouseArea overlays via a global QML Connections
//    workaround since we can't modify ii directly.
//    In practice: we subclass the sidebar window from ii and add our handlers.
//
//  For a cleaner integration, this file provides a helper function
//  `NilestiaHubTrigger` that the top-level shell.qml uses, and also
//  documents the IPC call pattern for nilestia-hub.sh.
// =============================================================================

import QtQuick
import Quickshell

// ── Sidebar event interceptor ─────────────────────────────────────────────────
// Listens for sidebar "icon right-click" events sent by the patched end-4 ii
// sidebarLeft module, which we patch via shell-level IPC.
//
// The ii sidebar fires:
//   qs ipc call nilestia sidebarBtRightClick
//   qs ipc call nilestia sidebarWifiRightClick
//
// To enable this in the end-4 sidebar, the installer patches
// ~/.config/quickshell/ii/modules/sidebarLeft/*.qml
// to add right-click handlers that fire these IPC calls.

Item {
    IpcHandler {
        target: "sidebarBtRightClick"
        function onMessage(msg: string): void {
            // Close sidebar first, then open BT hub
            Quickshell.ipc("ii", "sidebarLeftClose");
            Qt.callLater(function() {
                Quickshell.ipc("nilestia", "nilestiaBluetoothToggle");
            });
        }
    }

    IpcHandler {
        target: "sidebarWifiRightClick"
        function onMessage(msg: string): void {
            Quickshell.ipc("ii", "sidebarLeftClose");
            Qt.callLater(function() {
                Quickshell.ipc("nilestia", "nilestiaWifiToggle");
            });
        }
    }
}

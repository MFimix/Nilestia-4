//@ pragma Env QS_CRASHREPORT_URL=https://github.com/you/nilestia-4/issues/new
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// =============================================================================
//  Nilestia-4 — QuickShell Entry Point
//
//  Architecture:
//    - Inherits all end-4 ii components (bar, sidebar, overview, etc.)
//    - Adds Nilestia-specific modules: AudioManager, Network/BT Hubs,
//      MonitorHub, TopMenu, and Caelestia lockscreen
//
//  Import isolation: end-4 components are imported via the `ii` profile
//  namespace; Nilestia components live in `modules/` here. No variable
//  name collisions because each module manages its own state.
// =============================================================================

import QtQuick
import Quickshell
import "modules/audio"
import "modules/hubs"
import "modules/lock"
import "modules/topmenu"
import "modules/monitor"
import "modules/sidebar"
import "services"

ShellRoot {
    settings.watchFiles: true

    // ── IPC Handlers ─────────────────────────────────────────────────────────
    // These receive signals from nilestia-hub.sh via `qs ipc call`
    IpcHandler {
        target: "nilestiaAudioToggle"
        function onMessage(message: string): void {
            audioManager.toggle();
        }
    }
    IpcHandler {
        target: "nilestiaWifiToggle"
        function onMessage(message: string): void {
            wifiHub.toggle();
        }
    }
    IpcHandler {
        target: "nilestiaBluetoothToggle"
        function onMessage(message: string): void {
            bluetoothHub.toggle();
        }
    }
    IpcHandler {
        target: "nilestiaEthernetToggle"
        function onMessage(message: string): void {
            ethernetHub.toggle();
        }
    }
    IpcHandler {
        target: "nilestiaMonitorToggle"
        function onMessage(message: string): void {
            monitorHub.toggle();
        }
    }

    // ── Nilestia Hub Windows ──────────────────────────────────────────────────
    AudioManagerHub {
        id: audioManager
    }

    WifiHub {
        id: wifiHub
    }

    BluetoothHub {
        id: bluetoothHub
    }

    EthernetHub {
        id: ethernetHub
    }

    MonitorHub {
        id: monitorHub
    }

    // ── Top Hot-Zone Menu ─────────────────────────────────────────────────────
    TopMenu {}

    // ── Caelestia Lockscreen ──────────────────────────────────────────────────
    NilestiaLock {
        id: lockScreen
    }
}

#!/usr/bin/env bash
# =============================================================================
#  nilestia-hub.sh — Hub Toggle Dispatcher
#  Called by Hyprland keybinds to toggle Nilestia floating hub windows.
#  Routes to the correct QuickShell IPC call based on argument.
#
#  Usage: nilestia-hub.sh <audio|wifi|bluetooth|ethernet|monitor>
# =============================================================================

QS_PROFILE="nilestia"
HUB="${1:-}"

if [[ -z "$HUB" ]]; then
    echo "Usage: nilestia-hub.sh <audio|wifi|bluetooth|ethernet|monitor>" >&2
    exit 1
fi

# Check if QuickShell (nilestia profile) is running
if ! qs -c "$QS_PROFILE" ipc call TEST_ALIVE &>/dev/null; then
    echo "QuickShell nilestia profile not running. Starting..." >&2
    qs -c "$QS_PROFILE" &
    sleep 0.8
fi

case "$HUB" in
    audio)
        qs -c "$QS_PROFILE" ipc call nilestiaAudioToggle
        ;;
    wifi)
        qs -c "$QS_PROFILE" ipc call nilestiaWifiToggle
        ;;
    bluetooth|bt)
        qs -c "$QS_PROFILE" ipc call nilestiaBluetoothToggle
        ;;
    ethernet|wired)
        qs -c "$QS_PROFILE" ipc call nilestiaEthernetToggle
        ;;
    monitor)
        qs -c "$QS_PROFILE" ipc call nilestiaMonitorToggle
        ;;
    *)
        echo "Unknown hub: $HUB" >&2
        exit 1
        ;;
esac

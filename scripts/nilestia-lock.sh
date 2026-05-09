#!/usr/bin/env bash
# =============================================================================
#  nilestia-lock.sh — Lockscreen Activation Script
#  Triggers the Caelestia-based lockscreen in the Nilestia QuickShell profile.
#  Called by:
#    - Hyprland keybind: Super + L
#    - hypridle timeout listener
#    - systemd nilestia-lock.service (before sleep)
#    - loginctl lock-session (via systemd-logind pam hook)
# =============================================================================

QS_PROFILE="nilestia"

# Export wallpaper path for the lockscreen background
export NILESTIA_WALLPAPER
NILESTIA_WALLPAPER="$(cat ~/.config/matugen/templates/wallpaper.txt 2>/dev/null || \
                      hyprctl hyprpaper listloaded 2>/dev/null | head -1 || \
                      echo "")"

# Ensure QuickShell is running
if ! qs -c "$QS_PROFILE" ipc call TEST_ALIVE &>/dev/null; then
    qs -c "$QS_PROFILE" &
    sleep 1.0
fi

# Trigger lock via IPC
qs -c "$QS_PROFILE" ipc call lockToggle

# Fallback: if QuickShell fails, use hyprlock
if [[ $? -ne 0 ]]; then
    echo "QuickShell lock failed, falling back to hyprlock..." >&2
    exec hyprlock
fi

#!/usr/bin/env bash
# =============================================================================
#  nilestia-patch-sidebar.sh — Patch end-4 ii Sidebar for Hub Right-Clicks
#
#  Adds right-click handlers to the end-4 ii sidebar's WiFi and Bluetooth
#  icon buttons so they send IPC events to the Nilestia QuickShell profile.
#  Called automatically by install.sh after end-4 base is deployed.
#
#  Strategy:
#    The end-4 ii sidebar uses QML MouseArea for button clicks.
#    We inject a `acceptedButtons: Qt.LeftButton | Qt.RightButton` change
#    and add `onClicked: if (mouse.button === Qt.RightButton) { ... }` blocks.
# =============================================================================

set -euo pipefail

QS_II="$HOME/.config/quickshell/ii"
SIDEBAR_DIR="$QS_II/modules/sidebarLeft"

# Ensure backup
cp -r "$SIDEBAR_DIR" "${SIDEBAR_DIR}.nilestia-bak" 2>/dev/null || true

echo "[nilestia] Scanning sidebar QML files for network/bt icon buttons..."

# Find the QML file containing the WiFi/Bluetooth toggle buttons in the sidebar
# In end-4/dots-hyprland the sidebar quick-settings are in:
#   modules/sidebarLeft/modules/QuickToggles.qml  (or similar)

patch_file() {
    local FILE="$1"
    local WIDGET="$2"
    local IPC_CALL="$3"

    if [[ ! -f "$FILE" ]]; then
        echo "[nilestia] Skipping (not found): $FILE"
        return
    fi

    # Check if already patched
    if grep -q "nilestia.*${IPC_CALL}" "$FILE"; then
        echo "[nilestia] Already patched: $FILE ($WIDGET)"
        return
    fi

    # Backup
    cp "$FILE" "${FILE}.nilestia-bak"

    # Pattern: find the MouseArea block for the widget and inject right-click
    # We look for a comment or property that identifies the WiFi/BT button
    # and add a right-click handler below the existing onClicked handler.
    python3 <<PYEOF
import re, sys

with open(r'$FILE', 'r') as f:
    content = f.read()

# Inject right-click handler after the WiFi/BT icon button's MouseArea.
# This is a heuristic patch; exact format depends on end-4 version.
patch_block = '''
                        // Nilestia-4: Right-click opens $WIDGET hub
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                Quickshell.ipc("nilestia", "$IPC_CALL");
                            }
                        }
'''

# Look for "$WIDGET" references and patch the closest MouseArea
# We search for a heuristic marker like "wifi" or "bluetooth" near a MouseArea
pattern = r'(MouseArea\s*\{[^}]*?(?:wifi|wireless|network)[^}]*?\})'
if re.search(pattern, content, re.IGNORECASE | re.DOTALL):
    # Already has the structure — add right-click
    new_content = re.sub(
        r'(onClicked:\s*\{[^}]*?\})',
        r'\1\n' + patch_block.strip(),
        content,
        count=1,
        flags=re.DOTALL
    )
    with open(r'$FILE', 'w') as f:
        f.write(new_content)
    print("[nilestia] Patched: $FILE")
else:
    print("[nilestia] Pattern not found in: $FILE — manual patch may be needed")
PYEOF
}

# Patch WiFi icon
for f in "$SIDEBAR_DIR"/*.qml "$SIDEBAR_DIR"/**/*.qml 2>/dev/null; do
    if grep -qi "wifi\|wireless\|network" "$f" 2>/dev/null; then
        patch_file "$f" "WiFi" "sidebarWifiRightClick"
    fi
    if grep -qi "bluetooth\|bluez" "$f" 2>/dev/null; then
        patch_file "$f" "Bluetooth" "sidebarBtRightClick"
    fi
done

echo "[nilestia] Sidebar patch complete. Restart QuickShell to apply."

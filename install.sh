#!/usr/bin/env bash
# =============================================================================
#  Nilestia-4 Installer
#  A unified dotfile suite: end-4 dots-hyprland + Caelestia Shell components
#  Targets: Arch Linux / CachyOS
# =============================================================================

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.nilestia-4-backup-$(date +%Y%m%d_%H%M%S)"
CONFIG="$HOME/.config"

# ── Helpers ───────────────────────────────────────────────────────────────────
log()    { echo -e "${CYAN}${BOLD}[NILESTIA]${NC} $*"; }
ok()     { echo -e "${GREEN}${BOLD}  ✓${NC} $*"; }
warn()   { echo -e "${YELLOW}${BOLD}  ⚠${NC} $*"; }
err()    { echo -e "${RED}${BOLD}  ✗${NC} $*"; }
header() { echo -e "\n${MAGENTA}${BOLD}━━━ $* ━━━${NC}"; }

confirm() {
    local prompt="${1:-Continue?}"
    read -rp "$(echo -e "${YELLOW}${BOLD}  ?${NC} ${prompt} [y/N] ")" yn
    [[ "${yn,,}" == "y" ]]
}

need_cmd() {
    if ! command -v "$1" &>/dev/null; then
        err "Required command not found: $1"
        return 1
    fi
}

# ── Banner ────────────────────────────────────────────────────────────────────
print_banner() {
    echo -e "${MAGENTA}${BOLD}"
    cat <<'EOF'
  ███╗   ██╗██╗██╗     ███████╗███████╗████████╗██╗ █████╗       ██╗  ██╗
  ████╗  ██║██║██║     ██╔════╝██╔════╝╚══██╔══╝██║██╔══██╗      ██║  ██║
  ██╔██╗ ██║██║██║     █████╗  ███████╗   ██║   ██║███████║█████╗███████║
  ██║╚██╗██║██║██║     ██╔══╝  ╚════██║   ██║   ██║██╔══██║╚════╝╚════██║
  ██║ ╚████║██║███████╗███████╗███████║   ██║   ██║██║  ██║           ██║
  ╚═╝  ╚═══╝╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝   ╚═╝╚═╝  ╚═╝           ╚═╝
EOF
    echo -e "${NC}"
    echo -e "  ${CYAN}Unified Hyprland • end-4 foundation + Caelestia widgets${NC}"
    echo -e "  ${CYAN}Repository: https://github.com/you/nilestia-4${NC}\n"
}

# ── Distro detection ──────────────────────────────────────────────────────────
detect_distro() {
    header "Detecting Distribution"
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_NAME="${NAME:-Unknown}"
        DISTRO_LIKE="${ID_LIKE:-}"
    else
        DISTRO_ID="unknown"
        DISTRO_NAME="Unknown"
        DISTRO_LIKE=""
    fi

    log "Detected: ${BOLD}${DISTRO_NAME}${NC}"

    case "$DISTRO_ID" in
        arch|cachyos|endeavouros|garuda|artix)
            ok "Arch-based distro confirmed"
            PKG_MGR="pacman"
            AUR_MGR=""
            # Detect AUR helper
            for aur in paru yay trizen aurman; do
                if command -v "$aur" &>/dev/null; then
                    AUR_MGR="$aur"
                    ok "AUR helper: ${aur}"
                    break
                fi
            done
            if [[ -z "$AUR_MGR" ]]; then
                warn "No AUR helper found. Will attempt to install paru."
                INSTALL_PARU=true
            fi
            ;;
        *)
            if echo "$DISTRO_LIKE" | grep -q "arch"; then
                warn "Arch-like distro (${DISTRO_NAME}). Proceeding with pacman."
                PKG_MGR="pacman"
                AUR_MGR="yay"
            else
                err "Unsupported distribution: ${DISTRO_NAME}"
                err "Nilestia-4 targets Arch Linux and derivatives."
                exit 1
            fi
            ;;
    esac
}

# ── Dependency check ──────────────────────────────────────────────────────────
CORE_DEPS=(
    "hyprland"
    "quickshell"
    "hyprlock"
    "hypridle"
    "hyprpaper"
    "hyprpicker"
    "waybar"
    "networkmanager"
    "bluez"
    "bluez-utils"
    "wireplumber"
    "pipewire"
    "pipewire-alsa"
    "pipewire-pulse"
    "brightnessctl"
    "playerctl"
    "grim"
    "slurp"
    "wl-clipboard"
    "cliphist"
    "wlogout"
    "fuzzel"
    "foot"
    "matugen"
    "qt6-base"
    "qt6-declarative"
    "qt6-wayland"
    "qt6-svg"
    "qt6-multimedia"
    "noto-fonts"
    "ttf-material-symbols-variable-git"
    "ttf-jetbrains-mono-nerd"
)

AUR_DEPS=(
    "quickshell-git"
    "matugen-bin"
    "cliphist"
    "wlogout"
    "hyprshot"
    "ttf-material-symbols-variable-git"
)

check_deps() {
    header "Checking Dependencies"
    local missing_pacman=()
    local missing_aur=()

    # Check pacman packages
    for pkg in "${CORE_DEPS[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            missing_pacman+=("$pkg")
        else
            ok "$pkg"
        fi
    done

    if [[ ${#missing_pacman[@]} -gt 0 ]]; then
        warn "Missing packages: ${missing_pacman[*]}"
        if confirm "Install missing packages now?"; then
            install_deps "${missing_pacman[@]}"
        fi
    else
        ok "All core dependencies satisfied"
    fi
}

install_deps() {
    local pkgs=("$@")
    header "Installing Dependencies"

    # System packages via pacman
    log "Installing via pacman..."
    sudo pacman -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null || {
        warn "Some pacman packages failed, trying AUR helper..."
    }

    # AUR packages
    if [[ -n "$AUR_MGR" ]]; then
        log "Installing AUR packages via ${AUR_MGR}..."
        $AUR_MGR -S --needed --noconfirm "${AUR_DEPS[@]}" 2>/dev/null || {
            warn "Some AUR packages failed to install. Check manually."
        }
    fi

    # Enable services
    log "Enabling system services..."
    sudo systemctl enable --now NetworkManager.service 2>/dev/null && ok "NetworkManager enabled"
    sudo systemctl enable --now bluetooth.service 2>/dev/null && ok "Bluetooth service enabled"
    systemctl --user enable --now wireplumber.service 2>/dev/null && ok "WirePlumber enabled"
    systemctl --user enable --now pipewire.service 2>/dev/null && ok "PipeWire enabled"
    systemctl --user enable --now pipewire-pulse.service 2>/dev/null && ok "PipeWire-Pulse enabled"
}

install_paru() {
    header "Installing paru (AUR helper)"
    need_cmd git
    need_cmd makepkg

    local tmp
    tmp="$(mktemp -d)"
    git clone https://aur.archlinux.org/paru-bin.git "$tmp/paru"
    (cd "$tmp/paru" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    AUR_MGR="paru"
    ok "paru installed"
}

# ── Backup existing configs ───────────────────────────────────────────────────
backup_configs() {
    header "Backing Up Existing Configuration"
    mkdir -p "$BACKUP_DIR"

    local dirs_to_backup=(
        "$CONFIG/hypr"
        "$CONFIG/quickshell"
        "$CONFIG/nilestia-4"
    )

    for dir in "${dirs_to_backup[@]}"; do
        if [[ -d "$dir" || -L "$dir" ]]; then
            local name
            name="$(basename "$dir")"
            cp -r "$dir" "$BACKUP_DIR/$name" 2>/dev/null && \
                ok "Backed up: $dir → $BACKUP_DIR/$name"
        fi
    done

    ok "Backup complete → ${BOLD}${BACKUP_DIR}${NC}"
}

# ── Install end-4 dots-hyprland (base) ───────────────────────────────────────
install_end4_base() {
    header "Installing end-4 dots-hyprland (Base)"

    local tmp
    tmp="$(mktemp -d)"
    log "Cloning end-4/dots-hyprland..."
    git clone --depth=1 https://github.com/end-4/dots-hyprland.git "$tmp/dots-hyprland"

    log "Running end-4 installer (non-interactive copy)..."
    # Copy the dots subtree
    cp -r "$tmp/dots-hyprland/dots/." "$HOME/"
    ok "end-4 base configs deployed"

    # Copy quickshell config (ii profile)
    if [[ -d "$tmp/dots-hyprland/dots/.config/quickshell" ]]; then
        mkdir -p "$CONFIG/quickshell"
        cp -r "$tmp/dots-hyprland/dots/.config/quickshell/." "$CONFIG/quickshell/"
        ok "QuickShell ii profile deployed"
    fi

    rm -rf "$tmp"
}

# ── Deploy Nilestia-4 overlay ─────────────────────────────────────────────────
deploy_nilestia() {
    header "Deploying Nilestia-4 Overlay"

    local NILESTIA_TARGET="$CONFIG/nilestia-4"
    mkdir -p "$NILESTIA_TARGET"

    # Symlink/copy nilestia quickshell profile
    log "Deploying QuickShell nilestia profile..."
    mkdir -p "$CONFIG/quickshell"
    if [[ -L "$CONFIG/quickshell/nilestia" ]]; then
        rm "$CONFIG/quickshell/nilestia"
    fi
    ln -sf "$REPO_DIR/.config/quickshell/nilestia" "$CONFIG/quickshell/nilestia"
    ok "QuickShell nilestia → $CONFIG/quickshell/nilestia"

    # Deploy hypr nilestia overrides
    log "Deploying Hyprland nilestia overrides..."
    mkdir -p "$CONFIG/hypr/nilestia"
    cp -r "$REPO_DIR/.config/hypr/nilestia/." "$CONFIG/hypr/nilestia/"
    ok "Hyprland overrides → $CONFIG/hypr/nilestia/"

    # Deploy scripts
    log "Deploying scripts..."
    mkdir -p "$HOME/.local/bin"
    cp "$REPO_DIR/scripts/"*.sh "$HOME/.local/bin/" 2>/dev/null || true
    chmod +x "$HOME/.local/bin/"nilestia-*.sh 2>/dev/null || true
    ok "Scripts deployed to ~/.local/bin/"

    # Deploy assets
    log "Deploying assets..."
    mkdir -p "$NILESTIA_TARGET/assets"
    cp -r "$REPO_DIR/assets/." "$NILESTIA_TARGET/assets/" 2>/dev/null || true
    ok "Assets deployed"
}

# ── Patch end-4 hyprland.conf to source nilestia overrides ───────────────────
patch_hyprland_conf() {
    header "Patching Hyprland Config"

    local HYPR_CONF="$CONFIG/hypr/hyprland.conf"

    if [[ ! -f "$HYPR_CONF" ]]; then
        warn "hyprland.conf not found at $HYPR_CONF, creating minimal one"
        cat > "$HYPR_CONF" <<'HYPREOF'
# Hyprland config - generated by Nilestia-4 installer
source = ~/.config/hypr/hyprland/general.conf
source = ~/.config/hypr/hyprland/env.conf
source = ~/.config/hypr/hyprland/keybinds.conf
source = ~/.config/hypr/hyprland/rules.conf
source = ~/.config/hypr/hyprland/execs.conf
HYPREOF
    fi

    # Append nilestia source if not already present
    local NILESTIA_SOURCE="source = ~/.config/hypr/nilestia/nilestia.conf"
    if ! grep -qF "nilestia/nilestia.conf" "$HYPR_CONF"; then
        echo "" >> "$HYPR_CONF"
        echo "# ── Nilestia-4 Overlay ──────────────────────────────────────────" >> "$HYPR_CONF"
        echo "$NILESTIA_SOURCE" >> "$HYPR_CONF"
        ok "Added Nilestia-4 source to hyprland.conf"
    else
        ok "Nilestia-4 source already present in hyprland.conf"
    fi

    # Patch the quickshell config variable so 'qs' uses nilestia profile
    local QS_OVERRIDE="$CONFIG/hypr/hyprland/env.conf"
    if [[ -f "$QS_OVERRIDE" ]]; then
        if ! grep -q "qsConfig.*nilestia" "$QS_OVERRIDE"; then
            # Backup and patch
            cp "$QS_OVERRIDE" "${QS_OVERRIDE}.nilestia-bak"
            sed -i 's/env = qsConfig,ii/env = qsConfig,nilestia/' "$QS_OVERRIDE" || true
            ok "QuickShell profile switched to 'nilestia' in env.conf"
        fi
    fi
}

# ── Setup systemd logind hook for lockscreen ──────────────────────────────────
setup_lockscreen_hook() {
    header "Configuring Lockscreen (systemd-logind)"

    local HYPRIDLE_CONF="$CONFIG/hypr/hypridle.conf"

    # Write a nilestia-specific hypridle config
    cat > "$CONFIG/hypr/hypridle.conf" <<'IDLE'
# Nilestia-4 hypridle config
# Uses nilestia lockscreen script

general {
    lock_cmd      = $HOME/.local/bin/nilestia-lock.sh
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd  = hyprctl dispatch dpms on
    ignore_dbus_inhibit = false
}

listener {
    timeout  = 150
    on-timeout = brightnessctl -s && brightnessctl set 10
    on-resume  = brightnessctl -r
}

listener {
    timeout  = 300
    on-timeout = $HOME/.local/bin/nilestia-lock.sh
}

listener {
    timeout  = 380
    on-timeout = hyprctl dispatch dpms off
    on-resume  = hyprctl dispatch dpms on
}

listener {
    timeout  = 600
    on-timeout = systemctl suspend
}
IDLE
    ok "hypridle.conf written"

    # systemd user service for lock-on-sleep
    mkdir -p "$HOME/.config/systemd/user"
    cat > "$HOME/.config/systemd/user/nilestia-lock.service" <<'SVC'
[Unit]
Description=Nilestia-4 Lock Screen on Sleep
Before=sleep.target

[Service]
Type=forking
Environment=DISPLAY=:0
ExecStart=%h/.local/bin/nilestia-lock.sh
TimeoutSec=infinity

[Install]
WantedBy=sleep.target
SVC

    systemctl --user daemon-reload
    systemctl --user enable nilestia-lock.service 2>/dev/null && \
        ok "nilestia-lock.service enabled for sleep hook"

    # loginctl lock-session hook via pam-rundir or logind
    local LOGIND_OVERRIDE="/etc/systemd/logind.conf.d/nilestia.conf"
    if confirm "Write /etc/systemd/logind.conf.d/nilestia.conf (requires sudo)?"; then
        sudo mkdir -p /etc/systemd/logind.conf.d/
        sudo tee "$LOGIND_OVERRIDE" > /dev/null <<'LOGIND'
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=ignore
HandleSuspendKey=suspend
IdleAction=lock
IdleActionSec=10min
LOGIND
        sudo systemctl restart systemd-logind 2>/dev/null || true
        ok "logind.conf override written"
    fi
}

# ── Font & theme setup ────────────────────────────────────────────────────────
setup_theme() {
    header "Setting Up Dark Theme & Fonts"

    # Generate initial Material You colors from a default wallpaper
    local DEFAULT_WALL="$HOME/Pictures/Wallpapers"
    mkdir -p "$DEFAULT_WALL"

    if command -v matugen &>/dev/null; then
        # Copy the default wallpaper asset if present
        if [[ -f "$REPO_DIR/assets/wallpapers/default.jpg" ]]; then
            cp "$REPO_DIR/assets/wallpapers/default.jpg" "$DEFAULT_WALL/"
            log "Generating Material You palette from default wallpaper..."
            matugen image "$DEFAULT_WALL/default.jpg" --mode dark 2>/dev/null && \
                ok "Material You palette generated (dark mode)" || \
                warn "matugen failed - run manually: matugen image <wallpaper> --mode dark"
        else
            warn "No default wallpaper in assets/wallpapers/default.jpg"
            warn "Run: matugen image <your-wallpaper> --mode dark"
        fi
    else
        warn "matugen not found. Install it and run: matugen image <wallpaper> --mode dark"
    fi

    # GTK dark theme
    mkdir -p "$CONFIG/gtk-3.0" "$CONFIG/gtk-4.0"
    for ver in 3.0 4.0; do
        grep -q "gtk-application-prefer-dark-theme" "$CONFIG/gtk-${ver}/settings.ini" 2>/dev/null || \
        cat >> "$CONFIG/gtk-${ver}/settings.ini" <<GTKINI
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=adw-gtk3-dark
GTKINI
    done
    ok "GTK dark theme configured"

    # XDG color scheme
    mkdir -p "$CONFIG"
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
    ok "XDG color scheme → prefer-dark"
}

# ── Final instructions ────────────────────────────────────────────────────────
print_summary() {
    header "Installation Complete"
    echo ""
    echo -e "${BOLD}Nilestia-4 has been deployed. Here's what changed:${NC}"
    echo ""
    echo -e "  ${GREEN}✓${NC} end-4 dots-hyprland base → ${CYAN}~/.config/hypr/${NC}"
    echo -e "  ${GREEN}✓${NC} Nilestia QuickShell profile → ${CYAN}~/.config/quickshell/nilestia/${NC}"
    echo -e "  ${GREEN}✓${NC} Nilestia override keybinds → ${CYAN}~/.config/hypr/nilestia/${NC}"
    echo -e "  ${GREEN}✓${NC} Lockscreen scripts → ${CYAN}~/.local/bin/nilestia-lock.sh${NC}"
    echo -e "  ${GREEN}✓${NC} hypridle configured for nilestia lockscreen"
    echo -e "  ${GREEN}✓${NC} Backup saved → ${CYAN}${BACKUP_DIR}${NC}"
    echo ""
    echo -e "${BOLD}Key Keybindings:${NC}"
    printf "  %-30s %s\n" "Super + A"            "Audio Manager"
    printf "  %-30s %s\n" "Super + Alt + B"       "Bluetooth Hub"
    printf "  %-30s %s\n" "Super + Alt + W"       "WiFi Hub"
    printf "  %-30s %s\n" "Super + Alt + C"       "Wired Connection Hub"
    printf "  %-30s %s\n" "Super + Ctrl + M"      "Monitor Hub"
    printf "  %-30s %s\n" "Mouse to top edge"     "Top Menu (hot zone)"
    printf "  %-30s %s\n" "Super + L"             "Lock Screen (Caelestia)"
    echo ""
    echo -e "${BOLD}Next Steps:${NC}"
    echo -e "  1. ${CYAN}Log out${NC} and select ${BOLD}Hyprland${NC} from your display manager"
    echo -e "  2. Run ${CYAN}matugen image <wallpaper> --mode dark${NC} to theme the shell"
    echo -e "  3. Configure your displays with ${CYAN}Super + Ctrl + M${NC}"
    echo ""
    echo -e "${MAGENTA}${BOLD}Welcome to Nilestia-4.${NC}"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    print_banner

    echo -e "${BOLD}This installer will:${NC}"
    echo "  1. Detect your Arch-based distribution"
    echo "  2. Check and install dependencies"
    echo "  3. Backup existing Hyprland/QuickShell configs"
    echo "  4. Deploy end-4 dots-hyprland as the base"
    echo "  5. Overlay Nilestia-4 modules (Audio, Hubs, Lock, TopMenu, Monitor)"
    echo "  6. Configure the lockscreen systemd hook"
    echo "  7. Set up dark Material You theming"
    echo ""
    confirm "Proceed with Nilestia-4 installation?" || { echo "Aborted."; exit 0; }

    detect_distro

    # Install paru if no AUR helper
    if [[ "${INSTALL_PARU:-false}" == "true" ]]; then
        install_paru
    fi

    check_deps
    backup_configs
    install_end4_base
    deploy_nilestia
    patch_hyprland_conf
    setup_lockscreen_hook
    setup_theme
    print_summary
}

main "$@"

#!/bin/bash
# ============================================================
#  Spotify Multi-Account Installer — Ubuntu / Linux
#  Creates 5 sandboxed Spotify instances via Firejail
#  Each account gets its own isolated home directory and
#  a dedicated launcher in your application drawer.
# ============================================================

set -e

# ── Config ────────────────────────────────────────────────────
NUM_ACCOUNTS=5
ACCENT="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

print_header() {
    echo -e "${ACCENT}"
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║   Spotify Multi-Account Installer    ║"
    echo "  ║   Ubuntu / Linux  —  5 Accounts      ║"
    echo "  ╚══════════════════════════════════════╝"
    echo -e "${RESET}"
}

step() { echo -e "${ACCENT}[$1/$2]${RESET} $3"; }
ok()   { echo -e "       ${GREEN}✓${RESET} $1"; }
warn() { echo -e "       ${YELLOW}⚠${RESET}  $1"; }
fail() { echo -e "${RED}✗ Error:${RESET} $1"; exit 1; }

# ── Preflight ─────────────────────────────────────────────────
print_header

if [ "$EUID" -eq 0 ]; then
    fail "Do not run this script as root. It will use sudo when needed."
fi

# ── Step 1: Ensure Spotify is installed ───────────────────────
step 1 3 "Checking for Spotify..."

if command -v spotify &>/dev/null; then
    ok "Spotify already installed ($(command -v spotify))"
elif snap list spotify &>/dev/null 2>&1; then
    ok "Spotify snap already installed"
else
    warn "Spotify not found — installing via Snap..."
    sudo snap install spotify
    ok "Spotify installed"
fi

# ── Step 2: Ensure Firejail is installed ──────────────────────
step 2 3 "Checking for Firejail..."

if command -v firejail &>/dev/null; then
    ok "Firejail already installed ($(firejail --version 2>&1 | head -1))"
else
    warn "Firejail not found — installing..."
    sudo apt-get update -qq
    sudo apt-get install -y firejail
    ok "Firejail installed"
fi

# ── Step 3: Create sandboxed accounts ─────────────────────────
step 3 3 "Creating $NUM_ACCOUNTS sandboxed Spotify accounts..."

mkdir -p "$HOME/.local/share/applications"

for i in $(seq 1 $NUM_ACCOUNTS); do
    ACCOUNT_DIR="$HOME/.spotify-account$i"

    # Create isolated home directory
    mkdir -p "$ACCOUNT_DIR"

    # Write .desktop launcher
    DESKTOP_FILE="$HOME/.local/share/applications/spotify-account$i.desktop"
    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Name=Spotify Account $i
Comment=Sandboxed Spotify instance — Account $i
Exec=firejail --private=$ACCOUNT_DIR spotify %U
Icon=spotify
Terminal=false
Type=Application
Categories=Audio;Music;Player;
StartupNotify=true
StartupWMClass=spotify
EOF

    chmod +x "$DESKTOP_FILE"
    ok "Account $i  →  $ACCOUNT_DIR"
done

# Refresh the application menu
update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true

# ── Done ──────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║  ✅  Setup complete!                                  ║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo "  $NUM_ACCOUNTS launchers added to your application drawer:"
for i in $(seq 1 $NUM_ACCOUNTS); do
    echo "   • Spotify Account $i"
done
echo ""
echo "  On first launch, each will show the Spotify login screen."
echo "  Sign in with a different account in each — credentials are"
echo "  saved per-sandbox and persist across reboots."
echo ""
echo "  Account data directories:"
for i in $(seq 1 $NUM_ACCOUNTS); do
    echo "   • $HOME/.spotify-account$i"
done
echo ""

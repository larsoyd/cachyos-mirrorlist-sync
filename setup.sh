#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root, for example:" >&2
    echo "  sudo ./setup.sh" >&2
    exit 1
fi

REPO_DIR="$(cd -- "$(dirname "$0")" && pwd)"
SCRIPT_SRC="$REPO_DIR/cachyos-mirrorlist-sync/cachyos-mirrorlist-sync.sh"
SYSTEM_DIR="$REPO_DIR/cachyos-mirrorlist-sync/system"

SERVICE_SRC="$SYSTEM_DIR/cachyos-mirrorlist-sync.service"
TIMER_SRC="$SYSTEM_DIR/cachyos-mirrorlist-sync.timer"

SCRIPT_DEST="/usr/local/sbin/cachyos-mirrorlist-sync"
SERVICE_DEST="/etc/systemd/system/cachyos-mirrorlist-sync.service"
TIMER_DEST="/etc/systemd/system/cachyos-mirrorlist-sync.timer"

# checks
if [[ ! -f "$SCRIPT_SRC" ]]; then
    echo "setup: could not find script at $SCRIPT_SRC" >&2
    exit 1
fi

if [[ ! -f "$SERVICE_SRC" ]]; then
    echo "setup: could not find service unit at $SERVICE_SRC" >&2
    exit 1
fi

if [[ ! -f "$TIMER_SRC" ]]; then
    echo "setup: could not find timer unit at $TIMER_SRC" >&2
    exit 1
fi

echo "Installing cachyos-mirrorlist-sync script to $SCRIPT_DEST"
install -Dm755 "$SCRIPT_SRC" "$SCRIPT_DEST"

echo "Installing systemd service to $SERVICE_DEST"
install -Dm644 "$SERVICE_SRC" "$SERVICE_DEST"

echo "Installing systemd timer to $TIMER_DEST"
install -Dm644 "$TIMER_SRC" "$TIMER_DEST"

echo "Reloading systemd units"
systemctl daemon-reload

echo "Running cachyos-mirrorlist-sync once for initial update"
if ! "$SCRIPT_DEST"; then
    echo
    echo "setup: initial cachyos-mirrorlist-sync run failed."
    echo "Check the error above, fix it, then run:"
    echo "  sudo $SCRIPT_DEST"
    exit 1
fi

echo
echo "cachyos-mirrorlist-sync is installed."
echo
echo "Run manually any time with:"
echo "  sudo cachyos-mirrorlist-sync"
echo
echo "To enable automatic daily updates, run:"
echo "  sudo systemctl enable --now cachyos-mirrorlist-sync.timer"
echo
echo "To disable the timer later, run:"
echo "  sudo systemctl disable --now cachyos-mirrorlist-sync.timer"

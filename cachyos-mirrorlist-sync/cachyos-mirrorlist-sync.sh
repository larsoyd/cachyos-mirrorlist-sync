#!/bin/bash
set -euo pipefail

REMOTE_URL="https://raw.githubusercontent.com/CachyOS/CachyOS-PKGBUILDS/master/cachyos-mirrorlist/cachyos-mirrorlist"
DEST_DIR="/etc/pacman.d"

BASE_FILE="$DEST_DIR/cachyos-mirrorlist"
V3_FILE="$DEST_DIR/cachyos-v3-mirrorlist"
V4_FILE="$DEST_DIR/cachyos-v4-mirrorlist"

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root, for example:"
    echo "  sudo cachyos-mirrorlist-sync"
    exit 1
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

NEW_BASE="$TMPDIR/cachyos-mirrorlist.new"

curl -fsSL "$REMOTE_URL" > "$NEW_BASE"

if ! grep -q 'Server' "$NEW_BASE"; then
    echo "cachyos-mirrorlist-sync: downloaded mirrorlist looks wrong, aborting" >&2
    exit 1
fi

update_needed=false

if [[ ! -f "$BASE_FILE" ]] || ! cmp -s "$NEW_BASE" "$BASE_FILE"; then
    update_needed=true
fi

for f in "$V3_FILE" "$V4_FILE"; do
    if [[ ! -f "$f" ]]; then
        update_needed=true
    fi
done

if [[ "$update_needed" == false ]]; then
    exit 0
fi

echo "cachyos-mirrorlist-sync: updating CachyOS mirrorlists"

install -Dm644 "$NEW_BASE" "$BASE_FILE"

# v3
sed 's|/$arch/|/$arch_v3/|g' "$NEW_BASE" | install -Dm644 /dev/stdin "$V3_FILE"

# v4
sed 's|/$arch/|/$arch_v4/|g' "$NEW_BASE" | install -Dm644 /dev/stdin "$V4_FILE"

echo "cachyos-mirrorlist-sync: updated:"
echo "  $BASE_FILE"
echo "  $V3_FILE"
echo "  $V4_FILE"

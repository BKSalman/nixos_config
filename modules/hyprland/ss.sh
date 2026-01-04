#!/usr/bin/env bash

SOCKET="/tmp/quickshell-screenshot.sock"

if [ ! -S "$SOCKET" ]; then
    echo "Screenshot" "QuickShell not running"
    exit 1
fi

coproc QS { socat - UNIX-CONNECT:"$SOCKET"; }

# Send command
printf "screenshot\n" >&"${QS[1]}"

# Read exactly one line
IFS= read -r GEOMETRY <&"${QS[0]}"

# Close
exec {QS[0]}>&-
exec {QS[1]}>&-

if [ -z "$GEOMETRY" ]; then
    echo "Screenshot" "Cancelled"
    exit 0
fi

mkdir -p ~/Pictures/Screenshots
FILENAME=~/Pictures/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png

grim -g "$GEOMETRY" "$FILENAME"
grim -g "$GEOMETRY" - | wl-copy

echo "Screenshot saved" "$FILENAME" -i "$FILENAME"

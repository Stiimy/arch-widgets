#!/usr/bin/env bash
# Sylph Widget Launcher — toggle open/close
WIDGET_DIR="$(dirname "$(realpath "$0")")"
WIDGET_NAME="$(basename "$WIDGET_DIR")"
PID_FILE="/tmp/quickshell-${WIDGET_NAME}.pid"

if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID" 2>/dev/null
        rm -f "$PID_FILE"
        exit 0
    fi
    rm -f "$PID_FILE"
fi

mkdir -p ~/.cache/quickshell ~/.local/state/quickshell
quickshell --path "$WIDGET_DIR" > /dev/null 2>&1 &
echo $! > "$PID_FILE"

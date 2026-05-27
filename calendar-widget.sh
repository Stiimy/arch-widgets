#!/usr/bin/env bash
PID_FILE="/tmp/quickshell-calendar-widget.pid"
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID" 2>/dev/null
        rm -f "$PID_FILE"
        exit 0
    fi
    rm -f "$PID_FILE"
fi
quickshell --path ~/.config/quickshell/calendar-widget > /dev/null 2>&1 &
echo $! > "$PID_FILE"

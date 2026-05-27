#!/bin/bash
PID_FILE="/tmp/quickshell-settings-widget.pid"
[ -f "$PID_FILE" ] && kill $(cat "$PID_FILE") 2>/dev/null && rm -f "$PID_FILE" && exit 0
quickshell --path ~/.config/quickshell/settings-widget > /dev/null 2>&1 & echo $! > "$PID_FILE"

#!/bin/bash
# Always launch fresh (no toggle - simpler)
pkill -f "quickshell.*music-widget" 2>/dev/null
sleep 0.3
quickshell --path ~/.config/quickshell/music-widget > /dev/null 2>&1 &
echo $! > /tmp/quickshell-music-widget.pid

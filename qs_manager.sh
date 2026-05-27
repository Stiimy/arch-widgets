#!/bin/bash
case "$2" in
    network|wifi|bt)  exec ~/.config/hypr/scripts/network-widget.sh ;;
    battery)          exec ~/.config/hypr/scripts/battery-widget.sh ;;
    calendar)         exec ~/.config/hypr/scripts/calendar-widget.sh ;;
    music)            exec ~/.config/hypr/scripts/music-widget.sh ;;
    settings)         exec ~/.config/hypr/scripts/settings-widget.sh ;;
    applauncher|search|app) pkill -x rofi 2>/dev/null; exec ~/.local/lib/hyde/rofilaunch.sh d ;;
    guide)            pkill -x rofi 2>/dev/null; exec ~/.local/lib/hyde/keybinds_hint.sh c ;;
    wallpaper)        exec ~/.local/lib/hyde/wallpaper.sh -n 2>/dev/null ;;
    *) ;;
esac

#!/usr/bin/env bash

# --- CONFIGURATION ---
STRICT_SPAM_FILTER=false
# ---------------------

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$HOME/.config/hypr/scripts/caching.sh"
qs_ensure_cache "network"

CACHE_DIR="$QS_CACHE_NETWORK"
PID_FILE="$QS_RUN_DIR/bt_scan_pid"

# Wrapper for non-interactive bluetoothctl (needs pseudo-TTY, strips CR/ANSI)
_btctl() {
    script -q -c "bluetoothctl $*" /dev/null 2>/dev/null | tr -d '\r' | sed 's/\x1b\[[0-9;]*m//g'
}

# bluetoothctl with timeout
_btctl_timeout() {
    local t=$1; shift
    script -q -c "timeout $t bluetoothctl $*" /dev/null 2>/dev/null | tr -d '\r' | sed 's/\x1b\[[0-9;]*m//g'
}

get_icon() {
    local type="${1,,}"
    local name="${2,,}"
    if [[ "$type" == *"headset"* || "$type" == *"headphone"* || "$name" == *"headphone"* || "$name" == *"buds"* || "$name" == *"pods"* ]]; then echo "🎧"
    elif [[ "$type" == *"audio"* || "$type" == *"speaker"* || "$type" == *"card"* || "$name" == *"speaker"* ]]; then echo "蓼"
    elif [[ "$type" == *"phone"* || "$name" == *"phone"* || "$name" == *"iphone"* || "$name" == *"android"* ]]; then echo ""
    elif [[ "$type" == *"mouse"* || "$name" == *"mouse"* ]]; then echo ""
    elif [[ "$type" == *"keyboard"* || "$name" == *"keyboard"* ]]; then echo ""
    elif [[ "$type" == *"controller"* || "$name" == *"controller"* ]]; then echo ""
    else echo ""
    fi
}

get_audio_profile() {
    local mac="$1"
    local cards_data="$2"
    local mac_us="${mac//:/_}"
    
    local active=$(echo "$cards_data" | awk -v mac="$mac_us" '
        tolower($0) ~ "name:.*"tolower(mac) { found=1 }
        found && tolower($0) ~ "active profile:" { 
            sub(/.*Active Profile: /, ""); print; exit 
        }
        found && /^$/ { exit }
    ')
    
    if [[ -z "$active" || "$active" == "off" ]]; then echo "None"; return; fi
    if [[ "$active" == *"a2dp"* || "$active" == *"A2DP"* ]]; then echo "Hi-Fi (A2DP)"
    elif [[ "$active" == *"hfp"* || "$active" == *"HFP"* || "$active" == *"headset"* ]]; then echo "Headset (HFP)"
    else echo "$active"
    fi
}

get_status() {
    # 1. HW check (zero-latency, no bluetoothctl needed)
    if ! ls -1d /sys/class/bluetooth/hci* &>/dev/null; then
        echo "{\"present\":false,\"power\":\"off\",\"connected\":[],\"devices\":[]}"
        return
    fi

    # 2. Check if bluetoothctl is even installed to prevent command errors
    if ! command -v bluetoothctl &> /dev/null; then
        echo "{\"present\":false,\"power\":\"off\",\"connected\":[],\"devices\":[]}"
        return
    fi

    # 3. Controller presence check
    controller=$(_btctl_timeout 1 list 2>/dev/null | head -n1)
    if [[ -z "$controller" || "$controller" == *"Waiting"* ]]; then
        echo "{\"present\":false,\"power\":\"off\",\"connected\":[],\"devices\":[]}"
        return
    fi

    # 4. Power state
    power="off"
    if _btctl_timeout 1 show 2>/dev/null | grep -q "Powered: yes"; then power="on"; fi

    connected_json="[]"
    devices_json="[]"

    if [ "$power" == "on" ]; then
        # Run a brief scan to refresh device cache (async, don't wait)
        _btctl --timeout 3 scan on &>/dev/null &
        
        paired_macs=$(_btctl devices Paired 2>/dev/null)
        mapfile -t devices < <(_btctl devices 2>/dev/null)
        mapfile -t connected_info_lines < <(_btctl devices Connected 2>/dev/null)

        # Build set of connected MACs
        declare -A connected_data_map
        connected_macs=""
        connected_list_objs=()
        
        for line in "${connected_info_lines[@]}"; do
            [ -z "$line" ] && continue
            rest="${line#Device }"
            mac="${rest%% *}"
            name="${rest#* }"
            [[ "$name" == "$mac" ]] && name=""
            [ -z "$name" ] && name="$mac"
            
            # Cache audio profile once per poll
            cached_cards=$(timeout 0.5 pactl list cards 2>/dev/null)
            bat=$(_btctl info "$mac" 2>/dev/null | awk -F'[(|)]' '/Battery Percentage:/ {print $2}')
            [ -z "$bat" ] && bat="0"
            profile=$(get_audio_profile "$mac" "$cached_cards")
            icon=$(get_icon "unknown" "$name")
            
            name_esc="${name//\"/\\\"}"
            icon_esc="${icon//\"/\\\"}"
            profile_esc="${profile//\"/\\\"}"
            
            connected_macs+="$mac "
            connected_list_objs+=("{\"id\":\"$mac\",\"name\":\"$name_esc\",\"mac\":\"$mac\",\"icon\":\"$icon_esc\",\"battery\":\"$bat\",\"profile\":\"$profile_esc\"}")
        done

        if [ ${#connected_list_objs[@]} -gt 0 ]; then
            connected_json="[$(IFS=,; echo "${connected_list_objs[*]}")]"
        fi

        # Other discovered/paired devices
        devices_list_objs=()
        for line in "${devices[@]}"; do
            [ -z "$line" ] && continue
            rest="${line#Device }"
            mac="${rest%% *}"
            
            if [[ "$connected_macs" == *"$mac"* ]]; then continue; fi

            name="${rest#* }"
            name="${name%

            if [[ "$paired_macs" == *"$mac"* ]]; then
                pair_action="Connect"
            else
                pair_action="Pair"
                if [[ "$STRICT_SPAM_FILTER" == true ]]; then
                    mac_hyphens="${mac//:/-}"
                    if [[ "$name" == "$mac" || "$name" == "$mac_hyphens" || -z "$name" ]]; then
                        continue
                    fi
                fi
            fi

            icon=$(get_icon "unknown" "$name")
            icon_esc="${icon//\"/\\\"}"
            pair_action_esc="${pair_action//\"/\\\"}"

            devices_list_objs+=("{\"id\":\"$mac\",\"name\":\"$name_esc\",\"mac\":\"$mac\",\"icon\":\"$icon_esc\",\"action\":\"$pair_action_esc\"}")
        done

        if [ ${#devices_list_objs[@]} -gt 0 ]; then
            devices_json="[$(IFS=,; echo "${devices_list_objs[*]}")]"
        fi
    fi

    echo "{\"present\":true,\"power\":\"$power\",\"connected\":$connected_json,\"devices\":$devices_json}"
}

toggle_power() {
    if _btctl show 2>/dev/null | grep -q "Powered: yes"; then
        _btctl power off
    else
        _btctl power on
    fi
}

connect_device() {
    local mac="$1"
    _btctl trust "$mac" > /dev/null 2>&1
    _btctl connect "$mac"
}

disconnect_device() {
    local mac="$1"
    _btctl disconnect "$mac"
}


# ── Main ──
case "$1" in
    --status) get_status ;;
    --toggle) toggle_power ;;
    --connect) connect_device "$2" ;;
    --disconnect) disconnect_device "$2" ;;
    *) get_status ;;
esac
\r'}"  # strip trailing CR from script output
            name_esc="${name//\"/\\\"}"

            if [[ "$paired_macs" == *"$mac"* ]]; then
                pair_action="Connect"
            else
                pair_action="Pair"
                if [[ "$STRICT_SPAM_FILTER" == true ]]; then
                    mac_hyphens="${mac//:/-}"
                    if [[ "$name" == "$mac" || "$name" == "$mac_hyphens" || -z "$name" ]]; then
                        continue
                    fi
                fi
            fi

            icon=$(get_icon "unknown" "$name")
            icon_esc="${icon//\"/\\\"}"
            pair_action_esc="${pair_action//\"/\\\"}"

            devices_list_objs+=("{\"id\":\"$mac\",\"name\":\"$name_esc\",\"mac\":\"$mac\",\"icon\":\"$icon_esc\",\"action\":\"$pair_action_esc\"}")
        done

        if [ ${#devices_list_objs[@]} -gt 0 ]; then
            devices_json="[$(IFS=,; echo "${devices_list_objs[*]}")]"
        fi
    fi

    echo "{\"present\":true,\"power\":\"$power\",\"connected\":$connected_json,\"devices\":$devices_json}"
}

toggle_power() {
    if _btctl show 2>/dev/null | grep -q "Powered: yes"; then
        _btctl power off
    else
        _btctl power on
    fi
}

connect_device() {
    local mac="$1"
    _btctl trust "$mac" > /dev/null 2>&1
    _btctl connect "$mac"
}

disconnect_device() {
    local mac="$1"
    _btctl disconnect "$mac"
}


# ── Main ──
case "$1" in
    --status) get_status ;;
    --toggle) toggle_power ;;
    --connect) connect_device "$2" ;;
    --disconnect) disconnect_device "$2" ;;
    *) get_status ;;
esac

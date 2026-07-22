#!/usr/bin/env bash

set -u

CONNECTOR="DSI-1"
MODE="800x1280@60.568"
SCALE="1.0"

rotate_screen() {
    local transform="$1"
    local orientation="$2"
    local state
    local serial

    state="$(
        gdbus call \
            --session \
            --dest org.gnome.Mutter.DisplayConfig \
            --object-path /org/gnome/Mutter/DisplayConfig \
            --method org.gnome.Mutter.DisplayConfig.GetCurrentState
    )" || {
        echo "Failed to read Mutter display state." >&2
        return 1
    }

    serial="$(
        printf '%s\n' "$state" |
            sed -n 's/^(uint32 \([0-9]\+\),.*/\1/p'
    )"

    if [[ -z "$serial" ]]; then
        echo "Failed to extract Mutter configuration serial." >&2
        return 1
    fi

    echo "Orientation: ${orientation} -> transform: ${transform}"

    gdbus call \
        --session \
        --dest org.gnome.Mutter.DisplayConfig \
        --object-path /org/gnome/Mutter/DisplayConfig \
        --method org.gnome.Mutter.DisplayConfig.ApplyMonitorsConfig \
        "$serial" \
        1 \
        "[(0, 0, ${SCALE}, uint32 ${transform}, true, [('${CONNECTOR}', '${MODE}', {})])]" \
        "{'layout-mode': <uint32 1>}" \
        >/dev/null
}

command -v monitor-sensor >/dev/null 2>&1 || {
    echo "monitor-sensor is not installed." >&2
    exit 1
}

command -v gdbus >/dev/null 2>&1 || {
    echo "gdbus is not installed." >&2
    exit 1
}

stdbuf -oL monitor-sensor 2>&1 |
while IFS= read -r line; do
    case "$line" in
        *"orientation changed: normal"*|*"orientation: normal"*)
            rotate_screen 0 normal
            ;;
        *"orientation changed: right-up"*|*"orientation: right-up"*)
            rotate_screen 1 right-up
            ;;
        *"orientation changed: bottom-up"*|*"orientation: bottom-up"*)
            rotate_screen 2 bottom-up
            ;;
        *"orientation changed: left-up"*|*"orientation: left-up"*)
            rotate_screen 3 left-up
            ;;
    esac
done

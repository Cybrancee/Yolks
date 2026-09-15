#!/usr/bin/env bash
set -Eeuo pipefail

PURPLE='\033[38;5;141m'
RED='\033[38;5;196m'
RESET='\033[0m'
GUIDE='https://cybrancee.com/learn/how-to-host-an-eco-server'

brand() {
    printf '%b[Cybrancee]%b %s\n' "$PURPLE" "$RESET" "$*"
}

error() {
    printf '%b[Cybrancee]%b %b[ERROR]%b %s\n' "$PURPLE" "$RESET" "$RED" "$RESET" "$*" >&2
}

usage_error() {
    printf '%b============================================================%b\n' "$PURPLE" "$RESET" >&2
    error 'Eco requires Strange Cloud authentication before the server can start.'
    printf '%b[Cybrancee]%b Configure these authentication methods in Startup:\n' "$PURPLE" "$RESET" >&2
    printf '%b[Cybrancee]%b • ECO_USERNAME and ECO_PASSWORD\n' "$PURPLE" "$RESET" >&2
    printf '%b[Cybrancee]%b • ECO_USER_TOKEN\n' "$PURPLE" "$RESET" >&2
    printf '%b[Cybrancee]%b You can find these credentials at https://play.eco/account\n' "$PURPLE" "$RESET" >&2
    printf '%b[Cybrancee]%b After saving them, restart the server.\n' "$PURPLE" "$RESET" >&2
    printf '%b[Cybrancee]%b Guide: %s\n' "$PURPLE" "$RESET" "$GUIDE" >&2
    printf '%b============================================================%b\n' "$PURPLE" "$RESET" >&2
}

if [[ -z "${STARTUP:-}" ]]; then
    error 'STARTUP is not defined. Configure the Eco egg startup command first.'
    exit 64
fi

if [[ -z "${ECO_USERNAME:-}" || -z "${ECO_PASSWORD:-}" || -z "${ECO_USER_TOKEN:-}" ]]; then
    usage_error
    trap 'exit 0' TERM INT
    while :; do
        if IFS= read -r -t 60 command; then
            [[ "$command" == 'exit' ]] && exit 0
        fi
    done
fi

GAME_PORT="${SERVER_PORT:-}"
case "$GAME_PORT" in *[!0-9]*|"") error 'The server port is invalid.'; exit 64;; esac
if [[ "$GAME_PORT" -lt 1 || "$GAME_PORT" -gt 65534 ]]; then
    error 'The server port must allow the next port to be used by Eco.'
    exit 64
fi
WEB_PORT=$((GAME_PORT + 1))
export WEB_PORT
CONFIG='/home/container/Configs/Network.eco'
if [[ ! -f "$CONFIG" ]]; then
    error 'Eco server configuration could not be found.'
    exit 1
fi

temporary_config=$(mktemp "${CONFIG}.tmp.XXXXXX")
if ! jq --argjson game_port "$GAME_PORT" --argjson web_port "$WEB_PORT" '
    if (has("GameServerPort") and has("WebServerPort"))
    then .GameServerPort = $game_port | .WebServerPort = $web_port
    else error("required port settings are missing")
    end
' "$CONFIG" > "$temporary_config"; then
    rm -f -- "$temporary_config"
    error 'Eco server ports could not be configured.'
    exit 1
fi
chmod --reference="$CONFIG" "$temporary_config"
mv -f -- "$temporary_config" "$CONFIG"

auth_args=("-username=$ECO_USERNAME" "-password=$ECO_PASSWORD" "-userToken=$ECO_USER_TOKEN")

# STARTUP is intentionally evaluated by bash because it is the command supplied
# by Pterodactyl. Authentication arguments are shell-escaped before appending.
printf -v escaped_auth ' %q' "${auth_args[@]}"
brand 'Starting Eco Dedicated Server...'
exec /bin/bash -lc "${STARTUP}${escaped_auth}"
#!/bin/bash
set -euo pipefail

token=${AUTH_TOKEN:-}
if [[ -z "${token//[[:space:]]/}" ]]; then
    PURPLE='\033[0;35m'
    RESET='\033[0m'
    printf '%b============================================================%b\n' "$PURPLE" "$RESET"
    printf '%b[Cybrancee]%b [SETUP] Your server needs an authentication token.\n' "$PURPLE" "$RESET"
    printf '%b[Cybrancee]%b Open Bannerlord multiplayer and enter customserver.gettoken in the game console.\n' "$PURPLE" "$RESET"
    printf '%b[Cybrancee]%b Paste your token into Server Authentication Token in Startup.\n' "$PURPLE" "$RESET"
    printf '%b[Cybrancee]%b Save your changes, then restart this server.\n' "$PURPLE" "$RESET"
    printf '%b[Cybrancee]%b Guide: https://cybrancee.com/learn/how-to-host-a-mount-and-blade-ii-bannerlord-server\n' "$PURPLE" "$RESET"
    printf '%b============================================================%b\n' "$PURPLE" "$RESET"
    sleep infinity &
    waiting_pid=$!
    trap 'kill "$waiting_pid" 2>/dev/null || true; wait "$waiting_pid" 2>/dev/null || true; exit 0' INT TERM
    wait "$waiting_pid"
    exit 0
fi

if [[ -z "${STARTUP:-}" ]]; then
    echo '[Cybrancee] The server startup command is missing.' >&2
    exit 1
fi

exec /bin/bash /entrypoint.sh "$@"

#!/bin/bash
set -euo pipefail

MARKER_FILE="${FIRST_BOOT_MARKER:-/home/container/.sotf-first-boot-complete}"
AUTO_RESTART_FIRST_BOOT="${AUTO_RESTART_FIRST_BOOT:-1}"
DISPLAY="${DISPLAY:-:0}"
DISPLAY_WIDTH="${DISPLAY_WIDTH:-1024}"
DISPLAY_HEIGHT="${DISPLAY_HEIGHT:-768}"
DISPLAY_DEPTH="${DISPLAY_DEPTH:-16}"
XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-container}"
FORCE_SKIP_NETWORK_TEST="${FORCE_SKIP_NETWORK_TEST:-1}"
RESTART_HINT="#DSE [Self-Tests] Please restart the server."

if [ "$FORCE_SKIP_NETWORK_TEST" = "1" ]; then
    export SKIP_TESTS=true
fi

if [ "$#" -eq 0 ]; then
    if [ -n "${STARTUP:-}" ]; then
        startup_command="$STARTUP"

        while [[ "$startup_command" =~ \{\{([A-Z0-9_]+)\}\} ]]; do
            variable_name="${BASH_REMATCH[1]}"
            variable_value="${!variable_name:-}"
            startup_command="${startup_command//\{\{$variable_name\}\}/$variable_value}"
        done

        set -- /bin/bash -lc "$startup_command"
    else
        echo "No startup command was provided."
        exit 1
    fi
fi

run_server() {
    "$@"
}

run_server_with_log_capture() {
    local log_file="$1"
    shift

    : > "$log_file"

    setsid "$@" > >(tee "$log_file") 2>&1 &
    local command_pid=$!
    local restart_detected=0
    local command_exit_code=0

    while kill -0 "$command_pid" >/dev/null 2>&1; do
        if grep -Fq "$RESTART_HINT" "$log_file"; then
            restart_detected=1
            echo "[entrypoint] Restart hint detected in server output."
            kill -TERM -- "-$command_pid" >/dev/null 2>&1 || true
            break
        fi

        sleep 1
    done

    wait "$command_pid"
    command_exit_code=$?

    if [ "$restart_detected" = "1" ]; then
        return 75
    fi

    return "$command_exit_code"
}

start_headless_display() {
    export DISPLAY
    export XDG_RUNTIME_DIR

    mkdir -p "$XDG_RUNTIME_DIR"
    chmod 700 "$XDG_RUNTIME_DIR"

    if pgrep -f "Xvfb ${DISPLAY}" >/dev/null 2>&1; then
        return
    fi

    Xvfb "${DISPLAY}" -screen 0 "${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x${DISPLAY_DEPTH}" -nolisten tcp >/tmp/xvfb.log 2>&1 &
    sleep 1
}

start_headless_display

if [ "$AUTO_RESTART_FIRST_BOOT" = "1" ] && [ ! -f "$MARKER_FILE" ]; then
    echo "[entrypoint] First boot detected. Starting server once to allow initial setup."

    first_boot_log="$(mktemp)"
    first_exit_code=0

    set +e
    run_server_with_log_capture "$first_boot_log" "$@"
    first_exit_code=$?
    set -e

    mkdir -p "$(dirname "$MARKER_FILE")"
    touch "$MARKER_FILE"
    rm -f "$first_boot_log"

    if [ "$first_exit_code" -eq 75 ] || [ "$first_exit_code" -ne 0 ]; then
        echo "[entrypoint] First boot exited with code ${first_exit_code}. Restarting once automatically."
        exec "$@"
    fi
fi

exec "$@"

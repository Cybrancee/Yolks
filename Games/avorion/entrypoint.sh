#!/usr/bin/env bash
set -euo pipefail

NSS_DIR=/tmp/cybrancee-nss
uid=$(id -u)
gid=$(id -g)

if ! getent passwd "$uid" >/dev/null 2>&1; then
    mkdir -p "$NSS_DIR"
    sed -e "s/__PTERO_UID__/$uid/g" -e "s/__PTERO_GID__/$gid/g" \
        /usr/local/share/cybrancee/passwd.template > "$NSS_DIR/passwd"
    sed -e "s/__PTERO_GID__/$gid/g" \
        /usr/local/share/cybrancee/group.template > "$NSS_DIR/group"

    nss_wrapper=$(find /usr/lib /lib -name libnss_wrapper.so -type f -print -quit 2>/dev/null || true)
    if [[ -z "$nss_wrapper" ]]; then
        echo '[Cybrancee] ERROR: libnss-wrapper is missing from the image.'
        exit 1
    fi
    export NSS_WRAPPER_PASSWD="$NSS_DIR/passwd"
    export NSS_WRAPPER_GROUP="$NSS_DIR/group"
    export LD_PRELOAD="${nss_wrapper}${LD_PRELOAD:+:$LD_PRELOAD}"
fi

export HOME=/home/container
export USER=${USER:-container}
export LOGNAME=${LOGNAME:-container}
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME"
mkdir -p "$HOME/.avorion/backups"

# Wings normally passes the egg startup command as argv. Some registry/image
# combinations do not, so fall back to Pterodactyl's STARTUP environment
# variable instead of exiting successfully with no server process.
if [[ "$#" -eq 0 ]]; then
    if [[ -z "${STARTUP:-}" ]]; then
        echo '[Cybrancee] ERROR: No startup command was provided by Pterodactyl.'
        exit 1
    fi
    exec /bin/bash -lc "$STARTUP"
fi

exec "$@"
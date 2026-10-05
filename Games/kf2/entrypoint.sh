#!/bin/bash
set -euo pipefail

if [ ! -r /entrypoint.sh ]; then
    echo '[Cybrancee] The base image entrypoint is missing or unreadable.' >&2
    exit 1
fi
if [ -z "${STARTUP:-}" ]; then
    echo '[Cybrancee] The server startup command is empty.' >&2
    exit 1
fi

# The base entrypoint updates Steam before evaluating STARTUP.
export STARTUP="/usr/local/bin/cybrancee-kf2-workshop && ${STARTUP}"
exec /bin/bash /entrypoint.sh "$@"

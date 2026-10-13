#!/bin/bash
set -euo pipefail

if [ -z "${STARTUP:-}" ]; then
    echo '[Cybrancee] The server startup command is missing.' >&2
    exit 1
fi

cd /home/container
exec /bin/bash /entrypoint.sh "$@"

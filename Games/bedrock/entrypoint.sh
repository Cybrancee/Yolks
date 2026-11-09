#!/bin/bash
cd /home/container

# Make internal Docker IP address available to processes.
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP



#nethernet fix for server-udp-ports
FILE="server.properties"
KEY="server-udp-ports"

if [ "$SERVER_UDP_PORTS" -eq 0 ]; then
    # Key exists: delete the line from the file
    sed -i -E "/^[[:space:]]*${KEY}[[:space:]]*=/d" "$FILE"
    echo "Removed $KEY from $FILE because SERVER_UDP_PORTS is 0"
else

    if [[ -n "$EXTRA_PORT_10" && -n "$EXTRA_PORT_1" ]]; then
        # build udp ports with extra ports
        SAFE_VAL=$(printf '%s\n' "${SERVER_IP}:${EXTRA_PORT_1}-${EXTRA_PORT_10}:${EXTRA_PORT_1}-${EXTRA_PORT_10}" | sed -e 's/[\/&]/\\&/g')

    else
        # build udp ports without extra ports
        SAFE_VAL=$(printf '%s\n' "${SERVER_IP}:${SERVER_PORT}-${SERVER_PORT}:${SERVER_PORT}-${SERVER_PORT}" | sed -e 's/[\/&]/\\&/g')
    fi
    
    if grep -qE "^[[:space:]]*${KEY}[[:space:]]*=" "$FILE"; then
        sed -i -E "s/^[[:space:]]*(${KEY})[[:space:]]*=.*/\1=${SAFE_VAL}/" "$FILE"
    else
        echo "${KEY}=${SAFE_VAL}" >> "$FILE"
    fi
fi

echo "${SERVER_IP}, ${SERVER_PORT}"

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP}
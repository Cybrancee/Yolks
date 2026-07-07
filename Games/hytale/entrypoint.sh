#!/bin/bash
cd /home/container

# Make internal Docker IP address available to processes.
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Print Java Version
java -version


if [ -z ${MANUAL_AUTH} ] || [ "${MANUAL_AUTH}" == "0" ]; then 

    # Get Hytale token
    if [[ -z "$HYTALE_SERVER_SESSION_TOKEN" || -z "$HYTALE_SERVER_IDENTITY_TOKEN" ]]; then

        URL="https://hytale.cybrancee.com/token"

        RESPONSE=$(curl -sS "$URL")

        if [ $? -eq 0 ]; then
            
            s_token=$(echo "$RESPONSE" | jq -r '.sessionToken')
            i_token=$(echo "$RESPONSE" | jq -r '.identityToken')

            # validate tokens arent empty
            if [[ "$s_token" != "null" && -n "$s_token" && "$i_token" != "null" && -n "$i_token" ]]; then
                export HYTALE_SERVER_SESSION_TOKEN="$s_token"
                export HYTALE_SERVER_IDENTITY_TOKEN="$i_token"
                echo "Tokens exported successfully."
            else
                echo "Warning: API response was valid but tokens were missing or null."
            fi

        else
            echo "Warning: Network request failed. No variables were set."
        fi
    else
        echo "Tokens are already set. Skipping API request."
    fi

else
    echo -e "Manual Auth enabled... Please use /auth login device to authenticate the server"
fi


# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP}
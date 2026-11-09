#!/bin/bash
cd /home/container

# Make internal Docker IP address available to processes.
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

ARCH_SUFFIX=$(ls /usr/lib/jvm/ | grep "temurin-25-jdk" | sed 's/temurin-25-jdk-//')

SERVER_JAR="/home/container/$SERVER_JARFILE"

VARIABLE_TXT="/home/container/variables.txt"

INSTALLER_LOG="/home/container/neoforge-installer.jar.log"

PROPERTIES_FILE="server.properties"

FALLBACK_MOTD="A Minecraft Server"

LIST_URL="https://raw.githubusercontent.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words/master/en"

LOCAL_LIST="/tmp/badwords.txt"


if [ -d "/home/container/libraries/net/neoforged/neoforge" ]; then
        MINECRAFT_VERSION=$(ls "/home/container/libraries/net/neoforged/neoforge" | head -n 1)
        VERSION="1.$(echo "$MINECRAFT_VERSION" | cut -d'-' -f1 | cut -d'.' -f1,2 | tr -d ' \r ')"
        echo "Minecraft Server Version from neoforge libraries: $VERSION"

elif [ -d "/home/container/libraries/net/minecraftforge/fmlcore" ]; then
        FORGE_FOLDER=$(ls "/home/container/libraries/net/minecraftforge/fmlcore" | head -n 1)
        VERSION=$(echo "$FORGE_FOLDER" | cut -d'-' -f1 | tr -d ' \r ')
        echo "Minecraft Server Version from Forge libraries: $VERSION"


elif [ -d "/home/container/libraries/net/minecraftforge/forge" ]; then
        FORGE_FOLDER=$(ls "/home/container/libraries/net/minecraftforge/forge" | head -n 1)
        VERSION=$(echo "$FORGE_FOLDER" | cut -d'-' -f1 | tr -d ' \r ')
        echo "Minecraft Server Version from Forge libraries: $VERSION"

# Neoforge
elif [ -f "$INSTALLER_LOG" ] && grep -q "MC Version: " "$INSTALLER_LOG"; then

    if [ -f "$INSTALLER_LOG" ] && grep -q "MC Version: " "$INSTALLER_LOG"; then
        VERSION=$(grep 'MC Version: ' "$INSTALLER_LOG" | sed -E 's/.*MC\ Version\: ([0-9.]+).*/\1/' | cut -d':' -f2- | tr -d ' \r')
        echo "Minecraft Server Version: $VERSION"
    fi

elif [ -f "$VARIABLE_TXT" ] && grep -q "MINECRAFT_VERSION=" "$VARIABLE_TXT"; then

    if [ -f "$VARIABLE_TXT" ] && grep -q "MINECRAFT_VERSION=" "$VARIABLE_TXT"; then
        VERSION=$(grep 'MINECRAFT_VERSION=' "$VARIABLE_TXT" | sed -E 's/.*MINECRAFT\_VERSION\=([0-9.]+).*/\1/' | cut -d':' -f2- | tr -d ' \r')
        echo "Minecraft Server Version: $VERSION"
    fi

elif [ -f "$SERVER_JAR" ]; then

    TMP_DIR=$(mktemp -d)

    unzip -q "$SERVER_JAR" -d "$TMP_DIR" 2>/dev/null

    if [ -f "$TMP_DIR/version.json" ]; then
        VERSION=$(grep -o '"id": "[^"]*' "$TMP_DIR/version.json" | sed 's/"id": "//')
        echo "Minecraft Server Version: $VERSION"

    elif [ -f "$TMP_DIR/patch.properties" ]; then
        VERSION=$(grep "version=" "$TMP_DIR/patch.properties" | cut -d'=' -f2)
        echo "Minecraft Server Version: $VERSION"
    
    # for forge
    elif [ -f "$TMP_DIR/META-INF/MANIFEST.MF" ] && grep -q "Git-Branch: " "$TMP_DIR/META-INF/MANIFEST.MF"; then
        VERSION=$(grep "Git-Branch: " "$TMP_DIR/META-INF/MANIFEST.MF" | sed -E 's/.*Git\-Branch\:  ([0-9.]+).*/\1/' | cut -d':' -f2- | tr -d ' \r')
        echo "Minecraft Server Version grep: $VERSION"


    elif [ -f "$TMP_DIR/META-INF/MANIFEST.MF" ] && grep -q "fml.mcVersion" "$TMP_DIR/META-INF/MANIFEST.MF"; then
        VERSION=$(grep "fml.mcVersion" "$TMP_DIR/META-INF/MANIFEST.MF" | sed -E 's/.*--fml\.mcVersion ([0-9.]+).*/\1/' | cut -d':' -f2- | tr -d ' \r')
        echo "Minecraft Server Version grep: $VERSION"

    # for fabric
    elif [ -f "$TMP_DIR/install.properties" ] && grep -q "game-version=" "$TMP_DIR/install.properties"; then
        VERSION=$(grep "game-version=" "$TMP_DIR/install.properties" | sed -E 's/.*game\-version\=([0-9.]+).*/\1/' | cut -d':' -f2- | tr -d ' \r')
        echo "Minecraft Server Version fabric: $VERSION"

    else
        VERSION="${MC_VERSION:-${MINECRAFT_VERSION:-VANILLA_VERSION}}"
    fi

    rm -rf "$TMP_DIR"
else
    VERSION="${MC_VERSION:-${MINECRAFT_VERSION:-VANILLA_VERSION}}"
fi


if [ -n "$VERSION" ]; then

    VERSION_CLEAN=$(echo "${VERSION}" | tr -d ' ')

    if [[ "$VERSION_CLEAN" == 1.* ]]; then
        MINOR_VERSION=$(echo "$VERSION_CLEAN" | cut -d'.' -f2)
    else
        MINOR_VERSION=$(echo "$VERSION_CLEAN" | cut -d'.' -f1)
    fi
    
    echo -e "$VERSION_CLEAN $MINOR_VERSION"

    case "${MINOR_VERSION}" in
        [0-9]|1[0-6])
            export JAVA_HOME="/usr/lib/jvm/temurin-8-jdk-${ARCH_SUFFIX}"
            ;;
        17|18|19)
            export JAVA_HOME="/usr/lib/jvm/temurin-17-jdk-${ARCH_SUFFIX}"
            ;;
        20|21)
            export JAVA_HOME="/usr/lib/jvm/temurin-21-jdk-${ARCH_SUFFIX}"
            ;;
        26|*)
            export JAVA_HOME="/usr/lib/jvm/temurin-25-jdk-${ARCH_SUFFIX}"
            ;;
    esac
else
    #fallback if everything fails
    export JAVA_HOME="/usr/lib/jvm/temurin-25-jdk-${ARCH_SUFFIX}"
fi


echo "Java Home: $JAVA_HOME"

# Print Java Version
eval "${JAVA_HOME}/bin/java -version"

# filter MOTD
if [ -f "$PROPERTIES_FILE" ]; then
    CURRENT_MOTD=$(grep -E "^motd=" "$PROPERTIES_FILE" | cut -d'=' -f2-)

    # Remove common spacing or special characters before checking
    CLEANED_MOTD=$(echo "$CURRENT_MOTD" | tr -d '[]._#*-')

    # Simple character normalization (e.g., replace '3' with 'e')
    NORMALISED_MOTD=$(echo "$CLEANED_MOTD" | tr '301!$@' 'eoilsa')

    echo "Current MOTD: $CURRENT_MOTD"
    echo "Cleaned MOTD: $CLEANED_MOTD"
    echo "Normalised MOTD: $NORMALISED_MOTD"
    
    # Download the blocklist if it does not exist locally
    curl -sSL "$LIST_URL" -o "$LOCAL_LIST"

    if echo "$CURRENT_MOTD $NORMALISED_MOTD" | grep -iqw -f "$LOCAL_LIST"; then
        echo "Inappropriate or flagged MOTD detected! Resetting to default..."
        sed -i "s/^motd=.*/motd=$FALLBACK_MOTD/" "$PROPERTIES_FILE"
    fi
fi

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g' -e "s|^java |${JAVA_HOME}/bin/java |g" -e "s| java | ${JAVA_HOME}/bin/java |g")
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP}
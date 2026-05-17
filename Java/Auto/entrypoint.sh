#!/bin/bash
cd /home/container

# Make internal Docker IP address available to processes.
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP


ARCH_SUFFIX=$(ls /usr/lib/jvm/ | grep "temurin-25-jdk" | sed 's/temurin-25-jdk-//')

VERSION_CLEAN=$(echo "${VANILLA_VERSION}" | tr -d ' ')


if [[ "$VERSION_CLEAN" == 1.* ]]; then
    MINOR_VERSION=$(echo "$VERSION_CLEAN" | cut -d'.' -f2)
else
    MINOR_VERSION=$(echo "$VERSION_CLEAN" | cut -d'.' -f1)
fi

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

echo " Java Home: $JAVA_HOME"

# Print Java Version
eval "${JAVA_HOME}/bin/java -version"

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g' -e "s|^java |${JAVA_HOME}/bin/java |g" -e "s| java | ${JAVA_HOME}/bin/java |g")
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP}
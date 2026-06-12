FROM        --platform=$TARGETOS/$TARGETARCH ghcr.io/cybrancee/steamcmd:debian
LABEL       author="Matthew Penner" maintainer="support@cybrancee.com"
LABEL       org.opencontainers.image.source="https://github.com/Cybrancee/Yolks"
LABEL       org.opencontainers.image.licenses=MIT
LABEL       org.opencontainers.image.title="Squad Dedicated Server"
LABEL       org.opencontainers.image.description="Custom Squad image for Cybrancee panel"

ENV         DEBIAN_FRONTEND=noninteractive

# Squad-specific dependencies on top of the base image
USER        root
RUN         dpkg --add-architecture i386 \
            && apt-get update \
            && apt-get install -y --no-install-recommends \
                libgcc-s1 \
                libgcc-s1:i386 \
                libstdc++6 \
                libstdc++6:i386 \
                libcurl4 \
                libcurl4:i386 \
            && apt-get clean \
            && rm -rf /var/lib/apt/lists/*

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

# LD_LIBRARY_PATH needed for Squad Linux binaries
ENV         LD_LIBRARY_PATH=/home/container/linux64/

COPY        --chown=container:container entrypoint.sh /entrypoint.sh
RUN         chmod +x /entrypoint.sh

STOPSIGNAL  SIGINT
ENTRYPOINT  ["/usr/bin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]

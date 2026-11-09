FROM --platform=$TARGETOS/$TARGETARCH debian:bookworm-slim

LABEL author="Matthew Penner" \
      maintainer="support@cybrancee.com" \
      org.opencontainers.image.source="https://github.com/Cybrancee/Yolks" \
      org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive

# SteamCMD, Pterodactyl entrypoint, Wine and Enshrouded runtime dependencies.
# Install the i386 libraries SteamCMD commonly requires, while running the
# 64-bit Enshrouded server through native Wine (no Proton compatibility layer).
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
       bash ca-certificates curl tar gcc g++ \
       lib32gcc-s1 libgcc-s1 libgcc-12-dev libgcc-11-dev \
       libcurl4-gnutls-dev:i386 libssl-dev:i386 libcurl4:i386 \
       lib32tinfo6 libtinfo6:i386 lib32z1 lib32stdc++6 libncurses5:i386 \
       libcurl3-gnutls:i386 libsdl2-2.0-0:i386 libsdl2-2.0-0 \
       iproute2 gdb telnet net-tools netcat-traditional tzdata numactl \
       xvfb wget tini cabextract \
       libfontconfig1 libvulkan1 \
       ca-certificates gnutls-bin libgnutls30 \
    && useradd -m -d /home/container container \
    && mkdir -p /etc/apt/keyrings \
    && wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
    && wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources \
    && apt-get update \
    && apt-get install --install-recommends -y winehq-stable wine-binfmt \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install rcon-cli used by some Pterodactyl eggs. Avoid the old, untrusted
# Ubuntu libssl1.1 .deb download; Debian Bookworm supplies supported OpenSSL.
RUN mkdir -p /tmp/rcon \
    && curl -fsSL https://github.com/gorcon/rcon-cli/releases/download/v0.10.3/rcon-0.10.3-amd64_linux.tar.gz \
       -o /tmp/rcon/rcon.tar.gz \
    && tar -xzf /tmp/rcon/rcon.tar.gz -C /tmp/rcon \
    && install -m 0755 /tmp/rcon/rcon-0.10.3-amd64_linux/rcon /usr/local/bin/rcon \
    && rm -rf /tmp/rcon

# Keep Winetricks available for manual troubleshooting; do not install native
# Windows crypt32/Steam DLLs automatically because that can introduce mismatches.
RUN wget -q -O /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod 0755 /usr/local/bin/winetricks

# Enshrouded is a 64-bit Windows server. Let the container user create its own
# Wine prefix on first launch rather than baking a possibly stale prefix into
# the image. Do not set Proton's STEAM_COMPAT_* variables for native Wine.
ENV HOME=/home/container \
    WINEPREFIX=/home/container/.wine \
    WINEARCH=win64 \
    WINEDEBUG=-all \
    WINEDLLOVERRIDES="mscoree,mshtml=" \
    DISPLAY=:99 \
    DISPLAY_WIDTH=1024 \
    DISPLAY_HEIGHT=768 \
    DISPLAY_DEPTH=24 \
    AUTO_UPDATE=1 \
    XVFB=1 \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# Keep the .NET runtime installed by the original image for other egg tools.
RUN wget -q https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb \
    && dpkg -i /tmp/packages-microsoft-prod.deb \
    && rm /tmp/packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends dotnet-runtime-9.0 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /home/container \
    && chown -R container:container /home/container


RUN mkdir /dev/ntsync     
USER container
ENV USER=container
WORKDIR /home/container

STOPSIGNAL SIGINT

COPY --chown=container:container ./entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]

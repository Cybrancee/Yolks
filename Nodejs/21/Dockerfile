FROM        --platform=$TARGETOS/$TARGETARCH node:21-bookworm-slim

ARG CHROME_VERSION="130.0.6723.116"

LABEL       author="Michael Parker" maintainer="support@cybrancee.com"
LABEL       org.opencontainers.image.source="https://github.com/Cybrancee/Yolks"
LABEL       org.opencontainers.image.licenses=MIT


RUN         apt update \
            && apt -y upgrade \
            && apt -y install wget ffmpeg iproute2 git sqlite3 libsqlite3-dev python3 python3-dev ca-certificates dnsutils tzdata zip tar curl build-essential libtool iputils-ping libnss3 tini libdbus-1-3 pkg-config libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev\
            && useradd -m -d /home/container container

RUN         npm install npm@10.x.x typescript ts-node @types/node --location=global

# install pnpm
RUN         npm install -g corepack@latest
RUN         corepack enable
RUN         corepack prepare pnpm@latest --activate

RUN wget --no-verbose -O /tmp/chrome.deb https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_VERSION}-1_amd64.deb \
    && apt install -y /tmp/chrome.deb \
    && rm /tmp/chrome.deb

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

STOPSIGNAL SIGINT

COPY        --chown=container:container ./../entrypoint.sh /entrypoint.sh
RUN         chmod +x /entrypoint.sh
ENTRYPOINT    ["/usr/bin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]
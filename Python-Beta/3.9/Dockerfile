FROM        --platform=$TARGETOS/$TARGETARCH python:3.9-slim-bookworm

LABEL       author="Michael Parker" maintainer="support@cybrancee.com"
LABEL       org.opencontainers.image.source="https://github.com/Cybrancee/Yolks"
LABEL       org.opencontainers.image.licenses=MIT

ARG CHROME_VERSION="130.0.6723.116"

RUN apt update -y \
    && apt -y upgrade \
    && apt-get -y install sudo \
    && apt -y install wget curl git gcc g++ ca-certificates dnsutils curl iproute2 ffmpeg procps tini libmariadb3 libmariadb-dev libnss3 libnss3-dev libnss3-tools libgdk-pixbuf2.0-dev libgtk-3-dev libxss-dev \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -d /home/container container 

RUN apt update -y \
    && sudo apt install -y libnss3 \
    && apt search libnss3

RUN python -m pip install --upgrade pip

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
FROM        --platform=$TARGETOS/$TARGETARCH python:2.7-slim

LABEL       author="Michael Parker" maintainer="support@cybrancee.com"

RUN         apt-get update \
            && apt -y install git gcc g++ ca-certificates dnsutils curl iproute2 ffmpeg procps tini \
            && useradd -m -d /home/container container

RUN python -m pip install --upgrade pip

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

STOPSIGNAL SIGINT

COPY        --chown=container:container ./../entrypoint.sh /entrypoint.sh
RUN         chmod +x /entrypoint.sh
ENTRYPOINT    ["/usr/bin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]
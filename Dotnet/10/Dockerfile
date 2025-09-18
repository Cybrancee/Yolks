FROM        --platform=$TARGETOS/$TARGETARCH ghcr.io/cybrancee/debian:latest

LABEL       author="Torsten Widmann" maintainer="support@cybrancee"

LABEL       org.opencontainers.image.source="https://github.com/Cybrancee/Yolks"
LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND=noninteractive

RUN         apt update -y \
            && apt upgrade -y \
            && apt install -y apt-transport-https wget curl iproute2 libgdiplus tini \
            && wget https://dot.net/v1/dotnet-install.sh \
            && chmod +x dotnet-install.sh \
            && ./dotnet-install.sh -c 10.0 --install-dir /usr/share \
            && ln -s /usr/share/dotnet /usr/bin/dotnet

RUN         useradd -m -d /home/container -s /bin/bash container

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

STOPSIGNAL SIGINT

RUN dotnet --version

COPY        --chown=container:container ./../entrypoint.sh /entrypoint.sh
RUN         chmod +x /entrypoint.sh
ENTRYPOINT    ["/usr/bin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]
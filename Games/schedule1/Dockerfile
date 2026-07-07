FROM        --platform=$TARGETOS/$TARGETARCH debian:bookworm-slim

LABEL       author="Matthew Penner" maintainer="support@cybrancee.com"

LABEL       org.opencontainers.image.source="https://github.com/Cybrancee/Yolks"
LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND=noninteractive

RUN         dpkg --add-architecture i386 \
            && apt-get update \
            && apt-get upgrade -y \
            && apt-get install -y tar curl gcc g++ lib32gcc-s1 libgcc-12-dev libgcc-11-dev libcurl4-gnutls-dev:i386 libssl-dev:i386 libcurl4:i386 lib32tinfo6 libtinfo6:i386 lib32z1 lib32stdc++6 libncurses5:i386 libcurl3-gnutls:i386 libsdl2-2.0-0:i386 libsdl2-2.0-0 iproute2 gdb libsdl1.2debian libfontconfig1 telnet net-tools netcat-traditional tzdata numactl xvfb wget tini git build-essential socat unzip ca-certificates\
            && useradd -m -d /home/container container

RUN update-ca-certificates

## install rcon
RUN         cd /tmp/ \
            && curl -sSL https://github.com/gorcon/rcon-cli/releases/download/v0.10.3/rcon-0.10.3-amd64_linux.tar.gz > rcon.tar.gz \
            && tar xvf rcon.tar.gz \
            && mv rcon-0.10.3-amd64_linux/rcon /usr/local/bin/

            # Temp fix for things that still need libssl1.1
RUN         if [ "$(uname -m)" = "x86_64" ]; then \
                wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
                dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
                rm libssl1.1_1.1.0g-2ubuntu4_amd64.deb; \
            fi

# Install wine and with recommends
RUN             mkdir -pm755 /etc/apt/keyrings
RUN             wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
RUN             wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources
RUN             apt update
RUN             apt install --install-recommends winehq-stable cabextract wine-binfmt -y

# Set up Winetricks
RUN	            wget -q -O /usr/sbin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
                && chmod +x /usr/sbin/winetricks

ENV             HOME=/home/container
ENV             WINEPREFIX=/home/container/.wine
ENV             WINEDEBUG=-all
ENV             WINEDLLOVERRIDES="version=n,b;steam_api64=n,b;steamclient64=n,b;tier0_s64=n,b;vstdlib_s64=n,b;steamclient=n,b;tier0_s=n,b;vstdlib_s=n,b"
ENV             DISPLAY=:0
ENV             DISPLAY_WIDTH=1024
ENV             DISPLAY_HEIGHT=768
ENV             DISPLAY_DEPTH=16
ENV             AUTO_UPDATE=1
ENV             XVFB=1
ENV             XDG_RUNTIME_DIR=/tmp/runtime-root

RUN mkdir /home/container/.wine

#RUN winetricks --self-update


RUN winetricks -q winhttp


RUN update-ca-certificates

RUN wine certutil -addstore -user Root /etc/ssl/certs/ca-certificates.crt

# RUN winetricks -q crypt32

# RUN xvfb-run winetricks -q dotnet6


#RUN xvfb-run winetricks dotnet6 /quiet /norestart
#RUN xvfb-run wineboot --init

# RUN wget https://aka.ms/dotnet/6.0/dotnet-runtime-win-x64.exe && \
#     xvfb-run wine dotnet-runtime-6.0.36-win-x64.exe /quiet /norestart && \
#     rm dotnet-runtime-6.0.36-win-x64.exe

#export WINEDLLOVERRIDES="version=n,b;steam_api64=n,b;steamclient64=n,b;tier0_s64=n,b;vstdlib_s64=n,b;steamclient=n,b;tier0_s=n,b;vstdlib_s=n,b"

# install netcat-keepalive
RUN git clone https://github.com/cyberelf/netcat-keepalive.git
RUN cd netcat-keepalive && make linux && ls && mv nckl-linux /usr/bin/nc-keepalive

RUN nc-keepalive -h || true

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

STOPSIGNAL SIGINT

COPY        --chown=container:container ../entrypoint.sh /entrypoint.sh
RUN         chmod +x /entrypoint.sh
ENTRYPOINT    ["/usr/bin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]
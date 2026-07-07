FROM            ghcr.io/ptero-eggs/yolks:debian_trixie

LABEL           author="Michael Parker" maintainer="parker@pterodactyl.io"
LABEL           org.opencontainers.image.licenses=MIT

## install required packages
RUN             dpkg --add-architecture i386 \
                && apt update -y \
                && apt install -y --no-install-recommends gnupg2 numactl tzdata libntlm0 winbind xvfb xauth python3 libncurses6 libncurses6:i386 libsdl2-2.0-0 libsdl2-2.0-0:i386 \
                unzip \
                cabextract \
                p11-kit \
                openssl \
                libssl3 \
                build-essential \
                mingw-w64 \
                perl \
                make \
                ca-certificates

RUN             cd /tmp/ \
                && curl -sSL https://github.com/gorcon/rcon-cli/releases/download/v0.10.3/rcon-0.10.3-amd64_linux.tar.gz > rcon.tar.gz \
                && tar xvf rcon.tar.gz \
                && mv rcon-0.10.3-amd64_linux/rcon /usr/local/bin/

# Install wine and with recommends
RUN             mkdir -pm755 /etc/apt/keyrings
RUN             wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
RUN             wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/trixie/winehq-trixie.sources
RUN             apt update
RUN             apt install --install-recommends winehq-staging cabextract -y

# Set up Winetricks
RUN	            wget -q -O /usr/sbin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
                && chmod +x /usr/sbin/winetricks

RUN mkdir -p /tmp/openssl \
                && wget -q https://github.com/openssl/openssl/releases/download/openssl-4.0.0/openssl-4.0.0.tar.gz -O /tmp/openssl.tar.gz \
                && tar -xvzf /tmp/openssl.tar.gz -C /tmp/ \
                && ls -a /tmp/ \
                && cd /tmp/openssl-4.0.0/ \
                && ./Configure mingw64 --cross-compile-prefix=x86_64-w64-mingw32- shared \
                && make -j$(nproc) \
                && ls -a /tmp/openssl-4.0.0 \
                && cp /tmp/openssl-4.0.0/libcrypto-4-x64.dll /usr/local/bin/ \
                && cp /tmp/openssl-4.0.0/libssl-4-x64.dll /usr/local/bin/ \
                && rm -rf /tmp/openssl-src


RUN mkdir -p /run/user/0 \
    && chmod 700 /run/user/0
    
ENV XDG_RUNTIME_DIR=/run/user/0

ENV             HOME=/home/container
ENV             WINEPREFIX=/home/container/.wine
ENV             WINEDLLOVERRIDES="mscoree,mshtml="
ENV             DISPLAY=:0
ENV             DISPLAY_WIDTH=1024
ENV             DISPLAY_HEIGHT=768
ENV             DISPLAY_DEPTH=16
ENV             AUTO_UPDATE=1
ENV             XVFB=1

COPY            ./../entrypoint.sh /entrypoint.sh
CMD             [ "/bin/bash", "/entrypoint.sh" ]
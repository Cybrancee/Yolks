# ---------------------------------------
# Generic Wine image based on Wine staging
# ---------------------------------------
FROM            ghcr.io/ptero-eggs/yolks:debian_trixie

LABEL           author="Michael Parker" maintainer="parker@pterodactyl.io"
LABEL           org.opencontainers.image.licenses=MIT

## install required packages
RUN             dpkg --add-architecture i386 \
                && apt update -y \
                && apt install -y --no-install-recommends gnupg2 numactl tzdata libntlm0 winbind xvfb xauth python3 libncurses6 libncurses6:i386 libsdl2-2.0-0 libsdl2-2.0-0:i386 ca-certificates libgnutls30 libgnutls30:i386

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

ENV             HOME=/home/container
ENV             WINEPREFIX=/home/container/.wine
ENV             WINEDLLOVERRIDES="mscoree,mshtml="
ENV             DISPLAY=:0
ENV             DISPLAY_WIDTH=1024
ENV             DISPLAY_HEIGHT=768
ENV             DISPLAY_DEPTH=16
ENV             AUTO_UPDATE=1
ENV             XVFB=1

RUN             xvfb-run -a winetricks -q win10

COPY            ./../entrypoint.sh /entrypoint.sh
CMD             [ "/bin/bash", "/entrypoint.sh" ]
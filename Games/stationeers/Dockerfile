FROM ghcr.io/ptero-eggs/steamcmd:debian AS upstream
FROM debian:trixie-slim
LABEL org.opencontainers.image.title="Cybrancee Stationeers Server"
LABEL org.opencontainers.image.source="https://cybrancee.com/learn/how-to-host-a-stationeers-server"
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates curl tar tini \
       libgcc-s1 libstdc++6 libgcc-s1:i386 libstdc++6:i386 libcurl4t64 libcurl4t64:i386 \
       libtinfo6 libtinfo6:i386 lib32z1 libicu76 libsdl2-2.0-0 libfontconfig1 \
       iproute2 net-tools numactl tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -d /home/container -s /bin/bash container
COPY --from=upstream /entrypoint.sh /entrypoint.sh
COPY entrypoint.sh /usr/local/bin/cybrancee-stationeers
RUN chmod 0755 /entrypoint.sh /usr/local/bin/cybrancee-stationeers
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container
STOPSIGNAL SIGINT
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/usr/local/bin/cybrancee-stationeers"]

FROM ghcr.io/ptero-eggs/steamcmd:debian

LABEL org.opencontainers.image.title="Cybrancee Killing Floor 2 Server"
LABEL org.opencontainers.image.description="Killing Floor 2 runtime with optional Steam Workshop configuration"
LABEL org.opencontainers.image.source="https://cybrancee.com/learn/how-to-host-a-killing-floor-2-server"

USER root
COPY entrypoint.sh /usr/local/bin/cybrancee-kf2
COPY workshop.sh /usr/local/bin/cybrancee-kf2-workshop
RUN chmod 0755 /usr/local/bin/cybrancee-kf2 /usr/local/bin/cybrancee-kf2-workshop \
    && test -r /entrypoint.sh

USER container
WORKDIR /home/container
ENTRYPOINT ["/usr/local/bin/cybrancee-kf2"]

FROM ghcr.io/ptero-eggs/steamcmd:debian

LABEL org.opencontainers.image.title="Cybrancee Eco Server"
LABEL org.opencontainers.image.description="Cybrancee runtime image for Eco Dedicated Server"
LABEL org.opencontainers.image.source="https://cybrancee.com/learn/how-to-host-an-eco-server"

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        coreutils \
        jq \
        libgdiplus \
        libc6-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --chown=container:container entrypoint.sh /usr/local/bin/cybrancee-eco
RUN chmod 0755 /usr/local/bin/cybrancee-eco

USER container

ENTRYPOINT ["/usr/local/bin/cybrancee-eco"]

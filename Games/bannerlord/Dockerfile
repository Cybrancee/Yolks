FROM ghcr.io/ptero-eggs/steamcmd:debian
LABEL org.opencontainers.image.title="Cybrancee Bannerlord Server"
LABEL org.opencontainers.image.description="Bannerlord Linux runtime with server authentication setup"
LABEL org.opencontainers.image.source="https://cybrancee.com/learn/how-to-host-a-mount-and-blade-ii-bannerlord-server"
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends libicu72 libssl3 libgssapi-krb5-2 libunwind8 \
    && rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh /usr/local/bin/cybrancee-bannerlord
RUN chmod 0755 /usr/local/bin/cybrancee-bannerlord
USER container
WORKDIR /home/container
STOPSIGNAL SIGINT
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/usr/local/bin/cybrancee-bannerlord"]

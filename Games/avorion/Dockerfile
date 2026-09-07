FROM ghcr.io/ptero-eggs/steamcmd:debian

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends libnss-wrapper \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/cybrancee-avorion-entrypoint
COPY passwd.template /usr/local/share/cybrancee/passwd.template
COPY group.template /usr/local/share/cybrancee/group.template
RUN chmod 0755 /usr/local/bin/cybrancee-avorion-entrypoint
ENTRYPOINT ["/usr/local/bin/cybrancee-avorion-entrypoint"]

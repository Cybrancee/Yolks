FROM ghcr.io/goover/wine:stable

USER root

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

USER container
WORKDIR /home/container

ENTRYPOINT ["/entrypoint.sh"]

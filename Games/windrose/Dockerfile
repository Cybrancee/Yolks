FROM ghcr.io/ptero-eggs/yolks:wine_latest

LABEL maintainer="Maximiliano Moldenhauer <hello@molret.dev>"
LABEL description="Windrose Dedicated Server Enhanced"

RUN apt-get update && apt-get install -y --no-install-recommends jq && rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /home/container/R5/Saved && \
    chown -R container:container /home/container 2>/dev/null || true

USER container
ENV USER=container HOME=/home/container

WORKDIR /home/container

CMD ["/bin/bash", "/entrypoint.sh"]

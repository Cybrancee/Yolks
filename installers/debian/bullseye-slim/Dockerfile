FROM        --platform=$TARGETOS/$TARGETARCH debian:bullseye-slim

LABEL       author="Cybrancee" maintainer="support@cybrancee.com"

LABEL       org.opencontainers.image.source="https://github.com/Cybrancee/Yolks"
LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND=noninteractive

RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i '/debian-security/d' /etc/apt/sources.list && \
    apt-get update -o Acquire::Check-Valid-Until=false && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

RUN     apt update && apt upgrade -y \
        && apt -y --no-install-recommends install curl

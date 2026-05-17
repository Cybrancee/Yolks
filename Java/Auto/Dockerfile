FROM --platform=$TARGETOS/$TARGETARCH debian:bookworm-slim

LABEL author="Cybrancee" maintainer="Support@cybrancee.com"

RUN apt-get update && apt-get install -y wget apt-transport-https gnupg lsb-release \
    && mkdir -p /etc/apt/keyrings \
    && wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor | tee /etc/apt/keyrings/adoptium.gpg > /dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/adoptium.list

RUN apt-get update && apt-get install -y \
    curl \
    lsof \
    ca-certificates \
    openssl \
    git \
    tar \
    sqlite3 \
    fontconfig \
    tzdata \
    iproute2 \
    libfreetype6 \
    tini \
    zip \
    unzip \
    libxrender1 \
    libxtst6 \
    libxi6 \
    temurin-8-jdk \
    temurin-11-jdk \
    temurin-17-jdk \
    temurin-21-jdk \
    temurin-25-jdk \
    ca-certificates curl fontconfig git iproute2 openssl sqlite3 tar tzdata


RUN useradd -m -d /home/container -s /bin/bash container
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD ["/bin/bash", "/entrypoint.sh"]
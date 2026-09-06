ARG BASE_IMAGE=ghcr.io/ptero-eggs/steamcmd:proton@sha256:c219f672cf6fedd11e811b7a41dc4ddab1fea659f77977bb956a939f2ef4e2a5
FROM ${BASE_IMAGE}

ARG GE_PROTON_VERSION=GE-Proton10-34
ARG GE_PROTON_SHA512=9fd0b2cfbd501c0b5c892239c392c7283a029b5e5d5a77d3f85b0ce190d555456241a18eebca16b53f094b403499201c13550a3f0b9b365e1a5eb5737cbb7303

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gawk \
        iproute2 \
        locales \
        procps \
        util-linux \
        xvfb \
    && sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    archive="/tmp/${GE_PROTON_VERSION}.tar.gz"; \
    curl --fail --location --show-error --silent \
        --retry 5 --retry-delay 3 \
        --output "${archive}" \
        "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${GE_PROTON_VERSION}/${GE_PROTON_VERSION}.tar.gz"; \
    printf '%s  %s\n' "${GE_PROTON_SHA512}" "${archive}" | sha512sum --check --strict; \
    mkdir -p /opt/cybrancee; \
    tar --extract --gzip --file "${archive}" --directory /opt/cybrancee; \
    mv "/opt/cybrancee/${GE_PROTON_VERSION}" /opt/cybrancee/proton; \
    rm -f "${archive}"; \
    mkdir -p /tmp/.X11-unix; \
    chmod 1777 /tmp/.X11-unix

COPY --chmod=0755 astroneer /usr/local/bin/astroneer

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PROTONFIXES_DISABLE=1 \
    PROTON_USE_XALIA=0

LABEL org.opencontainers.image.title="Cybrancee - Astroneer" \
      org.opencontainers.image.description="Astroneer Custom Image" \
      org.opencontainers.image.vendor="Cybrancee" \
      org.opencontainers.image.version="1.5.0"

USER container
WORKDIR /home/container

CMD ["/usr/local/bin/astroneer"]

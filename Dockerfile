FROM debian:bookworm-slim AS builder

LABEL org.opencontainers.image.description="the base image for building zwoo related images" 

WORKDIR /temp/zwooc

ENV ZWOOC_VERSION=1.1.1

# Download zwooc from GitHub releases
RUN apt-get update && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/* \
    && curl -L -o zwooc_linux_amd64.tar.gz "https://github.com/zwoo-hq/zwooc/releases/download/v$ZWOOC_VERSION/zwooc_linux_amd64.tar.gz" \
    && echo "c9e3b8e91a0ac75ec351bec935e9e49978d3a94405f30402ef6c70379ed796d1  zwooc_linux_amd64.tar.gz" | sha256sum -c - \
    && tar -xzf zwooc_linux_amd64.tar.gz -C ./ \
    && rm zwooc_linux_amd64.tar.gz \
    && chmod +x zwooc \
    && ./zwooc -h

FROM mcr.microsoft.com/dotnet/sdk:9.0.100-bookworm-slim-amd64

# Node 22, see: https://github.com/nodejs/docker-node/blob/main/22/bookworm-slim/Dockerfile

ENV NODE_VERSION=21.11.0

RUN groupadd --gid 1000 node \
    && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

RUN ARCH= OPENSSL_ARCH= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64' OPENSSL_ARCH='linux-x86_64';; \
    ppc64el) ARCH='ppc64le' OPENSSL_ARCH='linux-ppc64le';; \
    s390x) ARCH='s390x' OPENSSL_ARCH='linux*-s390x';; \
    arm64) ARCH='arm64' OPENSSL_ARCH='linux-aarch64';; \
    armhf) ARCH='armv7l' OPENSSL_ARCH='linux-armv4';; \
    i386) ARCH='x86' OPENSSL_ARCH='linux-elf';; \
    *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && set -ex \
    # libatomic1 for arm
    && apt-get update && apt-get install -y ca-certificates curl wget gnupg dirmngr xz-utils libatomic1 --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    # use pre-existing gpg directory, see https://github.com/nodejs/docker-node/pull/1895#issuecomment-1550389150
    && export GNUPGHOME="$(mktemp -d)" \
    # gpg keys listed at https://github.com/nodejs/node#release-keys
    && for key in \
    C0D6248439F1D5604AAFFB4021D900FFDB233756 \
    DD792F5973C6DE52C432CBDAC77ABFA00DDBF2B7 \
    CC68F5A3106FF448322E48ED27F5E38D5B0A215F \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    890C08DB8579162FEE0DF9DB8BEAB4DFCF555EF4 \
    C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
    108F52B48DB57BB0CC439B2997B01419BD92F80A \
    A363A499291CBBC940DD62E41F10027AF002F8B0 \
    ; do \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
    done \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    # Remove unused OpenSSL headers to save ~34MB. See this NodeJS issue: https://github.com/nodejs/node/issues/46451
    && find /usr/local/include/node/openssl/archs -mindepth 1 -maxdepth 1 ! -name "$OPENSSL_ARCH" -exec rm -rf {} \; \
    && apt-mark auto '.*' > /dev/null \
    && find /usr/local -type f -executable -exec ldd '{}' ';' \
    | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
    | sort -u \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u \
    | xargs -r apt-mark manual \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
    # smoke tests
    && node --version \
    && npm --version

# Instal dotnet wasm dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    libatomic1 \
    python3 \
    libicu72 \
    wget \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /temp/zwooc/zwooc /usr/local/bin/zwooc
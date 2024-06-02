FROM ubuntu:22.04

# Install dependencies

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y --no-install-recommends  \
    # dotnet 8 dependencies
    wget \
    ca-certificates \
    libc6 \
    libgcc-s1 \
    libgssapi-krb5-2 \
    libicu70 \
    liblttng-ust1 \
    libssl3 \
    libstdc++6 \
    libunwind8 \
    zlib1g \
    # dotnet wasm-tools dependencies
    libatomic1 \
    python3 \
    # for installing nodejs
    curl \
    sudo

# install nodejs
# https://github.com/nodesource/distributions?tab=readme-ov-file#using-ubuntu-1
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - \
    && apt-get install -y nodejs


# install dotnet 8
# https://github.com/dotnet/dotnet-docker/blob/main/documentation/scenarios/installing-dotnet.md#installing-from-a-linux-package-manager
RUN wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    # Install .NET
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    dotnet-sdk-8.0 aspnetcore-runtime-8.0 \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

# install dotnet workloads
RUN dotnet workload install wasm-tools
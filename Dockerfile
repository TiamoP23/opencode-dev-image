FROM ubuntu:24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ARG OPENCODE_UID=1000
ARG OPENCODE_GID=1000
ARG NODE_MAJOR=22
ARG DENO_VERSION=2.6.1
ARG KOTLIN_VERSION=2.2.21
ARG PLAYWRIGHT_VERSION=1.61.1

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=/home/opencode/.cargo/bin:/home/opencode/.deno/bin:/home/opencode/.bun/bin:/home/opencode/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin \
    PLAYWRIGHT_BROWSERS_PATH=/home/opencode/.cache/ms-playwright

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        zsh \
        fish \
        sudo \
        tzdata \
        locales \
        ca-certificates \
        gnupg \
        lsb-release \
        software-properties-common \
        curl \
        wget \
        git \
        git-lfs \
        openssh-client \
        rsync \
        unzip \
        zip \
        tar \
        gzip \
        xz-utils \
        less \
        nano \
        vim \
        jq \
        yq \
        ripgrep \
        fd-find \
        tree \
        bat \
        fzf \
        direnv \
        just \
        build-essential \
        pkg-config \
        cmake \
        ninja-build \
        make \
        gdb \
        lldb \
        clang \
        llvm \
        libssl-dev \
        zlib1g-dev \
        libsqlite3-dev \
        libffi-dev \
        libreadline-dev \
        libbz2-dev \
        liblzma-dev \
        iproute2 \
        iputils-ping \
        dnsutils \
        netcat-openbsd \
        telnet \
        traceroute \
        tcpdump \
        nmap \
        httpie \
        whois \
        procps \
        psmisc \
        lsof \
        strace \
        htop \
        ncdu \
        duf \
        file \
        time \
        xxd \
        podman \
        podman-compose \
        skopeo \
        crun \
        python3 \
        python3-pip \
        python3-venv \
        pipx \
        openjdk-21-jdk-headless \
        libasound2t64 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libatspi2.0-0 \
        libcairo2 \
        libcups2 \
        libdbus-1-3 \
        libdrm2 \
        libgbm1 \
        libglib2.0-0 \
        libgtk-3-0 \
        libnspr4 \
        libnss3 \
        libpango-1.0-0 \
        libx11-6 \
        libxcb1 \
        libxcomposite1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxkbcommon0 \
        libxrandr2 \
        xvfb \
    && locale-gen C.UTF-8 \
    && git lfs install --system \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && ln -sf /usr/bin/batcat /usr/local/bin/bat \
    && rm -rf /var/lib/apt/lists/*

RUN install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && corepack enable \
    && npx -y "playwright@${PLAYWRIGHT_VERSION}" install-deps \
    && npx -y "playwright@${PLAYWRIGHT_VERSION}" install chrome \
    && npm install -g opencode-ai@latest \
    && rm -rf /var/lib/apt/lists/* /root/.npm

RUN existing_group="$(getent group "${OPENCODE_GID}" | cut -d: -f1 || true)" \
    && if [ -n "${existing_group}" ] && [ "${existing_group}" != opencode ]; then groupmod --new-name opencode "${existing_group}"; elif [ -z "${existing_group}" ]; then groupadd --gid "${OPENCODE_GID}" opencode; fi \
    && existing_user="$(getent passwd "${OPENCODE_UID}" | cut -d: -f1 || true)" \
    && if [ -n "${existing_user}" ] && [ "${existing_user}" != opencode ]; then usermod --login opencode --home /home/opencode --move-home --shell /bin/bash "${existing_user}"; elif [ -z "${existing_user}" ]; then useradd --uid "${OPENCODE_UID}" --gid "${OPENCODE_GID}" --create-home --shell /bin/bash opencode; fi \
    && usermod --gid "${OPENCODE_GID}" opencode \
    && install -d -o opencode -g opencode /home/workspace \
    && install -d -o opencode -g opencode /home/opencode/.config/opencode \
    && install -d -o opencode -g opencode /home/opencode/.local/share/opencode \
    && install -d -o opencode -g opencode /home/opencode/.local/state/opencode \
    && install -d -o opencode -g opencode /home/opencode/.cache/opencode \
    && chown -R opencode:opencode /home/opencode /home/workspace \
    && echo 'opencode ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/opencode \
    && chmod 0440 /etc/sudoers.d/opencode

ENV HOME=/home/opencode

USER opencode
WORKDIR /home/opencode

RUN curl -fsSL https://bun.sh/install | bash \
    && curl -fsSL https://deno.land/install.sh | sh -s -- "v${DENO_VERSION}" \
    && curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable \
    && python3 -m pipx ensurepath \
    && pipx install uv \
    && curl -fsSLo /tmp/kotlin.zip "https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip" \
    && unzip -q /tmp/kotlin.zip -d /home/opencode/.local \
    && rm /tmp/kotlin.zip \
    && mkdir -p /home/opencode/.local/bin \
    && ln -sf /home/opencode/.local/kotlinc/bin/kotlin /home/opencode/.local/bin/kotlin \
    && ln -sf /home/opencode/.local/kotlinc/bin/kotlinc /home/opencode/.local/bin/kotlinc

WORKDIR /home/workspace

CMD ["opencode", "--help"]

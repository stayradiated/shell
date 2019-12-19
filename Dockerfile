FROM phusion/baseimage:0.11 as base

# TERM environment
ENV TERM=xterm-256color

# use latest version of git
RUN add-apt-repository ppa:git-core/ppa

# Do not exclude man pages & other documentation
RUN rm /etc/dpkg/dpkg.cfg.d/excludes

# Reinstall all currently installed packages in order to get the man pages back
RUN apt-get update && \
    dpkg -l | grep ^ii | cut -d' ' -f3 | xargs apt-get install -y --reinstall && \
    rm -r /var/lib/apt/lists/*

# Requirements for building dependencies
RUN apt-get update && apt-get install -y \
  acpi \
  apt-transport-https \
  build-essential \
  ca-certificates \
  curl \
  dbus-x11 \
  dnsutils \
  exfat-fuse \
  fontconfig \
  git \
  iputils-ping \
  jq \
  libevent-dev \
  libgl1-mesa-dri \
  libgl1-mesa-glx \
  libncurses5-dev \
  libpulse0 \
  libssl-dev \
  libxv1 \
  locales  \
  man \
  mesa-utils \
  mesa-utils-extra \
  net-tools \
  netcat-openbsd \
  pkg-config \
  psmisc \
  pulseaudio \
  python-pip \
  python3-pip \
  socat \
  software-properties-common \
  tzdata \
  unzip \
  wget \
  x11-utils \
  x11-xkb-utils \
  x11-xserver-utils \
  xclip \
  xdg-utils \
  xdo \
  xfonts-utils \
  zip \
  zsh

# Install Docker-CE
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable" && \
  apt-get update && \
  apt-get install -y docker-ce

# configure fonts
RUN cd /etc/fonts/conf.d && \
  rm 10* 70-no-bitmaps.conf && \
  ln -s ../conf.avail/70-yes-bitmaps.conf . && \
  dpkg-reconfigure fontconfig && \
  fc-cache -fv

# Locales
ENV LANGUAGE=en_NZ.UTF-8
ENV LANG=en_NZ.UTF-8
ENV LC_CTYPE=en_NZ.UTF-8
ENV LC_ALL=en_NZ.UTF-8
RUN locale-gen en_NZ.UTF-8

# Setup root shell
RUN chsh -s /usr/bin/zsh
WORKDIR /root

###
### apps
###

# Rust
FROM base as rust
ARG RUST_VERSION=1.38.0
RUN \
  wget -O rust.sh "https://sh.rustup.rs" && \
  sh rust.sh -y --default-toolchain "${RUST_VERSION}" && \
  rm rust.sh
ENV PATH /root/.cargo/bin:$PATH
RUN \
  cargo install --version 0.6.5 sd && \
  cargo install --version 7.4.0 fd-find && \
  cargo install --version 11.0.2 ripgrep && \
  cargo install --version 0.1.15 chit

# ALACRITTY
FROM rust as alacritty
ARG ALACRITTY_VERSION=v0.3.3
RUN apt-get update && apt-get install -y \
  cmake \
  pkg-config \
  libfreetype6-dev \
  libfontconfig1-dev \
  libxcb-xfixes0-dev \
  xclip
RUN git clone --depth 1 https://github.com/jwilm/alacritty && \
  cd alacritty && \
  git fetch --depth 1 origin tag "${ALACRITTY_VERSION}" && \
  git reset --hard "${ALACRITTY_VERSION}" && \
  cargo build --release

# Docker Compose
FROM base as docker-compose
ARG DOCKER_COMPOSE_VERSION=1.24.0
RUN wget -O docker-compose "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64" && \
  chmod +x docker-compose && \
  mv docker-compose /usr/local/bin/docker-compose

# GO
FROM base as go
ARG GO_VERSION=1.13.4
RUN wget -O go.tgz "https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz" && \
  tar xzvf go.tgz && \
  mv go /usr/local/go && \
  rm -rf go.tgz
ENV PATH "/usr/local/go/bin:${PATH}"

# GO >> CLONE
FROM go as clone
ENV GOPATH /usr/local
WORKDIR /usr/local/src
RUN git clone https://github.com/stayradiated/clone && \
  cd clone && \
  go install && \
  rm -rf /usr/local/src/github.com

# TMUX
FROM base as tmux
ARG TMUX_VERSION=2.8
RUN wget -O tmux.tgz "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz" && \
  tar xzvf tmux.tgz && \
  cd "tmux-${TMUX_VERSION}" && \
  ./configure && \
  make && \
  make install && \
  cd .. && \
  rm -rf tmux tmux.tgz

# NEOVIM
FROM base as neovim
WORKDIR /usr/local/src
RUN apt-get update && apt-get install -y \
  autoconf \
  automake \
  cmake \
  g++ \
  gettext \
  libtool \
  libtool-bin \
  ninja-build \
  pkg-config \
  texinfo
ARG NEOVIM_VERSION=v0.4.2
RUN git clone --depth 1 https://github.com/neovim/neovim && \
  cd neovim && \
  git fetch --depth 1 origin tag "${NEOVIM_VERSION}" && \
  git reset --hard "${NEOVIM_VERSION}" && \
  make CMAKE_BUILD_TYPE=Release && \
  make install && \
  cd .. && \
  rm -rf neovim

# DOTFILES
FROM base as dotfiles
ARG DOTFILES_VERSION=v1.4.12
RUN git clone https://github.com/stayradiated/dotfiles && \
  cd dotfiles && \
  git fetch && \
  git reset --hard "${DOTFILES_VERSION}"

# FZF
FROM base as fzf
ARG FZF_VERSION=0.17.0
RUN mkdir -p /home/admin && \
  git clone --depth=1 https://github.com/junegunn/fzf /home/admin/.fzf && \
  cd /home/admin/.fzf && \
  git fetch --depth 1 origin tag "${FZF_VERSION}" && \
  git reset --hard "${FZF_VERSION}" && \
  ./install --all && \
  cd && \
  mv /home/admin/.fzf /root/.fzf

# NODE
FROM base as nvm
ARG NVM_VERSION=v0.35.1
ARG NODE_VERSION=v13.0.1
RUN git clone --depth 1 https://github.com/creationix/nvm && \
  cd nvm && \
  git fetch --depth 1 origin tag $NVM_VERSION && \
  git reset --hard $NVM_VERSION && \
  bash -c "source nvm.sh && nvm install ${NODE_VERSION}" && \
  mv "versions/node/${NODE_VERSION}" /usr/local/lib/node
ENV PATH "/usr/local/lib/node/bin:${PATH}"
COPY ./files/.npmrc /root/.npmrc
RUN apt-get install -y libsecret-1-dev
RUN npm config set user root && npm config set save-exact true && npm install -g \
  @mishguru/admincli@1.19.0 \
  @mishguru/fandex@0.6.0 \
  @mishguru/ghostphone@5.0.0 \
  @mishguru/jadx-node@3.0.0 \
  @mishguru/logview-cli@4.6.0 \
  @mishguru/mish@3.4.0 \
  @mishguru/passwd@3.2.0 \
  diff-so-fancy@1.2.7 \
  lerna@3.19.0 \
  npm-check-updates@4.0.1 \
  release-it@12.4.3 \
  tagrelease@1.0.1 \
  yarn@1.21.1

# RANCHER
FROM base as rancher
ARG RANCHER_VERSION=v2.2.0
RUN wget -O rancher.tgz "https://github.com/rancher/cli/releases/download/${RANCHER_VERSION}/rancher-linux-amd64-${RANCHER_VERSION}.tar.gz" && \
  tar xzvf rancher.tgz && \
  mv "rancher-${RANCHER_VERSION}/rancher" /usr/local/bin/rancher && \
  chmod +x /usr/local/bin/rancher && \
  rm -rf "rancher-${RANCHER_VERSION}"

# HUB
FROM base as hub
ARG HUB_VERSION=2.11.2
RUN wget -O hub.tgz "https://github.com/github/hub/releases/download/v${HUB_VERSION}/hub-linux-amd64-${HUB_VERSION}.tgz" && \
  tar xzvf hub.tgz && \
  cd "hub-linux-amd64-${HUB_VERSION}" && \
  mv bin/hub /usr/local/bin/hub && \
  cd .. && \
  rm -rf "hub-linux-amd64-${HUB_VERSION}" hub.tgz

# Z.LUA
FROM base as zlua
ARG ZLUA_VERSION=1.7.0
RUN wget "https://raw.githubusercontent.com/skywind3000/z.lua/v${ZLUA_VERSION}/z.lua"

# PRETTYPING
FROM base as prettyping
RUN wget https://raw.githubusercontent.com/denilsonsa/prettyping/master/prettyping && \
  chmod +x prettyping && \
  mv prettyping /usr/local/bin/prettyping

# BAT
FROM base as bat
ARG BAT_VERSION=0.10.0
RUN wget -O bat.tgz "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu.tar.gz" && \
  tar xzvf bat.tgz && \
  mv "bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu/bat" /usr/local/bin/bat && \
  rm -rf "bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu" bat.tgz

# ADB
# https://developer.android.com/studio/releases/platform-tools
FROM base as adb
ARG TOOLS_VESRION=29.0.5
RUN wget -O tools.zip "https://dl.google.com/android/repository/platform-tools_r${TOOLS_VESRION}-linux.zip" && \
  unzip tools.zip && \
  mv platform-tools/adb /usr/local/bin/adb && \
  mv platform-tools/fastboot /usr/local/bin/fastboot && \
  rm -rf platform-tools

# NGROK
FROM base as ngrok
RUN wget -O ngrok.zip "https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip" && \
  unzip ngrok.zip && \
  mv ngrok /usr/local/bin/ngrok && \
  rm ngrok.zip

# FONTS:GOMME
FROM base as gomme
RUN mkdir -p gomme/ && cd gomme/ && \
  wget -O gomme.bdf "https://raw.githubusercontent.com/Tecate/bitmap-fonts/master/bitmap/gomme/Gomme10x20n.bdf"

# LIGHT
FROM base as light
RUN wget -O light.deb "https://github.com/haikarainen/light/releases/download/v1.2/light_1.2_amd64.deb" && \
  dpkg -i light.deb && \
  rm light.deb

# ETCHER
FROM base as etcher
ARG ETCHER_VERSION=1.5.63
RUN wget -O etcher.zip "https://github.com/balena-io/etcher/releases/download/v${ETCHER_VERSION}/balena-etcher-electron-${ETCHER_VERSION}-linux-ia32.zip" && \
  unzip etcher.zip && \
  mv balenaEtcher-*.AppImage etcher && \
  rm etcher.zip

# BSPWM
FROM base as bspwm
ARG BSPWM_VERSION=0.9.9
RUN \
  apt-get install -y \
    libxcb-ewmh-dev \
    libxcb-icccm4-dev \
    libxcb-keysyms1-dev \
    libxcb-randr0-dev \
    libxcb-shape0-dev \
    libxcb-util-dev \
    libxcb-xinerama0-dev \
    && \
  git clone --depth 1 https://github.com/baskerville/bspwm && \
  cd bspwm && \
  git fetch --depth 1 origin tag "${BSPWM_VERSION}" && \
  git reset --hard "${BSPWM_VERSION}" && \
  make all

# SXHKD
FROM base as sxhkd
ARG SXHKD_VERSION=0.6.1
RUN \
  apt-get install -y \
    libxcb-util-dev \
    libxcb-keysyms1-dev \
    && \
  git clone --depth 1 https://github.com/baskerville/sxhkd && \
  cd sxhkd && \
  git fetch --depth 1 origin tag "${SXHKD_VERSION}" && \
  git reset --hard "${SXHKD_VERSION}" && \
  make all

###
### the real deal
###

FROM base as shell

# weechat ppa
RUN apt-key adv \
  --keyserver hkp://p80.pool.sks-keyservers.net:80 \
  --recv-keys 11E9DE8848F2B65222AA75B8D1820DB22A11534E && \
  add-apt-repository \
    "deb [arch=amd64] https://weechat.org/ubuntu \
    $(lsb_release -cs) \
    main"

# prolog ppa
RUN apt-add-repository ppa:swi-prolog/stable

# install apps
RUN apt-get update && apt-get install -y \
  aria2=1.33.\* \
  audacity \
  bs1770gain=0.4.\* \
  chromium-browser=79.0* \
  ddgr \
  ffmpeg=7:3\* \
  firefox=71.0+* \
  fonts-noto \
  fonts-noto-cjk \
  fonts-noto-color-emoji \
  gnome-keyring \
  graphicsmagick \
  gthumb \
  htop \
  httpie \
  libsecret-1-dev \
  lua5.3 \
  mediainfo \
  mkvtoolnix \
  moreutils \
  mysql-client \
  nmap \
  nnn \
  openjdk-11-jre \
  pandoc \
  pdd \
  pv \
  qpdfview \
  ranger \
  redshift \
  rofi \
  rsync \
  safe-rm \
  scrot \
  sudo \
  swi-prolog \
  tig \
  tree \
  ttf-ubuntu-font-family \
  urlview=0.9-20\* \
  vlc \
  weechat-curses \
  weechat-perl \
  weechat-plugins \
  weechat-python && \
  apt-get clean

# setup admin user
RUN useradd -s /usr/bin/zsh --create-home admin && \
  echo "admin:admin" | chpasswd && \
  adduser admin sudo && \
  mkdir -p /home/admin/bin

# switch to admin
USER admin
WORKDIR /home/admin

# beets, mycli, awsli
RUN pip3 install --user beets requests pylast eyeD3 mycli awscli td-watson

###
### COPY LARGE DIRECTORIES
###

# GO
COPY --from=go /usr/local/go /usr/local/go

# NODE
COPY --from=nvm --chown=admin:admin /usr/local/lib/node /usr/local/lib/node

# NEOVIM
COPY --from=neovim /usr/local/bin/nvim /usr/local/bin/nvim
COPY --from=neovim /usr/local/share/nvim /usr/local/share/nvim
RUN pip install --user neovim && \
  pip3 install --user neovim && \
  pip install --user pynvim && \
  nvim +UpdateRemotePlugins +qall

###
### COPY SINGLE BINARIES
###

# FONTS
COPY --from=gomme /root/gomme /usr/share/fonts/X11/gomme

# ETCHER
COPY --from=etcher /root/etcher /usr/local/bin/etcher

# BSPWM
COPY --from=bspwm /root/bspwm/bspwm /usr/local/bin/bspwm

# SXHKD
COPY --from=sxhkd /root/sxhkd/sxhkd /usr/local/bin/sxhkd

# LIGHT
COPY --from=light /usr/bin/light /usr/local/bin/light

# RUST TOOLS 
COPY --from=rust --chown=admin:admin /root/.cargo/bin/* /usr/local/bin/

# ALACRITTY
COPY --from=alacritty --chown=admin:admin /root/alacritty/target/release/alacritty /usr/local/bin/alacritty

# DOCKER-COMPOSE
COPY --from=docker-compose /usr/local/bin/docker-compose /usr/local/bin/docker-compose

# ADB
COPY --from=adb /usr/local/bin/fastboot /usr/local/bin/adb /usr/local/bin/

# BAT
COPY --from=bat /usr/local/bin/bat /usr/local/bin/bat

# TMUX
COPY --from=tmux /usr/local/bin/tmux /usr/local/bin/tmux

# FZF
COPY --from=fzf --chown=admin:admin /root/.fzf /home/admin/.fzf
COPY --from=fzf --chown=admin:admin /root/.fzf.zsh /home/admin/.fzf.zsh

# CLONE
COPY --from=clone --chown=admin:admin /usr/local/bin/clone /usr/local/bin/clone

# HUB
COPY --from=hub --chown=admin:admin /usr/local/bin/hub /usr/local/bin/hub

# Z.LUA
copy --from=zlua --chown=admin:admin /root/z.lua /home/admin/bin/z.lua

# PRETTYPING
COPY --from=prettyping --chown=admin:admin /usr/local/bin/prettyping /usr/local/bin/prettyping

# rancher
COPY --from=rancher --chown=admin:admin /usr/local/bin/rancher /usr/local/bin/rancher

# ngrok
COPY --from=ngrok --chown=admin:admin /usr/local/bin/ngrok /usr/local/bin/ngrok

###
### FINISHING UP
###

# copy files
COPY --chown=admin:admin ./files ./

# allow certain ssh hosts
RUN ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts && \
  ssh-keyscan -t rsa bitbucket.org >> ~/.ssh/known_hosts

# dotfiles
COPY --chown=admin:admin --from=dotfiles /root/dotfiles /home/admin/dotfiles
RUN cd dotfiles && \
  make apps && \
  cd ../.zprezto && \
  git pull --rebase && \
  nvim +'call dein#update()' +GoInstallBinaries +UpdateRemotePlugins +qall 

RUN \
  echo 'export GOPATH=/home/admin' >> /home/admin/.zpath && \
  echo 'export GOROOT=/usr/local/go' >> /home/admin/.zpath && \
  echo 'export PATH=/home/admin/bin:/home/admin/.local/bin:/home/admin/.cargo/bin:/usr/local/lib/node/bin:/home/admin/.yarn/bin:/usr/local/go/bin:$PATH' >> /home/admin/.zpath

ENV PULSE_SERVER /run/pulse/native

CMD /home/admin/.xinitrc

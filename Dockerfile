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

# CRYSTAL 
FROM base as crystal
ARG CRYSTAL_VERSION=0.32.1
RUN \
  wget -O crystal.tgz "https://github.com/crystal-lang/crystal/releases/download/${CRYSTAL_VERSION}/crystal-${CRYSTAL_VERSION}-1-linux-x86_64.tar.gz" && \
  tar xzvf crystal.tgz && \
  mv "crystal-${CRYSTAL_VERSION}-1" crystal

# GIT CRYPT
FROM base as git-crypt
ARG GIT_CRYPT_VERSION=0.6.0
RUN \
  # xsltproc is required to build the man files
  apt-get install -y xsltproc && \
  wget -O git-crypt.tgz "https://www.agwa.name/projects/git-crypt/downloads/git-crypt-${GIT_CRYPT_VERSION}.tar.gz" && \
  tar xzvf git-crypt.tgz && \
  rm -rf git-crypt.tgz && \
  mv "git-crypt-${GIT_CRYPT_VERSION}" git-crypt && \
  cd git-crypt && \
  ENABLE_MAN=yes make && \
  make install

# RUST
FROM base as rust
ARG RUST_VERSION=1.40.0
RUN \
  wget -O rust.sh "https://sh.rustup.rs" && \
  sh rust.sh -y --default-toolchain "${RUST_VERSION}" && \
  rm rust.sh
ENV PATH /root/.cargo/bin:$PATH
# install a package to prime the crates.io index
# chit is also really useful for checking if a new version of a crate exists
ARG CHIT_VERSION=0.1.15
RUN cargo install --version "${CHIT_VERSION}" chit

# RUST >> BR
FROM rust as br
ARG BR_VERSION=0.11.5
RUN cargo install --version "${BR_VERSION}" broot

# RUST >> FD
FROM rust as fd
ARG FD_VERSION=7.4.0
RUN cargo install --version "${FD_VERSION}" fd-find

# RUST >> RG
FROM rust as rg
ARG RG_VERSION=11.0.2
RUN cargo install --version "${RG_VERSION}" ripgrep

# RUST >> SD
FROM rust as sd
ARG SD_VERSION=0.6.5
RUN cargo install --version "${SD_VERSION}" sd

# RUST >> BANDWHICH
FROM rust as bandwhich
ARG BANDWHICH_VERSION=0.8.0
RUN cargo install --version "${BANDWHICH_VERSION}" bandwhich

# ALACRITTY
FROM rust as alacritty
ARG ALACRITTY_VERSION=v0.4.2
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

## ANKI
FROM base as anki
ARG ANKI_VERSION=2.1.19
RUN wget -O anki.tar "https://apps.ankiweb.net/downloads/current/anki-${ANKI_VERSION}-linux-amd64.tar.bz2" && \
  tar xjvf anki.tar && \
  mv "anki-${ANKI_VERSION}-linux-amd64" anki && \
  cd anki && \
  make install && \
  cd .. && \
  rm -r anki anki.tar

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

# GO >> 1PW
FROM go as onepw
ENV GOPATH /usr/local
RUN \
  go get github.com/special/1pw && \
  go install github.com/special/1pw && \
  rm -rf src

# GCLOUD
FROM base as gcloud
ARG GCLOUD_VERSION=274.0.0
RUN wget -O gcloud.tgz "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz" && \
  tar xzvf gcloud.tgz && \
  mv google-cloud-sdk /usr/local/ && \
  rm -rf gcloud.tgz

# TMUX
FROM base as tmux
ARG TMUX_VERSION=3.0a
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
ARG NEOVIM_VERSION=v0.4.3
RUN git clone --depth 1 https://github.com/neovim/neovim && \
  cd neovim && \
  git fetch --depth 1 origin tag "${NEOVIM_VERSION}" && \
  git reset --hard "${NEOVIM_VERSION}" && \
  make CMAKE_BUILD_TYPE=Release && \
  make install && \
  cd .. && \
  rm -rf neovim

# DOTFILES
FROM git-crypt as dotfiles
ARG DOTFILES_VERSION=v1.5.16
COPY ./files/secret-key /root/secret-key
RUN git clone --depth 1 https://github.com/stayradiated/dotfiles && \
  cd dotfiles && \
  git fetch --depth 1 origin tag "${DOTFILES_VERSION}" && \
  git reset --hard "${DOTFILES_VERSION}" && \
  git-crypt unlock ~/secret-key

# FZF
FROM base as fzf
ARG FZF_VERSION=0.21.0
RUN mkdir -p /home/admin && \
  git clone --depth=1 https://github.com/junegunn/fzf /home/admin/.fzf && \
  cd /home/admin/.fzf && \
  git fetch --depth 1 origin tag "${FZF_VERSION}" && \
  git reset --hard "${FZF_VERSION}" && \
  ./install --all && \
  cd && \
  mv /home/admin/.fzf /root/.fzf

# DENO
FROM base as deno
ARG DENO_VERSION=v0.35.0
RUN wget -O deno.gz "https://github.com/denoland/deno/releases/download/${DENO_VERSION}/deno_linux_x64.gz" && \
  gunzip -df deno.gz && \
  chmod +x deno

# NODE
FROM base as nvm
ARG NVM_VERSION=v0.35.3
ARG NODE_VERSION=v13.12.0
RUN git clone --depth 1 https://github.com/creationix/nvm && \
  cd nvm && \
  git fetch --depth 1 origin tag $NVM_VERSION && \
  git reset --hard $NVM_VERSION && \
  bash -c "source nvm.sh && nvm install ${NODE_VERSION}" && \
  mv "versions/node/${NODE_VERSION}" /usr/local/lib/node
ENV PATH "/usr/local/lib/node/bin:${PATH}"
COPY ./files/.npmrc /root/.npmrc
RUN apt-get update && apt-get install -y libsecret-1-dev
RUN npm config set user root && npm config set save-exact true && npm install -g \
  castnow@0.6.0 \
  diff-so-fancy@1.2.7 \
  lerna@3.20.2 \
  npm-check-updates@4.1.1 \
  expo-cli@3.17.8 \
  np@6.2.0 \
  public-ip-cli@2.0.0 \
  yarn@1.22.4

# GH
FROM base as gh
ARG GH_VERSION=0.6.4
RUN wget -O gh.tgz "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" && \
  tar xzvf gh.tgz && \
  cd "gh_${GH_VERSION}_linux_amd64" && \
  mv bin/gh /usr/local/bin/gh && \
  cd .. && \
  rm -rf "gh_${GH_VERSION}_linux_amd64" gh.tgz

# Z.LUA
FROM base as zlua
ARG ZLUA_VERSION=1.8.4
RUN wget "https://raw.githubusercontent.com/skywind3000/z.lua/${ZLUA_VERSION}/z.lua"

# PRETTYPING
FROM base as prettyping
RUN wget https://raw.githubusercontent.com/denilsonsa/prettyping/master/prettyping && \
  chmod +x prettyping && \
  mv prettyping /usr/local/bin/prettyping

# BAT
FROM base as bat
ARG BAT_VERSION=0.13.0
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

# FONTS:bitmapfonts
FROM base as fonts
RUN mkdir -p bitmap/ && cd bitmap/ && \
  wget -O gomme.bdf "https://raw.githubusercontent.com/Tecate/bitmap-fonts/master/bitmap/gomme/Gomme10x20n.bdf" && \
  wget -O terminal.bdf "https://raw.githubusercontent.com/Tecate/bitmap-fonts/master/bitmap/dylex/7x13.bdf"

# LIGHT
FROM base as light
RUN wget -O light.deb "https://github.com/haikarainen/light/releases/download/v1.2/light_1.2_amd64.deb" && \
  dpkg -i light.deb && \
  rm light.deb

# ETCHER
FROM base as etcher
ARG ETCHER_VERSION=1.5.73
RUN wget -O etcher.zip "https://github.com/balena-io/etcher/releases/download/v${ETCHER_VERSION}/balena-etcher-electron-${ETCHER_VERSION}-linux-x64.zip" && \
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

### ANTIBODY
FROM base as antibody
RUN curl -sfL git.io/antibody | sh -s - -b /usr/local/bin

### CHARLES PROXY
FROM base as charles
ARG CHARLES_VERSION="4.5.6"
RUN \
  wget -O charles.tgz "https://www.charlesproxy.com/assets/release/${CHARLES_VERSION}/charles-proxy-${CHARLES_VERSION}_amd64.tar.gz" && \
  tar xzvf charles.tgz && \
  rm charles.tgz

### SQLITE3

FROM base as sqlite3
ARG SQLITE_VERSION="3310100"
RUN \
  wget -O sqlite.tgz "https://sqlite.org/2020/sqlite-autoconf-${SQLITE_VERSION}.tar.gz" && \
  tar xzvf sqlite.tgz && \
  rm sqlite.tgz && \
  cd "sqlite-autoconf-${SQLITE_VERSION}" && \
  ./configure --prefix=/usr     \
              --disable-static  \
              --enable-fts5     \
              CFLAGS="-g -O2                    \
              -DSQLITE_ENABLE_FTS3=1            \
              -DSQLITE_ENABLE_FTS4=1            \
              -DSQLITE_ENABLE_COLUMN_METADATA=1 \
              -DSQLITE_ENABLE_UNLOCK_NOTIFY=1   \
              -DSQLITE_ENABLE_DBSTAT_VTAB=1     \
              -DSQLITE_SECURE_DELETE=1          \
              -DSQLITE_ENABLE_FTS3_TOKENIZER=1" && \
  make && \
  make install

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

# PPAs
RUN \
  # PROLOG
  apt-add-repository ppa:swi-prolog/stable && \
  # OLIVER EDITOR
  add-apt-repository ppa:olive-editor/olive-editor

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
  olive-editor \
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
  adduser admin sudo

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

# DENO
COPY --from=deno --chown=admin:admin /root/deno /usr/local/bin/deno

# NODE
COPY --from=nvm --chown=admin:admin /usr/local/lib/node /usr/local/lib/node

# NEOVIM
COPY --from=neovim /usr/local/bin/nvim /usr/local/bin/nvim
COPY --from=neovim /usr/local/share/nvim /usr/local/share/nvim
RUN pip install --user neovim && \
  pip3 install --user neovim msgpack && \
  pip install --user pynvim && \
  nvim +UpdateRemotePlugins +qall

###
### COPY SINGLE BINARIES
###

# FONTS
COPY --from=fonts /root/bitmap /usr/share/fonts/X11/bitmap

# ETCHER
COPY --from=etcher /root/etcher /usr/local/bin/etcher

# BSPWM
COPY --from=bspwm /root/bspwm/bspc /root/bspwm/bspwm /usr/local/bin/
COPY --from=bspwm /root/bspwm/doc/bspwm.1 /root/bspwm/doc/bspc.1 /usr/local/share/man1/

# SXHKD
COPY --from=sxhkd /root/sxhkd/sxhkd /usr/local/bin/sxhkd

# LIGHT
COPY --from=light /usr/bin/light /usr/local/bin/light

# RUST TOOLS 
COPY --from=rust --chown=admin:admin /root/.cargo /home/admin/.cargo
COPY --from=rust --chown=admin:admin /root/.rustup /home/admin/.rustup
COPY --from=br --chown=admin:admin /root/.cargo/bin/broot /usr/local/bin
COPY --from=fd --chown=admin:admin /root/.cargo/bin/fd /usr/local/bin
COPY --from=rg --chown=admin:admin /root/.cargo/bin/rg /usr/local/bin
COPY --from=sd --chown=admin:admin /root/.cargo/bin/sd /usr/local/bin
COPY --from=bandwhich --chown=admin:admin /root/.cargo/bin/bandwhich /usr/local/bin

# ALACRITTY
COPY --from=alacritty --chown=admin:admin /root/alacritty/target/release/alacritty /usr/local/bin/alacritty

# CRYSTAL
COPY --from=crystal --chown=admin:admin /root/crystal/ /usr/local/

# GCLOUD
COPY --from=gcloud --chown=admin:admin /usr/local/google-cloud-sdk /usr/local/google-cloud-sdk

# DOCKER-COMPOSE
COPY --from=docker-compose /usr/local/bin/docker-compose /usr/local/bin/docker-compose

# ANKI
COPY --from=anki /usr/local/share/anki /usr/local/share/anki

# GIT CRYPT
COPY --from=git-crypt /root/git-crypt/git-crypt /usr/local/bin/git-crypt
COPY --from=git-crypt /root/git-crypt/man/man1/git-crypt.1 /usr/local/share/man/man1

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

# ONEPW
COPY --from=onepw --chown=admin:admin /usr/local/bin/1pw /usr/local/bin/1pw

# GH
COPY --from=gh --chown=admin:admin /usr/local/bin/gh /usr/local/bin/gh

# Z.LUA
copy --from=zlua --chown=admin:admin /root/z.lua /usr/local/bin/z.lua

# PRETTYPING
COPY --from=prettyping --chown=admin:admin /usr/local/bin/prettyping /usr/local/bin/prettyping

# NGROK
COPY --from=ngrok --chown=admin:admin /usr/local/bin/ngrok /usr/local/bin/ngrok

# ANTIBODY
COPY --from=antibody --chown=admin:admin /usr/local/bin/antibody /usr/local/bin/antibody

# CHARLES
COPY --from=charles --chown=admin:admin /root/charles/bin/charles /usr/local/bin/charles
COPY --from=charles --chown=admin:admin /root/charles/lib/* /usr/share/java/charles/

# SQLITE
COPY --from=sqlite3 --chown=admin:admin /usr/lib/libsqlite3.* /usr/lib/
COPY --from=sqlite3 --chown=admin:admin /usr/bin/sqlite3 /usr/bin/sqlite3

###
### FINISHING UP
###

# dotfiles
COPY --chown=admin:admin --from=dotfiles /root/dotfiles /home/admin/dotfiles
RUN cd dotfiles && \
  make apps && \
  antibody bundle \
    < /home/admin/dotfiles/apps/zsh/bundles.txt \
    > /home/admin/.antibody.sh && \
  nvim +'call dein#update()' +GoInstallBinaries +UpdateRemotePlugins +qall 

ENV PULSE_SERVER /run/pulse/native

CMD /home/admin/.xinitrc

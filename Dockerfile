FROM phusion/baseimage:0.10.0 as base

# TERM environment
ENV TERM=xterm-256color

# use latest version of git
RUN add-apt-repository ppa:git-core/ppa

# Requirements for building dependencies
RUN apt-get update && apt-get install -y \
  apt-transport-https \
  build-essential \
  ca-certificates \
  curl \
  git \
  iputils-ping \
  jq \
  libevent-dev \
  libncurses5-dev \
  locales  \
  net-tools \
  netcat-openbsd \
  python-pip \
  python3-pip \
  socat \
  software-properties-common \
  tzdata \
  wget \
  zsh

# Install Docker-CE
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
RUN apt-get update && apt-get install -y docker-ce

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
RUN curl https://sh.rustup.rs -sSf > /usr/local/src/rust.sh
RUN sh /usr/local/src/rust.sh -y
ENV PATH /root/.cargo/bin:$PATH
RUN rustup override set stable
RUN rustup update stable

# Docker Compose
FROM base as docker-compose
RUN curl -o /usr/local/bin/docker-compose -L "https://github.com/docker/compose/releases/download/1.20.1/docker-compose-$(uname -s)-$(uname -m)"
RUN chmod +x /usr/local/bin/docker-compose

# GO
FROM base as go
RUN add-apt-repository ppa:gophers/archive
RUN apt-get update
RUN apt-get install -y golang-1.10-go
ENV PATH /usr/lib/go-1.10/bin:$PATH

# GO >> CLONE
FROM go as clone
WORKDIR /usr/local/src
RUN git clone https://github.com/stayradiated/clone
WORKDIR /usr/local/src/clone
ENV GOPATH /usr/local
RUN go install

# TMUX
FROM base as tmux
WORKDIR /usr/local/src
RUN wget https://github.com/tmux/tmux/releases/download/2.6/tmux-2.6.tar.gz
RUN tar xzvf tmux-2.6.tar.gz
WORKDIR /usr/local/src/tmux-2.6
RUN ./configure
RUN make
RUN make install
RUN rm -rf /usr/local/src/tmux*

# NEOVIM
FROM base as neovim
WORKDIR /usr/local/src
RUN apt-get install -y \
  autoconf \
  automake \
  cmake \
  g++ \
  gettext \
  libtool \
  libtool-bin \
  ninja-build \
  pkg-config \
  texinfo \
  unzip
RUN git clone --depth 1 https://github.com/neovim/neovim
WORKDIR /usr/local/src/neovim
RUN git fetch --depth 1 origin tag nightly
RUN git reset --hard nightly
RUN make CMAKE_BUILD_TYPE=Release
RUN make install
RUN rm -rf /usr/local/src/neovim

# NEOVIM + TMUX >> DOTFILES
FROM base as dotfiles
COPY --from=tmux /usr/local/bin/tmux /usr/local/bin/tmux
WORKDIR /usr/local/src
RUN git clone https://github.com/stayradiated/dotfiles
WORKDIR /usr/local/src/dotfiles
RUN git fetch && git reset --hard v1.4.2
RUN make apps
RUN nvim +'call dein#install() | quit' || :

# FZF
FROM base as fzf
RUN mkdir -p /home/admin
WORKDIR /home/admin
RUN git clone --depth=1 https://github.com/junegunn/fzf .fzf
WORKDIR /home/admin/.fzf
RUN git fetch  --depth 1 origin tag 0.17.0
RUN git reset --hard 0.17.0
RUN ./install --all

# PT
FROM base as pt
WORKDIR /usr/local/src
RUN wget https://github.com/monochromegane/the_platinum_searcher/releases/download/v2.1.5/pt_linux_amd64.tar.gz
RUN tar xzvf pt_linux_amd64.tar.gz
RUN rm -rf pt_linux_amd64.tar.gz
RUN mv pt_linux_amd64/pt /usr/local/bin
RUN rm -rf pt_linux_amd64

# NVM
FROM base as nvm
WORKDIR /usr/local/src
RUN git clone --depth 1 https://github.com/creationix/nvm
WORKDIR /usr/local/src/nvm
RUN git fetch --depth 1 origin tag v0.33.8
RUN git reset --hard v0.33.8
RUN bash -c "source nvm.sh && nvm install v10.6.0"
ENV PATH /usr/local/src/nvm/versions/node/v10.6.0/bin:$PATH
COPY ./files/.npmrc /root/.npmrc
RUN npm config set save-exact true
RUN npm install -g @mishguru/jack
RUN npm install -g @mishguru/migrate
RUN npm install -g @mishguru/mish
RUN npm install -g @mishguru/passwd
RUN npm install -g diff-so-fancy
RUN npm install -g npm-check-updates
RUN npm install -g tagrelease
RUN npm install -g release-it
RUN npm install -g resin

# MILLER
FROM base as miller
RUN wget https://github.com/johnkerl/miller/releases/download/v5.3.0/mlr.linux.x86_64 -O mlr
RUN chmod +x ./mlr

# MIGRATE
FROM base as migrate
RUN wget https://github.com/golang-migrate/migrate/releases/download/v3.3.1/migrate.linux-amd64.tar.gz
RUN tar xzvf migrate.linux-amd64.tar.gz && \
  mv migrate.linux-amd64 migrate

# Hub
FROM go as hub
RUN apt-get update && apt-get install -y \
  bsdmainutils \
  groff \
  ruby-dev
RUN gem install bundler
ENV GOPATH /usr/local
RUN mkdir -p /usr/local/src/github.com/github
RUN git clone --depth=1 https://github.com/github/hub /usr/local/src/github.com/github/hub
WORKDIR /usr/local/src/github.com/github/hub
RUN go get
RUN make install prefix=/usr/local

# usql
FROM base as usql
RUN wget https://github.com/xo/usql/releases/download/v0.7.0/usql-0.7.0-linux-amd64.tar.bz2 -O usql.tar && \
  tar xvf usql.tar

# PrettyPing
FROM base as prettyping
RUN wget https://raw.githubusercontent.com/denilsonsa/prettyping/master/prettyping
RUN chmod +x prettyping

# Bat
FROM base as bat
RUN wget https://github.com/sharkdp/bat/releases/download/v0.6.1/bat_0.6.1_amd64.deb -O bat.deb

###
### the real deal
###

FROM base as shell

# build args
ARG DOCKER_GID

# fasd
RUN add-apt-repository ppa:aacebedo/fasd

# weechat
RUN add-apt-repository \
  "deb [arch=amd64] https://weechat.org/ubuntu \
  $(lsb_release -cs) \
  main"
RUN apt-key adv \
  --keyserver hkp://p80.pool.sks-keyservers.net:80 \
  --recv-keys 11E9DE8848F2B65222AA75B8D1820DB22A11534E

# install apps
RUN apt-get update && apt-get install -y \
  adb \
  bs1770gain \
  dnsutils \
  fasd \
  ffmpeg \
  htop \
  httpie \
  man \
  mediainfo \
  mitmproxy \
  moreutils \
  mysql-client \
  ranger \
  safe-rm \
  sudo \
  tig \
  tree \
  unzip \
  weechat-curses \
  weechat-perl \
  weechat-plugins \
  weechat-python \
  xsel \
  zip

# bat
COPY --from=bat /root/bat.deb /tmp/bat.deb
RUN sudo dpkg -i /tmp/bat.deb && rm -rf /tmp/bat.deb

# setup admin user
RUN groupmod -g $DOCKER_GID docker
RUN useradd -s /usr/bin/zsh --create-home admin
RUN echo "admin:admin" | chpasswd
RUN adduser admin sudo
RUN adduser admin docker
RUN chown -R admin:admin /usr/local/src
USER admin
WORKDIR /home/admin

# install neovim
RUN pip install --user neovim
RUN pip3 install --user neovim

# beets
RUN pip install --user beets requests pylast
RUN mkdir -p /home/admin/.config/beets
RUN ln -s /home/admin/src/bitbucket.org/stayradiated/beets/config.yaml /home/admin/.config/beets/config.yaml

# weechat
RUN pip install --user websocket-client

# eyeD3
RUN pip install --user eyeD3

# awscli
RUN pip install --user awscli
RUN pip install --user awsebcli

# nvm
COPY --from=nvm --chown=admin:admin /usr/local/src/nvm/versions/node/v10.6.0 /usr/local/lib/node

# go
COPY --from=go /usr/lib/go-1.10 /usr/lib/go-1.10
COPY --from=go /usr/share/go-1.10 /usr/share/go-1.10
RUN mkdir -p /home/admin/bin

# rust
copy --from=rust --chown=admin:admin /root/.cargo /home/admin/.cargo

# docker-compose
COPY --from=docker-compose /usr/local/bin/docker-compose /usr/local/bin/docker-compose

# tmux
COPY --from=tmux /usr/local/bin/tmux /usr/local/bin/tmux

# neovim
COPY --from=neovim /usr/local/bin/nvim /usr/local/bin/nvim
COPY --from=neovim /usr/local/share/nvim /usr/local/share/nvim
RUN nvim +'UpdateRemotePlugins | quit' || :

# pt
COPY --from=pt /usr/local/bin/pt /usr/local/bin/pt

# fzf
COPY --from=fzf --chown=admin:admin /home/admin/.fzf /home/admin/.fzf
COPY --from=fzf --chown=admin:admin /root/.fzf.zsh /home/admin/.fzf.zsh

# miller
COPY --from=miller --chown=admin:admin /root/mlr /usr/local/bin/mlr

# migrate
COPY --from=migrate --chown=admin:admin /root/migrate /usr/local/bin/migrate

# clone
COPY --from=clone --chown=admin:admin /usr/local/bin/clone /home/admin/bin/clone

# hub
COPY --from=hub --chown=admin:admin /usr/local/bin/hub /home/admin/bin/hub

# prettyping
COPY --from=usql --chown=admin:admin /root/usql /usr/local/bin/usql

# prettyping
COPY --from=prettyping --chown=admin:admin /root/prettyping /usr/local/bin/prettyping

# copy files
COPY --chown=admin:admin ./files ./

# allow certain ssh hosts
RUN ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
RUN ssh-keyscan -t rsa bitbucket.org >> ~/.ssh/known_hosts

# dotfiles
COPY --chown=admin:admin --from=dotfiles /usr/local/src/dotfiles /home/admin/dotfiles
COPY --chown=admin:admin --from=dotfiles /root/.zprezto /home/admin/.zprezto
COPY --chown=admin:admin --from=dotfiles /root/.tmux /home/admin/.tmux
WORKDIR /home/admin/dotfiles
RUN make apps
WORKDIR /home/admin/.zprezto
RUN git pull --rebase
WORKDIR /home/admin

RUN echo 'export GOPATH=/home/admin' >> /home/admin/.zshrc
RUN echo 'export GOROOT=/usr/lib/go-1.10' >> /home/admin/.zshrc
RUN echo 'export PATH=/home/admin/bin:/home/admin/.local/bin:/home/admin/.cargo/bin:/usr/local/lib/node/bin:/usr/lib/go-1.10/bin:$PATH' >> /home/admin/.zshrc

CMD ["/sbin/my_init"]
USER root


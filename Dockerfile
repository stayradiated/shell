FROM phusion/baseimage:0.11 as base

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
  unzip \
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

# Kubernetes
FROM base as kubernetes
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    touch /etc/apt/sources.list.d/kubernetes.list && \
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
     apt-get update && \
     apt-get install -y kubectl
RUN curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.29.0/minikube-linux-amd64 && \
    chmod +x minikube && \
    cp minikube /usr/local/bin/ && \
    rm minikube

# Rust
FROM base as rust
RUN curl https://sh.rustup.rs -sSf > /usr/local/src/rust.sh
RUN sh /usr/local/src/rust.sh -y
ENV PATH /root/.cargo/bin:$PATH
RUN rustup override set stable
RUN rustup update stable
RUN cargo install sd
RUN cargo install fd-find

# Docker Compose
FROM base as docker-compose
RUN curl -o /usr/local/bin/docker-compose -L "https://github.com/docker/compose/releases/download/1.20.1/docker-compose-$(uname -s)-$(uname -m)"
RUN chmod +x /usr/local/bin/docker-compose

# GO
FROM base as go
RUN add-apt-repository ppa:gophers/archive
RUN apt-get update && apt-get install -y golang-1.11-go
ENV PATH /usr/lib/go-1.11/bin:$PATH

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
ARG NEOVIM_VERSION=v0.3.4
RUN git clone --depth 1 https://github.com/neovim/neovim
WORKDIR /usr/local/src/neovim
RUN git fetch --depth 1 origin tag "${NEOVIM_VERSION}"
RUN git reset --hard "${NEOVIM_VERSION}"
RUN make CMAKE_BUILD_TYPE=Release
RUN make install
RUN rm -rf /usr/local/src/neovim

# NEOVIM + TMUX >> DOTFILES
FROM base as dotfiles
COPY --from=tmux /usr/local/bin/tmux /usr/local/bin/tmux
WORKDIR /usr/local/src
RUN git clone https://github.com/stayradiated/dotfiles
WORKDIR /usr/local/src/dotfiles
RUN git fetch && git reset --hard v1.4.3
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
ARG NVM_VERSION=v0.34.0
RUN git clone --depth 1 https://github.com/creationix/nvm /usr/local/src/nvm
WORKDIR /usr/local/src/nvm
RUN git fetch --depth 1 origin tag $NVM_VERSION && git reset --hard $NVM_VERSION
ARG NODE_VERSION=v11.11.0
RUN bash -c "source nvm.sh && nvm install $NODE_VERSION"
ENV PATH /usr/local/src/nvm/versions/node/$NODE_VERSION/bin:$PATH
COPY ./files/.npmrc /root/.npmrc
RUN npm config set save-exact true && npm install -g \
  @mishguru/admincli \
  @mishguru/fandex \
  @mishguru/jack \
  @mishguru/logview-cli \
  @mishguru/mish \
  @mishguru/passwd \
  diff-so-fancy \
  lerna \
  npm-check-updates \
  release-it \
  tagrelease
RUN mv /usr/local/src/nvm/versions/node/$NODE_VERSION /root/node

# MILLER
FROM base as miller
RUN wget https://github.com/johnkerl/miller/releases/download/v5.3.0/mlr.linux.x86_64 -O mlr
RUN chmod +x ./mlr

# MIGRATE
FROM base as migrate
RUN wget https://github.com/golang-migrate/migrate/releases/download/v3.3.1/migrate.linux-amd64.tar.gz
RUN tar xzvf migrate.linux-amd64.tar.gz && \
  mv migrate.linux-amd64 migrate

# HUB
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
RUN git fetch --depth 1 origin tag v2.9.0
RUN git reset --hard v2.9.0
RUN go get
RUN make install prefix=/usr/local

# Z.LUA
FROM base as zlua
RUN wget https://raw.githubusercontent.com/skywind3000/z.lua/v1.5.6/z.lua

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

## hugo
FROM base as hugo
RUN wget https://github.com/gohugoio/hugo/releases/download/v0.54.0/hugo_0.54.0_Linux-64bit.tar.gz -O hugo.tgz && \
  tar xvf hugo.tgz

## mbt
FROM base as mbt
ARG MBT_VERSION=0.21.0
RUN wget "https://bintray.com/buddyspike/bin/download_file?file_path=mbt_linux_x86_64%2F${MBT_VERSION}%2F${MBT_VERSION}%2Fmbt_linux_x86_64" -O mbt && \
  chmod +x mbt

###
### the real deal
###

FROM base as shell

# build args
ARG DOCKER_GID

# weechat
RUN apt-key adv \
  --keyserver hkp://p80.pool.sks-keyservers.net:80 \
  --recv-keys 11E9DE8848F2B65222AA75B8D1820DB22A11534E

RUN add-apt-repository \
  "deb [arch=amd64] https://weechat.org/ubuntu \
  $(lsb_release -cs) \
  main"

# install apps
RUN apt-get update && apt-get install -y \
  adb \
  aria2 \
  bs1770gain \
  dnsutils \
  ffmpeg \
  htop \
  httpie \
  lua5.3 \
  man \
  mediainfo \
  moreutils \
  mysql-client \
  nmap \
  ranger \
  safe-rm \
  scrot \
  sudo \
  tig \
  tree \
  weechat-curses \
  weechat-perl \
  weechat-plugins \
  weechat-python \
  xclip \
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

# rust
COPY --from=rust --chown=admin:admin /root/.cargo /home/admin/.cargo

# install neovim
RUN pip install --user neovim
RUN pip3 install --user neovim

# beets
RUN pip3 install --user beets requests pylast
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
COPY --from=nvm --chown=admin:admin /root/node /usr/local/lib/node

# go
COPY --from=go /usr/lib/go-1.11 /usr/lib/go-1.11
COPY --from=go /usr/share/go-1.11 /usr/share/go-1.11
RUN mkdir -p /home/admin/bin

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

# usql
COPY --from=usql --chown=admin:admin /root/usql /usr/local/bin/usql

# z.lua
copy --from=zlua --chown=admin:admin /root/z.lua /home/admin/bin/z.lua

# prettyping
COPY --from=prettyping --chown=admin:admin /root/prettyping /usr/local/bin/prettyping

# hugo
COPY --from=hugo --chown=admin:admin /root/hugo /usr/local/bin/hugo

# mbt
COPY --from=mbt --chown=admin:admin /root/mbt /usr/local/bin/mbt

# kubernetes
COPY --from=kubernetes --chown=admin:admin /usr/bin/kubectl /usr/local/bin/kubectl
COPY --from=kubernetes --chown=admin:admin /usr/local/bin/minikube /usr/local/bin/minikube

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

RUN \
  echo 'export GOPATH=/home/admin' >> /home/admin/.zpath && \
  echo 'export GOROOT=/usr/lib/go-1.11' >> /home/admin/.zpath && \
  echo 'export PATH=/home/admin/bin:/home/admin/.local/bin:/home/admin/.cargo/bin:/usr/local/lib/node/bin:/usr/lib/go-1.11/bin:$PATH' >> /home/admin/.zpath

CMD ["/sbin/my_init"]
USER root


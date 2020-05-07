

# BASE
FROM phusion/baseimage:0.11 AS base
RUN \
  export LANG=en_NZ.UTF-8 && \
  locale-gen en_NZ.UTF-8 && \
  rm /etc/dpkg/dpkg.cfg.d/excludes && \
  apt-get -q update && \
  dpkg -l | grep ^ii | cut -d' ' -f3 | xargs apt-get install -y --reinstall && \
  apt-get -q clean && \
  rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

# APTERYX
FROM base AS apteryx
RUN \
  EXPORT=/usr/local/bin/apteryx && \
  echo '#!/usr/bin/env sh' >> ${EXPORT} && \
  echo 'set -e' >> ${EXPORT} && \
  echo 'export DEBIAN_FRONTEND="noninteractive"' >> ${EXPORT} && \
  echo 'apt-get -q update' >> ${EXPORT} && \
  echo 'apt-get install -y --no-install-recommends --auto-remove "${@}"' >> ${EXPORT} && \
  echo 'apt-get -q clean' >> ${EXPORT} && \
  echo 'rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*' >> ${EXPORT} && \
  chmod +x ${EXPORT}

# TAR
FROM base AS tar
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx tar='1.29*'

# WGET
FROM base AS wget
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx wget='1.19.4-*'

# GIT
FROM base AS git
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  add-apt-repository ppa:git-core/ppa && \
  apteryx git='1:2.26.2*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/ && \
  mv /usr/bin/git /exports/usr/bin/ && \
  mv /usr/lib/git-core /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.* /usr/lib/x86_64-linux-gnu/libpcre2-8.so.* /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/share/git-core /exports/usr/share/

# GO
FROM base AS go
COPY --from=wget /usr/bin/wget /usr/bin/
COPY --from=tar /bin/tar /bin/
RUN \
  wget -O /tmp/go.tgz "https://dl.google.com/go/go1.13.4.linux-amd64.tar.gz" && \
  tar xzvf /tmp/go.tgz && \
  mv go /usr/local/go && \
  rm -rf /tmp/go.tgz

# MAKE
FROM base AS make
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx make='4.1-*'

# CLONE
FROM base AS clone
COPY --from=go /usr/local/go/ /usr/local/go/
COPY --from=git /exports/ /
ENV \
  PATH=/usr/local/go/bin:${PATH} \
  GOPATH=/root
RUN \
  mkdir -p /root/src/github.com/stayradiated && \
  cd /root/src/github.com/stayradiated && \
  git clone --depth 1 https://github.com/stayradiated/clone && \
  cd clone && \
  git fetch --depth 1 origin tag 'v1.3.0' && \
  git reset --hard 'v1.3.0' && \
  go install && \
  mv /root/bin/clone /usr/local/bin/clone && \
  cd /root && \
  rm -rf src bin

# BUILD-ESSENTIAL
FROM base AS build-essential
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx build-essential='12.4*'
RUN \
  mkdir -p /exports/etc/alternatives/ /exports/etc/ /exports/lib/ /exports/usr/bin/ /exports/usr/ && \
  mv /etc/alternatives/c++ /etc/alternatives/c89 /etc/alternatives/c99 /etc/alternatives/cc /etc/alternatives/cpp /etc/alternatives/lzcat /etc/alternatives/lzcmp /etc/alternatives/lzdiff /etc/alternatives/lzegrep /etc/alternatives/lzfgrep /etc/alternatives/lzgrep /etc/alternatives/lzless /etc/alternatives/lzma /etc/alternatives/lzmore /etc/alternatives/unlzma /exports/etc/alternatives/ && \
  mv /etc/perl /exports/etc/ && \
  mv /lib/cpp /exports/lib/ && \
  mv /usr/bin/addr2line /usr/bin/ar /usr/bin/as /usr/bin/c++ /usr/bin/c++filt /usr/bin/c89 /usr/bin/c89-gcc /usr/bin/c99 /usr/bin/c99-gcc /usr/bin/cc /usr/bin/corelist /usr/bin/cpan /usr/bin/cpan5.26-x86_64-linux-gnu /usr/bin/cpp /usr/bin/cpp-7 /usr/bin/dpkg-architecture /usr/bin/dpkg-buildflags /usr/bin/dpkg-buildpackage /usr/bin/dpkg-checkbuilddeps /usr/bin/dpkg-distaddfile /usr/bin/dpkg-genbuildinfo /usr/bin/dpkg-genchanges /usr/bin/dpkg-gencontrol /usr/bin/dpkg-gensymbols /usr/bin/dpkg-mergechangelogs /usr/bin/dpkg-name /usr/bin/dpkg-parsechangelog /usr/bin/dpkg-scanpackages /usr/bin/dpkg-scansources /usr/bin/dpkg-shlibdeps /usr/bin/dpkg-source /usr/bin/dpkg-vendor /usr/bin/dwp /usr/bin/elfedit /usr/bin/enc2xs /usr/bin/encguess /usr/bin/g++ /usr/bin/g++-7 /usr/bin/gcc /usr/bin/gcc-7 /usr/bin/gcc-ar /usr/bin/gcc-ar-7 /usr/bin/gcc-nm /usr/bin/gcc-nm-7 /usr/bin/gcc-ranlib /usr/bin/gcc-ranlib-7 /usr/bin/gcov /usr/bin/gcov-7 /usr/bin/gcov-dump /usr/bin/gcov-dump-7 /usr/bin/gcov-tool /usr/bin/gcov-tool-7 /usr/bin/gencat /usr/bin/gold /usr/bin/gprof /usr/bin/h2ph /usr/bin/h2xs /usr/bin/instmodsh /usr/bin/json_pp /usr/bin/ld /usr/bin/ld.bfd /usr/bin/ld.gold /usr/bin/libnetcfg /usr/bin/lzcat /usr/bin/lzcmp /usr/bin/lzdiff /usr/bin/lzegrep /usr/bin/lzfgrep /usr/bin/lzgrep /usr/bin/lzless /usr/bin/lzma /usr/bin/lzmainfo /usr/bin/lzmore /usr/bin/make /usr/bin/make-first-existing-target /usr/bin/mtrace /usr/bin/nm /usr/bin/objcopy /usr/bin/objdump /usr/bin/patch /usr/bin/perl5.26-x86_64-linux-gnu /usr/bin/perlbug /usr/bin/perldoc /usr/bin/perlivp /usr/bin/perlthanks /usr/bin/piconv /usr/bin/pl2pm /usr/bin/pod2html /usr/bin/pod2man /usr/bin/pod2text /usr/bin/pod2usage /usr/bin/podchecker /usr/bin/podselect /usr/bin/prove /usr/bin/ptar /usr/bin/ptardiff /usr/bin/ptargrep /usr/bin/ranlib /usr/bin/readelf /usr/bin/rpcgen /usr/bin/shasum /usr/bin/size /usr/bin/sotruss /usr/bin/splain /usr/bin/sprof /usr/bin/strings /usr/bin/strip /usr/bin/unlzma /usr/bin/unxz /usr/bin/x86_64-linux-gnu-* /usr/bin/xsubpp /usr/bin/xz /usr/bin/xzcat /usr/bin/xzcmp /usr/bin/xzdiff /usr/bin/xzegrep /usr/bin/xzfgrep /usr/bin/xzgrep /usr/bin/xzless /usr/bin/xzmore /usr/bin/zipdetails /exports/usr/bin/ && \
  mv /usr/include /usr/lib /exports/usr/

# GIT-CRYPT
FROM base AS git-crypt
COPY --from=make /usr/bin/make /usr/bin/
COPY --from=git /exports/ /
COPY --from=clone /usr/local/bin/clone /usr/local/bin/
COPY --from=build-essential /exports/ /
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx libssl-dev xsltproc && \
  clone --https --shallow --tag '0.6.0' https://github.com/AGWA/git-crypt && \
  cd /root/src/github.com/AGWA/git-crypt && \
  ENABLE_MAN=yes make && \
  make install && \
  mv git-crypt /usr/local/bin/git-crypt && \
  mkdir -p /usr/local/share/man/man1/ && \
  mv man/man1/git-crypt.1 /usr/local/share/man/man1/git-crypt.1

# ZSH
FROM base AS zsh
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx zsh='5.4.2-*'
RUN \
  mkdir -p /exports/bin/ /exports/etc/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/ && \
  mv /bin/zsh /exports/bin/ && \
  mv /etc/zsh /exports/etc/ && \
  mv /usr/lib/x86_64-linux-gnu/zsh /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/share/zsh /exports/usr/share/

# DOTFILES
FROM base AS dotfiles
COPY --from=git-crypt /usr/local/bin/git-crypt /usr/local/bin/
COPY --from=git /exports/ /
COPY --from=clone /usr/local/bin/clone /usr/local/bin/
COPY ./secret/dotfiles-key /tmp/dotfiles-key
RUN \
  clone --https --shallow --tag 'v1.20.0' https://github.com/stayradiated/dotfiles && \
  cd /root/src/github.com/stayradiated/dotfiles && \
  git-crypt unlock /tmp/dotfiles-key && \
  rm /tmp/dotfiles-key && \
  mv /root/src/github.com/stayradiated/dotfiles /root/dotfiles && \
  rm -rf src

# NVM
FROM base AS nvm
COPY --from=git /exports/ /
COPY --from=clone /usr/local/bin/clone /usr/local/bin/
RUN \
  clone --https --shallow --tag 'v0.35.3' https://github.com/nvm-sh/nvm && \
  mv /root/src/github.com/nvm-sh/nvm /usr/local/share/nvm && \
  rm -rf /root/src

# LUA
FROM base AS lua
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx lua5.3='5.3.3-*'

# SHELL-ROOT
FROM base AS shell-root
COPY --from=zsh /exports/ /
COPY --from=dotfiles /root/dotfiles/ /root/dotfiles/
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
COPY ./secret/admin-passwd /tmp/admin-passwd
RUN \
  useradd -s /bin/zsh --create-home admin && \
  echo "admin:$(cat /tmp/admin-passwd)" | chpasswd --encrypted && \
  adduser admin sudo && \
  mv /root/dotfiles /home/admin/dotfiles && \
  mkdir -p /home/admin/.cache && \
  mkdir -p /home/admin/.config && \
  mkdir -p /home/admin/.local/share && \
  chown -R admin:admin /home/admin

# PYTHON3-PIP
FROM base AS python3-pip
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx python3-pip='9.0.1-*' python3-setuptools='39.0.1-*' python3-wheel='0.30.0-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/share/ && \
  mv /usr/bin/pip3 /exports/usr/bin/ && \
  mv /usr/lib/python3.6 /usr/lib/python3.7 /usr/lib/python3.8 /usr/lib/python3 /exports/usr/lib/ && \
  mv /usr/share/python-wheels /exports/usr/share/

# NODE
FROM base AS node
COPY --from=nvm /usr/local/share/nvm/ /usr/local/share/nvm/
ENV \
  NVM_DIR=/usr/local/share/nvm
RUN \
  bash -c 'source $NVM_DIR/nvm.sh && nvm install 14.0.0' && \
  mv "${NVM_DIR}/versions/node/v14.0.0" /usr/local/lib/node && \
  PATH="/usr/local/lib/node/bin:${PATH}" && \
  npm config set user root && \
  npm config set save-exact true

# PYTHON2
FROM base AS python2
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx python2.7='2.7.17-*' && \
  update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
RUN \
  mkdir -p /exports/etc/alternatives/ /exports/etc/ /exports/usr/bin/ /exports/usr/lib/ && \
  mv /etc/alternatives/python /exports/etc/alternatives/ && \
  mv /etc/python2.7 /exports/etc/ && \
  mv /usr/bin/python /usr/bin/python2.7 /exports/usr/bin/ && \
  mv /usr/lib/python2.7 /exports/usr/lib/

# Z.LUA
FROM base AS z.lua
COPY --from=wget /usr/bin/wget /usr/bin/
COPY --from=lua /usr/bin/lua5.3 /usr/bin/
RUN \
  wget -O /usr/local/bin/z.lua 'https://raw.githubusercontent.com/skywind3000/z.lua/1.8.4/z.lua'

# FZF
FROM base AS fzf
COPY --from=git /exports/ /
COPY --from=clone /usr/local/bin/clone /usr/local/bin/
RUN \
  clone --https --shallow --tag '0.21.1' https://github.com/junegunn/fzf && \
  mv /root/src/github.com/junegunn/fzf /usr/local/share/fzf && \
  rm -rf /root/src && \
  /usr/local/share/fzf/install --bin

# ANTIBODY
FROM base AS antibody
COPY --from=wget /usr/bin/wget /usr/bin/
RUN \
  wget -O /tmp/install-antibody.sh https://git.io/antibody && \
  sh /tmp/install-antibody.sh -b /usr/local/bin && \
  rm /tmp/install-antibody.sh

# SHELL-ADMIN
FROM shell-root AS shell-admin
USER admin
WORKDIR /home/admin
RUN \
  mkdir -p /home/admin/exports

# SXHKD
FROM base AS sxhkd
COPY --from=make /usr/bin/make /usr/bin/
COPY --from=git /exports/ /
COPY --from=clone /usr/local/bin/clone /usr/local/bin/
COPY --from=build-essential /exports/ /
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx libxcb-util-dev libxcb-keysyms1-dev && \
  clone --https --shallow --tag '0.6.1' https://github.com/baskerville/sxhkd && \
  cd /root/src/github.com/baskerville/sxhkd && \
  make all && \
  make install && \
  rm -rf /root/src

# BSPWM
FROM base AS bspwm
COPY --from=make /usr/bin/make /usr/bin/
COPY --from=git /exports/ /
COPY --from=clone /usr/local/bin/clone /usr/local/bin/
COPY --from=build-essential /exports/ /
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx libxcb-ewmh-dev libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-randr0-dev libxcb-shape0-dev libxcb-util-dev libxcb-xinerama0-dev && \
  clone --https --shallow --tag '0.9.9' https://github.com/baskerville/bspwm && \
  cd /root/src/github.com/baskerville/bspwm && \
  make all && \
  make install && \
  rm -rf /root/src
RUN \
  mkdir -p /exports/usr/lib/ /exports/usr/local/bin/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/ && \
  mv /usr/local/bin/bspc /usr/local/bin/bspwm /exports/usr/local/bin/

# NEOVIM
FROM base AS neovim
COPY --from=wget /usr/bin/wget /usr/bin/
COPY --from=python3-pip /exports/ /
RUN \
  wget -O /tmp/nvim.appimage 'https://github.com/neovim/neovim/releases/download/v0.4.3/nvim.appimage' && \
  chmod +x /tmp/nvim.appimage && \
  /tmp/nvim.appimage --appimage-extract && \
  rm /tmp/nvim.appimage && \
  mv squashfs-root/usr/bin/nvim /usr/local/bin/nvim && \
  mv squashfs-root/usr/share/nvim /usr/local/share/nvim && \
  mkdir -p /usr/local/share/man/man1 && \
  mv squashfs-root/usr/man/man1/nvim.1 /usr/local/share/man/man1/nvim.1 && \
  rm -r squashfs-root && \
  find /usr/local/share/nvim -type d -print0 | xargs -0 chmod 0775 && \
  find /usr/local/share/nvim -type f -print0 | xargs -0 chmod 0664 && \
  pip3 install neovim msgpack
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/include/ /exports/usr/local/lib/ /exports/usr/local/share/ && \
  mv /usr/local/bin/nvim /exports/usr/local/bin/ && \
  mv /usr/local/include/python3.6 /exports/usr/local/include/ && \
  mv /usr/local/lib/python3.6 /exports/usr/local/lib/ && \
  mv /usr/local/share/nvim /exports/usr/local/share/

# TMUX
FROM base AS tmux
COPY --from=wget /usr/bin/wget /usr/bin/
COPY --from=tar /bin/tar /bin/
COPY --from=make /usr/bin/make /usr/bin/
COPY --from=build-essential /exports/ /
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx libncurses5-dev libevent-dev && \
  cd /root && \
  wget -O /tmp/tmux.tgz 'https://github.com/tmux/tmux/releases/download/3.1/tmux-3.1.tar.gz' && \
  tar xzvf /tmp/tmux.tgz && \
  rm /tmp/tmux.tgz && \
  cd 'tmux-3.1' && \
  ./configure && \
  make && \
  make install && \
  cd .. && \
  rm -r 'tmux-3.1'
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/lib/ && \
  mv /usr/local/bin/tmux /exports/usr/local/bin/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# RANGER
FROM base AS ranger
COPY --from=python3-pip /exports/ /
RUN \
  pip3 install ranger-fm=='1.9.3'
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/ && \
  mv /usr/local/bin/ranger /usr/local/bin/rifle /exports/usr/local/bin/ && \
  mv /usr/local/lib/python3.6 /exports/usr/local/lib/

# ONE-PW
FROM base AS one-pw
COPY --from=go /usr/local/go/ /usr/local/go/
COPY --from=git /exports/ /
COPY --from=clone /usr/local/bin/clone /usr/local/bin/
ENV \
  PATH=/usr/local/go/bin:${PATH} \
  GOPATH=/root
RUN \
  clone --https --shallow --tag 'master' https://github.com/special/1pw && \
  cd /root/src/github.com/special/1pw && \
  go get -v && \
  go build && \
  mv 1pw /usr/local/bin/1pw && \
  rm -rf /root/src

# DBXCLI
FROM base AS dbxcli
COPY --from=wget /usr/bin/wget /usr/bin/
RUN \
  wget -O dbxcli 'https://github.com/dropbox/dbxcli/releases/download/v3.0.0/dbxcli-linux-amd64' && \
  chmod +x dbxcli && \
  mv dbxcli /usr/local/bin/dbxcli

# DIFF-SO-FANCY
FROM base AS diff-so-fancy
COPY --from=node /usr/local/lib/node/ /usr/local/lib/node/
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  npm install -g 'diff-so-fancy@1.2.6'

# UNZIP
FROM base AS unzip
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx unzip='6.0-*'

# PING
FROM base AS ping
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx iputils-ping='3:20161105-*'
RUN \
  mkdir -p /exports/bin/ /exports/lib/x86_64-linux-gnu/ && \
  mv /bin/ping /exports/bin/ && \
  mv /lib/x86_64-linux-gnu/libidn.so.* /exports/lib/x86_64-linux-gnu/

# XZ
FROM base AS xz
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx xz-utils='5.2.2-*'

# ZOOM
FROM base AS zoom
COPY --from=wget /usr/bin/wget /usr/bin/
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  wget -O /tmp/zoom.deb 'https://zoom.us/client/3.5.383291.0407/zoom_amd64.deb' && \
  apteryx /tmp/zoom.deb
RUN \
  mkdir -p /exports/opt/ /exports/usr/bin/ /exports/usr/lib/ && \
  mv /opt/zoom /exports/opt/ && \
  mv /usr/bin/zoom /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# VLC
FROM base AS vlc
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx vlc='3.0.8-*'

# GOOGLE-CHROME
FROM base AS google-chrome
COPY --from=wget /usr/bin/wget /usr/bin/
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  wget -O /tmp/chrome.deb 'https://www.slimjet.com/chrome/download-chrome.php?file=files/81.0.4044.92/google-chrome-stable_current_amd64.deb' && \
  apteryx /tmp/chrome.deb
RUN \
  mkdir -p /exports/opt/ /exports/usr/lib/ && \
  mv /opt/google /exports/opt/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# FIREFOX
FROM base AS firefox
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx firefox='75.0+*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/share/ && \
  mv /usr/bin/firefox /exports/usr/bin/ && \
  mv /usr/lib/firefox-addons /usr/lib/firefox /usr/lib/x86_64-linux-gnu /exports/usr/lib/ && \
  mv /usr/share/icons /exports/usr/share/

# ALACRITTY
FROM base AS alacritty
COPY --from=wget /usr/bin/wget /usr/bin/
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  wget -O /tmp/alacritty.deb 'https://github.com/alacritty/alacritty/releases/download/v0.4.2/Alacritty-v0.4.2-ubuntu_18_04_amd64.deb' && \
  apteryx /tmp/alacritty.deb
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ && \
  mv /usr/bin/alacritty /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# X11-UTILS
FROM base AS x11-utils
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx x11-utils='7.7+*' x11-xkb-utils='7.7+*' x11-xserver-utils='7.7+*' xkb-data='2.23.1-*'
RUN \
  mkdir -p /exports/etc/ /exports/etc/init.d/ /exports/etc/rcS.d/ /exports/usr/ && \
  mv /etc/X11 /etc/fonts /etc/sensors.d /etc/sensors3.conf /exports/etc/ && \
  mv /etc/init.d/x11-common /exports/etc/init.d/ && \
  mv /etc/rcS.d/S01x11-common /exports/etc/rcS.d/ && \
  mv /usr/bin /usr/lib /usr/share /exports/usr/

# MESA
FROM base AS mesa
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx mesa-utils='8.4.0-*' mesa-utils-extra='8.4.0-*'
RUN \
  mkdir -p /exports/etc/ /exports/usr/ /exports/usr/lib/ && \
  mv /etc/glvnd /etc/sensors.d /etc/sensors3.conf /exports/etc/ && \
  mv /usr/bin /usr/share /exports/usr/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# LIBXV1
FROM base AS libxv1
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx libxv1='2:1.0.11-1'
RUN \
  mkdir -p /exports/usr/lib/ /exports/usr/share/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/ && \
  mv /usr/share/X11 /exports/usr/share/

# SHELL-ZSH
FROM shell-admin AS shell-zsh
COPY --from=z.lua /usr/local/bin/z.lua /usr/local/bin/
COPY --from=python2 /exports/ /
COPY --from=make /usr/bin/make /usr/bin/
COPY --from=lua /usr/bin/lua5.3 /usr/bin/
COPY --from=git /exports/ /
COPY --from=fzf /usr/local/share/fzf/ /usr/local/share/fzf/
COPY --from=antibody /usr/local/bin/antibody /usr/local/bin/
ENV \
  PATH=/home/admin/dotfiles/bin:${PATH}
RUN \
  cd dotfiles && \
  make zsh && \
  antibody bundle < /home/admin/dotfiles/apps/zsh/bundles.txt > /home/admin/.antibody.sh && \
  /usr/local/share/fzf/install --key-bindings --completion && \
  mkdir -p ~/src
RUN \
  mkdir -p /home/admin/exports/home/admin/ /home/admin/exports/home/admin/.cache/ && \
  mv /home/admin/.antibody.sh /home/admin/.fzf.zsh /home/admin/.zshrc /home/admin/src /home/admin/exports/home/admin/ && \
  mv /home/admin/.cache/antibody /home/admin/exports/home/admin/.cache/

# SHELL-WM
FROM shell-admin AS shell-wm
COPY --from=sxhkd /usr/local/bin/sxhkd /usr/local/bin/
COPY --from=make /usr/bin/make /usr/bin/
COPY --from=git /exports/ /
COPY --from=bspwm /exports/ /
ENV \
  PATH=/home/admin/dotfiles/bin:${PATH}
RUN \
  cd dotfiles && \
  make bspwm sxhkd x11
RUN \
  mkdir -p /home/admin/exports/home/admin/.config/ /home/admin/exports/home/admin/ && \
  mv /home/admin/.config/bspwm /home/admin/.config/sxhkd /home/admin/exports/home/admin/.config/ && \
  mv /home/admin/.xinitrc /home/admin/exports/home/admin/

# SHELL-VIM
FROM shell-admin AS shell-vim
COPY --from=neovim /exports/ /
COPY --from=make /usr/bin/make /usr/bin/
COPY --from=git /exports/ /
ENV \
  PATH=/home/admin/dotfiles/bin:${PATH}
RUN \
  cd dotfiles && \
  make vim && \
  nvim +'call dein#update()' +qall && \
  nvim +UpdateRemotePlugins +qall
RUN \
  mkdir -p /home/admin/exports/home/admin/.config/ /home/admin/exports/home/admin/.local/share/ /home/admin/exports/home/admin/dotfiles/apps/ && \
  mv /home/admin/.config/nvim /home/admin/exports/home/admin/.config/ && \
  mv /home/admin/.local/share/nvim /home/admin/exports/home/admin/.local/share/ && \
  mv /home/admin/dotfiles/apps/vim /home/admin/exports/home/admin/dotfiles/apps/

# SHELL-TMUX
FROM shell-admin AS shell-tmux
COPY --from=tmux /exports/ /
COPY --from=make /usr/bin/make /usr/bin/
COPY --from=git /exports/ /
ENV \
  PATH=/home/admin/dotfiles/bin:${PATH}
RUN \
  cd dotfiles && \
  make tmux

# SHELL-SSH
FROM shell-admin AS shell-ssh
COPY --from=make /usr/bin/make /usr/bin/
ENV \
  PATH=/home/admin/dotfiles/bin:${PATH}

# SHELL-RANGER
FROM shell-admin AS shell-ranger
COPY --from=ranger /exports/ /
COPY --from=make /usr/bin/make /usr/bin/
ENV \
  PATH=/home/admin/dotfiles/bin:${PATH}
RUN \
  cd dotfiles && \
  make ranger

# SHELL-PASSWORDS
FROM shell-admin AS shell-passwords
COPY --from=one-pw /usr/local/bin/1pw /usr/local/bin/
COPY --from=make /usr/bin/make /usr/bin/
COPY --from=dbxcli /usr/local/bin/dbxcli /usr/local/bin/
ENV \
  PATH=/home/admin/dotfiles/bin:${PATH}
RUN \
  cd dotfiles && \
  make dbxcli && \
  1pw-pull
RUN \
  mkdir -p /home/admin/exports/home/admin/.config/ /home/admin/exports/home/admin/ && \
  mv /home/admin/.config/dbxcli /home/admin/exports/home/admin/.config/ && \
  mv /home/admin/vaults /home/admin/exports/home/admin/

# SHELL-NPM
FROM shell-admin AS shell-npm
COPY --from=node /usr/local/lib/node/ /usr/local/lib/node/
COPY --from=make /usr/bin/make /usr/bin/
ENV \
  PATH=/home/admin/dotfiles/bin:${PATH}
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  cd dotfiles && \
  make npm

# SHELL-GIT
FROM shell-admin AS shell-git
COPY --from=node /usr/local/lib/node/ /usr/local/lib/node/
COPY --from=make /usr/bin/make /usr/bin/
COPY --from=git-crypt /usr/local/bin/git-crypt /usr/local/bin/
COPY --from=git /exports/ /
COPY --from=diff-so-fancy /usr/local/lib/node/ /usr/local/lib/node/
ENV \
  PATH=/home/admin/dotfiles/bin:${PATH}
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  cd dotfiles && \
  make git

# YARN
FROM base AS yarn
COPY --from=node /usr/local/lib/node/ /usr/local/lib/node/
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  npm install -g 'yarn@1.22.4'

# TREE
FROM base AS tree
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx tree='1.7.0-*'

# TIG
FROM base AS tig
COPY --from=make /usr/bin/make /usr/bin/
COPY --from=git /exports/ /
COPY --from=clone /usr/local/bin/clone /usr/local/bin/
COPY --from=build-essential /exports/ /
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx autoconf automake pkg-config libreadline-dev libncursesw5-dev && \
  clone --https --shallow --tag 'tig-2.5.1' https://github.com/jonas/tig && \
  cd /root/src/github.com/jonas/tig && \
  make configure && \
  ./configure && \
  make prefix=/usr/local && \
  make install prefix=/usr/local && \
  rm -rf /root/src
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/etc/ && \
  mv /usr/local/bin/tig /exports/usr/local/bin/ && \
  mv /usr/local/etc/tigrc /exports/usr/local/etc/

# SUDO
FROM base AS sudo
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx sudo='1.8.21p2*'
RUN \
  mkdir -p /exports/etc/ /exports/usr/bin/ /exports/usr/lib/ /exports/var/lib/ && \
  mv /etc/sudoers /exports/etc/ && \
  mv /usr/bin/sudo /exports/usr/bin/ && \
  mv /usr/lib/sudo /exports/usr/lib/ && \
  mv /var/lib/sudo /exports/var/lib/

# SD
FROM base AS sd
COPY --from=wget /usr/bin/wget /usr/bin/
COPY --from=unzip /usr/bin/unzip /usr/bin/
RUN \
  wget -O /tmp/sd.zip 'https://github.com/chmln/sd/releases/download/v0.7.4/sd-0.7.4.x86_64-unknown-linux-gnu.zip' && \
  unzip /tmp/sd.zip && \
  rm /tmp/sd.zip && \
  mv b/x86_64-unknown-linux-gnu/release/sd /usr/local/bin/sd && \
  mkdir -p /usr/local/share/man/man1 && \
  mv b/x86_64-unknown-linux-gnu/release/build/sd-*/out/sd.1 /usr/local/share/man/man1/sd.1 && \
  rm -r b

# SAFE-RM
FROM base AS safe-rm
COPY --from=git /exports/ /
COPY --from=clone /usr/local/bin/clone /usr/local/bin/
RUN \
  clone --https --shallow --tag '1.0.7' https://github.com/kaelzhang/shell-safe-rm && \
  cd /root/src/github.com/kaelzhang/shell-safe-rm && \
  cp ./bin/rm.sh /usr/local/bin/safe-rm && \
  rm -rf /root/src/

# RIPGREP
FROM base AS ripgrep
COPY --from=wget /usr/bin/wget /usr/bin/
COPY --from=tar /bin/tar /bin/
RUN \
  wget -O /tmp/ripgrep.tgz 'https://github.com/BurntSushi/ripgrep/releases/download/12.0.1/ripgrep-12.0.1-x86_64-unknown-linux-musl.tar.gz' && \
  tar -xzvf /tmp/ripgrep.tgz && \
  rm /tmp/ripgrep.tgz && \
  mv ripgrep-12.0.1-x86_64-unknown-linux-musl ripgrep && \
  mv ripgrep/rg /usr/local/bin/rg && \
  mkdir -p /usr/local/share/man/man1 && \
  mv ripgrep/doc/rg.1 /usr/local/share/man/man1/rg.1 && \
  rm -r ripgrep

# PRETTYPING
FROM base AS prettyping
COPY --from=wget /usr/bin/wget /usr/bin/
COPY --from=ping /exports/ /
RUN \
  wget -O /usr/local/bin/prettyping 'https://raw.githubusercontent.com/denilsonsa/prettyping/v1.0.1/prettyping' && \
  chmod +x /usr/local/bin/prettyping

# NP
FROM base AS np
COPY --from=node /usr/local/lib/node/ /usr/local/lib/node/
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  npm install -g 'np@6.2.3'

# NCU
FROM base AS ncu
COPY --from=node /usr/local/lib/node/ /usr/local/lib/node/
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  npm install -g 'npm-check-updates@4.1.2'

# MOREUTILS
FROM base AS moreutils
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx moreutils='0.60-*'

# HTOP
FROM base AS htop
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  apteryx htop='2.1.0-*'

# FFMPEG
FROM base AS ffmpeg
COPY --from=xz /usr/bin/xz /usr/bin/
COPY --from=wget /usr/bin/wget /usr/bin/
COPY --from=tar /bin/tar /bin/
RUN \
  wget -O /tmp/ffmpeg.txz 'https://www.johnvansickle.com/ffmpeg/old-releases/ffmpeg-4.2.1-i686-static.tar.xz' && \
  tar -xvf /tmp/ffmpeg.txz && \
  rm /tmp/ffmpeg.txz && \
  mv 'ffmpeg-4.2.1-i686-static' ffmpeg && \
  mv ffmpeg/ffmpeg /usr/local/bin/ffmpeg && \
  mv ffmpeg/ffprobe /usr/local/bin/ffprobe && \
  rm -r ffmpeg

# FD
FROM base AS fd
COPY --from=wget /usr/bin/wget /usr/bin/
COPY --from=tar /bin/tar /bin/
RUN \
  wget -O /tmp/fd.tgz 'https://github.com/sharkdp/fd/releases/download/v8.0.0/fd-v8.0.0-x86_64-unknown-linux-musl.tar.gz' && \
  tar -xzvf /tmp/fd.tgz && \
  rm /tmp/fd.tgz && \
  mv 'fd-v8.0.0-x86_64-unknown-linux-musl' fd && \
  mv fd/fd /usr/local/bin/fd && \
  mkdir -p /usr/local/share/man/man1 && \
  mv fd/fd.1 /usr/local/share/man/man1/fd.1 && \
  rm -r fd

# DOCKER
FROM base AS docker
COPY --from=wget /usr/bin/wget /usr/bin/
COPY --from=apteryx /usr/local/bin/apteryx /usr/local/bin/
RUN \
  wget -O /tmp/docker.gpg https://download.docker.com/linux/ubuntu/gpg && \
  apt-key add /tmp/docker.gpg && \
  apt-add-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable' && \
  apteryx docker-ce='5:19.03.8*'

# CONTAINER-DIFF
FROM base AS container-diff
COPY --from=wget /usr/bin/wget /usr/bin/
RUN \
  wget -O container-diff 'https://storage.googleapis.com/container-diff/v0.15.0/container-diff-linux-amd64' && \
  chmod +x container-diff && \
  mv container-diff /usr/local/bin/container-diff

# BAT
FROM base AS bat
COPY --from=wget /usr/bin/wget /usr/bin/
COPY --from=tar /bin/tar /bin/
RUN \
  wget -O bat.tgz 'https://github.com/sharkdp/bat/releases/download/v0.13.0/bat-v0.13.0-x86_64-unknown-linux-gnu.tar.gz' && \
  tar -xzvf bat.tgz && \
  rm bat.tgz && \
  mv 'bat-v0.13.0-x86_64-unknown-linux-gnu/bat' /usr/local/bin/bat && \
  rm -rf 'bat-v0.13.0-x86_64-unknown-linux-gnu'

# ADB
FROM base AS adb
COPY --from=wget /usr/bin/wget /usr/bin/
COPY --from=unzip /usr/bin/unzip /usr/bin/
RUN \
  wget -O tools.zip 'https://dl.google.com/android/repository/platform-tools_r29.0.5-linux.zip' && \
  unzip tools.zip && \
  rm tools.zip && \
  mv platform-tools/adb /usr/local/bin/adb && \
  rm -rf platform-tools

# MY-DESKTOP
FROM shell-admin AS my-desktop
COPY --from=zoom /exports/ /
COPY --from=z.lua /usr/local/bin/z.lua /usr/local/bin/
COPY --from=yarn /usr/local/lib/node/ /usr/local/lib/node/
COPY --from=x11-utils /exports/ /
COPY --from=vlc /usr/bin/vlc /usr/bin/
COPY --from=tree /usr/bin/tree /usr/bin/
COPY --from=tmux /exports/ /
COPY --from=tig /exports/ /
COPY --from=sxhkd /usr/local/bin/sxhkd /usr/local/bin/
COPY --from=sudo /exports/ /
COPY --from=shell-zsh --chown=admin /home/admin/exports/ /
COPY --from=shell-wm --chown=admin /home/admin/exports/ /
COPY --from=shell-vim --chown=admin /home/admin/exports/ /
COPY --from=shell-tmux --chown=admin /home/admin/exports/ /
COPY --from=shell-ranger --chown=admin /home/admin/.config/ranger/ /home/admin/.config/ranger/
COPY --from=shell-passwords --chown=admin /home/admin/exports/ /
COPY --from=shell-npm --chown=admin /home/admin/.npmrc /home/admin/
COPY --from=shell-git --chown=admin /home/admin/.gitconfig /home/admin/
COPY --from=sd /usr/local/bin/sd /usr/local/bin/
COPY --from=safe-rm /usr/local/bin/safe-rm /usr/local/bin/
COPY --from=ripgrep /usr/local/bin/rg /usr/local/bin/
COPY --from=ranger /exports/ /
COPY --from=python2 /exports/ /
COPY --from=prettyping /usr/local/bin/prettyping /usr/local/bin/
COPY --from=ping /exports/ /
COPY --from=one-pw /usr/local/bin/1pw /usr/local/bin/
COPY --from=np /usr/local/lib/node/ /usr/local/lib/node/
COPY --from=node /usr/local/lib/node/ /usr/local/lib/node/
COPY --from=neovim /exports/ /
COPY --from=ncu /usr/local/lib/node/ /usr/local/lib/node/
COPY --from=moreutils \
  /usr/bin/chronic \
  /usr/bin/combine \
  /usr/bin/errno \
  /usr/bin/ifdata \
  /usr/bin/ifne \
  /usr/bin/isutf8 \
  /usr/bin/lckdo \
  /usr/bin/mispipe \
  /usr/bin/parallel \
  /usr/bin/pee \
  /usr/bin/sponge \
  /usr/bin/ts \
  /usr/bin/vidir \
  /usr/bin/vipe \
  /usr/bin/zrun \
  /usr/bin/
COPY --from=mesa /exports/ /
COPY --from=make /usr/bin/make /usr/bin/
COPY --from=lua /usr/bin/lua5.3 /usr/bin/
COPY --from=libxv1 /exports/ /
COPY --from=htop /usr/bin/htop /usr/bin/
COPY --from=google-chrome /exports/ /
COPY --from=go /usr/local/go/ /usr/local/go/
COPY --from=git-crypt /usr/local/bin/git-crypt /usr/local/bin/
COPY --from=git /exports/ /
COPY --from=fzf /usr/local/share/fzf/ /usr/local/share/fzf/
COPY --from=firefox /exports/ /
COPY --from=ffmpeg \
  /usr/local/bin/ffmpeg \
  /usr/local/bin/ffprobe \
  /usr/local/bin/
COPY --from=fd /usr/local/bin/fd /usr/local/bin/
COPY --from=docker /usr/bin/docker /usr/bin/
COPY --from=diff-so-fancy /usr/local/lib/node/ /usr/local/lib/node/
COPY --from=dbxcli /usr/local/bin/dbxcli /usr/local/bin/
COPY --from=container-diff /usr/local/bin/container-diff /usr/local/bin/
COPY --from=clone /usr/local/bin/clone /usr/local/bin/
COPY --from=build-essential /exports/ /
COPY --from=bspwm /exports/ /
COPY --from=bat /usr/local/bin/bat /usr/local/bin/
COPY --from=alacritty /exports/ /
COPY --from=adb /usr/local/bin/adb /usr/local/bin/
ENV \
  PATH=/home/admin/dotfiles/bin:${PATH}
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
ENV \
  PATH=${PATH}:/opt/google/chrome
ENV \
  PATH=/usr/local/go/bin:${PATH} \
  GOPATH=/root
RUN \
  cd dotfiles && \
  make ssh
CMD /home/admin/.xinitrc
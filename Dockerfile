

# BASE
FROM phusion/baseimage:bionic-1.0.0 AS base
RUN \
  export LANG=en_NZ.UTF-8 && \
  locale-gen en_NZ.UTF-8 && \
  rm /etc/dpkg/dpkg.cfg.d/excludes && \
  apt-get -q update && \
  dpkg -l | grep ^ii | cut -d' ' -f3 | xargs apt-get install -y --reinstall && \
  apt-get -q clean && \
  rm -rf /var/tmp/* /tmp/*

# APTERYX
FROM base AS apteryx
RUN \
  EXPORT=/usr/local/bin/apteryx && \
  echo '#!/usr/bin/env sh' >> ${EXPORT} && \
  echo 'set -e' >> ${EXPORT} && \
  echo 'export DEBIAN_FRONTEND="noninteractive"' >> ${EXPORT} && \
  echo 'if [ ! "$(find /var/lib/apt/lists/ -mmin -1440)" ]; then apt-get -q update; fi' >> ${EXPORT} && \
  echo 'apt-get install -y --no-install-recommends --auto-remove "${@}"' >> ${EXPORT} && \
  echo 'apt-get -q clean' >> ${EXPORT} && \
  echo 'rm -rf /var/tmp/* /tmp/*' >> ${EXPORT} && \
  chmod +x ${EXPORT}
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/apteryx /exports/usr/local/bin/

# TAR
FROM base AS tar
COPY --from=apteryx /exports/ /
RUN \
  apteryx tar='1.29*'
RUN \
  mkdir -p /exports/bin/ && \
  mv /bin/tar /exports/bin/

# WGET
FROM base AS wget
COPY --from=apteryx /exports/ /
RUN \
  apteryx wget='1.19.4-*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/wget /exports/usr/bin/

# GIT
FROM base AS git
COPY --from=apteryx /exports/ /
RUN \
  add-apt-repository ppa:git-core/ppa && \
  apteryx git='1:2.29.2-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/ && \
  mv /usr/bin/git /exports/usr/bin/ && \
  mv /usr/lib/git-core /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.* /usr/lib/x86_64-linux-gnu/libpcre2-8.so.* /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/share/git-core /exports/usr/share/

# GO
FROM base AS go
COPY --from=wget /exports/ /
COPY --from=tar /exports/ /
RUN \
  wget -O /tmp/go.tgz "https://dl.google.com/go/go1.15.3.linux-amd64.tar.gz" && \
  tar xzvf /tmp/go.tgz && \
  mv go /usr/local/go && \
  rm -rf /tmp/go.tgz
RUN \
  mkdir -p /exports/usr/local/ && \
  mv /usr/local/go /exports/usr/local/

# MAKE
FROM base AS make
COPY --from=apteryx /exports/ /
RUN \
  apteryx make='4.1-*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/make /exports/usr/bin/

# CLONE
FROM base AS clone
COPY --from=go /exports/ /
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
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ /exports/usr/share/ && \
  mv /usr/bin/git /exports/usr/bin/ && \
  mv /usr/lib/git-core /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.* /usr/lib/x86_64-linux-gnu/libpcre2-8.so.* /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/bin/clone /exports/usr/local/bin/ && \
  mv /usr/share/git-core /exports/usr/share/

# BUILD-ESSENTIAL
FROM base AS build-essential
COPY --from=apteryx /exports/ /
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
COPY --from=build-essential /exports/ /
COPY --from=apteryx /exports/ /
COPY --from=clone /exports/ /
COPY --from=make /exports/ /
RUN \
  apteryx libssl-dev xsltproc && \
  clone --https --shallow --tag '0.6.0' https://github.com/AGWA/git-crypt && \
  cd /root/src/github.com/AGWA/git-crypt && \
  ENABLE_MAN=yes make && \
  make install && \
  mv git-crypt /usr/local/bin/git-crypt && \
  mkdir -p /usr/local/share/man/man1/ && \
  mv man/man1/git-crypt.1 /usr/local/share/man/man1/git-crypt.1
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/git-crypt /exports/usr/local/bin/

# ZSH
FROM base AS zsh
COPY --from=apteryx /exports/ /
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
COPY --from=clone /exports/ /
COPY --from=git-crypt /exports/ /
COPY ./secret/dotfiles-key /tmp/dotfiles-key
RUN \
  clone --https --shallow --tag 'v1.34.0' https://github.com/stayradiated/dotfiles && \
  cd /root/src/github.com/stayradiated/dotfiles && \
  git-crypt unlock /tmp/dotfiles-key && \
  rm /tmp/dotfiles-key && \
  mv /root/src/github.com/stayradiated/dotfiles /root/dotfiles && \
  rm -rf src
RUN \
  mkdir -p /exports/root/ && \
  mv /root/dotfiles /exports/root/

# NVM
FROM base AS nvm
COPY --from=clone /exports/ /
RUN \
  clone --https --shallow --tag 'v0.35.3' https://github.com/nvm-sh/nvm && \
  mv /root/src/github.com/nvm-sh/nvm /usr/local/share/nvm && \
  rm -rf /root/src
RUN \
  mkdir -p /exports/usr/local/share/ && \
  mv /usr/local/share/nvm /exports/usr/local/share/

# XZ
FROM base AS xz
COPY --from=apteryx /exports/ /
RUN \
  apteryx xz-utils='5.2.2-*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/xz /exports/usr/bin/

# LUA
FROM base AS lua
COPY --from=apteryx /exports/ /
RUN \
  apteryx lua5.3='5.3.3-*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/lua5.3 /exports/usr/bin/

# SHELL-ROOT
FROM base AS shell-root
COPY --from=apteryx /exports/ /
COPY --from=dotfiles /exports/ /
COPY --from=zsh /exports/ /
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

# NODE
FROM base AS node
COPY --from=nvm /exports/ /
ENV \
  NVM_DIR=/usr/local/share/nvm
RUN \
  bash -c 'source $NVM_DIR/nvm.sh && nvm install 14.13.0' && \
  mv "${NVM_DIR}/versions/node/v14.13.0" /usr/local/lib/node && \
  PATH="/usr/local/lib/node/bin:${PATH}" && \
  npm config set user root && \
  npm config set save-exact true
RUN \
  mkdir -p /exports/usr/local/lib/ && \
  mv /usr/local/lib/node /exports/usr/local/lib/

# PYTHON3-PIP
FROM base AS python3-pip
COPY --from=apteryx /exports/ /
RUN \
  apteryx python3-pip='9.0.1-*' python3-setuptools='39.0.1-*' python3-wheel='0.30.0-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/share/ && \
  mv /usr/bin/pip3 /exports/usr/bin/ && \
  mv /usr/lib/python3.6 /usr/lib/python3.7 /usr/lib/python3.8 /usr/lib/python3 /exports/usr/lib/ && \
  mv /usr/share/python-wheels /exports/usr/share/

# FFMPEG
FROM base AS ffmpeg
COPY --from=wget /exports/ /
COPY --from=tar /exports/ /
COPY --from=xz /exports/ /
RUN \
  wget -O /tmp/ffmpeg.txz 'https://www.johnvansickle.com/ffmpeg/old-releases/ffmpeg-4.2.1-i686-static.tar.xz' && \
  tar -xvf /tmp/ffmpeg.txz && \
  rm /tmp/ffmpeg.txz && \
  mv 'ffmpeg-4.2.1-i686-static' ffmpeg && \
  mv ffmpeg/ffmpeg /usr/local/bin/ffmpeg && \
  mv ffmpeg/ffprobe /usr/local/bin/ffprobe && \
  rm -r ffmpeg
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /exports/usr/local/bin/

# UNZIP
FROM base AS unzip
COPY --from=apteryx /exports/ /
RUN \
  apteryx unzip='6.0-*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/unzip /exports/usr/bin/

# Z.LUA
FROM base AS z.lua
COPY --from=wget /exports/ /
COPY --from=lua /exports/ /
RUN \
  wget -O /usr/local/bin/z.lua 'https://raw.githubusercontent.com/skywind3000/z.lua/1.8.4/z.lua'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/local/bin/ && \
  mv /usr/bin/lua5.3 /exports/usr/bin/ && \
  mv /usr/local/bin/z.lua /exports/usr/local/bin/

# PYTHON2
FROM base AS python2
COPY --from=apteryx /exports/ /
RUN \
  apteryx python2.7='2.7.17-*' && \
  update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
RUN \
  mkdir -p /exports/etc/alternatives/ /exports/etc/ /exports/usr/bin/ /exports/usr/lib/ && \
  mv /etc/alternatives/python /exports/etc/alternatives/ && \
  mv /etc/python2.7 /exports/etc/ && \
  mv /usr/bin/python /usr/bin/python2.7 /exports/usr/bin/ && \
  mv /usr/lib/python2.7 /exports/usr/lib/

# FZF
FROM base AS fzf
COPY --from=clone /exports/ /
RUN \
  clone --https --shallow --tag '0.21.1' https://github.com/junegunn/fzf && \
  mv /root/src/github.com/junegunn/fzf /usr/local/share/fzf && \
  rm -rf /root/src && \
  /usr/local/share/fzf/install --bin
RUN \
  mkdir -p /exports/usr/local/share/ && \
  mv /usr/local/share/fzf /exports/usr/local/share/

# ANTIBODY
FROM base AS antibody
COPY --from=wget /exports/ /
RUN \
  wget -O /tmp/install-antibody.sh https://git.io/antibody && \
  sh /tmp/install-antibody.sh -b /usr/local/bin && \
  rm /tmp/install-antibody.sh
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/antibody /exports/usr/local/bin/

# SHELL-ADMIN
FROM shell-root AS shell-admin
USER admin
WORKDIR /home/admin
ENV \
  PATH=/home/admin/dotfiles/bin:${PATH}
RUN \
  mkdir -p /home/admin/exports && \
  mkdir -p /home/admin/.local/tmp

# YARN
FROM base AS yarn
COPY --from=node /exports/ /
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  npm install -g 'yarn@1.22.4'
RUN \
  mkdir -p /exports/usr/local/lib/ && \
  mv /usr/local/lib/node /exports/usr/local/lib/

# SXHKD
FROM base AS sxhkd
COPY --from=build-essential /exports/ /
COPY --from=apteryx /exports/ /
COPY --from=clone /exports/ /
COPY --from=make /exports/ /
RUN \
  apteryx libxcb-util-dev libxcb-keysyms1-dev && \
  clone --https --shallow --tag '0.6.1' https://github.com/baskerville/sxhkd && \
  cd /root/src/github.com/baskerville/sxhkd && \
  make all && \
  make install && \
  rm -rf /root/src
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/sxhkd /exports/usr/local/bin/

# BSPWM
FROM base AS bspwm
COPY --from=apteryx /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=clone /exports/ /
COPY --from=make /exports/ /
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
COPY --from=wget /exports/ /
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
COPY --from=apteryx /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=make /exports/ /
COPY --from=tar /exports/ /
COPY --from=wget /exports/ /
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
COPY --from=go /exports/ /
COPY --from=clone /exports/ /
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
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/1pw /exports/usr/local/bin/

# DBXCLI
FROM base AS dbxcli
COPY --from=wget /exports/ /
RUN \
  wget -O dbxcli 'https://github.com/dropbox/dbxcli/releases/download/v3.0.0/dbxcli-linux-amd64' && \
  chmod +x dbxcli && \
  mv dbxcli /usr/local/bin/dbxcli
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/dbxcli /exports/usr/local/bin/

# DIFF-SO-FANCY
FROM base AS diff-so-fancy
COPY --from=node /exports/ /
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  npm install -g 'diff-so-fancy@1.2.6'
RUN \
  mkdir -p /exports/usr/local/lib/ && \
  mv /usr/local/lib/node /exports/usr/local/lib/

# FIREFOX
FROM base AS firefox
COPY --from=apteryx /exports/ /
RUN \
  apteryx firefox='82.0+*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/share/ /exports/usr/share/applications/ && \
  mv /usr/bin/firefox /exports/usr/bin/ && \
  mv /usr/lib/firefox-addons /usr/lib/firefox /usr/lib/x86_64-linux-gnu /exports/usr/lib/ && \
  mv /usr/share/icons /exports/usr/share/ && \
  mv /usr/share/applications/firefox.desktop /exports/usr/share/applications/

# GOOGLE-CHROME
FROM base AS google-chrome
COPY --from=wget /exports/ /
COPY --from=apteryx /exports/ /
RUN \
  wget -O /tmp/chrome.deb 'https://www.slimjet.com/chrome/download-chrome.php?file=files/86.0.4240.75/google-chrome-stable_current_amd64.deb' && \
  apteryx /tmp/chrome.deb
RUN \
  mkdir -p /exports/opt/ /exports/usr/lib/ && \
  mv /opt/google /exports/opt/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# XDG-UTILS
FROM base AS xdg-utils
COPY --from=apteryx /exports/ /
RUN \
  apteryx xdg-utils='1.1.2-*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/browse /usr/bin/xdg-desktop-icon /usr/bin/xdg-desktop-menu /usr/bin/xdg-email /usr/bin/xdg-icon-resource /usr/bin/xdg-mime /usr/bin/xdg-open /usr/bin/xdg-screensaver /usr/bin/xdg-settings /exports/usr/bin/

# PULSEAUDIO
FROM base AS pulseaudio
COPY --from=apteryx /exports/ /
RUN \
  apteryx pulseaudio='1:11.1-*'
RUN \
  mkdir -p /exports/etc/ /exports/usr/bin/ /exports/usr/lib/ /exports/usr/share/ && \
  mv /etc/pulse /exports/etc/ && \
  mv /usr/bin/pacat /usr/bin/pacmd /usr/bin/pactl /usr/bin/padsp /usr/bin/pamon /usr/bin/paplay /usr/bin/parec /usr/bin/parecord /usr/bin/pasuspender /usr/bin/pax11publish /usr/bin/pulseaudio /usr/bin/start-pulseaudio-x11 /exports/usr/bin/ && \
  mv /usr/lib/pulse-11.1 /usr/lib/x86_64-linux-gnu /exports/usr/lib/ && \
  mv /usr/share/alsa /usr/share/pulseaudio /exports/usr/share/

# PING
FROM base AS ping
COPY --from=apteryx /exports/ /
RUN \
  apteryx iputils-ping='3:20161105-*'
RUN \
  mkdir -p /exports/bin/ /exports/lib/x86_64-linux-gnu/ && \
  mv /bin/ping /exports/bin/ && \
  mv /lib/x86_64-linux-gnu/libidn.so.* /exports/lib/x86_64-linux-gnu/

# WITHEXEDITORHOST
FROM base AS withexeditorhost
COPY --from=node /exports/ /
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  npm install -g 'withexeditorhost@5.4.5'
RUN \
  mkdir -p /exports/usr/local/lib/ && \
  mv /usr/local/lib/node /exports/usr/local/lib/

# XSV
FROM base AS xsv
COPY --from=wget /exports/ /
COPY --from=tar /exports/ /
RUN \
  wget -O /tmp/xsv.tgz https://github.com/BurntSushi/xsv/releases/download/0.13.0/xsv-0.13.0-i686-unknown-linux-musl.tar.gz && \
  tar xzvf /tmp/xsv.tgz -C /tmp && \
  mv /tmp/xsv /usr/local/bin && \
  rm -r /tmp/xsv*
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/xsv /exports/usr/local/bin/

# XSECURELOCK
FROM base AS xsecurelock
COPY --from=apteryx /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=clone /exports/ /
RUN \
  apteryx apache2-utils autoconf autotools-dev automake binutils gcc libc6-dev libpam-dev libx11-dev libxcomposite-dev libxext-dev libxfixes-dev libxft-dev libxmuu-dev libxrandr-dev libxss-dev make mplayer mpv pamtester pkg-config x11proto-core-dev xscreensaver && \
  clone --https --shallow --tag 'v1.7.0' https://github.com/google/xsecurelock && \
  cd ~/src/github.com/google/xsecurelock && \
  sh autogen.sh && \
  ./configure --with-pam-service-name=xscreensaver && \
  make && \
  make install
RUN \
  mkdir -p /exports/etc/pam.d/ /exports/usr/bin/ /exports/usr/lib/ /exports/usr/share/ /exports/usr/lib/systemd/user/ /exports/usr/local/bin/ /exports/usr/local/libexec/ && \
  mv /etc/pam.d/xscreensaver /exports/etc/pam.d/ && \
  mv /usr/bin/xscreensaver /usr/bin/xscreensaver-* /exports/usr/bin/ && \
  mv /usr/lib/xscreensaver /exports/usr/lib/ && \
  mv /usr/share/xscreensaver /exports/usr/share/ && \
  mv /usr/lib/systemd/user/xscreensaver.service /exports/usr/lib/systemd/user/ && \
  mv /usr/local/bin/xsecurelock /exports/usr/local/bin/ && \
  mv /usr/local/libexec/xsecurelock /exports/usr/local/libexec/

# SIGNAL
FROM base AS signal
COPY --from=apteryx /exports/ /
RUN \
  curl -s https://updates.signal.org/desktop/apt/keys.asc | apt-key add - && \
  echo "deb [arch=amd64] https://updates.signal.org/desktop/apt xenial main" > /etc/apt/sources.list.d/signal-xenial.list && \
  apt-get -q update && \
  apteryx signal-desktop='1.37.2'
RUN \
  mkdir -p /exports/opt/ /exports/usr/bin/ && \
  mv /opt/Signal /exports/opt/ && \
  mv /usr/bin/signal-desktop /exports/usr/bin/

# PROLOG
FROM base AS prolog
COPY --from=apteryx /exports/ /
RUN \
  apt-add-repository ppa:swi-prolog/stable && \
  apteryx swi-prolog
RUN \
  mkdir -p /exports/etc/alternatives/ /exports/usr/bin/ /exports/usr/lib/ /exports/usr/share/ /exports/usr/local/share/ && \
  mv /etc/alternatives/prolog /exports/etc/alternatives/ && \
  mv /usr/bin/swipl /usr/bin/prolog /exports/usr/bin/ && \
  mv /usr/lib/swi-prolog /exports/usr/lib/ && \
  mv /usr/share/swi-prolog /exports/usr/share/ && \
  mv /usr/local/share/swi-prolog /exports/usr/local/share/

# PEEK
FROM base AS peek
COPY --from=apteryx /exports/ /
COPY --from=ffmpeg /exports/ /
RUN \
  add-apt-repository ppa:peek-developers/stable && \
  apteryx peek='1.5.1-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/local/bin/ /exports/usr/share/glib-2.0/schemas/ && \
  mv /usr/bin/peek /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/ && \
  mv /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /exports/usr/local/bin/ && \
  mv /usr/share/glib-2.0/schemas/com.uploadedlobster.peek.gschema.xml /usr/share/glib-2.0/schemas/gschemas.compiled /exports/usr/share/glib-2.0/schemas/

# KHAL
FROM base AS khal
COPY --from=python3-pip /exports/ /
RUN \
  pip3 install khal=='0.10.2'
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/ && \
  mv /usr/local/bin/khal /exports/usr/local/bin/ && \
  mv /usr/local/lib/python3.6 /exports/usr/local/lib/

# HEROKU
FROM base AS heroku
COPY --from=node /exports/ /
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  npm install -g 'heroku@7.46.0'
RUN \
  mkdir -p /exports/usr/local/lib/ && \
  mv /usr/local/lib/node /exports/usr/local/lib/

# GIFSKI
FROM base AS gifski
COPY --from=apteryx /exports/ /
COPY --from=wget /exports/ /
COPY --from=tar /exports/ /
COPY --from=xz /exports/ /
RUN \
  wget -O gifski.txz "https://github.com/ImageOptim/gifski/releases/download/1.2.0/gifski-1.2.0.tar.xz"
RUN \
  tar -xvf gifski.txz debian && \
  apteryx ./debian/gifski*.deb && \
  rm -rf debian
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/gifski /exports/usr/bin/

# FILE
FROM base AS file
COPY --from=apteryx /exports/ /
RUN \
  apteryx file='1:5.32-*'
RUN \
  mkdir -p /exports/etc/ /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/misc/ && \
  mv /etc/magic /etc/magic.mime /exports/etc/ && \
  mv /usr/bin/file /exports/usr/bin/ && \
  mv /usr/lib/file /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/libmagic.so.* /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/share/misc/magic /usr/share/misc/magic.mgc /exports/usr/share/misc/

# FEH
FROM base AS feh
COPY --from=apteryx /exports/ /
COPY --from=wget /exports/ /
COPY --from=tar /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=make /exports/ /
RUN \
  apteryx libimlib2-dev libpng-dev libx11-dev libxt-dev && \
  wget -O /tmp/feh.tar.bz2 https://feh.finalrewind.org/feh-3.5.tar.bz2 && \
  tar xjvf /tmp/feh.tar.bz2 -C /tmp && \
  cd /tmp/feh-3.5 && \
  make curl=0 xinerama=0 && \
  make install app=1 && \
  rm -rf /tmp/feh*
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/share/ /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/bin/feh /exports/usr/local/bin/ && \
  mv /usr/local/share/feh /exports/usr/local/share/ && \
  mv /usr/lib/x86_64-linux-gnu/imlib2 /usr/lib/x86_64-linux-gnu/libImlib2* /usr/lib/x86_64-linux-gnu/libpng* /usr/lib/x86_64-linux-gnu/libX11* /usr/lib/x86_64-linux-gnu/libXt* /exports/usr/lib/x86_64-linux-gnu/

# DENO
FROM base AS deno
COPY --from=wget /exports/ /
COPY --from=unzip /exports/ /
RUN \
  wget -O /tmp/deno.zip 'https://github.com/denoland/deno/releases/download/v1.4.6/deno-x86_64-unknown-linux-gnu.zip' && \
  cd /usr/local/bin && \
  unzip /tmp/deno.zip && \
  rm /tmp/deno.zip
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/deno /exports/usr/local/bin/

# HTTPIE
FROM base AS httpie
COPY --from=python3-pip /exports/ /
RUN \
  pip3 install httpie=='2.2.0'
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/ && \
  mv /usr/local/bin/http /usr/local/bin/https /exports/usr/local/bin/ && \
  mv /usr/local/lib/python3.6 /exports/usr/local/lib/

# DOCKER-COMPOSE
FROM base AS docker-compose
COPY --from=wget /exports/ /
RUN \
  wget -O /usr/local/bin/docker-compose 'https://github.com/docker/compose/releases/download/1.27.4/docker-compose-Linux-x86_64' && \
  chmod +x /usr/local/bin/docker-compose
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/docker-compose /exports/usr/local/bin/

# SHELL-ZSH
FROM shell-admin AS shell-zsh
COPY --from=antibody /exports/ /
COPY --from=git /exports/ /
COPY --from=make /exports/ /
COPY --from=fzf /exports/ /
COPY --from=python2 /exports/ /
COPY --from=z.lua /exports/ /
COPY --from=zsh /exports/ /
RUN \
  cd dotfiles && \
  make zsh && \
  antibody bundle < /home/admin/dotfiles/apps/zsh/bundles.txt > /home/admin/.antibody.sh && \
  XDG_CONFIG_HOME=/home/admin/.config && \
  /usr/local/share/fzf/install --xdg --key-bindings --completion --no-bash && \
  mkdir -p ~/src
RUN \
  mkdir -p /home/admin/exports/home/admin/ /home/admin/exports/home/admin/.cache/ /home/admin/exports/home/admin/.config/ && \
  mv /home/admin/.antibody.sh /home/admin/.zshrc /home/admin/src /home/admin/exports/home/admin/ && \
  mv /home/admin/.cache/antibody /home/admin/exports/home/admin/.cache/ && \
  mv /home/admin/.config/fzf /home/admin/exports/home/admin/.config/
USER root
RUN \
  mkdir -p /exports/bin/ /exports/etc/alternatives/ /exports/etc/ /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ /exports/usr/local/share/ /exports/usr/share/ && \
  mv /bin/zsh /exports/bin/ && \
  mv /etc/alternatives/python /exports/etc/alternatives/ && \
  mv /etc/python2.7 /etc/zsh /exports/etc/ && \
  mv /usr/bin/lua5.3 /usr/bin/python /usr/bin/python2.7 /exports/usr/bin/ && \
  mv /usr/lib/python2.7 /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/zsh /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/bin/z.lua /exports/usr/local/bin/ && \
  mv /usr/local/share/fzf /exports/usr/local/share/ && \
  mv /usr/share/zsh /exports/usr/share/

# SHELL-YARN
FROM shell-admin AS shell-yarn
COPY --from=yarn /exports/ /
USER root
RUN \
  mkdir -p /exports/usr/local/lib/ && \
  mv /usr/local/lib/node /exports/usr/local/lib/

# SHELL-WM
FROM shell-admin AS shell-wm
COPY --from=make /exports/ /
COPY --from=git /exports/ /
COPY --from=bspwm /exports/ /
COPY --from=sxhkd /exports/ /
RUN \
  cd dotfiles && \
  make bspwm sxhkd x11
RUN \
  mkdir -p /home/admin/exports/home/admin/.config/ /home/admin/exports/home/admin/ && \
  mv /home/admin/.config/bspwm /home/admin/.config/sxhkd /home/admin/exports/home/admin/.config/ && \
  mv /home/admin/.xinitrc /home/admin/exports/home/admin/
USER root
RUN \
  mkdir -p /exports/usr/lib/ /exports/usr/local/bin/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/ && \
  mv /usr/local/bin/bspc /usr/local/bin/bspwm /usr/local/bin/sxhkd /exports/usr/local/bin/

# SHELL-VIM
FROM shell-admin AS shell-vim
COPY --from=make /exports/ /
COPY --from=git /exports/ /
COPY --from=neovim /exports/ /
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
USER root
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/include/ /exports/usr/local/lib/ /exports/usr/local/share/ && \
  mv /usr/local/bin/nvim /exports/usr/local/bin/ && \
  mv /usr/local/include/python3.6 /exports/usr/local/include/ && \
  mv /usr/local/lib/python3.6 /exports/usr/local/lib/ && \
  mv /usr/local/share/nvim /exports/usr/local/share/

# SHELL-TMUX
FROM shell-admin AS shell-tmux
COPY --from=make /exports/ /
COPY --from=git /exports/ /
COPY --from=tmux /exports/ /
RUN \
  cd dotfiles && \
  make tmux
RUN \
  mkdir -p /home/admin/exports/home/admin/ && \
  mv /home/admin/.tmux.conf /home/admin/.tmux /home/admin/exports/home/admin/
USER root
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/lib/ && \
  mv /usr/local/bin/tmux /exports/usr/local/bin/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# SHELL-SSH
FROM shell-admin AS shell-ssh
COPY --from=make /exports/ /
RUN \
  cd dotfiles && \
  make ssh
RUN \
  mkdir -p /home/admin/exports/home/admin/ && \
  mv /home/admin/.ssh /home/admin/exports/home/admin/

# SHELL-RANGER
FROM shell-admin AS shell-ranger
COPY --from=make /exports/ /
COPY --from=ranger /exports/ /
RUN \
  cd dotfiles && \
  make ranger
RUN \
  mkdir -p /home/admin/exports/home/admin/.config/ && \
  mv /home/admin/.config/ranger /home/admin/exports/home/admin/.config/
USER root
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/ && \
  mv /usr/local/bin/ranger /usr/local/bin/rifle /exports/usr/local/bin/ && \
  mv /usr/local/lib/python3.6 /exports/usr/local/lib/

# SHELL-PASSWORDS
FROM shell-admin AS shell-passwords
COPY --from=make /exports/ /
COPY --from=dbxcli /exports/ /
COPY --from=one-pw /exports/ /
RUN \
  cd dotfiles && \
  make dbxcli && \
  1pw-pull
RUN \
  mkdir -p /home/admin/exports/home/admin/.config/ /home/admin/exports/home/admin/ && \
  mv /home/admin/.config/dbxcli /home/admin/exports/home/admin/.config/ && \
  mv /home/admin/vaults /home/admin/exports/home/admin/
USER root
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/1pw /usr/local/bin/dbxcli /exports/usr/local/bin/

# SHELL-NPM
FROM shell-admin AS shell-npm
COPY --from=make /exports/ /
COPY --from=node /exports/ /
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  cd dotfiles && \
  make npm && \
  mkdir -p /home/admin/.cache/npm && \
  npm config set prefix /home/admin/.cache/npm
RUN \
  mkdir -p /home/admin/exports/home/admin/ && \
  mv /home/admin/.npmrc /home/admin/exports/home/admin/
USER root
RUN \
  mkdir -p /exports/usr/local/lib/ && \
  mv /usr/local/lib/node /exports/usr/local/lib/

# SHELL-GIT
FROM shell-admin AS shell-git
COPY --from=make /exports/ /
COPY --from=git /exports/ /
COPY --from=git-crypt /exports/ /
COPY --from=diff-so-fancy /exports/ /
RUN \
  cd dotfiles && \
  make git
RUN \
  mkdir -p /home/admin/exports/home/admin/ && \
  mv /home/admin/.gitconfig /home/admin/exports/home/admin/
USER root
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ /exports/usr/local/lib/ /exports/usr/share/ && \
  mv /usr/bin/git /exports/usr/bin/ && \
  mv /usr/lib/git-core /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.* /usr/lib/x86_64-linux-gnu/libpcre2-8.so.* /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/bin/git-crypt /exports/usr/local/bin/ && \
  mv /usr/local/lib/node /exports/usr/local/lib/ && \
  mv /usr/share/git-core /exports/usr/share/

# SHELL-BROWSER
FROM shell-admin AS shell-browser
COPY --from=make /exports/ /
COPY --from=xdg-utils /exports/ /
COPY --from=google-chrome /exports/ /
COPY --from=firefox /exports/ /
ENV \
  PATH=${PATH}:/opt/google/chrome
RUN \
  cd dotfiles && \
  make firefox
RUN \
  mkdir -p /home/admin/exports/home/admin/.config/ && \
  mv /home/admin/.config/mimeapps.list /home/admin/exports/home/admin/.config/
USER root
RUN \
  mkdir -p /exports/opt/ /exports/usr/bin/ /exports/usr/lib/ /exports/usr/share/applications/ /exports/usr/share/ && \
  mv /opt/google /exports/opt/ && \
  mv /usr/bin/firefox /exports/usr/bin/ && \
  mv /usr/lib/firefox-addons /usr/lib/firefox /usr/lib/x86_64-linux-gnu /exports/usr/lib/ && \
  mv /usr/share/applications/firefox.desktop /exports/usr/share/applications/ && \
  mv /usr/share/icons /exports/usr/share/

# ZOOM
FROM base AS zoom
COPY --from=apteryx /exports/ /
COPY --from=wget /exports/ /
RUN \
  wget -O /tmp/zoom.deb 'https://zoom.us/client/5.3.469451.0927/zoom_amd64.deb' && \
  apteryx /tmp/zoom.deb
RUN \
  mkdir -p /exports/opt/ /exports/usr/bin/ /exports/usr/lib/ && \
  mv /opt/zoom /exports/opt/ && \
  mv /usr/bin/zoom /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# XCLIP
FROM base AS xclip
COPY --from=apteryx /exports/ /
RUN \
  apteryx xclip='0.12+*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/bin/xclip /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu/libICE.so.* /usr/lib/x86_64-linux-gnu/libSM.so.* /usr/lib/x86_64-linux-gnu/libX11.so.* /usr/lib/x86_64-linux-gnu/libXau.so.* /usr/lib/x86_64-linux-gnu/libxcb.so.* /usr/lib/x86_64-linux-gnu/libXdmcp.so.* /usr/lib/x86_64-linux-gnu/libXext.so.* /usr/lib/x86_64-linux-gnu/libXmu.so.* /usr/lib/x86_64-linux-gnu/libXt.so.* /exports/usr/lib/x86_64-linux-gnu/

# ROFI
FROM base AS rofi
COPY --from=apteryx /exports/ /
RUN \
  apteryx rofi='1.5.0-1'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ && \
  mv /usr/bin/rofi /usr/bin/rofi-sensible-terminal /usr/bin/rofi-theme-selector /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# REDSHIFT
FROM base AS redshift
COPY --from=apteryx /exports/ /
RUN \
  apteryx redshift='1.11-1ubuntu1'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ && \
  mv /usr/bin/redshift /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# QPDFVIEW
FROM base AS qpdfview
COPY --from=apteryx /exports/ /
RUN \
  apteryx qpdfview='0.4.14-1build1'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ && \
  mv /usr/bin/qpdfview /exports/usr/bin/ && \
  mv /usr/lib/qpdfview /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# PAVUCONTROL
FROM base AS pavucontrol
COPY --from=apteryx /exports/ /
COPY --from=pulseaudio /exports/ /
RUN \
  apteryx pavucontrol='3.0-4'
RUN \
  mkdir -p /exports/etc/ /exports/usr/bin/ /exports/usr/lib/ /exports/usr/share/ /exports/usr/share/glib-2.0/schemas/ && \
  mv /etc/gtk-3.0 /etc/pulse /exports/etc/ && \
  mv /usr/bin/pacat /usr/bin/pacmd /usr/bin/pactl /usr/bin/padsp /usr/bin/pamon /usr/bin/paplay /usr/bin/parec /usr/bin/parecord /usr/bin/pasuspender /usr/bin/pavucontrol /usr/bin/pax11publish /usr/bin/pulseaudio /usr/bin/start-pulseaudio-x11 /usr/bin/update-mime-database /exports/usr/bin/ && \
  mv /usr/lib/pulse-11.1 /usr/lib/x86_64-linux-gnu /exports/usr/lib/ && \
  mv /usr/share/alsa /usr/share/libthai /usr/share/mime /usr/share/pavucontrol /usr/share/pulseaudio /usr/share/sounds /usr/share/themes /usr/share/thumbnailers /exports/usr/share/ && \
  mv /usr/share/glib-2.0/schemas/gschemas.compiled /usr/share/glib-2.0/schemas/org.gtk.Settings.ColorChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.EmojiChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.FileChooser.gschema.xml /exports/usr/share/glib-2.0/schemas/

# LIGHT
FROM base AS light
COPY --from=build-essential /exports/ /
COPY --from=apteryx /exports/ /
COPY --from=clone /exports/ /
RUN \
  apteryx automake autoconf && \
  clone --https --shallow --tag 'v1.2.2' https://github.com/haikarainen/light && \
  cd /root/src/github.com/haikarainen/light && \
  ./autogen.sh && \
  ./configure && \
  make && \
  make install
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/light /exports/usr/local/bin/

# FONTS
FROM base AS fonts
COPY --from=apteryx /exports/ /
COPY --from=wget /exports/ /
RUN \
  apteryx fonts-noto='20171026-2' fonts-noto-color-emoji='0~20180810-*' ttf-ubuntu-font-family='1:0.83-2' xfonts-utils='1:7.7+6' fontconfig='2.12.6-*' && \
  mkdir -p /usr/share/fonts/X11/bitmap && \
  wget -O /usr/share/fonts/X11/bitmap/gomme.bdf 'https://raw.githubusercontent.com/Tecate/bitmap-fonts/master/bitmap/gomme/Gomme10x20n.bdf' && \
  wget -O /usr/share/fonts/X11/bitmap/terminal.bdf 'https://raw.githubusercontent.com/Tecate/bitmap-fonts/master/bitmap/dylex/7x13.bdf' && \
  cd /etc/fonts/conf.d && \
  rm 10* 70-no-bitmaps.conf && \
  ln -s ../conf.avail/70-yes-bitmaps.conf . && \
  dpkg-reconfigure fontconfig && \
  fc-cache -fv
RUN \
  mkdir -p /exports/etc/ /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/share/ /exports/usr/sbin/ /exports/usr/share/aclocal/ /exports/usr/share/apport/package-hooks/ /exports/usr/share/ /exports/usr/share/pkgconfig/ /exports/usr/share/xml/ /exports/var/cache/ /exports/var/lib/ && \
  mv /etc/fonts /exports/etc/ && \
  mv /usr/bin/bdftopcf /usr/bin/bdftruncate /usr/bin/fc-cache /usr/bin/fc-cat /usr/bin/fc-list /usr/bin/fc-match /usr/bin/fc-pattern /usr/bin/fc-query /usr/bin/fc-scan /usr/bin/fc-validate /usr/bin/fonttosfnt /usr/bin/mkfontdir /usr/bin/mkfontscale /usr/bin/ucs2any /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu/libfontconfig.so.* /usr/lib/x86_64-linux-gnu/libfontenc.so.* /usr/lib/x86_64-linux-gnu/libfreetype.so.* /usr/lib/x86_64-linux-gnu/libpng16.so.* /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/share/fonts /exports/usr/local/share/ && \
  mv /usr/sbin/update-fonts-alias /usr/sbin/update-fonts-dir /usr/sbin/update-fonts-scale /exports/usr/sbin/ && \
  mv /usr/share/aclocal/fontutil.m4 /exports/usr/share/aclocal/ && \
  mv /usr/share/apport/package-hooks/source_fontconfig.py /exports/usr/share/apport/package-hooks/ && \
  mv /usr/share/fonts /exports/usr/share/ && \
  mv /usr/share/pkgconfig/fontutil.pc /exports/usr/share/pkgconfig/ && \
  mv /usr/share/xml/fontconfig /exports/usr/share/xml/ && \
  mv /var/cache/fontconfig /exports/var/cache/ && \
  mv /var/lib/xfonts /exports/var/lib/

# FLAMESHOT
FROM base AS flameshot
COPY --from=apteryx /exports/ /
RUN \
  apteryx flameshot='0.5.1-2'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ && \
  mv /usr/bin/flameshot /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# CHARLES
FROM base AS charles
COPY --from=wget /exports/ /
COPY --from=tar /exports/ /
RUN \
  wget -O /tmp/charles.tgz 'https://www.charlesproxy.com/assets/release/4.5.6/charles-proxy-4.5.6_amd64.tar.gz' && \
  tar -xzvf /tmp/charles.tgz && \
  rm /tmp/charles.tgz && \
  mv ./charles/bin/charles /usr/local/bin/charles && \
  mkdir -p /usr/share/java/charles/ && \
  mv ./charles/lib/* /usr/share/java/charles/ && \
  rm -r ./charles
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/share/java/ && \
  mv /usr/local/bin/charles /exports/usr/local/bin/ && \
  mv /usr/share/java/charles /exports/usr/share/java/

# AUDACITY
FROM base AS audacity
COPY --from=apteryx /exports/ /
RUN \
  apteryx audacity='2.2.1-1'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/share/ && \
  mv /usr/bin/audacity /exports/usr/bin/ && \
  mv /usr/lib/liblilv-0.so.* /usr/lib/x86_64-linux-gnu /exports/usr/lib/ && \
  mv /usr/share/alsa /exports/usr/share/

# ALACRITTY
FROM base AS alacritty
COPY --from=apteryx /exports/ /
COPY --from=wget /exports/ /
RUN \
  wget -O /tmp/alacritty.deb 'https://github.com/alacritty/alacritty/releases/download/v0.4.2/Alacritty-v0.4.2-ubuntu_18_04_amd64.deb' && \
  apteryx /tmp/alacritty.deb
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ && \
  mv /usr/bin/alacritty /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# WATSON
FROM base AS watson
COPY --from=python3-pip /exports/ /
RUN \
  pip3 install td-watson=='1.10.0'
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/ && \
  mv /usr/local/bin/watson /exports/usr/local/bin/ && \
  mv /usr/local/lib/python3.6 /exports/usr/local/lib/

# TREE
FROM base AS tree
COPY --from=apteryx /exports/ /
RUN \
  apteryx tree='1.7.0-*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/tree /exports/usr/bin/

# TIG
FROM base AS tig
COPY --from=build-essential /exports/ /
COPY --from=apteryx /exports/ /
COPY --from=clone /exports/ /
COPY --from=make /exports/ /
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
COPY --from=apteryx /exports/ /
RUN \
  apteryx sudo='1.8.21p2*'
RUN \
  mkdir -p /exports/etc/ /exports/usr/bin/ /exports/usr/lib/ /exports/var/lib/ && \
  mv /etc/sudoers /exports/etc/ && \
  mv /usr/bin/sudo /exports/usr/bin/ && \
  mv /usr/lib/sudo /exports/usr/lib/ && \
  mv /var/lib/sudo /exports/var/lib/

# SHOEBOX
FROM base AS shoebox
COPY --from=node /exports/ /
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  npm install -g '@stayradiated/shoebox@1.4.0'
RUN \
  mkdir -p /exports/usr/local/lib/ && \
  mv /usr/local/lib/node /exports/usr/local/lib/

# SD
FROM base AS sd
COPY --from=wget /exports/ /
COPY --from=unzip /exports/ /
RUN \
  wget -O /tmp/sd.zip 'https://github.com/chmln/sd/releases/download/v0.7.4/sd-0.7.4.x86_64-unknown-linux-gnu.zip' && \
  unzip /tmp/sd.zip && \
  rm /tmp/sd.zip && \
  mv b/x86_64-unknown-linux-gnu/release/sd /usr/local/bin/sd && \
  mkdir -p /usr/local/share/man/man1 && \
  mv b/x86_64-unknown-linux-gnu/release/build/sd-*/out/sd.1 /usr/local/share/man/man1/sd.1 && \
  rm -r b
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/sd /exports/usr/local/bin/

# SAFE-RM
FROM base AS safe-rm
COPY --from=clone /exports/ /
RUN \
  clone --https --shallow --tag '1.0.7' https://github.com/kaelzhang/shell-safe-rm && \
  cd /root/src/github.com/kaelzhang/shell-safe-rm && \
  cp ./bin/rm.sh /usr/local/bin/safe-rm && \
  rm -rf /root/src/
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/safe-rm /exports/usr/local/bin/

# RSYNC
FROM base AS rsync
COPY --from=apteryx /exports/ /
RUN \
  apteryx rsync='3.1.2-*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/rsync /exports/usr/bin/

# RIPGREP
FROM base AS ripgrep
COPY --from=wget /exports/ /
COPY --from=tar /exports/ /
RUN \
  wget -O /tmp/ripgrep.tgz 'https://github.com/BurntSushi/ripgrep/releases/download/12.0.1/ripgrep-12.0.1-x86_64-unknown-linux-musl.tar.gz' && \
  tar -xzvf /tmp/ripgrep.tgz && \
  rm /tmp/ripgrep.tgz && \
  mv ripgrep-12.0.1-x86_64-unknown-linux-musl ripgrep && \
  mv ripgrep/rg /usr/local/bin/rg && \
  mkdir -p /usr/local/share/man/man1 && \
  mv ripgrep/doc/rg.1 /usr/local/share/man/man1/rg.1 && \
  rm -r ripgrep
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/rg /exports/usr/local/bin/

# PRETTYPING
FROM base AS prettyping
COPY --from=wget /exports/ /
COPY --from=ping /exports/ /
RUN \
  wget -O /usr/local/bin/prettyping 'https://raw.githubusercontent.com/denilsonsa/prettyping/v1.0.1/prettyping' && \
  chmod +x /usr/local/bin/prettyping
RUN \
  mkdir -p /exports/bin/ /exports/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ && \
  mv /bin/ping /exports/bin/ && \
  mv /lib/x86_64-linux-gnu/libidn.so.* /exports/lib/x86_64-linux-gnu/ && \
  mv /usr/local/bin/prettyping /exports/usr/local/bin/

# PGCLI
FROM base AS pgcli
COPY --from=apteryx /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=python3-pip /exports/ /
RUN \
  apteryx libpq-dev python3-dev && \
  pip3 install pgcli=='3.0.0'
RUN \
  mkdir -p /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ /exports/usr/local/lib/ /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/libpq.* /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/bin/pgcli /usr/local/bin/sqlformat /exports/usr/local/bin/ && \
  mv /usr/local/lib/python3.6 /exports/usr/local/lib/ && \
  mv /usr/lib/python3.6 /usr/lib/python3.7 /usr/lib/python3.8 /usr/lib/python3 /exports/usr/lib/

# NP
FROM base AS np
COPY --from=node /exports/ /
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  npm install -g 'np@6.2.3'
RUN \
  mkdir -p /exports/usr/local/lib/ && \
  mv /usr/local/lib/node /exports/usr/local/lib/

# NCU
FROM base AS ncu
COPY --from=node /exports/ /
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  npm install -g 'npm-check-updates@4.1.2'
RUN \
  mkdir -p /exports/usr/local/lib/ && \
  mv /usr/local/lib/node /exports/usr/local/lib/

# MOREUTILS
FROM base AS moreutils
COPY --from=apteryx /exports/ /
RUN \
  apteryx moreutils='0.60-*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/chronic /usr/bin/combine /usr/bin/errno /usr/bin/ifdata /usr/bin/ifne /usr/bin/isutf8 /usr/bin/lckdo /usr/bin/mispipe /usr/bin/parallel /usr/bin/pee /usr/bin/sponge /usr/bin/ts /usr/bin/vidir /usr/bin/vipe /usr/bin/zrun /exports/usr/bin/

# MEDIAINFO
FROM base AS mediainfo
COPY --from=apteryx /exports/ /
RUN \
  apteryx mediainfo='17.12-1'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/bin/mediainfo /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.* /usr/lib/x86_64-linux-gnu/libmediainfo.so.* /usr/lib/x86_64-linux-gnu/libmms.so.* /usr/lib/x86_64-linux-gnu/libtinyxml2.so.* /usr/lib/x86_64-linux-gnu/libzen.so.* /exports/usr/lib/x86_64-linux-gnu/

# JQ
FROM base AS jq
COPY --from=wget /exports/ /
RUN \
  wget -O /usr/local/bin/jq 'https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64' && \
  chmod +x /usr/local/bin/jq
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/jq /exports/usr/local/bin/

# HTOP
FROM base AS htop
COPY --from=apteryx /exports/ /
RUN \
  apteryx htop='2.1.0-*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/htop /exports/usr/bin/

# GH
FROM base AS gh
COPY --from=wget /exports/ /
COPY --from=tar /exports/ /
RUN \
  wget -O /tmp/gh.tgz 'https://github.com/cli/cli/releases/download/v0.7.0/gh_0.7.0_linux_amd64.tar.gz' && \
  tar xzvf /tmp/gh.tgz && \
  rm /tmp/gh.tgz && \
  mv 'gh_0.7.0_linux_amd64/bin/gh' /usr/local/bin/gh && \
  rm -r 'gh_0.7.0_linux_amd64'
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/gh /exports/usr/local/bin/

# FD
FROM base AS fd
COPY --from=wget /exports/ /
COPY --from=tar /exports/ /
RUN \
  wget -O /tmp/fd.tgz 'https://github.com/sharkdp/fd/releases/download/v8.0.0/fd-v8.0.0-x86_64-unknown-linux-musl.tar.gz' && \
  tar -xzvf /tmp/fd.tgz && \
  rm /tmp/fd.tgz && \
  mv 'fd-v8.0.0-x86_64-unknown-linux-musl' fd && \
  mv fd/fd /usr/local/bin/fd && \
  mkdir -p /usr/local/share/man/man1 && \
  mv fd/fd.1 /usr/local/share/man/man1/fd.1 && \
  rm -r fd
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/fd /exports/usr/local/bin/

# DOCKER
FROM base AS docker
COPY --from=apteryx /exports/ /
COPY --from=wget /exports/ /
RUN \
  wget -O /tmp/docker.gpg https://download.docker.com/linux/ubuntu/gpg && \
  apt-key add /tmp/docker.gpg && \
  apt-add-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable' && \
  apteryx docker-ce='5:19.03.8*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/docker /exports/usr/bin/

# CONTAINER-DIFF
FROM base AS container-diff
COPY --from=wget /exports/ /
RUN \
  wget -O container-diff 'https://storage.googleapis.com/container-diff/v0.15.0/container-diff-linux-amd64' && \
  chmod +x container-diff && \
  mv container-diff /usr/local/bin/container-diff
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/container-diff /exports/usr/local/bin/

# BAT
FROM base AS bat
COPY --from=wget /exports/ /
COPY --from=tar /exports/ /
RUN \
  wget -O bat.tgz 'https://github.com/sharkdp/bat/releases/download/v0.13.0/bat-v0.13.0-x86_64-unknown-linux-gnu.tar.gz' && \
  tar -xzvf bat.tgz && \
  rm bat.tgz && \
  mv 'bat-v0.13.0-x86_64-unknown-linux-gnu/bat' /usr/local/bin/bat && \
  rm -rf 'bat-v0.13.0-x86_64-unknown-linux-gnu'
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/bat /exports/usr/local/bin/

# ADB
FROM base AS adb
COPY --from=wget /exports/ /
COPY --from=unzip /exports/ /
RUN \
  wget -O tools.zip 'https://dl.google.com/android/repository/platform-tools_r29.0.5-linux.zip' && \
  unzip tools.zip && \
  rm tools.zip && \
  mv platform-tools/adb /usr/local/bin/adb && \
  rm -rf platform-tools
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/adb /exports/usr/local/bin/

# ACPI
FROM base AS acpi
COPY --from=apteryx /exports/ /
RUN \
  apteryx acpi='1.7-1.1'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/acpi /exports/usr/bin/

# X11-UTILS
FROM base AS x11-utils
COPY --from=apteryx /exports/ /
RUN \
  apteryx x11-utils='7.7+*' x11-xkb-utils='7.7+*' x11-xserver-utils='7.7+*' xkb-data='2.23.1-*'
RUN \
  mkdir -p /exports/etc/ /exports/etc/init.d/ /exports/etc/rcS.d/ /exports/usr/ && \
  mv /etc/X11 /etc/sensors.d /etc/sensors3.conf /exports/etc/ && \
  mv /etc/init.d/x11-common /exports/etc/init.d/ && \
  mv /etc/rcS.d/S01x11-common /exports/etc/rcS.d/ && \
  mv /usr/bin /usr/lib /usr/share /exports/usr/

# MESA
FROM base AS mesa
COPY --from=apteryx /exports/ /
RUN \
  apteryx mesa-utils='8.4.0-*' mesa-utils-extra='8.4.0-*'
RUN \
  mkdir -p /exports/etc/ /exports/usr/ /exports/usr/lib/ && \
  mv /etc/glvnd /etc/sensors.d /etc/sensors3.conf /exports/etc/ && \
  mv /usr/bin /usr/share /exports/usr/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# LIBXV1
FROM base AS libxv1
COPY --from=apteryx /exports/ /
RUN \
  apteryx libxv1='2:1.0.11-1'
RUN \
  mkdir -p /exports/usr/lib/ /exports/usr/share/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/ && \
  mv /usr/share/X11 /exports/usr/share/

# MY-DESKTOP
FROM shell-admin AS my-desktop
COPY --from=libxv1 /exports/ /
COPY --from=mesa /exports/ /
COPY --from=x11-utils /exports/ /
COPY --from=acpi /exports/ /
COPY --from=adb /exports/ /
COPY --from=bat /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=clone /exports/ /
COPY --from=container-diff /exports/ /
COPY --from=docker /exports/ /
COPY --from=fd /exports/ /
COPY --from=ffmpeg /exports/ /
COPY --from=fzf /exports/ /
COPY --from=gh /exports/ /
COPY --from=go /exports/ /
COPY --from=htop /exports/ /
COPY --from=jq /exports/ /
COPY --from=make /exports/ /
COPY --from=mediainfo /exports/ /
COPY --from=moreutils /exports/ /
COPY --from=ncu /exports/ /
COPY --from=node /exports/ /
COPY --from=np /exports/ /
COPY --from=pgcli /exports/ /
COPY --from=prettyping /exports/ /
COPY --from=ripgrep /exports/ /
COPY --from=rsync /exports/ /
COPY --from=safe-rm /exports/ /
COPY --from=sd /exports/ /
COPY --from=shoebox /exports/ /
COPY --from=sudo /exports/ /
COPY --from=tig /exports/ /
COPY --from=tree /exports/ /
COPY --from=unzip /exports/ /
COPY --from=watson /exports/ /
COPY --from=wget /exports/ /
COPY --from=alacritty /exports/ /
COPY --from=audacity /exports/ /
COPY --from=charles /exports/ /
COPY --from=flameshot /exports/ /
COPY --from=fonts /exports/ /
COPY --from=light /exports/ /
COPY --from=pavucontrol /exports/ /
COPY --from=qpdfview /exports/ /
COPY --from=redshift /exports/ /
COPY --from=rofi /exports/ /
COPY --from=xclip /exports/ /
COPY --from=xdg-utils /exports/ /
COPY --from=zoom /exports/ /
COPY --from=shell-browser --chown=admin /home/admin/exports/ /
COPY --from=shell-browser /exports/ /
COPY --from=shell-git --chown=admin /home/admin/exports/ /
COPY --from=shell-git /exports/ /
COPY --from=shell-npm --chown=admin /home/admin/exports/ /
COPY --from=shell-npm /exports/ /
COPY --from=shell-passwords --chown=admin /home/admin/exports/ /
COPY --from=shell-passwords /exports/ /
COPY --from=shell-ranger --chown=admin /home/admin/exports/ /
COPY --from=shell-ranger /exports/ /
COPY --from=shell-ssh --chown=admin /home/admin/exports/ /
COPY --from=shell-tmux --chown=admin /home/admin/exports/ /
COPY --from=shell-tmux /exports/ /
COPY --from=shell-vim --chown=admin /home/admin/exports/ /
COPY --from=shell-vim /exports/ /
COPY --from=shell-wm --chown=admin /home/admin/exports/ /
COPY --from=shell-wm /exports/ /
COPY --from=shell-yarn /exports/ /
COPY --from=shell-zsh --chown=admin /home/admin/exports/ /
COPY --from=shell-zsh /exports/ /
COPY --from=docker-compose /exports/ /
COPY --from=httpie /exports/ /
COPY --from=deno /exports/ /
COPY --from=feh /exports/ /
COPY --from=file /exports/ /
COPY --from=gifski /exports/ /
COPY --from=heroku /exports/ /
COPY --from=khal /exports/ /
COPY --from=peek /exports/ /
COPY --from=prolog /exports/ /
COPY --from=signal /exports/ /
COPY --from=xsecurelock /exports/ /
COPY --from=xsv /exports/ /
COPY --from=withexeditorhost /exports/ /
ENV \
  PATH=/usr/local/go/bin:${PATH} \
  GOPATH=/root
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
ENV \
  PATH=${PATH}:/opt/google/chrome
ENV \
  PATH=${PATH}:/home/admin/.cache/npm/bin
ENV \
  PATH=/home/admin/.yarn/bin:${PATH}
RUN \
  chmod 0600 /home/admin/.ssh/*
CMD /home/admin/.xinitrc
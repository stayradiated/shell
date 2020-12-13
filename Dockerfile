

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
  wget -O /tmp/go.tgz "https://dl.google.com/go/go1.15.5.linux-amd64.tar.gz" && \
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
  clone --https --shallow --tag 'v1.39.0' https://github.com/stayradiated/dotfiles && \
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
  clone --https --shallow --tag 'v0.37.0' https://github.com/nvm-sh/nvm && \
  mv /root/src/github.com/nvm-sh/nvm /usr/local/share/nvm && \
  rm -rf /root/src
RUN \
  mkdir -p /exports/usr/local/share/ && \
  mv /usr/local/share/nvm /exports/usr/local/share/

# PYTHON3-PIP
FROM base AS python3-pip
COPY --from=apteryx /exports/ /
RUN \
  apteryx python3-pip='9.0.1-*' python3-dev='3.6.7-*' python3-setuptools='39.0.1-*' python3-venv='3.6.7-*' python3-wheel='0.30.0-*' && \
  pip3 install wheel
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/include/ /exports/usr/lib/ /exports/usr/share/gdb/auto-load/ /exports/usr/share/ /exports/usr/share/python3/runtime.d/ && \
  mv /usr/bin/pip3 /usr/bin/pybuild /usr/bin/python3*-config /usr/bin/pyvenv* /usr/bin/x86_64-linux-gnu-python3*-config /exports/usr/bin/ && \
  mv /usr/include/*.h /usr/include/arpa /usr/include/asm-generic /usr/include/drm /usr/include/linux /usr/include/misc /usr/include/mtd /usr/include/net /usr/include/netash /usr/include/netatalk /usr/include/netax25 /usr/include/neteconet /usr/include/netinet /usr/include/netipx /usr/include/netiucv /usr/include/netpacket /usr/include/netrom /usr/include/netrose /usr/include/nfs /usr/include/protocols /usr/include/python3.6 /usr/include/python3.6m /usr/include/rdma /usr/include/rpc /usr/include/rpcsvc /usr/include/scsi /usr/include/sound /usr/include/video /usr/include/x86_64-linux-gnu /usr/include/xen /exports/usr/include/ && \
  mv /usr/lib/python3.6 /usr/lib/python3.7 /usr/lib/python3.8 /usr/lib/python3 /usr/lib/x86_64-linux-gnu /exports/usr/lib/ && \
  mv /usr/share/gdb/auto-load/lib /exports/usr/share/gdb/auto-load/ && \
  mv /usr/share/python-wheels /exports/usr/share/ && \
  mv /usr/share/python3/runtime.d/dh-python.rtupdate /exports/usr/share/python3/runtime.d/

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

# LUA
FROM base AS lua
COPY --from=apteryx /exports/ /
RUN \
  apteryx lua5.3='5.3.3-*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/lua5.3 /exports/usr/bin/

# NODE
FROM base AS node
COPY --from=nvm /exports/ /
ENV \
  NVM_DIR=/usr/local/share/nvm
RUN \
  bash -c 'source $NVM_DIR/nvm.sh && nvm install 14.15.1' && \
  mv "${NVM_DIR}/versions/node/v14.15.1" /usr/local/lib/node && \
  PATH="/usr/local/lib/node/bin:${PATH}" && \
  npm config set user root && \
  npm config set save-exact true
RUN \
  mkdir -p /exports/usr/local/lib/ && \
  mv /usr/local/lib/node /exports/usr/local/lib/

# PIPX
FROM base AS pipx
COPY --from=apteryx /exports/ /
COPY --from=python3-pip /exports/ /
RUN \
  pip3 install pipx==0.15.6.0
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/ && \
  mv /usr/local/bin/pipx /exports/usr/local/bin/ && \
  mv /usr/local/lib/python3.6 /exports/usr/local/lib/

# XZ
FROM base AS xz
COPY --from=apteryx /exports/ /
RUN \
  apteryx xz-utils='5.2.2-*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/xz /exports/usr/bin/

# SCDOC
FROM base AS scdoc
COPY --from=build-essential /exports/ /
COPY --from=clone /exports/ /
RUN \
  clone --https --shallow --tag "${VERSION}" https://git.sr.ht/~sircmpwn/scdoc && \
  cd ~/src/git.sr.ht/~sircmpwn/scdoc && \
  make && \
  make install && \
  rm -rf ~/src
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/scdoc /exports/usr/local/bin/

# FIREFOX
FROM base AS firefox
COPY --from=apteryx /exports/ /
RUN \
  apteryx firefox='83.0+*'
RUN \
  mkdir -p /exports/etc/ /exports/run/ /exports/usr/bin/ /exports/usr/lib/ /exports/usr/share/applications/ /exports/usr/share/ && \
  mv /etc/firefox /exports/etc/ && \
  mv /run/firefox-restart-required /exports/run/ && \
  mv /usr/bin/firefox /exports/usr/bin/ && \
  mv /usr/lib/firefox-addons /usr/lib/firefox /usr/lib/x86_64-linux-gnu /exports/usr/lib/ && \
  mv /usr/share/applications/firefox.desktop /exports/usr/share/applications/ && \
  mv /usr/share/glib-2.0 /usr/share/icons /usr/share/mime /exports/usr/share/

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

# SHELL-ADMIN
FROM shell-root AS shell-admin
USER admin
WORKDIR /home/admin
ENV \
  PATH=/home/admin/dotfiles/bin:${PATH}
RUN \
  mkdir -p /home/admin/exports && \
  mkdir -p /home/admin/.local/tmp

# Z.LUA
FROM base AS z.lua
COPY --from=wget /exports/ /
COPY --from=lua /exports/ /
RUN \
  wget -O /usr/local/bin/z.lua 'https://raw.githubusercontent.com/skywind3000/z.lua/1.8.7/z.lua'
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
  clone --https --shallow --tag '0.24.3' https://github.com/junegunn/fzf && \
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

# YARN
FROM base AS yarn
COPY --from=node /exports/ /
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  npm install -g 'yarn@1.22.10'
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
  clone --https --shallow --tag '0.6.2' https://github.com/baskerville/sxhkd && \
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
  clone --https --shallow --tag '0.9.10' https://github.com/baskerville/bspwm && \
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
  wget -O /tmp/nvim.appimage 'https://github.com/neovim/neovim/releases/download/v0.4.4/nvim.appimage' && \
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
  wget -O /tmp/tmux.tgz 'https://github.com/tmux/tmux/releases/download/3.1c/tmux-3.1c.tar.gz' && \
  tar xzvf /tmp/tmux.tgz && \
  rm /tmp/tmux.tgz && \
  cd 'tmux-3.1c' && \
  ./configure && \
  make && \
  make install && \
  cd .. && \
  rm -r 'tmux-3.1c'
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/lib/ && \
  mv /usr/local/bin/tmux /exports/usr/local/bin/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# RANGER
FROM base AS ranger
COPY --from=python3-pip /exports/ /
COPY --from=pipx /exports/ /
ENV \
  PIPX_HOME=/usr/local/pipx \
  PIPX_BIN_DIR=/usr/local/bin
RUN \
  pipx install ranger-fm=='1.9.3'
RUN \
  mkdir -p /exports/usr/local/ /exports/usr/local/bin/ && \
  mv /usr/local/pipx /exports/usr/local/ && \
  mv /usr/local/bin/ranger /usr/local/bin/rifle /exports/usr/local/bin/

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
  npm install -g 'diff-so-fancy@1.3.0'
RUN \
  mkdir -p /exports/usr/local/lib/ && \
  mv /usr/local/lib/node /exports/usr/local/lib/

# FFMPEG
FROM base AS ffmpeg
COPY --from=wget /exports/ /
COPY --from=tar /exports/ /
COPY --from=xz /exports/ /
RUN \
  wget -O /tmp/ffmpeg.txz 'https://www.johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz' && \
  tar -xvf /tmp/ffmpeg.txz && \
  rm /tmp/ffmpeg.txz && \
  mv 'ffmpeg-4.3.1-amd64-static' ffmpeg && \
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

# PING
FROM base AS ping
COPY --from=apteryx /exports/ /
RUN \
  apteryx iputils-ping='3:20161105-*'
RUN \
  mkdir -p /exports/bin/ /exports/lib/x86_64-linux-gnu/ && \
  mv /bin/ping /exports/bin/ && \
  mv /lib/x86_64-linux-gnu/libidn.so.* /exports/lib/x86_64-linux-gnu/

# AERC
FROM base AS aerc
COPY --from=build-essential /exports/ /
COPY --from=clone /exports/ /
COPY --from=go /exports/ /
COPY --from=scdoc /exports/ /
ENV \
  PATH=/usr/local/go/bin:${PATH} \
  GOPATH=/root
RUN \
  clone --https --shallow --tag "${VERSION}" https://git.sr.ht/~sircmpwn/aerc && \
  cd ~/src/git.sr.ht/~sircmpwn/aerc && \
  make && \
  make install && \
  rm -rf ~/src
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/share/man/man1/ /exports/usr/local/share/man/man5/ /exports/usr/local/share/man/man7/ /exports/usr/local/share/ && \
  mv /usr/local/bin/aerc /exports/usr/local/bin/ && \
  mv /usr/local/share/man/man1/aerc-* /exports/usr/local/share/man/man1/ && \
  mv /usr/local/share/man/man5/aerc-* /exports/usr/local/share/man/man5/ && \
  mv /usr/local/share/man/man7/aerc-* /exports/usr/local/share/man/man7/ && \
  mv /usr/local/share/aerc /exports/usr/local/share/

# MAN
FROM base AS man
COPY --from=apteryx /exports/ /
RUN \
  apteryx man-db='2.8.3-*'
RUN \
  mkdir -p /exports/etc/ /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/tmpfiles.d/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/ /exports/var/cache/ && \
  mv /etc/groff /etc/manpath.config /exports/etc/ && \
  mv /usr/bin/apropos /usr/bin/bsd-from /usr/bin/bsd-write /usr/bin/cal /usr/bin/calendar /usr/bin/catman /usr/bin/col /usr/bin/colcrt /usr/bin/colrm /usr/bin/column /usr/bin/eqn /usr/bin/from /usr/bin/geqn /usr/bin/gpic /usr/bin/groff /usr/bin/grog /usr/bin/grops /usr/bin/grotty /usr/bin/gtbl /usr/bin/hd /usr/bin/hexdump /usr/bin/lexgrog /usr/bin/look /usr/bin/lorder /usr/bin/man /usr/bin/mandb /usr/bin/manpath /usr/bin/ncal /usr/bin/neqn /usr/bin/nroff /usr/bin/pic /usr/bin/preconv /usr/bin/printerbanner /usr/bin/soelim /usr/bin/tbl /usr/bin/troff /usr/bin/ul /usr/bin/whatis /usr/bin/write /exports/usr/bin/ && \
  mv /usr/lib/man-db /usr/lib/groff /exports/usr/lib/ && \
  mv /usr/lib/tmpfiles.d/man-db.conf /exports/usr/lib/tmpfiles.d/ && \
  mv /usr/lib/x86_64-linux-gnu/libgdbm.so.* /usr/lib/x86_64-linux-gnu/libpipeline.so.* /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/share/groff /usr/share/man /usr/share/man-db /exports/usr/share/ && \
  mv /var/cache/man /exports/var/cache/

# CLANG-FORMAT
FROM base AS clang-format
COPY --from=apteryx /exports/ /
RUN \
  apteryx clang-format-10='1:10.0.0-*' && \
  mv /usr/bin/clang-format-10 /usr/bin/clang-format
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/ && \
  mv /usr/bin/clang-format /exports/usr/bin/ && \
  mv /usr/lib/llvm-10 /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/libclang-cpp.so.10 /usr/lib/x86_64-linux-gnu/libLLVM-10.so /usr/lib/x86_64-linux-gnu/libLLVM-10.so.1 /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/share/clang /exports/usr/share/

# XOURNALPP
FROM base AS xournalpp
COPY --from=apteryx /exports/ /
RUN \
  add-apt-repository ppa:apandada1/xournalpp-stable && \
  apteryx xournalpp='1.0.19-*'
RUN \
  mkdir -p /exports/etc/ /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/glib-2.0/ /exports/usr/share/ && \
  mv /etc/gtk-3.0 /exports/etc/ && \
  mv /usr/bin/xournalpp /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu/gtk-3.0 /usr/lib/x86_64-linux-gnu/libgtk-3-0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.* /usr/lib/x86_64-linux-gnu/liblua5.3.so.* /usr/lib/x86_64-linux-gnu/libpoppler-glib.so.* /usr/lib/x86_64-linux-gnu/libportaudiocpp.so.* /usr/lib/x86_64-linux-gnu/libzip.so.* /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/share/glib-2.0/schemas /exports/usr/share/glib-2.0/ && \
  mv /usr/share/icons /usr/share/xournalpp /exports/usr/share/

# PEACLOCK
FROM base AS peaclock
COPY --from=clone /exports/ /
RUN \
  add-apt-repository ppa:ubuntu-toolchain-r/test && \
  apt-get update -q && \
  apt-get install -y --no-install-recommends --auto-remove cmake libpthread-stubs0-dev libicu-dev gcc-9 g++-9 && \
  clone --https --shallow --tag '0.4.3' https://github.com/octobanana/peaclock && \
  cd /root/src/github.com/octobanana/peaclock && \
  ./RUNME.sh build --release -- -DCMAKE_CXX_COMPILER=$(which g++-9) && \
  ./RUNME.sh install --release && \
  rm -rf /root/src && \
  apt purge -y cmake libpthread-stubs0-dev libicu-dev gcc-9 g++-9 && \
  apt autoremove -y && \
  apt-get -q clean
RUN \
  mkdir -p /exports/etc/ /exports/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ /exports/usr/share/ /exports/usr/share/gdb/auto-load/usr/lib/x86_64-linux-gnu/ /exports/var/cache/ldconfig/ && \
  mv /etc/perl /exports/etc/ && \
  mv /lib/x86_64-linux-gnu/libgcc_s.so.1 /exports/lib/x86_64-linux-gnu/ && \
  mv /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.28 /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/bin/peaclock /exports/usr/local/bin/ && \
  mv /usr/share/gcc-10 /exports/usr/share/ && \
  mv /usr/share/gdb/auto-load/usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.28-gdb.py /exports/usr/share/gdb/auto-load/usr/lib/x86_64-linux-gnu/ && \
  mv /var/cache/ldconfig/aux-cache /exports/var/cache/ldconfig/

# BSDMAINUTILS
FROM base AS bsdmainutils
COPY --from=apteryx /exports/ /
RUN \
  apteryx bsdmainutils='11.1.2*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/column /exports/usr/bin/

# URLVIEW
FROM base AS urlview
COPY --from=apteryx /exports/ /
RUN \
  apteryx urlview='0.9-*'
RUN \
  mkdir -p /exports/etc/ /exports/usr/bin/ && \
  mv /etc/urlview /exports/etc/ && \
  mv /usr/bin/urlview /exports/usr/bin/

# WEECHAT
FROM base AS weechat
COPY --from=apteryx /exports/ /
COPY --from=python3-pip /exports/ /
RUN \
  apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 11E9DE8848F2B65222AA75B8D1820DB22A11534E && add-apt-repository "deb [arch=amd64] https://weechat.org/ubuntu $(lsb_release -cs) main" && \
  apteryx weechat-curses weechat-perl weechat-plugins weechat-python && \
  pip3 install websocket-client
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/perl/ /exports/usr/local/bin/ /exports/usr/local/lib/python3.6/dist-packages/ /exports/usr/share/ /exports/usr/share/pixmaps/ && \
  mv /usr/bin/cpan5.26-x86_64-linux-gnu /usr/bin/perl5.26-x86_64-linux-gnu /usr/bin/weechat /usr/bin/weechat-curses /exports/usr/bin/ && \
  mv /usr/lib/aspell /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/libaspell.so.* /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.* /usr/lib/x86_64-linux-gnu/libgdbm_compat.so.* /usr/lib/x86_64-linux-gnu/libgdbm.so.* /usr/lib/x86_64-linux-gnu/libperl.so.* /usr/lib/x86_64-linux-gnu/libpspell.so.* /usr/lib/x86_64-linux-gnu/weechat /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/lib/x86_64-linux-gnu/perl/5.26 /usr/lib/x86_64-linux-gnu/perl/5.26.1 /usr/lib/x86_64-linux-gnu/perl/cross-config-5.26.1 /usr/lib/x86_64-linux-gnu/perl/debian-config-data-5.26.1 /exports/usr/lib/x86_64-linux-gnu/perl/ && \
  mv /usr/local/bin/wsdump.py /exports/usr/local/bin/ && \
  mv /usr/local/lib/python3.6/dist-packages/six-1.15.0.dist-info /usr/local/lib/python3.6/dist-packages/six.py /usr/local/lib/python3.6/dist-packages/websocket_client-0.57.0.dist-info /usr/local/lib/python3.6/dist-packages/websocket /exports/usr/local/lib/python3.6/dist-packages/ && \
  mv /usr/share/perl /exports/usr/share/ && \
  mv /usr/share/pixmaps/weechat.xpm /exports/usr/share/pixmaps/

# XINPUT
FROM base AS xinput
COPY --from=apteryx /exports/ /
RUN \
  apteryx xinput='1.6.2-*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/xinput /exports/usr/bin/

# ALSA-UTILS
FROM base AS alsa-utils
COPY --from=apteryx /exports/ /
RUN \
  apteryx alsa-utils='1.1.3-*'
RUN \
  mkdir -p /exports/etc/rc0.d/ /exports/etc/rc1.d/ /exports/etc/rc6.d/ /exports/etc/rcS.d/ /exports/lib/systemd/system/ /exports/lib/udev/ /exports/lib/x86_64-linux-gnu/ /exports/sbin/ /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/sbin/ /exports/usr/share/ /exports/var/cache/ldconfig/ /exports/var/lib/ && \
  mv /etc/rc0.d/K01alsa-utils /exports/etc/rc0.d/ && \
  mv /etc/rc1.d/K01alsa-utils /exports/etc/rc1.d/ && \
  mv /etc/rc6.d/K01alsa-utils /exports/etc/rc6.d/ && \
  mv /etc/rcS.d/S01alsa-utils /etc/rcS.d/S01kmod /exports/etc/rcS.d/ && \
  mv /lib/systemd/system/alsa-restore.service /lib/systemd/system/alsa-state.service /lib/systemd/system/alsa-utils.service /lib/systemd/system/basic.target.wants /exports/lib/systemd/system/ && \
  mv /lib/udev/rules.d /exports/lib/udev/ && \
  mv /lib/x86_64-linux-gnu/libkmod.so.* /lib/x86_64-linux-gnu/libnewt.so.* /lib/x86_64-linux-gnu/libslang.so.* /exports/lib/x86_64-linux-gnu/ && \
  mv /sbin/depmod /sbin/insmod /sbin/lsmod /sbin/modinfo /sbin/modprobe /sbin/rmmod /exports/sbin/ && \
  mv /usr/bin/aconnect /usr/bin/alsabat /usr/bin/alsaloop /usr/bin/alsamixer /usr/bin/alsatplg /usr/bin/alsaucm /usr/bin/amidi /usr/bin/amixer /usr/bin/aplay /usr/bin/aplaymidi /usr/bin/arecord /usr/bin/arecordmidi /usr/bin/aseqdump /usr/bin/aseqnet /usr/bin/iecset /usr/bin/speaker-test /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu/libasound.so.* /usr/lib/x86_64-linux-gnu/libfftw3f_omp.so.* /usr/lib/x86_64-linux-gnu/libfftw3f_threads.so.* /usr/lib/x86_64-linux-gnu/libfftw3f.so.* /usr/lib/x86_64-linux-gnu/libgomp.so.* /usr/lib/x86_64-linux-gnu/libsamplerate.so.* /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/sbin/alsa-info /usr/sbin/alsabat-test /usr/sbin/alsactl /exports/usr/sbin/ && \
  mv /usr/share/alsa /usr/share/sounds /exports/usr/share/ && \
  mv /var/cache/ldconfig/aux-cache /exports/var/cache/ldconfig/ && \
  mv /var/lib/alsa /exports/var/lib/

# APULSE
FROM base AS apulse
COPY --from=apteryx /exports/ /
RUN \
  apteryx apulse='0.1.10+*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/bin/apulse /exports/usr/bin/ && \
  mv /usr/lib/apulse /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/libasound.so.* /exports/usr/lib/x86_64-linux-gnu/

# WACOM
FROM base AS wacom
COPY --from=apteryx /exports/ /
RUN \
  apteryx xserver-xorg-input-wacom='1:0.36.1-*'
RUN \
  mkdir -p /exports/lib/x86_64-linux-gnu/ /exports/usr/bin/ /exports/usr/lib/ /exports/usr/local/bin/ && \
  mv /lib/x86_64-linux-gnu/libkmod.so.* /exports/lib/x86_64-linux-gnu/ && \
  mv /usr/bin/xsetwacom /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/ && \
  mv /usr/local/bin/apteryx /exports/usr/local/bin/

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
  mkdir -p /exports/etc/ /exports/opt/ /exports/run/ /exports/usr/bin/ /exports/usr/lib/ /exports/usr/share/applications/ /exports/usr/share/ && \
  mv /etc/firefox /exports/etc/ && \
  mv /opt/google /exports/opt/ && \
  mv /run/firefox-restart-required /exports/run/ && \
  mv /usr/bin/firefox /exports/usr/bin/ && \
  mv /usr/lib/firefox-addons /usr/lib/firefox /usr/lib/x86_64-linux-gnu /exports/usr/lib/ && \
  mv /usr/share/applications/firefox.desktop /exports/usr/share/applications/ && \
  mv /usr/share/glib-2.0 /usr/share/icons /usr/share/mime /exports/usr/share/

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
  mkdir -p /exports/usr/local/ /exports/usr/local/bin/ && \
  mv /usr/local/pipx /exports/usr/local/ && \
  mv /usr/local/bin/ranger /usr/local/bin/rifle /exports/usr/local/bin/

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

# XCLIP
FROM base AS xclip
COPY --from=apteryx /exports/ /
RUN \
  apteryx xclip='0.12+*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/bin/xclip /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu/libICE.so.* /usr/lib/x86_64-linux-gnu/libSM.so.* /usr/lib/x86_64-linux-gnu/libX11.so.* /usr/lib/x86_64-linux-gnu/libXau.so.* /usr/lib/x86_64-linux-gnu/libxcb.so.* /usr/lib/x86_64-linux-gnu/libXdmcp.so.* /usr/lib/x86_64-linux-gnu/libXext.so.* /usr/lib/x86_64-linux-gnu/libXmu.so.* /usr/lib/x86_64-linux-gnu/libXt.so.* /exports/usr/lib/x86_64-linux-gnu/

# SIGNAL
FROM base AS signal
COPY --from=apteryx /exports/ /
RUN \
  curl -s https://updates.signal.org/desktop/apt/keys.asc | apt-key add - && \
  echo "deb [arch=amd64] https://updates.signal.org/desktop/apt xenial main" > /etc/apt/sources.list.d/signal-xenial.list && \
  apt-get -q update && \
  apteryx signal-desktop='1.38.1'
RUN \
  mkdir -p /exports/opt/ /exports/usr/bin/ && \
  mv /opt/Signal /exports/opt/ && \
  mv /usr/bin/signal-desktop /exports/usr/bin/

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
COPY --from=clone /exports/ /
COPY --from=apteryx /exports/ /
COPY --from=wget /exports/ /
RUN \
  apteryx fonts-noto='20171026-2' fonts-noto-color-emoji='0~20180810-*' ttf-ubuntu-font-family='1:0.83-2' xfonts-utils='1:7.7+6' fontconfig='2.12.6-*' && \
  mkdir -p /usr/share/fonts/X11/bitmap && \
  wget -O /usr/share/fonts/X11/bitmap/gomme.bdf 'https://raw.githubusercontent.com/Tecate/bitmap-fonts/master/bitmap/gomme/Gomme10x20n.bdf' && \
  wget -O /usr/share/fonts/X11/bitmap/terminal.bdf 'https://raw.githubusercontent.com/Tecate/bitmap-fonts/master/bitmap/dylex/7x13.bdf' && \
  clone --shallow --https https://github.com/blaisck/sfwin && \
  cd /root/src/github.com/blaisck/sfwin && \
  mv SFCompact/TrueType /usr/share/fonts/SFCompact && \
  mv SFMono/TrueType /usr/share/fonts/SFMono && \
  mv SFPro/TrueType /usr/share/fonts/SFPro && \
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

# CHARLES
FROM base AS charles
COPY --from=wget /exports/ /
COPY --from=tar /exports/ /
RUN \
  wget -O /tmp/charles.tgz 'https://www.charlesproxy.com/assets/release/4.6.1/charles-proxy-4.6.1_amd64.tar.gz' && \
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

# WITHEXEDITORHOST
FROM base AS withexeditorhost
COPY --from=node /exports/ /
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  npm install -g 'withexeditorhost@5.5.0'
RUN \
  mkdir -p /exports/usr/local/lib/ && \
  mv /usr/local/lib/node /exports/usr/local/lib/

# WATSON
FROM base AS watson
COPY --from=python3-pip /exports/ /
COPY --from=pipx /exports/ /
ENV \
  PIPX_HOME=/usr/local/pipx \
  PIPX_BIN_DIR=/usr/local/bin
RUN \
  pipx install td-watson=='1.10.0'
RUN \
  mkdir -p /exports/usr/local/ /exports/usr/local/bin/ && \
  mv /usr/local/pipx /exports/usr/local/ && \
  mv /usr/local/bin/watson /exports/usr/local/bin/

# VDIRSYNCER
FROM base AS vdirsyncer
COPY --from=python3-pip /exports/ /
COPY --from=pipx /exports/ /
ENV \
  PIPX_HOME=/usr/local/pipx \
  PIPX_BIN_DIR=/usr/local/bin
RUN \
  pipx install vdirsyncer=='0.16.8' && \
  pipx inject vdirsyncer vdirsyncer[gcalendar] && \
  pipx inject vdirsyncer requests-oauthlib
RUN \
  mkdir -p /exports/usr/local/ /exports/usr/local/bin/ && \
  mv /usr/local/pipx /exports/usr/local/ && \
  mv /usr/local/bin/vdirsyncer /exports/usr/local/bin/

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
  wget -O /usr/local/bin/sd 'https://github.com/chmln/sd/releases/download/v0.7.6/sd-v0.7.6-x86_64-unknown-linux-gnu' && \
  chmod +x /usr/local/bin/sd
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
  wget -O /tmp/ripgrep.tgz 'https://github.com/BurntSushi/ripgrep/releases/download/12.1.1/ripgrep-12.1.1-x86_64-unknown-linux-musl.tar.gz' && \
  tar -xzvf /tmp/ripgrep.tgz && \
  rm /tmp/ripgrep.tgz && \
  mv ripgrep-12.1.1-x86_64-unknown-linux-musl ripgrep && \
  mv ripgrep/rg /usr/local/bin/rg && \
  mkdir -p /usr/local/share/man/man1 && \
  mv ripgrep/doc/rg.1 /usr/local/share/man/man1/rg.1 && \
  rm -r ripgrep
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/rg /exports/usr/local/bin/

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
COPY --from=pipx /exports/ /
ENV \
  PIPX_HOME=/usr/local/pipx \
  PIPX_BIN_DIR=/usr/local/bin
RUN \
  apteryx libpq-dev && \
  pipx install pgcli=='3.0.0' --include-deps
RUN \
  mkdir -p /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ /exports/usr/local/ && \
  mv /usr/lib/x86_64-linux-gnu/libpq.* /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/bin/pgcli /usr/local/bin/sqlformat /exports/usr/local/bin/ && \
  mv /usr/local/pipx /exports/usr/local/

# NP
FROM base AS np
COPY --from=node /exports/ /
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  npm install -g 'np@7.0.0'
RUN \
  mkdir -p /exports/usr/local/lib/ && \
  mv /usr/local/lib/node /exports/usr/local/lib/

# NGROK
FROM base AS ngrok
COPY --from=wget /exports/ /
COPY --from=unzip /exports/ /
RUN \
  wget -O /tmp/ngrok.zip 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip' && \
  unzip /tmp/ngrok.zip && \
  rm /tmp/ngrok.zip && \
  mv ngrok /usr/local/bin/ngrok
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/ngrok /exports/usr/local/bin/

# NCU
FROM base AS ncu
COPY --from=node /exports/ /
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  npm install -g 'npm-check-updates@10.2.2'
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

# KHAL
FROM base AS khal
COPY --from=python3-pip /exports/ /
COPY --from=pipx /exports/ /
ENV \
  PIPX_HOME=/usr/local/pipx \
  PIPX_BIN_DIR=/usr/local/bin
RUN \
  pipx install khal=='0.10.2'
RUN \
  mkdir -p /exports/usr/local/ /exports/usr/local/bin/ && \
  mv /usr/local/pipx /exports/usr/local/ && \
  mv /usr/local/bin/khal /exports/usr/local/bin/

# JQ
FROM base AS jq
COPY --from=wget /exports/ /
RUN \
  wget -O /usr/local/bin/jq 'https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64' && \
  chmod +x /usr/local/bin/jq
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/jq /exports/usr/local/bin/

# HTTPIE
FROM base AS httpie
COPY --from=python3-pip /exports/ /
COPY --from=pipx /exports/ /
ENV \
  PIPX_HOME=/usr/local/pipx \
  PIPX_BIN_DIR=/usr/local/bin
RUN \
  pipx install httpie=='2.3.0'
RUN \
  mkdir -p /exports/usr/local/ /exports/usr/local/bin/ && \
  mv /usr/local/pipx /exports/usr/local/ && \
  mv /usr/local/bin/http /usr/local/bin/https /exports/usr/local/bin/

# HTOP
FROM base AS htop
COPY --from=apteryx /exports/ /
RUN \
  apteryx htop='2.1.0-*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/htop /exports/usr/bin/

# HEROKU
FROM base AS heroku
COPY --from=node /exports/ /
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
RUN \
  npm install -g 'heroku@7.47.3'
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
  wget -O gifski.txz "https://github.com/ImageOptim/gifski/releases/download/1.2.3/gifski-1.2.3.tar.xz"
RUN \
  tar -xvf gifski.txz debian && \
  apteryx ./debian/gifski*.deb && \
  rm -rf debian
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/gifski /exports/usr/bin/

# GH
FROM base AS gh
COPY --from=wget /exports/ /
COPY --from=tar /exports/ /
RUN \
  wget -O /tmp/gh.tgz 'https://github.com/cli/cli/releases/download/v1.2.1/gh_1.2.1_linux_amd64.tar.gz' && \
  tar xzvf /tmp/gh.tgz && \
  rm /tmp/gh.tgz && \
  mv 'gh_1.2.1_linux_amd64/bin/gh' /usr/local/bin/gh && \
  rm -r 'gh_1.2.1_linux_amd64'
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/gh /exports/usr/local/bin/

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

# FD
FROM base AS fd
COPY --from=wget /exports/ /
COPY --from=tar /exports/ /
RUN \
  wget -O /tmp/fd.tgz 'https://github.com/sharkdp/fd/releases/download/v8.1.1/fd-v8.1.1-x86_64-unknown-linux-musl.tar.gz' && \
  tar -xzvf /tmp/fd.tgz && \
  rm /tmp/fd.tgz && \
  mv 'fd-v8.1.1-x86_64-unknown-linux-musl' fd && \
  mv fd/fd /usr/local/bin/fd && \
  mkdir -p /usr/local/share/man/man1 && \
  mv fd/fd.1 /usr/local/share/man/man1/fd.1 && \
  rm -r fd
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/fd /exports/usr/local/bin/

# DOCKER-COMPOSE
FROM base AS docker-compose
COPY --from=wget /exports/ /
RUN \
  wget -O /usr/local/bin/docker-compose 'https://github.com/docker/compose/releases/download/1.27.4/docker-compose-Linux-x86_64' && \
  chmod +x /usr/local/bin/docker-compose
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/docker-compose /exports/usr/local/bin/

# DOCKER
FROM base AS docker
COPY --from=apteryx /exports/ /
COPY --from=wget /exports/ /
RUN \
  wget -O /tmp/docker.gpg https://download.docker.com/linux/ubuntu/gpg && \
  apt-key add /tmp/docker.gpg && \
  apt-add-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable' && \
  apteryx docker-ce='5:19.03.13*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/docker /exports/usr/bin/

# DENO
FROM base AS deno
COPY --from=wget /exports/ /
COPY --from=unzip /exports/ /
RUN \
  wget -O /tmp/deno.zip 'https://github.com/denoland/deno/releases/download/v1.5.3/deno-x86_64-unknown-linux-gnu.zip' && \
  cd /usr/local/bin && \
  unzip /tmp/deno.zip && \
  rm /tmp/deno.zip
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/deno /exports/usr/local/bin/

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

# CADDY
FROM base AS caddy
COPY --from=wget /exports/ /
RUN \
  wget -O /usr/local/bin/caddy 'https://caddyserver.com/api/download?os=linux&arch=amd64&idempotency=72866995282326' && \
  chmod +x /usr/local/bin/caddy
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/caddy /exports/usr/local/bin/

# BAT
FROM base AS bat
COPY --from=wget /exports/ /
COPY --from=tar /exports/ /
RUN \
  wget -O bat.tgz 'https://github.com/sharkdp/bat/releases/download/v0.16.0/bat-v0.16.0-x86_64-unknown-linux-gnu.tar.gz' && \
  tar -xzvf bat.tgz && \
  rm bat.tgz && \
  mv 'bat-v0.16.0-x86_64-unknown-linux-gnu/bat' /usr/local/bin/bat && \
  rm -rf 'bat-v0.16.0-x86_64-unknown-linux-gnu'
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
COPY --from=python3-pip /exports/ /
COPY --from=acpi /exports/ /
COPY --from=adb /exports/ /
COPY --from=bat /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=caddy /exports/ /
COPY --from=clone /exports/ /
COPY --from=container-diff /exports/ /
COPY --from=deno /exports/ /
COPY --from=docker /exports/ /
COPY --from=docker-compose /exports/ /
COPY --from=fd /exports/ /
COPY --from=ffmpeg /exports/ /
COPY --from=file /exports/ /
COPY --from=fzf /exports/ /
COPY --from=gh /exports/ /
COPY --from=gifski /exports/ /
COPY --from=go /exports/ /
COPY --from=heroku /exports/ /
COPY --from=htop /exports/ /
COPY --from=httpie /exports/ /
COPY --from=jq /exports/ /
COPY --from=khal /exports/ /
COPY --from=make /exports/ /
COPY --from=mediainfo /exports/ /
COPY --from=moreutils /exports/ /
COPY --from=ncu /exports/ /
COPY --from=ngrok /exports/ /
COPY --from=node /exports/ /
COPY --from=np /exports/ /
COPY --from=pgcli /exports/ /
COPY --from=prettyping /exports/ /
COPY --from=prolog /exports/ /
COPY --from=ripgrep /exports/ /
COPY --from=rsync /exports/ /
COPY --from=safe-rm /exports/ /
COPY --from=sd /exports/ /
COPY --from=shoebox /exports/ /
COPY --from=sudo /exports/ /
COPY --from=tig /exports/ /
COPY --from=tree /exports/ /
COPY --from=unzip /exports/ /
COPY --from=vdirsyncer /exports/ /
COPY --from=watson /exports/ /
COPY --from=wget /exports/ /
COPY --from=withexeditorhost /exports/ /
COPY --from=xsv /exports/ /
COPY --from=alacritty /exports/ /
COPY --from=audacity /exports/ /
COPY --from=charles /exports/ /
COPY --from=feh /exports/ /
COPY --from=flameshot /exports/ /
COPY --from=fonts /exports/ /
COPY --from=light /exports/ /
COPY --from=peek /exports/ /
COPY --from=qpdfview /exports/ /
COPY --from=redshift /exports/ /
COPY --from=rofi /exports/ /
COPY --from=signal /exports/ /
COPY --from=xclip /exports/ /
COPY --from=xdg-utils /exports/ /
COPY --from=xsecurelock /exports/ /
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
COPY --from=shell-browser --chown=admin /home/admin/exports/ /
COPY --from=shell-browser /exports/ /
COPY --from=wacom /exports/ /
COPY --from=apulse /exports/ /
COPY --from=alsa-utils /exports/ /
COPY --from=xinput /exports/ /
COPY --from=weechat /exports/ /
COPY --from=urlview /exports/ /
COPY --from=bsdmainutils /exports/ /
COPY --from=peaclock /exports/ /
COPY --from=xournalpp /exports/ /
COPY --from=clang-format /exports/ /
COPY --from=man /exports/ /
COPY --from=aerc /exports/ /
ENV \
  PATH=/usr/local/go/bin:${PATH} \
  GOPATH=/root
ENV \
  PATH=/usr/local/lib/node/bin:${PATH}
ENV \
  PATH=${PATH}:/home/admin/.cache/npm/bin
ENV \
  PATH=/home/admin/.yarn/bin:${PATH}
ENV \
  PATH=${PATH}:/opt/google/chrome
RUN \
  chmod 0600 /home/admin/.ssh/*
CMD /home/admin/.xinitrc
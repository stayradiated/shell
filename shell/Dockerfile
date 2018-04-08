FROM stayradiated/base as fzf
WORKDIR /usr/local/src
RUN git clone --depth=1 https://github.com/junegunn/fzf
WORKDIR /usr/local/src/fzf
RUN git fetch  --depth 1 origin tag 0.17.0
RUN git reset --hard 0.17.0
RUN ./install

FROM stayradiated/base as pt
WORKDIR /usr/local/src
RUN wget https://github.com/monochromegane/the_platinum_searcher/releases/download/v2.1.5/pt_linux_amd64.tar.gz
RUN tar xzvf pt_linux_amd64.tar.gz
RUN rm -rf pt_linux_amd64.tar.gz
RUN mv pt_linux_amd64/pt /usr/local/bin
RUN rm -rf pt_linux_amd64

FROM stayradiated/base as dotfiles
WORKDIR /usr/local/src
RUN git clone --depth 1 https://github.com/stayradiated/dotfiles
WORKDIR /usr/local/src/dotfiles
RUN git fetch --depth 1 origin tag v1.1.1
RUN git reset --hard v1.1.1
RUN make apps
RUN nvim +qall || :

FROM stayradiated/base as clone
WORKDIR /usr/local/src
RUN git clone https://github.com/stayradiated/clone
WORKDIR /usr/local/src/clone
ENV GOPATH /usr/local
RUN go install

FROM stayradiated/base as nvm
WORKDIR /usr/local/src
RUN git clone --depth 1 https://github.com/creationix/nvm.git nvm
WORKDIR /usr/local/src/nvm
RUN git fetch --depth 1 origin tag v0.33.8
RUN git reset --hard v0.33.8
RUN bash -c 'source nvm.sh && nvm install v8.11.1'
ENV PATH /usr/local/src/nvm/versions/node/v8.11.1/bin:$PATH
COPY ./files/.npmrc /root/.npmrc
RUN npm install --global \
  1password \
  tagrelease \
  @mishguru/passwd \
  @mishguru/migrate

### the real deal ###

FROM stayradiated/base as shell
RUN apt-get update
RUN apt-get install -y \
  tree \
  safe-rm \
  ranger \
  sudo \
  fasd \
  tig \
  man \
  xsel

# setup admin user
RUN useradd -s /usr/bin/zsh --create-home admin
RUN echo "admin:admin" | chpasswd
RUN adduser admin sudo
RUN adduser admin docker
RUN chown -R admin:admin /usr/local/src
USER admin
WORKDIR /home/admin

# git
RUN git config --global user.email 'george@mish.guru'
RUN git config --global user.name 'stayradiated'
RUN git config --global push.default 'simple'
RUN git config --global url.git@github.com:.insteadOf 'https://github.com/'
RUN git config --global url.git@bitbucket.org:.insteadOf 'https://bitbucket.org/'

# copy files
COPY --chown=admin:admin ./files ./

# dotfiles
COPY --chown=admin:admin --from=dotfiles /usr/local/src/dotfiles /home/admin/dotfiles
COPY --chown=admin:admin --from=dotfiles /root/.zprezto /home/admin/.zprezto
COPY --chown=admin:admin --from=dotfiles /root/.tmux /home/admin/.tmux
WORKDIR /home/admin/dotfiles
RUN make apps
WORKDIR /home/admin

# pt
COPY --from=pt /usr/local/bin/pt /usr/local/bin/pt

# fzf
COPY --from=fzf --chown=admin:admin /usr/local/src/fzf /home/admin/.fzf

# clone
COPY --from=clone --chown=admin:admin /usr/local/bin/clone /home/admin/bin/clone

# npm
COPY --from=nvm --chown=admin:admin /usr/local/src/nvm/versions/node/v8.11.1 /usr/local/lib/node
ENV PATH /usr/local/lib/node/bin:$PATH

# configure go
ENV GOPATH /home/admin
RUN mkdir -p /home/admin/bin
ENV PATH /home/admin/bin:$PATH

CMD /usr/bin/zsh

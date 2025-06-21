

# BASE
FROM phusion/baseimage:noble-1.0.2 AS base
RUN set -e \
  ; echo noble-1.0.2 \
  ; export LANG=en_NZ.UTF-8 \
  ; locale-gen $LANG \
  ; export DEBIAN_FRONTEND=noninteractive \
  ; echo 'openssh-server openssh-server/permit-root-login select false' | debconf-set-selections \
  ; echo 'openssh-server openssh-server/password-authentication select true' | debconf-set-selections \
  ; yes | unminimize

# APTERYX
FROM base AS apteryx
COPY ./scripts/apteryx /usr/local/bin/apteryx
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/apteryx /exports/usr/local/bin/

# WGET
FROM base AS wget
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx wget='1.21.4-1ubuntu4.1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man1/ \
  ; mv /usr/bin/wget /exports/usr/bin/ \
  ; mv /usr/share/doc/wget /exports/usr/share/doc/ \
  ; mv /usr/share/man/man1/wget.1.gz /exports/usr/share/man/man1/

# DOTENV-LINTER
FROM base AS dotenv-linter
COPY --from=wget /exports/ /
RUN set -e \
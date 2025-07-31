

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

# MOSH
FROM base AS mosh
COPY --from=apteryx /exports/ /
RUN set -e \
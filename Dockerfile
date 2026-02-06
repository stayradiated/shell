

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

# ONE-PASSWORD
FROM base AS one-password
COPY --from=apteryx /exports/ /
RUN set -e \
  ; curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg \
  ; echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 beta main' | tee /etc/apt/sources.list.d/1password.list \
  ; mkdir -p /etc/debsig/policies/AC2D62742012EA22/ \
  ; curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | tee /etc/debsig/policies/AC2D62742012EA22/1password.pol \
  ; mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22 \
  ; curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg \
  ; apt update \
  ; version=$(echo "8.12.2-22" | sed 's/-/~/') \
  ; apteryx 1password="${version}.BETA"


# BASE
FROM phusion/baseimage:jammy-1.0.1 AS base
RUN set -e \
  ; echo jammy-1.0.1 \
  ; export LANG=en_NZ.UTF-8 \
  ; locale-gen $LANG \
  ; yes | unminimize

# APTERYX
FROM base AS apteryx
RUN set -e \
  ; EXPORT=/usr/local/bin/apteryx \
  ; echo '#!/usr/bin/env sh' >> ${EXPORT} \
  ; echo 'set -e' >> ${EXPORT} \
  ; echo 'export DEBIAN_FRONTEND="noninteractive"' >> ${EXPORT} \
  ; echo 'if [ ! "$(find /var/lib/apt/lists/ -mmin -1440)" ]; then apt-get -q update; fi' >> ${EXPORT} \
  ; echo 'apt-get install -y --no-install-recommends --auto-remove "${@}"' >> ${EXPORT} \
  ; echo 'apt-get -q clean' >> ${EXPORT} \
  ; echo 'rm -rf /var/tmp/* /tmp/*' >> ${EXPORT} \
  ; chmod +x ${EXPORT}
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/apteryx /exports/usr/local/bin/

# HTOP
FROM base AS htop
COPY --from=apteryx /exports/ /
RUN set -e \


# BASE
FROM phusion/baseimage:noble-1.0.0 AS base
RUN set -e \
  ; echo jammy-1.0.4 \
  ; export LANG=en_NZ.UTF-8 \
  ; locale-gen $LANG \
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

# ZIG
FROM base AS zig
COPY --from=wget /exports/ /
RUN set -e \
  ; wget --no-hsts -O /tmp/zig.tar.xz "https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz" \
  ; tar xvf /tmp/zig.tar.xz \
  ; mv "zig-linux-x86_64-0.13.0/zig" /usr/local/bin/zig \
  ; rm -r "zig-linux-x86_64-0.13.0"
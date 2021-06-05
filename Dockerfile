

# BASE
FROM phusion/baseimage:focal-1.0.0 AS base
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
  echo 'apt-cache show $(echo "${@}" | sed s/=.\*//) | grep "^Version:"' >> ${EXPORT} && \
  echo 'apt-get install -y --no-install-recommends --auto-remove "${@}"' >> ${EXPORT} && \
  echo 'apt-get -q clean' >> ${EXPORT} && \
  echo 'rm -rf /var/tmp/* /tmp/*' >> ${EXPORT} && \
  chmod +x ${EXPORT}
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/apteryx /exports/usr/local/bin/

# WGET
FROM base AS wget
COPY --from=apteryx /exports/ /
RUN \
  apteryx wget='1.20.3-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man1/ && \
  mv /usr/bin/wget /exports/usr/bin/ && \
  mv /usr/share/doc/wget /exports/usr/share/doc/ && \
  mv /usr/share/man/man1/wget.1.gz /exports/usr/share/man/man1/

# GIT
FROM base AS git
COPY --from=apteryx /exports/ /
RUN \
  add-apt-repository ppa:git-core/ppa && \
  apteryx git='1:2.31.1-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/ /exports/usr/share/perl5/ && \
  mv /usr/bin/git /exports/usr/bin/ && \
  mv /usr/lib/git-core /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.* /usr/lib/x86_64-linux-gnu/libgdbm_compat.so.* /usr/lib/x86_64-linux-gnu/libgdbm.so.* /usr/lib/x86_64-linux-gnu/libperl.so.* /usr/lib/x86_64-linux-gnu/perl /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/share/git-core /usr/share/perl /usr/share/man /exports/usr/share/ && \
  mv /usr/share/perl5/Error.pm /usr/share/perl5/Error /usr/share/perl5/Git.pm /usr/share/perl5/Git /exports/usr/share/perl5/

# GO
FROM base AS go
COPY --from=wget /exports/ /
RUN \
  wget -O /tmp/go.tgz "https://dl.google.com/go/go1.16.5.linux-amd64.tar.gz" && \
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
  apteryx make='4.2.1-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/share/man/man1/ && \
  mv /usr/bin/make /exports/usr/bin/ && \
  mv /usr/share/man/man1/make.1.gz /exports/usr/share/man/man1/

# CLONE
FROM base AS clone
COPY --from=go /exports/ /
COPY --from=git /exports/ /
ENV \
  PATH=/usr/local/go/bin:${PATH} \
  GOPATH=/root \
  GO111MODULE=auto
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
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ /exports/usr/share/ /exports/usr/share/perl5/ && \
  mv /usr/bin/git /exports/usr/bin/ && \
  mv /usr/lib/git-core /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.* /usr/lib/x86_64-linux-gnu/libgdbm_compat.so.* /usr/lib/x86_64-linux-gnu/libgdbm.so.* /usr/lib/x86_64-linux-gnu/libperl.so.* /usr/lib/x86_64-linux-gnu/perl /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/bin/clone /exports/usr/local/bin/ && \
  mv /usr/share/git-core /usr/share/man /usr/share/perl /exports/usr/share/ && \
  mv /usr/share/perl5/Error.pm /usr/share/perl5/Error /usr/share/perl5/Git.pm /usr/share/perl5/Git /exports/usr/share/perl5/

# BUILD-ESSENTIAL
FROM base AS build-essential
COPY --from=apteryx /exports/ /
RUN \
  apteryx build-essential='12.8*'
RUN \
  mkdir -p /exports/etc/alternatives/ /exports/etc/dpkg/ /exports/etc/ /exports/usr/bin/ /exports/usr/include/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/bug/ /exports/usr/share/ /exports/usr/share/doc/ /exports/usr/share/doc/libcrypt1/ /exports/usr/share/doc/perl/ /exports/usr/share/dpkg/ /exports/usr/share/gdb/auto-load/ /exports/usr/share/gdb/auto-load/usr/lib/x86_64-linux-gnu/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/de/man1/ /exports/usr/share/man/de/man5/ /exports/usr/share/man/de/ /exports/usr/share/man/es/man5/ /exports/usr/share/man/fr/man1/ /exports/usr/share/man/fr/man5/ /exports/usr/share/man/fr/ /exports/usr/share/man/it/man5/ /exports/usr/share/man/ja/man5/ /exports/usr/share/man/man1/ /exports/usr/share/man/man3/ /exports/usr/share/man/man5/ /exports/usr/share/man/man7/ /exports/usr/share/man/nl/man1/ /exports/usr/share/man/nl/man5/ /exports/usr/share/man/nl/ /exports/usr/share/man/pl/man5/ /exports/usr/share/man/sv/man1/ /exports/usr/share/man/sv/man5/ /exports/usr/share/perl5/ /exports/var/cache/ldconfig/ && \
  mv /etc/alternatives/c++ /etc/alternatives/c++.1.gz /etc/alternatives/c89 /etc/alternatives/c89.1.gz /etc/alternatives/c99 /etc/alternatives/c99.1.gz /etc/alternatives/cc /etc/alternatives/cc.1.gz /etc/alternatives/cpp /etc/alternatives/lzcat /etc/alternatives/lzcat.1.gz /etc/alternatives/lzcmp /etc/alternatives/lzcmp.1.gz /etc/alternatives/lzdiff /etc/alternatives/lzdiff.1.gz /etc/alternatives/lzegrep /etc/alternatives/lzegrep.1.gz /etc/alternatives/lzfgrep /etc/alternatives/lzfgrep.1.gz /etc/alternatives/lzgrep /etc/alternatives/lzgrep.1.gz /etc/alternatives/lzless /etc/alternatives/lzless.1.gz /etc/alternatives/lzma /etc/alternatives/lzma.1.gz /etc/alternatives/lzmore /etc/alternatives/lzmore.1.gz /etc/alternatives/unlzma /etc/alternatives/unlzma.1.gz /exports/etc/alternatives/ && \
  mv /etc/dpkg/shlibs.default /etc/dpkg/shlibs.override /exports/etc/dpkg/ && \
  mv /etc/ld.so.cache /etc/perl /exports/etc/ && \
  mv /usr/bin/addr2line /usr/bin/ar /usr/bin/as /usr/bin/c++ /usr/bin/c++filt /usr/bin/c89 /usr/bin/c89-gcc /usr/bin/c99 /usr/bin/c99-gcc /usr/bin/cc /usr/bin/corelist /usr/bin/cpan /usr/bin/cpan5.30-x86_64-linux-gnu /usr/bin/cpp /usr/bin/cpp-9 /usr/bin/dpkg-architecture /usr/bin/dpkg-buildflags /usr/bin/dpkg-buildpackage /usr/bin/dpkg-checkbuilddeps /usr/bin/dpkg-distaddfile /usr/bin/dpkg-genbuildinfo /usr/bin/dpkg-genchanges /usr/bin/dpkg-gencontrol /usr/bin/dpkg-gensymbols /usr/bin/dpkg-mergechangelogs /usr/bin/dpkg-name /usr/bin/dpkg-parsechangelog /usr/bin/dpkg-scanpackages /usr/bin/dpkg-scansources /usr/bin/dpkg-shlibdeps /usr/bin/dpkg-source /usr/bin/dpkg-vendor /usr/bin/dwp /usr/bin/elfedit /usr/bin/enc2xs /usr/bin/encguess /usr/bin/g++ /usr/bin/g++-9 /usr/bin/gcc /usr/bin/gcc-9 /usr/bin/gcc-ar /usr/bin/gcc-ar-9 /usr/bin/gcc-nm /usr/bin/gcc-nm-9 /usr/bin/gcc-ranlib /usr/bin/gcc-ranlib-9 /usr/bin/gcov /usr/bin/gcov-9 /usr/bin/gcov-dump /usr/bin/gcov-dump-9 /usr/bin/gcov-tool /usr/bin/gcov-tool-9 /usr/bin/gencat /usr/bin/gold /usr/bin/gprof /usr/bin/h2ph /usr/bin/h2xs /usr/bin/instmodsh /usr/bin/json_pp /usr/bin/ld /usr/bin/ld.bfd /usr/bin/ld.gold /usr/bin/libnetcfg /usr/bin/lzcat /usr/bin/lzcmp /usr/bin/lzdiff /usr/bin/lzegrep /usr/bin/lzfgrep /usr/bin/lzgrep /usr/bin/lzless /usr/bin/lzma /usr/bin/lzmainfo /usr/bin/lzmore /usr/bin/make /usr/bin/make-first-existing-target /usr/bin/mtrace /usr/bin/nm /usr/bin/objcopy /usr/bin/objdump /usr/bin/patch /usr/bin/perl5.30-x86_64-linux-gnu /usr/bin/perlbug /usr/bin/perldoc /usr/bin/perlivp /usr/bin/perlthanks /usr/bin/piconv /usr/bin/pl2pm /usr/bin/pod2html /usr/bin/pod2man /usr/bin/pod2text /usr/bin/pod2usage /usr/bin/podchecker /usr/bin/podselect /usr/bin/prove /usr/bin/ptar /usr/bin/ptardiff /usr/bin/ptargrep /usr/bin/ranlib /usr/bin/readelf /usr/bin/rpcgen /usr/bin/shasum /usr/bin/size /usr/bin/sotruss /usr/bin/splain /usr/bin/sprof /usr/bin/strings /usr/bin/strip /usr/bin/unlzma /usr/bin/unxz /usr/bin/x86_64-linux-gnu-addr2line /usr/bin/x86_64-linux-gnu-ar /usr/bin/x86_64-linux-gnu-as /usr/bin/x86_64-linux-gnu-c++filt /usr/bin/x86_64-linux-gnu-cpp /usr/bin/x86_64-linux-gnu-cpp-9 /usr/bin/x86_64-linux-gnu-dwp /usr/bin/x86_64-linux-gnu-elfedit /usr/bin/x86_64-linux-gnu-g++ /usr/bin/x86_64-linux-gnu-g++-9 /usr/bin/x86_64-linux-gnu-gcc /usr/bin/x86_64-linux-gnu-gcc-9 /usr/bin/x86_64-linux-gnu-gcc-ar /usr/bin/x86_64-linux-gnu-gcc-ar-9 /usr/bin/x86_64-linux-gnu-gcc-nm /usr/bin/x86_64-linux-gnu-gcc-nm-9 /usr/bin/x86_64-linux-gnu-gcc-ranlib /usr/bin/x86_64-linux-gnu-gcc-ranlib-9 /usr/bin/x86_64-linux-gnu-gcov /usr/bin/x86_64-linux-gnu-gcov-9 /usr/bin/x86_64-linux-gnu-gcov-dump /usr/bin/x86_64-linux-gnu-gcov-dump-9 /usr/bin/x86_64-linux-gnu-gcov-tool /usr/bin/x86_64-linux-gnu-gcov-tool-9 /usr/bin/x86_64-linux-gnu-gold /usr/bin/x86_64-linux-gnu-gprof /usr/bin/x86_64-linux-gnu-ld /usr/bin/x86_64-linux-gnu-ld.bfd /usr/bin/x86_64-linux-gnu-ld.gold /usr/bin/x86_64-linux-gnu-nm /usr/bin/x86_64-linux-gnu-objcopy /usr/bin/x86_64-linux-gnu-objdump /usr/bin/x86_64-linux-gnu-ranlib /usr/bin/x86_64-linux-gnu-readelf /usr/bin/x86_64-linux-gnu-size /usr/bin/x86_64-linux-gnu-strings /usr/bin/x86_64-linux-gnu-strip /usr/bin/xsubpp /usr/bin/xz /usr/bin/xzcat /usr/bin/xzcmp /usr/bin/xzdiff /usr/bin/xzegrep /usr/bin/xzfgrep /usr/bin/xzgrep /usr/bin/xzless /usr/bin/xzmore /usr/bin/zipdetails /exports/usr/bin/ && \
  mv /usr/include/aio.h /usr/include/aliases.h /usr/include/alloca.h /usr/include/ar.h /usr/include/argp.h /usr/include/argz.h /usr/include/arpa /usr/include/asm-generic /usr/include/assert.h /usr/include/byteswap.h /usr/include/c++ /usr/include/complex.h /usr/include/cpio.h /usr/include/crypt.h /usr/include/ctype.h /usr/include/dirent.h /usr/include/dlfcn.h /usr/include/drm /usr/include/elf.h /usr/include/endian.h /usr/include/envz.h /usr/include/err.h /usr/include/errno.h /usr/include/error.h /usr/include/execinfo.h /usr/include/fcntl.h /usr/include/features.h /usr/include/fenv.h /usr/include/finclude /usr/include/fmtmsg.h /usr/include/fnmatch.h /usr/include/fstab.h /usr/include/fts.h /usr/include/ftw.h /usr/include/gconv.h /usr/include/getopt.h /usr/include/glob.h /usr/include/gnu-versions.h /usr/include/gnumake.h /usr/include/grp.h /usr/include/gshadow.h /usr/include/iconv.h /usr/include/ifaddrs.h /usr/include/inttypes.h /usr/include/langinfo.h /usr/include/lastlog.h /usr/include/libgen.h /usr/include/libintl.h /usr/include/limits.h /usr/include/link.h /usr/include/linux /usr/include/locale.h /usr/include/malloc.h /usr/include/math.h /usr/include/mcheck.h /usr/include/memory.h /usr/include/misc /usr/include/mntent.h /usr/include/monetary.h /usr/include/mqueue.h /usr/include/mtd /usr/include/net /usr/include/netash /usr/include/netatalk /usr/include/netax25 /usr/include/netdb.h /usr/include/neteconet /usr/include/netinet /usr/include/netipx /usr/include/netiucv /usr/include/netpacket /usr/include/netrom /usr/include/netrose /usr/include/nfs /usr/include/nl_types.h /usr/include/nss.h /usr/include/obstack.h /usr/include/paths.h /usr/include/poll.h /usr/include/printf.h /usr/include/proc_service.h /usr/include/protocols /usr/include/pthread.h /usr/include/pty.h /usr/include/pwd.h /usr/include/rdma /usr/include/re_comp.h /usr/include/regex.h /usr/include/regexp.h /usr/include/resolv.h /usr/include/rpc /usr/include/rpcsvc /usr/include/sched.h /usr/include/scsi /usr/include/search.h /usr/include/semaphore.h /usr/include/setjmp.h /usr/include/sgtty.h /usr/include/shadow.h /usr/include/signal.h /usr/include/sound /usr/include/spawn.h /usr/include/stab.h /usr/include/stdc-predef.h /usr/include/stdint.h /usr/include/stdio_ext.h /usr/include/stdio.h /usr/include/stdlib.h /usr/include/string.h /usr/include/strings.h /usr/include/syscall.h /usr/include/sysexits.h /usr/include/syslog.h /usr/include/tar.h /usr/include/termio.h /usr/include/termios.h /usr/include/tgmath.h /usr/include/thread_db.h /usr/include/threads.h /usr/include/time.h /usr/include/ttyent.h /usr/include/uchar.h /usr/include/ucontext.h /usr/include/ulimit.h /usr/include/unistd.h /usr/include/utime.h /usr/include/utmp.h /usr/include/utmpx.h /usr/include/values.h /usr/include/video /usr/include/wait.h /usr/include/wchar.h /usr/include/wctype.h /usr/include/wordexp.h /usr/include/x86_64-linux-gnu /usr/include/xen /exports/usr/include/ && \
  mv /usr/lib/bfd-plugins /usr/lib/compat-ld /usr/lib/cpp /usr/lib/gcc /usr/lib/gold-ld /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/crt1.o /usr/lib/x86_64-linux-gnu/crti.o /usr/lib/x86_64-linux-gnu/crtn.o /usr/lib/x86_64-linux-gnu/gcrt1.o /usr/lib/x86_64-linux-gnu/grcrt1.o /usr/lib/x86_64-linux-gnu/ldscripts /usr/lib/x86_64-linux-gnu/libanl.a /usr/lib/x86_64-linux-gnu/libanl.so /usr/lib/x86_64-linux-gnu/libasan.so.5 /usr/lib/x86_64-linux-gnu/libasan.so.5.0.0 /usr/lib/x86_64-linux-gnu/libatomic.so.1 /usr/lib/x86_64-linux-gnu/libatomic.so.1.2.0 /usr/lib/x86_64-linux-gnu/libbfd-2.34-system.so /usr/lib/x86_64-linux-gnu/libBrokenLocale.a /usr/lib/x86_64-linux-gnu/libBrokenLocale.so /usr/lib/x86_64-linux-gnu/libc_nonshared.a /usr/lib/x86_64-linux-gnu/libc.a /usr/lib/x86_64-linux-gnu/libc.so /usr/lib/x86_64-linux-gnu/libcc1.so.0 /usr/lib/x86_64-linux-gnu/libcc1.so.0.0.0 /usr/lib/x86_64-linux-gnu/libcrypt.a /usr/lib/x86_64-linux-gnu/libcrypt.so /usr/lib/x86_64-linux-gnu/libctf-nobfd.so.0 /usr/lib/x86_64-linux-gnu/libctf-nobfd.so.0.0.0 /usr/lib/x86_64-linux-gnu/libctf.so.0 /usr/lib/x86_64-linux-gnu/libctf.so.0.0.0 /usr/lib/x86_64-linux-gnu/libdl.a /usr/lib/x86_64-linux-gnu/libdl.so /usr/lib/x86_64-linux-gnu/libg.a /usr/lib/x86_64-linux-gnu/libgdbm_compat.so.4 /usr/lib/x86_64-linux-gnu/libgdbm_compat.so.4.0.0 /usr/lib/x86_64-linux-gnu/libgdbm.so.6 /usr/lib/x86_64-linux-gnu/libgdbm.so.6.0.0 /usr/lib/x86_64-linux-gnu/libgomp.so.1 /usr/lib/x86_64-linux-gnu/libgomp.so.1.0.0 /usr/lib/x86_64-linux-gnu/libisl.so.22 /usr/lib/x86_64-linux-gnu/libisl.so.22.0.1 /usr/lib/x86_64-linux-gnu/libitm.so.1 /usr/lib/x86_64-linux-gnu/libitm.so.1.0.0 /usr/lib/x86_64-linux-gnu/liblsan.so.0 /usr/lib/x86_64-linux-gnu/liblsan.so.0.0.0 /usr/lib/x86_64-linux-gnu/libm-2.31.a /usr/lib/x86_64-linux-gnu/libm.a /usr/lib/x86_64-linux-gnu/libm.so /usr/lib/x86_64-linux-gnu/libmcheck.a /usr/lib/x86_64-linux-gnu/libmpc.so.3 /usr/lib/x86_64-linux-gnu/libmpc.so.3.1.0 /usr/lib/x86_64-linux-gnu/libmpfr.so.6 /usr/lib/x86_64-linux-gnu/libmpfr.so.6.0.2 /usr/lib/x86_64-linux-gnu/libmvec.a /usr/lib/x86_64-linux-gnu/libmvec.so /usr/lib/x86_64-linux-gnu/libnsl.a /usr/lib/x86_64-linux-gnu/libnsl.so /usr/lib/x86_64-linux-gnu/libnss_compat.so /usr/lib/x86_64-linux-gnu/libnss_dns.so /usr/lib/x86_64-linux-gnu/libnss_files.so /usr/lib/x86_64-linux-gnu/libnss_hesiod.so /usr/lib/x86_64-linux-gnu/libnss_nis.so /usr/lib/x86_64-linux-gnu/libnss_nisplus.so /usr/lib/x86_64-linux-gnu/libopcodes-2.34-system.so /usr/lib/x86_64-linux-gnu/libperl.so.5.30 /usr/lib/x86_64-linux-gnu/libperl.so.5.30.0 /usr/lib/x86_64-linux-gnu/libpthread.a /usr/lib/x86_64-linux-gnu/libpthread.so /usr/lib/x86_64-linux-gnu/libquadmath.so.0 /usr/lib/x86_64-linux-gnu/libquadmath.so.0.0.0 /usr/lib/x86_64-linux-gnu/libresolv.a /usr/lib/x86_64-linux-gnu/libresolv.so /usr/lib/x86_64-linux-gnu/librpcsvc.a /usr/lib/x86_64-linux-gnu/librt.a /usr/lib/x86_64-linux-gnu/librt.so /usr/lib/x86_64-linux-gnu/libthread_db.so /usr/lib/x86_64-linux-gnu/libtsan_preinit.o /usr/lib/x86_64-linux-gnu/libtsan.so.0 /usr/lib/x86_64-linux-gnu/libtsan.so.0.0.0 /usr/lib/x86_64-linux-gnu/libubsan.so.1 /usr/lib/x86_64-linux-gnu/libubsan.so.1.0.0 /usr/lib/x86_64-linux-gnu/libutil.a /usr/lib/x86_64-linux-gnu/libutil.so /usr/lib/x86_64-linux-gnu/Mcrt1.o /usr/lib/x86_64-linux-gnu/perl /usr/lib/x86_64-linux-gnu/pkgconfig /usr/lib/x86_64-linux-gnu/rcrt1.o /usr/lib/x86_64-linux-gnu/Scrt1.o /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/share/bug/binutils /usr/share/bug/dpkg-dev /usr/share/bug/libdpkg-perl /exports/usr/share/bug/ && \
  mv /usr/share/build-essential /usr/share/perl /exports/usr/share/ && \
  mv /usr/share/doc/binutils-common /usr/share/doc/binutils-x86-64-linux-gnu /usr/share/doc/binutils /usr/share/doc/build-essential /usr/share/doc/cpp-9 /usr/share/doc/cpp /usr/share/doc/dpkg-dev /usr/share/doc/g++ /usr/share/doc/g++-9 /usr/share/doc/gcc /usr/share/doc/gcc-9 /usr/share/doc/gcc-9-base /usr/share/doc/libasan5 /usr/share/doc/libatomic1 /usr/share/doc/libbinutils /usr/share/doc/libc-dev-bin /usr/share/doc/libc6-dev /usr/share/doc/libcc1-0 /usr/share/doc/libcrypt-dev /usr/share/doc/libctf-nobfd0 /usr/share/doc/libctf0 /usr/share/doc/libdpkg-perl /usr/share/doc/libgcc-9-dev /usr/share/doc/libgdbm-compat4 /usr/share/doc/libgdbm6 /usr/share/doc/libgomp1 /usr/share/doc/libisl22 /usr/share/doc/libitm1 /usr/share/doc/liblsan0 /usr/share/doc/libmpc3 /usr/share/doc/libmpfr6 /usr/share/doc/libperl5.30 /usr/share/doc/libquadmath0 /usr/share/doc/libstdc++-9-dev /usr/share/doc/libtsan0 /usr/share/doc/libubsan1 /usr/share/doc/linux-libc-dev /usr/share/doc/make /usr/share/doc/patch /usr/share/doc/perl-modules-5.30 /usr/share/doc/xz-utils /exports/usr/share/doc/ && \
  mv /usr/share/doc/libcrypt1/README.md.gz /usr/share/doc/libcrypt1/TODO.md.gz /exports/usr/share/doc/libcrypt1/ && \
  mv /usr/share/doc/perl/changelog.Debian.gz /usr/share/doc/perl/Changes.gz /usr/share/doc/perl/copyright /usr/share/doc/perl/README.Debian /exports/usr/share/doc/perl/ && \
  mv /usr/share/dpkg/architecture.mk /usr/share/dpkg/buildflags.mk /usr/share/dpkg/buildtools.mk /usr/share/dpkg/default.mk /usr/share/dpkg/no-pie-compile.specs /usr/share/dpkg/no-pie-link.specs /usr/share/dpkg/pie-compile.specs /usr/share/dpkg/pie-link.specs /usr/share/dpkg/pkg-info.mk /usr/share/dpkg/vendor.mk /exports/usr/share/dpkg/ && \
  mv /usr/share/gdb/auto-load/lib /exports/usr/share/gdb/auto-load/ && \
  mv /usr/share/gdb/auto-load/usr/lib/x86_64-linux-gnu/libisl.so.22.0.1-gdb.py /exports/usr/share/gdb/auto-load/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/share/lintian/overrides/binutils /usr/share/lintian/overrides/binutils-common /usr/share/lintian/overrides/binutils-x86-64-linux-gnu /usr/share/lintian/overrides/cpp-9 /usr/share/lintian/overrides/g++-9 /usr/share/lintian/overrides/gcc-9 /usr/share/lintian/overrides/libbinutils /usr/share/lintian/overrides/libc-dev-bin /usr/share/lintian/overrides/libc6-dev /usr/share/lintian/overrides/perl /usr/share/lintian/overrides/perl-modules-5.30 /exports/usr/share/lintian/overrides/ && \
  mv /usr/share/man/de/man1/dpkg-architecture.1.gz /usr/share/man/de/man1/dpkg-buildflags.1.gz /usr/share/man/de/man1/dpkg-buildpackage.1.gz /usr/share/man/de/man1/dpkg-checkbuilddeps.1.gz /usr/share/man/de/man1/dpkg-distaddfile.1.gz /usr/share/man/de/man1/dpkg-genbuildinfo.1.gz /usr/share/man/de/man1/dpkg-genchanges.1.gz /usr/share/man/de/man1/dpkg-gencontrol.1.gz /usr/share/man/de/man1/dpkg-gensymbols.1.gz /usr/share/man/de/man1/dpkg-mergechangelogs.1.gz /usr/share/man/de/man1/dpkg-name.1.gz /usr/share/man/de/man1/dpkg-parsechangelog.1.gz /usr/share/man/de/man1/dpkg-scanpackages.1.gz /usr/share/man/de/man1/dpkg-scansources.1.gz /usr/share/man/de/man1/dpkg-shlibdeps.1.gz /usr/share/man/de/man1/dpkg-source.1.gz /usr/share/man/de/man1/dpkg-vendor.1.gz /exports/usr/share/man/de/man1/ && \
  mv /usr/share/man/de/man5/deb-buildinfo.5.gz /usr/share/man/de/man5/deb-changelog.5.gz /usr/share/man/de/man5/deb-changes.5.gz /usr/share/man/de/man5/deb-conffiles.5.gz /usr/share/man/de/man5/deb-control.5.gz /usr/share/man/de/man5/deb-extra-override.5.gz /usr/share/man/de/man5/deb-old.5.gz /usr/share/man/de/man5/deb-origin.5.gz /usr/share/man/de/man5/deb-override.5.gz /usr/share/man/de/man5/deb-postinst.5.gz /usr/share/man/de/man5/deb-postrm.5.gz /usr/share/man/de/man5/deb-preinst.5.gz /usr/share/man/de/man5/deb-prerm.5.gz /usr/share/man/de/man5/deb-shlibs.5.gz /usr/share/man/de/man5/deb-split.5.gz /usr/share/man/de/man5/deb-src-control.5.gz /usr/share/man/de/man5/deb-src-files.5.gz /usr/share/man/de/man5/deb-src-rules.5.gz /usr/share/man/de/man5/deb-substvars.5.gz /usr/share/man/de/man5/deb-symbols.5.gz /usr/share/man/de/man5/deb-triggers.5.gz /usr/share/man/de/man5/deb.5.gz /usr/share/man/de/man5/deb822.5.gz /usr/share/man/de/man5/dsc.5.gz /exports/usr/share/man/de/man5/ && \
  mv /usr/share/man/de/man7 /exports/usr/share/man/de/ && \
  mv /usr/share/man/es/man5/deb-extra-override.5.gz /usr/share/man/es/man5/deb-old.5.gz /usr/share/man/es/man5/deb-override.5.gz /usr/share/man/es/man5/deb-split.5.gz /exports/usr/share/man/es/man5/ && \
  mv /usr/share/man/fr/man1/dpkg-architecture.1.gz /usr/share/man/fr/man1/dpkg-buildflags.1.gz /usr/share/man/fr/man1/dpkg-buildpackage.1.gz /usr/share/man/fr/man1/dpkg-checkbuilddeps.1.gz /usr/share/man/fr/man1/dpkg-distaddfile.1.gz /usr/share/man/fr/man1/dpkg-genbuildinfo.1.gz /usr/share/man/fr/man1/dpkg-genchanges.1.gz /usr/share/man/fr/man1/dpkg-gencontrol.1.gz /usr/share/man/fr/man1/dpkg-gensymbols.1.gz /usr/share/man/fr/man1/dpkg-mergechangelogs.1.gz /usr/share/man/fr/man1/dpkg-name.1.gz /usr/share/man/fr/man1/dpkg-parsechangelog.1.gz /usr/share/man/fr/man1/dpkg-scanpackages.1.gz /usr/share/man/fr/man1/dpkg-scansources.1.gz /usr/share/man/fr/man1/dpkg-shlibdeps.1.gz /usr/share/man/fr/man1/dpkg-source.1.gz /usr/share/man/fr/man1/dpkg-vendor.1.gz /exports/usr/share/man/fr/man1/ && \
  mv /usr/share/man/fr/man5/deb-buildinfo.5.gz /usr/share/man/fr/man5/deb-changelog.5.gz /usr/share/man/fr/man5/deb-changes.5.gz /usr/share/man/fr/man5/deb-conffiles.5.gz /usr/share/man/fr/man5/deb-control.5.gz /usr/share/man/fr/man5/deb-extra-override.5.gz /usr/share/man/fr/man5/deb-old.5.gz /usr/share/man/fr/man5/deb-origin.5.gz /usr/share/man/fr/man5/deb-override.5.gz /usr/share/man/fr/man5/deb-postinst.5.gz /usr/share/man/fr/man5/deb-postrm.5.gz /usr/share/man/fr/man5/deb-preinst.5.gz /usr/share/man/fr/man5/deb-prerm.5.gz /usr/share/man/fr/man5/deb-shlibs.5.gz /usr/share/man/fr/man5/deb-split.5.gz /usr/share/man/fr/man5/deb-src-control.5.gz /usr/share/man/fr/man5/deb-src-files.5.gz /usr/share/man/fr/man5/deb-src-rules.5.gz /usr/share/man/fr/man5/deb-substvars.5.gz /usr/share/man/fr/man5/deb-symbols.5.gz /usr/share/man/fr/man5/deb-triggers.5.gz /usr/share/man/fr/man5/deb.5.gz /usr/share/man/fr/man5/deb822.5.gz /usr/share/man/fr/man5/dsc.5.gz /exports/usr/share/man/fr/man5/ && \
  mv /usr/share/man/fr/man7 /exports/usr/share/man/fr/ && \
  mv /usr/share/man/it/man5/deb-extra-override.5.gz /usr/share/man/it/man5/deb-old.5.gz /usr/share/man/it/man5/deb-override.5.gz /usr/share/man/it/man5/deb-split.5.gz /exports/usr/share/man/it/man5/ && \
  mv /usr/share/man/ja/man5/deb-extra-override.5.gz /usr/share/man/ja/man5/deb-old.5.gz /usr/share/man/ja/man5/deb-override.5.gz /usr/share/man/ja/man5/deb-split.5.gz /exports/usr/share/man/ja/man5/ && \
  mv /usr/share/man/man1/addr2line.1.gz /usr/share/man/man1/ar.1.gz /usr/share/man/man1/as.1.gz /usr/share/man/man1/c++.1.gz /usr/share/man/man1/c++filt.1.gz /usr/share/man/man1/c89-gcc.1.gz /usr/share/man/man1/c89.1.gz /usr/share/man/man1/c99-gcc.1.gz /usr/share/man/man1/c99.1.gz /usr/share/man/man1/cc.1.gz /usr/share/man/man1/corelist.1.gz /usr/share/man/man1/cpan.1.gz /usr/share/man/man1/cpan5.30-x86_64-linux-gnu.1.gz /usr/share/man/man1/cpp-9.1.gz /usr/share/man/man1/cpp.1.gz /usr/share/man/man1/dpkg-architecture.1.gz /usr/share/man/man1/dpkg-buildflags.1.gz /usr/share/man/man1/dpkg-buildpackage.1.gz /usr/share/man/man1/dpkg-checkbuilddeps.1.gz /usr/share/man/man1/dpkg-distaddfile.1.gz /usr/share/man/man1/dpkg-genbuildinfo.1.gz /usr/share/man/man1/dpkg-genchanges.1.gz /usr/share/man/man1/dpkg-gencontrol.1.gz /usr/share/man/man1/dpkg-gensymbols.1.gz /usr/share/man/man1/dpkg-mergechangelogs.1.gz /usr/share/man/man1/dpkg-name.1.gz /usr/share/man/man1/dpkg-parsechangelog.1.gz /usr/share/man/man1/dpkg-scanpackages.1.gz /usr/share/man/man1/dpkg-scansources.1.gz /usr/share/man/man1/dpkg-shlibdeps.1.gz /usr/share/man/man1/dpkg-source.1.gz /usr/share/man/man1/dpkg-vendor.1.gz /usr/share/man/man1/dwp.1.gz /usr/share/man/man1/elfedit.1.gz /usr/share/man/man1/enc2xs.1.gz /usr/share/man/man1/encguess.1.gz /usr/share/man/man1/g++-9.1.gz /usr/share/man/man1/g++.1.gz /usr/share/man/man1/gcc-9.1.gz /usr/share/man/man1/gcc-ar-9.1.gz /usr/share/man/man1/gcc-ar.1.gz /usr/share/man/man1/gcc-nm-9.1.gz /usr/share/man/man1/gcc-nm.1.gz /usr/share/man/man1/gcc-ranlib-9.1.gz /usr/share/man/man1/gcc-ranlib.1.gz /usr/share/man/man1/gcc.1.gz /usr/share/man/man1/gcov-9.1.gz /usr/share/man/man1/gcov-dump-9.1.gz /usr/share/man/man1/gcov-dump.1.gz /usr/share/man/man1/gcov-tool-9.1.gz /usr/share/man/man1/gcov-tool.1.gz /usr/share/man/man1/gcov.1.gz /usr/share/man/man1/gencat.1.gz /usr/share/man/man1/gold.1.gz /usr/share/man/man1/gprof.1.gz /usr/share/man/man1/h2ph.1.gz /usr/share/man/man1/h2xs.1.gz /usr/share/man/man1/instmodsh.1.gz /usr/share/man/man1/json_pp.1.gz /usr/share/man/man1/ld.1.gz /usr/share/man/man1/ld.bfd.1.gz /usr/share/man/man1/ld.gold.1.gz /usr/share/man/man1/libnetcfg.1.gz /usr/share/man/man1/lzcat.1.gz /usr/share/man/man1/lzcmp.1.gz /usr/share/man/man1/lzdiff.1.gz /usr/share/man/man1/lzegrep.1.gz /usr/share/man/man1/lzfgrep.1.gz /usr/share/man/man1/lzgrep.1.gz /usr/share/man/man1/lzless.1.gz /usr/share/man/man1/lzma.1.gz /usr/share/man/man1/lzmainfo.1.gz /usr/share/man/man1/lzmore.1.gz /usr/share/man/man1/make-first-existing-target.1.gz /usr/share/man/man1/make.1.gz /usr/share/man/man1/nm.1.gz /usr/share/man/man1/objcopy.1.gz /usr/share/man/man1/objdump.1.gz /usr/share/man/man1/patch.1.gz /usr/share/man/man1/perl5.30-x86_64-linux-gnu.1.gz /usr/share/man/man1/perlbug.1.gz /usr/share/man/man1/perlivp.1.gz /usr/share/man/man1/perlthanks.1.gz /usr/share/man/man1/piconv.1.gz /usr/share/man/man1/pl2pm.1.gz /usr/share/man/man1/pod2html.1.gz /usr/share/man/man1/pod2man.1.gz /usr/share/man/man1/pod2text.1.gz /usr/share/man/man1/pod2usage.1.gz /usr/share/man/man1/podchecker.1.gz /usr/share/man/man1/podselect.1.gz /usr/share/man/man1/prove.1.gz /usr/share/man/man1/ptar.1.gz /usr/share/man/man1/ptardiff.1.gz /usr/share/man/man1/ptargrep.1.gz /usr/share/man/man1/ranlib.1.gz /usr/share/man/man1/readelf.1.gz /usr/share/man/man1/rpcgen.1.gz /usr/share/man/man1/shasum.1.gz /usr/share/man/man1/size.1.gz /usr/share/man/man1/sotruss.1.gz /usr/share/man/man1/splain.1.gz /usr/share/man/man1/strings.1.gz /usr/share/man/man1/strip.1.gz /usr/share/man/man1/unlzma.1.gz /usr/share/man/man1/unxz.1.gz /usr/share/man/man1/x86_64-linux-gnu-addr2line.1.gz /usr/share/man/man1/x86_64-linux-gnu-ar.1.gz /usr/share/man/man1/x86_64-linux-gnu-as.1.gz /usr/share/man/man1/x86_64-linux-gnu-c++filt.1.gz /usr/share/man/man1/x86_64-linux-gnu-cpp-9.1.gz /usr/share/man/man1/x86_64-linux-gnu-cpp.1.gz /usr/share/man/man1/x86_64-linux-gnu-dwp.1.gz /usr/share/man/man1/x86_64-linux-gnu-elfedit.1.gz /usr/share/man/man1/x86_64-linux-gnu-g++-9.1.gz /usr/share/man/man1/x86_64-linux-gnu-g++.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcc-9.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcc-ar-9.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcc-ar.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcc-nm-9.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcc-nm.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcc-ranlib-9.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcc-ranlib.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcc.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcov-9.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcov-dump-9.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcov-dump.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcov-tool-9.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcov-tool.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcov.1.gz /usr/share/man/man1/x86_64-linux-gnu-gold.1.gz /usr/share/man/man1/x86_64-linux-gnu-gprof.1.gz /usr/share/man/man1/x86_64-linux-gnu-ld.1.gz /usr/share/man/man1/x86_64-linux-gnu-ld.bfd.1.gz /usr/share/man/man1/x86_64-linux-gnu-ld.gold.1.gz /usr/share/man/man1/x86_64-linux-gnu-nm.1.gz /usr/share/man/man1/x86_64-linux-gnu-objcopy.1.gz /usr/share/man/man1/x86_64-linux-gnu-objdump.1.gz /usr/share/man/man1/x86_64-linux-gnu-ranlib.1.gz /usr/share/man/man1/x86_64-linux-gnu-readelf.1.gz /usr/share/man/man1/x86_64-linux-gnu-size.1.gz /usr/share/man/man1/x86_64-linux-gnu-strings.1.gz /usr/share/man/man1/x86_64-linux-gnu-strip.1.gz /usr/share/man/man1/xsubpp.1.gz /usr/share/man/man1/xz.1.gz /usr/share/man/man1/xzcat.1.gz /usr/share/man/man1/xzcmp.1.gz /usr/share/man/man1/xzdiff.1.gz /usr/share/man/man1/xzegrep.1.gz /usr/share/man/man1/xzfgrep.1.gz /usr/share/man/man1/xzgrep.1.gz /usr/share/man/man1/xzless.1.gz /usr/share/man/man1/xzmore.1.gz /usr/share/man/man1/zipdetails.1.gz /exports/usr/share/man/man1/ && \
  mv /usr/share/man/man3/crypt_checksalt.3.gz /usr/share/man/man3/crypt_gensalt_ra.3.gz /usr/share/man/man3/crypt_gensalt_rn.3.gz /usr/share/man/man3/crypt_gensalt.3.gz /usr/share/man/man3/crypt_preferred_method.3.gz /usr/share/man/man3/crypt_r.3.gz /usr/share/man/man3/crypt_ra.3.gz /usr/share/man/man3/crypt_rn.3.gz /usr/share/man/man3/crypt.3.gz /usr/share/man/man3/Dpkg::Arch.3perl.gz /usr/share/man/man3/Dpkg::Build::Env.3perl.gz /usr/share/man/man3/Dpkg::Build::Info.3perl.gz /usr/share/man/man3/Dpkg::Build::Types.3perl.gz /usr/share/man/man3/Dpkg::BuildFlags.3perl.gz /usr/share/man/man3/Dpkg::BuildOptions.3perl.gz /usr/share/man/man3/Dpkg::BuildProfiles.3perl.gz /usr/share/man/man3/Dpkg::Changelog::Debian.3perl.gz /usr/share/man/man3/Dpkg::Changelog::Entry::Debian.3perl.gz /usr/share/man/man3/Dpkg::Changelog::Entry.3perl.gz /usr/share/man/man3/Dpkg::Changelog::Parse.3perl.gz /usr/share/man/man3/Dpkg::Changelog.3perl.gz /usr/share/man/man3/Dpkg::Checksums.3perl.gz /usr/share/man/man3/Dpkg::Compression::FileHandle.3perl.gz /usr/share/man/man3/Dpkg::Compression::Process.3perl.gz /usr/share/man/man3/Dpkg::Compression.3perl.gz /usr/share/man/man3/Dpkg::Conf.3perl.gz /usr/share/man/man3/Dpkg::Control::Changelog.3perl.gz /usr/share/man/man3/Dpkg::Control::Fields.3perl.gz /usr/share/man/man3/Dpkg::Control::FieldsCore.3perl.gz /usr/share/man/man3/Dpkg::Control::Hash.3perl.gz /usr/share/man/man3/Dpkg::Control::HashCore.3perl.gz /usr/share/man/man3/Dpkg::Control::Info.3perl.gz /usr/share/man/man3/Dpkg::Control::Tests::Entry.3perl.gz /usr/share/man/man3/Dpkg::Control::Tests.3perl.gz /usr/share/man/man3/Dpkg::Control::Types.3perl.gz /usr/share/man/man3/Dpkg::Control.3perl.gz /usr/share/man/man3/Dpkg::Deps::AND.3perl.gz /usr/share/man/man3/Dpkg::Deps::KnownFacts.3perl.gz /usr/share/man/man3/Dpkg::Deps::Multiple.3perl.gz /usr/share/man/man3/Dpkg::Deps::OR.3perl.gz /usr/share/man/man3/Dpkg::Deps::Simple.3perl.gz /usr/share/man/man3/Dpkg::Deps::Union.3perl.gz /usr/share/man/man3/Dpkg::Deps.3perl.gz /usr/share/man/man3/Dpkg::Exit.3perl.gz /usr/share/man/man3/Dpkg::Gettext.3perl.gz /usr/share/man/man3/Dpkg::Index.3perl.gz /usr/share/man/man3/Dpkg::Interface::Storable.3perl.gz /usr/share/man/man3/Dpkg::IPC.3perl.gz /usr/share/man/man3/Dpkg::Path.3perl.gz /usr/share/man/man3/Dpkg::Source::Format.3perl.gz /usr/share/man/man3/Dpkg::Source::Package.3perl.gz /usr/share/man/man3/Dpkg::Substvars.3perl.gz /usr/share/man/man3/Dpkg::Vendor::Debian.3perl.gz /usr/share/man/man3/Dpkg::Vendor::Default.3perl.gz /usr/share/man/man3/Dpkg::Vendor::Ubuntu.3perl.gz /usr/share/man/man3/Dpkg::Vendor.3perl.gz /usr/share/man/man3/Dpkg::Version.3perl.gz /usr/share/man/man3/Dpkg.3perl.gz /exports/usr/share/man/man3/ && \
  mv /usr/share/man/man5/crypt.5.gz /usr/share/man/man5/deb-buildinfo.5.gz /usr/share/man/man5/deb-changelog.5.gz /usr/share/man/man5/deb-changes.5.gz /usr/share/man/man5/deb-conffiles.5.gz /usr/share/man/man5/deb-control.5.gz /usr/share/man/man5/deb-extra-override.5.gz /usr/share/man/man5/deb-old.5.gz /usr/share/man/man5/deb-origin.5.gz /usr/share/man/man5/deb-override.5.gz /usr/share/man/man5/deb-postinst.5.gz /usr/share/man/man5/deb-postrm.5.gz /usr/share/man/man5/deb-preinst.5.gz /usr/share/man/man5/deb-prerm.5.gz /usr/share/man/man5/deb-shlibs.5.gz /usr/share/man/man5/deb-split.5.gz /usr/share/man/man5/deb-src-control.5.gz /usr/share/man/man5/deb-src-files.5.gz /usr/share/man/man5/deb-src-rules.5.gz /usr/share/man/man5/deb-substvars.5.gz /usr/share/man/man5/deb-symbols.5.gz /usr/share/man/man5/deb-triggers.5.gz /usr/share/man/man5/deb.5.gz /usr/share/man/man5/deb822.5.gz /usr/share/man/man5/dsc.5.gz /exports/usr/share/man/man5/ && \
  mv /usr/share/man/man7/deb-version.7.gz /usr/share/man/man7/fsf-funding.7gcc.gz /usr/share/man/man7/gfdl.7gcc.gz /usr/share/man/man7/gpl.7gcc.gz /exports/usr/share/man/man7/ && \
  mv /usr/share/man/nl/man1/dpkg-architecture.1.gz /usr/share/man/nl/man1/dpkg-buildflags.1.gz /usr/share/man/nl/man1/dpkg-buildpackage.1.gz /usr/share/man/nl/man1/dpkg-checkbuilddeps.1.gz /usr/share/man/nl/man1/dpkg-distaddfile.1.gz /usr/share/man/nl/man1/dpkg-genbuildinfo.1.gz /usr/share/man/nl/man1/dpkg-genchanges.1.gz /usr/share/man/nl/man1/dpkg-gencontrol.1.gz /usr/share/man/nl/man1/dpkg-gensymbols.1.gz /usr/share/man/nl/man1/dpkg-mergechangelogs.1.gz /usr/share/man/nl/man1/dpkg-name.1.gz /usr/share/man/nl/man1/dpkg-parsechangelog.1.gz /usr/share/man/nl/man1/dpkg-scanpackages.1.gz /usr/share/man/nl/man1/dpkg-scansources.1.gz /usr/share/man/nl/man1/dpkg-shlibdeps.1.gz /usr/share/man/nl/man1/dpkg-source.1.gz /usr/share/man/nl/man1/dpkg-vendor.1.gz /exports/usr/share/man/nl/man1/ && \
  mv /usr/share/man/nl/man5/deb-buildinfo.5.gz /usr/share/man/nl/man5/deb-changelog.5.gz /usr/share/man/nl/man5/deb-changes.5.gz /usr/share/man/nl/man5/deb-conffiles.5.gz /usr/share/man/nl/man5/deb-control.5.gz /usr/share/man/nl/man5/deb-extra-override.5.gz /usr/share/man/nl/man5/deb-old.5.gz /usr/share/man/nl/man5/deb-origin.5.gz /usr/share/man/nl/man5/deb-override.5.gz /usr/share/man/nl/man5/deb-postinst.5.gz /usr/share/man/nl/man5/deb-postrm.5.gz /usr/share/man/nl/man5/deb-preinst.5.gz /usr/share/man/nl/man5/deb-prerm.5.gz /usr/share/man/nl/man5/deb-shlibs.5.gz /usr/share/man/nl/man5/deb-split.5.gz /usr/share/man/nl/man5/deb-src-control.5.gz /usr/share/man/nl/man5/deb-src-files.5.gz /usr/share/man/nl/man5/deb-src-rules.5.gz /usr/share/man/nl/man5/deb-substvars.5.gz /usr/share/man/nl/man5/deb-symbols.5.gz /usr/share/man/nl/man5/deb-triggers.5.gz /usr/share/man/nl/man5/deb.5.gz /usr/share/man/nl/man5/deb822.5.gz /usr/share/man/nl/man5/dsc.5.gz /exports/usr/share/man/nl/man5/ && \
  mv /usr/share/man/nl/man7 /exports/usr/share/man/nl/ && \
  mv /usr/share/man/pl/man5/deb-extra-override.5.gz /usr/share/man/pl/man5/deb-old.5.gz /usr/share/man/pl/man5/deb-override.5.gz /usr/share/man/pl/man5/deb-split.5.gz /exports/usr/share/man/pl/man5/ && \
  mv /usr/share/man/sv/man1/dpkg-gencontrol.1.gz /usr/share/man/sv/man1/dpkg-gensymbols.1.gz /exports/usr/share/man/sv/man1/ && \
  mv /usr/share/man/sv/man5/deb-extra-override.5.gz /usr/share/man/sv/man5/deb-old.5.gz /usr/share/man/sv/man5/deb-override.5.gz /usr/share/man/sv/man5/deb-split.5.gz /exports/usr/share/man/sv/man5/ && \
  mv /usr/share/perl5/Dpkg.pm /usr/share/perl5/Dpkg /exports/usr/share/perl5/ && \
  mv /var/cache/ldconfig/aux-cache /exports/var/cache/ldconfig/

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
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/share/man/man1/ && \
  mv /usr/local/bin/git-crypt /exports/usr/local/bin/ && \
  mv /usr/local/share/man/man1/git-crypt.1 /exports/usr/local/share/man/man1/

# ZSH
FROM base AS zsh
COPY --from=apteryx /exports/ /
RUN \
  apteryx zsh='5.8-*'
RUN \
  mkdir -p /exports/etc/ /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ /exports/usr/local/share/ /exports/usr/share/bug/ /exports/usr/share/doc/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ /exports/usr/share/menu/ /exports/usr/share/zsh/ && \
  mv /etc/shells /etc/zsh /exports/etc/ && \
  mv /usr/bin/rzsh /usr/bin/zsh /usr/bin/zsh5 /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu/zsh /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/bin/apteryx /exports/usr/local/bin/ && \
  mv /usr/local/share/zsh /exports/usr/local/share/ && \
  mv /usr/share/bug/zsh /usr/share/bug/zsh-common /exports/usr/share/bug/ && \
  mv /usr/share/doc/zsh-common /usr/share/doc/zsh /exports/usr/share/doc/ && \
  mv /usr/share/lintian/overrides/zsh /usr/share/lintian/overrides/zsh-common /exports/usr/share/lintian/overrides/ && \
  mv /usr/share/man/man1/rzsh.1.gz /usr/share/man/man1/zsh.1.gz /usr/share/man/man1/zshall.1.gz /usr/share/man/man1/zshbuiltins.1.gz /usr/share/man/man1/zshcalsys.1.gz /usr/share/man/man1/zshcompctl.1.gz /usr/share/man/man1/zshcompsys.1.gz /usr/share/man/man1/zshcompwid.1.gz /usr/share/man/man1/zshcontrib.1.gz /usr/share/man/man1/zshexpn.1.gz /usr/share/man/man1/zshmisc.1.gz /usr/share/man/man1/zshmodules.1.gz /usr/share/man/man1/zshoptions.1.gz /usr/share/man/man1/zshparam.1.gz /usr/share/man/man1/zshroadmap.1.gz /usr/share/man/man1/zshtcpsys.1.gz /usr/share/man/man1/zshzftpsys.1.gz /usr/share/man/man1/zshzle.1.gz /exports/usr/share/man/man1/ && \
  mv /usr/share/menu/zsh-common /exports/usr/share/menu/ && \
  mv /usr/share/zsh/5.8 /usr/share/zsh/functions /usr/share/zsh/help /exports/usr/share/zsh/

# DOTFILES
FROM base AS dotfiles
COPY --from=clone /exports/ /
COPY --from=git-crypt /exports/ /
COPY ./secret/dotfiles-key /tmp/dotfiles-key
RUN \
  clone --https --shallow --tag 'v1.63.0' https://github.com/stayradiated/dotfiles && \
  cd /root/src/github.com/stayradiated/dotfiles && \
  git-crypt unlock /tmp/dotfiles-key && \
  rm /tmp/dotfiles-key && \
  mv /root/src/github.com/stayradiated/dotfiles /root/dotfiles && \
  rm -rf src
RUN \
  mkdir -p /exports/root/ && \
  mv /root/dotfiles /exports/root/

# PYTHON3-PIP
FROM base AS python3-pip
COPY --from=apteryx /exports/ /
RUN \
  apteryx python3-pip python3-dev python3-setuptools python3-venv python3-wheel && \
  pip3 install wheel && \
  python3 -m pip install -U pip==21.1.2
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/include/ /exports/usr/lib/python3.8/ /exports/usr/lib/python3.8/distutils/__pycache__/ /exports/usr/lib/python3.8/distutils/ /exports/usr/lib/ /exports/usr/lib/python3/dist-packages/__pycache__/ /exports/usr/lib/python3/dist-packages/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ /exports/usr/local/lib/python3.8/dist-packages/ /exports/usr/share/ /exports/usr/share/doc-base/ /exports/usr/share/doc/ /exports/usr/share/doc/libcrypt1/ /exports/usr/share/doc/python3.8/ /exports/usr/share/gdb/auto-load/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ /exports/usr/share/man/man3/ /exports/usr/share/man/man5/ && \
  mv /usr/bin/gencat /usr/bin/mtrace /usr/bin/pip /usr/bin/pip3 /usr/bin/python3-config /usr/bin/python3.8-config /usr/bin/pyvenv /usr/bin/rpcgen /usr/bin/sotruss /usr/bin/sprof /usr/bin/x86_64-linux-gnu-python3-config /usr/bin/x86_64-linux-gnu-python3.8-config /exports/usr/bin/ && \
  mv /usr/include/aio.h /usr/include/aliases.h /usr/include/alloca.h /usr/include/ar.h /usr/include/argp.h /usr/include/argz.h /usr/include/arpa /usr/include/asm-generic /usr/include/assert.h /usr/include/byteswap.h /usr/include/complex.h /usr/include/cpio.h /usr/include/crypt.h /usr/include/ctype.h /usr/include/dirent.h /usr/include/dlfcn.h /usr/include/drm /usr/include/elf.h /usr/include/endian.h /usr/include/envz.h /usr/include/err.h /usr/include/errno.h /usr/include/error.h /usr/include/execinfo.h /usr/include/expat_external.h /usr/include/expat.h /usr/include/fcntl.h /usr/include/features.h /usr/include/fenv.h /usr/include/finclude /usr/include/fmtmsg.h /usr/include/fnmatch.h /usr/include/fstab.h /usr/include/fts.h /usr/include/ftw.h /usr/include/gconv.h /usr/include/getopt.h /usr/include/glob.h /usr/include/gnu-versions.h /usr/include/grp.h /usr/include/gshadow.h /usr/include/iconv.h /usr/include/ifaddrs.h /usr/include/inttypes.h /usr/include/langinfo.h /usr/include/lastlog.h /usr/include/libgen.h /usr/include/libintl.h /usr/include/limits.h /usr/include/link.h /usr/include/linux /usr/include/locale.h /usr/include/malloc.h /usr/include/math.h /usr/include/mcheck.h /usr/include/memory.h /usr/include/misc /usr/include/mntent.h /usr/include/monetary.h /usr/include/mqueue.h /usr/include/mtd /usr/include/net /usr/include/netash /usr/include/netatalk /usr/include/netax25 /usr/include/netdb.h /usr/include/neteconet /usr/include/netinet /usr/include/netipx /usr/include/netiucv /usr/include/netpacket /usr/include/netrom /usr/include/netrose /usr/include/nfs /usr/include/nl_types.h /usr/include/nss.h /usr/include/obstack.h /usr/include/paths.h /usr/include/poll.h /usr/include/printf.h /usr/include/proc_service.h /usr/include/protocols /usr/include/pthread.h /usr/include/pty.h /usr/include/pwd.h /usr/include/python3.8 /usr/include/rdma /usr/include/re_comp.h /usr/include/regex.h /usr/include/regexp.h /usr/include/resolv.h /usr/include/rpc /usr/include/rpcsvc /usr/include/sched.h /usr/include/scsi /usr/include/search.h /usr/include/semaphore.h /usr/include/setjmp.h /usr/include/sgtty.h /usr/include/shadow.h /usr/include/signal.h /usr/include/sound /usr/include/spawn.h /usr/include/stab.h /usr/include/stdc-predef.h /usr/include/stdint.h /usr/include/stdio_ext.h /usr/include/stdio.h /usr/include/stdlib.h /usr/include/string.h /usr/include/strings.h /usr/include/syscall.h /usr/include/sysexits.h /usr/include/syslog.h /usr/include/tar.h /usr/include/termio.h /usr/include/termios.h /usr/include/tgmath.h /usr/include/thread_db.h /usr/include/threads.h /usr/include/time.h /usr/include/ttyent.h /usr/include/uchar.h /usr/include/ucontext.h /usr/include/ulimit.h /usr/include/unistd.h /usr/include/utime.h /usr/include/utmp.h /usr/include/utmpx.h /usr/include/values.h /usr/include/video /usr/include/wait.h /usr/include/wchar.h /usr/include/wctype.h /usr/include/wordexp.h /usr/include/x86_64-linux-gnu /usr/include/xen /usr/include/zconf.h /usr/include/zlib.h /exports/usr/include/ && \
  mv /usr/lib/python3.8/config-3.8-x86_64-linux-gnu /usr/lib/python3.8/ensurepip /usr/lib/python3.8/lib2to3 /exports/usr/lib/python3.8/ && \
  mv /usr/lib/python3.8/distutils/__pycache__/_msvccompiler.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/archive_util.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/bcppcompiler.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/ccompiler.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/cmd.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/config.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/core.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/cygwinccompiler.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/debug.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/dep_util.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/dir_util.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/dist.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/errors.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/extension.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/fancy_getopt.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/file_util.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/filelist.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/log.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/msvc9compiler.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/msvccompiler.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/spawn.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/sysconfig.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/text_file.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/unixccompiler.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/util.cpython-38.pyc /usr/lib/python3.8/distutils/__pycache__/versionpredicate.cpython-38.pyc /exports/usr/lib/python3.8/distutils/__pycache__/ && \
  mv /usr/lib/python3.8/distutils/_msvccompiler.py /usr/lib/python3.8/distutils/archive_util.py /usr/lib/python3.8/distutils/bcppcompiler.py /usr/lib/python3.8/distutils/ccompiler.py /usr/lib/python3.8/distutils/cmd.py /usr/lib/python3.8/distutils/command /usr/lib/python3.8/distutils/config.py /usr/lib/python3.8/distutils/core.py /usr/lib/python3.8/distutils/cygwinccompiler.py /usr/lib/python3.8/distutils/debug.py /usr/lib/python3.8/distutils/dep_util.py /usr/lib/python3.8/distutils/dir_util.py /usr/lib/python3.8/distutils/dist.py /usr/lib/python3.8/distutils/errors.py /usr/lib/python3.8/distutils/extension.py /usr/lib/python3.8/distutils/fancy_getopt.py /usr/lib/python3.8/distutils/file_util.py /usr/lib/python3.8/distutils/filelist.py /usr/lib/python3.8/distutils/log.py /usr/lib/python3.8/distutils/msvc9compiler.py /usr/lib/python3.8/distutils/msvccompiler.py /usr/lib/python3.8/distutils/README /usr/lib/python3.8/distutils/spawn.py /usr/lib/python3.8/distutils/sysconfig.py /usr/lib/python3.8/distutils/text_file.py /usr/lib/python3.8/distutils/unixccompiler.py /usr/lib/python3.8/distutils/util.py /usr/lib/python3.8/distutils/versionpredicate.py /exports/usr/lib/python3.8/distutils/ && \
  mv /usr/lib/python3.9 /exports/usr/lib/ && \
  mv /usr/lib/python3/dist-packages/__pycache__/easy_install.cpython-38.pyc /usr/lib/python3/dist-packages/__pycache__/lsb_release.cpython-38.pyc /exports/usr/lib/python3/dist-packages/__pycache__/ && \
  mv /usr/lib/python3/dist-packages/easy_install.py /usr/lib/python3/dist-packages/pip-20.0.2.egg-info /usr/lib/python3/dist-packages/pip /usr/lib/python3/dist-packages/setuptools-45.2.0.egg-info /usr/lib/python3/dist-packages/setuptools /usr/lib/python3/dist-packages/wheel-0.34.2.egg-info /usr/lib/python3/dist-packages/wheel /exports/usr/lib/python3/dist-packages/ && \
  mv /usr/lib/x86_64-linux-gnu/crt1.o /usr/lib/x86_64-linux-gnu/crti.o /usr/lib/x86_64-linux-gnu/crtn.o /usr/lib/x86_64-linux-gnu/gcrt1.o /usr/lib/x86_64-linux-gnu/grcrt1.o /usr/lib/x86_64-linux-gnu/libanl.a /usr/lib/x86_64-linux-gnu/libanl.so /usr/lib/x86_64-linux-gnu/libBrokenLocale.a /usr/lib/x86_64-linux-gnu/libBrokenLocale.so /usr/lib/x86_64-linux-gnu/libc_nonshared.a /usr/lib/x86_64-linux-gnu/libc.a /usr/lib/x86_64-linux-gnu/libc.so /usr/lib/x86_64-linux-gnu/libcrypt.a /usr/lib/x86_64-linux-gnu/libcrypt.so /usr/lib/x86_64-linux-gnu/libdl.a /usr/lib/x86_64-linux-gnu/libdl.so /usr/lib/x86_64-linux-gnu/libexpat.a /usr/lib/x86_64-linux-gnu/libexpat.so /usr/lib/x86_64-linux-gnu/libexpatw.a /usr/lib/x86_64-linux-gnu/libexpatw.so /usr/lib/x86_64-linux-gnu/libg.a /usr/lib/x86_64-linux-gnu/libm-2.31.a /usr/lib/x86_64-linux-gnu/libm.a /usr/lib/x86_64-linux-gnu/libm.so /usr/lib/x86_64-linux-gnu/libmcheck.a /usr/lib/x86_64-linux-gnu/libmvec.a /usr/lib/x86_64-linux-gnu/libmvec.so /usr/lib/x86_64-linux-gnu/libnsl.a /usr/lib/x86_64-linux-gnu/libnsl.so /usr/lib/x86_64-linux-gnu/libnss_compat.so /usr/lib/x86_64-linux-gnu/libnss_dns.so /usr/lib/x86_64-linux-gnu/libnss_files.so /usr/lib/x86_64-linux-gnu/libnss_hesiod.so /usr/lib/x86_64-linux-gnu/libnss_nis.so /usr/lib/x86_64-linux-gnu/libnss_nisplus.so /usr/lib/x86_64-linux-gnu/libpthread.a /usr/lib/x86_64-linux-gnu/libpthread.so /usr/lib/x86_64-linux-gnu/libpython3.8.a /usr/lib/x86_64-linux-gnu/libpython3.8.so /usr/lib/x86_64-linux-gnu/libpython3.8.so.1 /usr/lib/x86_64-linux-gnu/libpython3.8.so.1.0 /usr/lib/x86_64-linux-gnu/libresolv.a /usr/lib/x86_64-linux-gnu/libresolv.so /usr/lib/x86_64-linux-gnu/librpcsvc.a /usr/lib/x86_64-linux-gnu/librt.a /usr/lib/x86_64-linux-gnu/librt.so /usr/lib/x86_64-linux-gnu/libthread_db.so /usr/lib/x86_64-linux-gnu/libutil.a /usr/lib/x86_64-linux-gnu/libutil.so /usr/lib/x86_64-linux-gnu/libz.a /usr/lib/x86_64-linux-gnu/libz.so /usr/lib/x86_64-linux-gnu/Mcrt1.o /usr/lib/x86_64-linux-gnu/pkgconfig /usr/lib/x86_64-linux-gnu/rcrt1.o /usr/lib/x86_64-linux-gnu/Scrt1.o /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/bin/pip /usr/local/bin/pip3 /usr/local/bin/pip3.8 /exports/usr/local/bin/ && \
  mv /usr/local/lib/python3.8/dist-packages/pip-21.1.2.dist-info /usr/local/lib/python3.8/dist-packages/pip /exports/usr/local/lib/python3.8/dist-packages/ && \
  mv /usr/share/aclocal /usr/share/python-wheels /exports/usr/share/ && \
  mv /usr/share/doc-base/expat /exports/usr/share/doc-base/ && \
  mv /usr/share/doc/libc-dev-bin /usr/share/doc/libc6-dev /usr/share/doc/libcrypt-dev /usr/share/doc/libexpat1-dev /usr/share/doc/libpython3-dev /usr/share/doc/libpython3.8 /usr/share/doc/libpython3.8-dev /usr/share/doc/linux-libc-dev /usr/share/doc/python-pip-whl /usr/share/doc/python3-dev /usr/share/doc/python3-distutils /usr/share/doc/python3-lib2to3 /usr/share/doc/python3-pip /usr/share/doc/python3-setuptools /usr/share/doc/python3-venv /usr/share/doc/python3-wheel /usr/share/doc/python3.8-dev /usr/share/doc/python3.8-venv /usr/share/doc/zlib1g-dev /exports/usr/share/doc/ && \
  mv /usr/share/doc/libcrypt1/README.md.gz /usr/share/doc/libcrypt1/TODO.md.gz /exports/usr/share/doc/libcrypt1/ && \
  mv /usr/share/doc/python3.8/gdbinit.gz /usr/share/doc/python3.8/HISTORY.gz /usr/share/doc/python3.8/pybench.log /usr/share/doc/python3.8/README.maintainers /usr/share/doc/python3.8/README.valgrind.gz /usr/share/doc/python3.8/test_results.gz /exports/usr/share/doc/python3.8/ && \
  mv /usr/share/gdb/auto-load/lib /exports/usr/share/gdb/auto-load/ && \
  mv /usr/share/lintian/overrides/libc-dev-bin /usr/share/lintian/overrides/libc6-dev /usr/share/lintian/overrides/libpython3.8 /usr/share/lintian/overrides/libpython3.8-dev /usr/share/lintian/overrides/python3-distutils /usr/share/lintian/overrides/python3-lib2to3 /usr/share/lintian/overrides/python3.8-venv /exports/usr/share/lintian/overrides/ && \
  mv /usr/share/man/man1/gencat.1.gz /usr/share/man/man1/pip.1.gz /usr/share/man/man1/pip3.1.gz /usr/share/man/man1/python3-config.1.gz /usr/share/man/man1/python3.8-config.1.gz /usr/share/man/man1/pyvenv.1.gz /usr/share/man/man1/rpcgen.1.gz /usr/share/man/man1/sotruss.1.gz /usr/share/man/man1/x86_64-linux-gnu-python3-config.1.gz /usr/share/man/man1/x86_64-linux-gnu-python3.8-config.1.gz /exports/usr/share/man/man1/ && \
  mv /usr/share/man/man3/crypt_checksalt.3.gz /usr/share/man/man3/crypt_gensalt_ra.3.gz /usr/share/man/man3/crypt_gensalt_rn.3.gz /usr/share/man/man3/crypt_gensalt.3.gz /usr/share/man/man3/crypt_preferred_method.3.gz /usr/share/man/man3/crypt_r.3.gz /usr/share/man/man3/crypt_ra.3.gz /usr/share/man/man3/crypt_rn.3.gz /usr/share/man/man3/crypt.3.gz /usr/share/man/man3/zlib.3.gz /exports/usr/share/man/man3/ && \
  mv /usr/share/man/man5/crypt.5.gz /exports/usr/share/man/man5/

# N
FROM base AS n
RUN \
  curl -L https://raw.githubusercontent.com/tj/n/v7.2.2/bin/n -o /usr/local/bin/n && \
  chmod +x /usr/local/bin/n
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/n /exports/usr/local/bin/

# LUA
FROM base AS lua
COPY --from=apteryx /exports/ /
RUN \
  apteryx lua5.3='5.3.3-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/share/man/man1/ && \
  mv /usr/bin/lua5.3 /exports/usr/bin/ && \
  mv /usr/share/man/man1/lua5.3.1.gz /exports/usr/share/man/man1/

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
  mkdir -p /home/admin/.cache /home/admin/.config /home/admin/.local/share && \
  chown -R admin:admin /home/admin

# PIPX
FROM base AS pipx
COPY --from=apteryx /exports/ /
COPY --from=python3-pip /exports/ /
RUN \
  pip3 install pipx==0.16.3
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/python3.8/dist-packages/ && \
  mv /usr/local/bin/activate-global-python-argcomplete /usr/local/bin/pipx /usr/local/bin/python-argcomplete-check-easy-install-script /usr/local/bin/python-argcomplete-tcsh /usr/local/bin/register-python-argcomplete /usr/local/bin/userpath /exports/usr/local/bin/ && \
  mv /usr/local/lib/python3.8/dist-packages/__pycache__ /usr/local/lib/python3.8/dist-packages/argcomplete-1.12.3.dist-info /usr/local/lib/python3.8/dist-packages/argcomplete /usr/local/lib/python3.8/dist-packages/click-8.0.1.dist-info /usr/local/lib/python3.8/dist-packages/click /usr/local/lib/python3.8/dist-packages/packaging-20.9.dist-info /usr/local/lib/python3.8/dist-packages/packaging /usr/local/lib/python3.8/dist-packages/pipx-0.16.3.dist-info /usr/local/lib/python3.8/dist-packages/pipx /usr/local/lib/python3.8/dist-packages/pyparsing-2.4.7.dist-info /usr/local/lib/python3.8/dist-packages/pyparsing.py /usr/local/lib/python3.8/dist-packages/userpath-1.6.0.dist-info /usr/local/lib/python3.8/dist-packages/userpath /exports/usr/local/lib/python3.8/dist-packages/

# NODE
FROM base AS node
COPY --from=n /exports/ /
RUN \
  n lts && \
  n 16.3.0 && \
  npm install -g npm
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/include/ /exports/usr/local/lib/ /exports/usr/local/ && \
  mv /usr/local/bin/n /usr/local/bin/node /usr/local/bin/npm /usr/local/bin/npx /exports/usr/local/bin/ && \
  mv /usr/local/include/node /exports/usr/local/include/ && \
  mv /usr/local/lib/node_modules /exports/usr/local/lib/ && \
  mv /usr/local/n /exports/usr/local/

# Z.LUA
FROM base AS z.lua
COPY --from=wget /exports/ /
COPY --from=lua /exports/ /
RUN \
  wget -O /usr/local/bin/z.lua 'https://raw.githubusercontent.com/skywind3000/z.lua/1.8.7/z.lua'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/local/bin/ /exports/usr/share/man/man1/ && \
  mv /usr/bin/lua5.3 /exports/usr/bin/ && \
  mv /usr/local/bin/z.lua /exports/usr/local/bin/ && \
  mv /usr/share/man/man1/lua5.3.1.gz /exports/usr/share/man/man1/

# PYTHON2
FROM base AS python2
COPY --from=apteryx /exports/ /
RUN \
  apteryx python2.7='2.7.18-1~*' && \
  update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
RUN \
  mkdir -p /exports/etc/alternatives/ /exports/etc/ /exports/usr/bin/ /exports/usr/lib/python2.7/ /exports/usr/lib/python2.7/dist-packages/ /exports/usr/local/bin/ /exports/usr/local/lib/ /exports/usr/share/applications/ /exports/usr/share/binfmts/ /exports/usr/share/doc/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ /exports/usr/share/pixmaps/ && \
  mv /etc/alternatives/python /exports/etc/alternatives/ && \
  mv /etc/python2.7 /exports/etc/ && \
  mv /usr/bin/2to3-2.7 /usr/bin/pdb2.7 /usr/bin/pydoc2.7 /usr/bin/pygettext2.7 /usr/bin/python /usr/bin/python2.7 /exports/usr/bin/ && \
  mv /usr/lib/python2.7/__future__.py /usr/lib/python2.7/__future__.pyc /usr/lib/python2.7/__phello__.foo.py /usr/lib/python2.7/__phello__.foo.pyc /usr/lib/python2.7/_abcoll.py /usr/lib/python2.7/_abcoll.pyc /usr/lib/python2.7/_LWPCookieJar.py /usr/lib/python2.7/_LWPCookieJar.pyc /usr/lib/python2.7/_MozillaCookieJar.py /usr/lib/python2.7/_MozillaCookieJar.pyc /usr/lib/python2.7/_osx_support.py /usr/lib/python2.7/_osx_support.pyc /usr/lib/python2.7/_pyio.py /usr/lib/python2.7/_pyio.pyc /usr/lib/python2.7/_strptime.py /usr/lib/python2.7/_strptime.pyc /usr/lib/python2.7/_sysconfigdata.py /usr/lib/python2.7/_sysconfigdata.pyc /usr/lib/python2.7/_threading_local.py /usr/lib/python2.7/_threading_local.pyc /usr/lib/python2.7/_weakrefset.py /usr/lib/python2.7/_weakrefset.pyc /usr/lib/python2.7/abc.py /usr/lib/python2.7/abc.pyc /usr/lib/python2.7/aifc.py /usr/lib/python2.7/aifc.pyc /usr/lib/python2.7/antigravity.py /usr/lib/python2.7/antigravity.pyc /usr/lib/python2.7/anydbm.py /usr/lib/python2.7/anydbm.pyc /usr/lib/python2.7/argparse.egg-info /usr/lib/python2.7/argparse.py /usr/lib/python2.7/argparse.pyc /usr/lib/python2.7/ast.py /usr/lib/python2.7/ast.pyc /usr/lib/python2.7/asynchat.py /usr/lib/python2.7/asynchat.pyc /usr/lib/python2.7/asyncore.py /usr/lib/python2.7/asyncore.pyc /usr/lib/python2.7/atexit.py /usr/lib/python2.7/atexit.pyc /usr/lib/python2.7/audiodev.py /usr/lib/python2.7/audiodev.pyc /usr/lib/python2.7/base64.py /usr/lib/python2.7/base64.pyc /usr/lib/python2.7/BaseHTTPServer.py /usr/lib/python2.7/BaseHTTPServer.pyc /usr/lib/python2.7/Bastion.py /usr/lib/python2.7/Bastion.pyc /usr/lib/python2.7/bdb.py /usr/lib/python2.7/bdb.pyc /usr/lib/python2.7/binhex.py /usr/lib/python2.7/binhex.pyc /usr/lib/python2.7/bisect.py /usr/lib/python2.7/bisect.pyc /usr/lib/python2.7/bsddb /usr/lib/python2.7/calendar.py /usr/lib/python2.7/calendar.pyc /usr/lib/python2.7/cgi.py /usr/lib/python2.7/cgi.pyc /usr/lib/python2.7/CGIHTTPServer.py /usr/lib/python2.7/CGIHTTPServer.pyc /usr/lib/python2.7/cgitb.py /usr/lib/python2.7/cgitb.pyc /usr/lib/python2.7/chunk.py /usr/lib/python2.7/chunk.pyc /usr/lib/python2.7/cmd.py /usr/lib/python2.7/cmd.pyc /usr/lib/python2.7/code.py /usr/lib/python2.7/code.pyc /usr/lib/python2.7/codecs.py /usr/lib/python2.7/codecs.pyc /usr/lib/python2.7/codeop.py /usr/lib/python2.7/codeop.pyc /usr/lib/python2.7/collections.py /usr/lib/python2.7/collections.pyc /usr/lib/python2.7/colorsys.py /usr/lib/python2.7/colorsys.pyc /usr/lib/python2.7/commands.py /usr/lib/python2.7/commands.pyc /usr/lib/python2.7/compileall.py /usr/lib/python2.7/compileall.pyc /usr/lib/python2.7/compiler /usr/lib/python2.7/ConfigParser.py /usr/lib/python2.7/ConfigParser.pyc /usr/lib/python2.7/contextlib.py /usr/lib/python2.7/contextlib.pyc /usr/lib/python2.7/Cookie.py /usr/lib/python2.7/Cookie.pyc /usr/lib/python2.7/cookielib.py /usr/lib/python2.7/cookielib.pyc /usr/lib/python2.7/copy_reg.py /usr/lib/python2.7/copy_reg.pyc /usr/lib/python2.7/copy.py /usr/lib/python2.7/copy.pyc /usr/lib/python2.7/cProfile.py /usr/lib/python2.7/cProfile.pyc /usr/lib/python2.7/csv.py /usr/lib/python2.7/csv.pyc /usr/lib/python2.7/ctypes /usr/lib/python2.7/curses /usr/lib/python2.7/dbhash.py /usr/lib/python2.7/dbhash.pyc /usr/lib/python2.7/decimal.py /usr/lib/python2.7/decimal.pyc /usr/lib/python2.7/difflib.py /usr/lib/python2.7/difflib.pyc /usr/lib/python2.7/dircache.py /usr/lib/python2.7/dircache.pyc /usr/lib/python2.7/dis.py /usr/lib/python2.7/dis.pyc /usr/lib/python2.7/distutils /usr/lib/python2.7/doctest.py /usr/lib/python2.7/doctest.pyc /usr/lib/python2.7/DocXMLRPCServer.py /usr/lib/python2.7/DocXMLRPCServer.pyc /usr/lib/python2.7/dumbdbm.py /usr/lib/python2.7/dumbdbm.pyc /usr/lib/python2.7/dummy_thread.py /usr/lib/python2.7/dummy_thread.pyc /usr/lib/python2.7/dummy_threading.py /usr/lib/python2.7/dummy_threading.pyc /usr/lib/python2.7/email /usr/lib/python2.7/encodings /usr/lib/python2.7/ensurepip /usr/lib/python2.7/filecmp.py /usr/lib/python2.7/filecmp.pyc /usr/lib/python2.7/fileinput.py /usr/lib/python2.7/fileinput.pyc /usr/lib/python2.7/fnmatch.py /usr/lib/python2.7/fnmatch.pyc /usr/lib/python2.7/formatter.py /usr/lib/python2.7/formatter.pyc /usr/lib/python2.7/fpformat.py /usr/lib/python2.7/fpformat.pyc /usr/lib/python2.7/fractions.py /usr/lib/python2.7/fractions.pyc /usr/lib/python2.7/ftplib.py /usr/lib/python2.7/ftplib.pyc /usr/lib/python2.7/functools.py /usr/lib/python2.7/functools.pyc /usr/lib/python2.7/genericpath.py /usr/lib/python2.7/genericpath.pyc /usr/lib/python2.7/getopt.py /usr/lib/python2.7/getopt.pyc /usr/lib/python2.7/getpass.py /usr/lib/python2.7/getpass.pyc /usr/lib/python2.7/gettext.py /usr/lib/python2.7/gettext.pyc /usr/lib/python2.7/glob.py /usr/lib/python2.7/glob.pyc /usr/lib/python2.7/gzip.py /usr/lib/python2.7/gzip.pyc /usr/lib/python2.7/hashlib.py /usr/lib/python2.7/hashlib.pyc /usr/lib/python2.7/heapq.py /usr/lib/python2.7/heapq.pyc /usr/lib/python2.7/hmac.py /usr/lib/python2.7/hmac.pyc /usr/lib/python2.7/hotshot /usr/lib/python2.7/htmlentitydefs.py /usr/lib/python2.7/htmlentitydefs.pyc /usr/lib/python2.7/htmllib.py /usr/lib/python2.7/htmllib.pyc /usr/lib/python2.7/HTMLParser.py /usr/lib/python2.7/HTMLParser.pyc /usr/lib/python2.7/httplib.py /usr/lib/python2.7/httplib.pyc /usr/lib/python2.7/ihooks.py /usr/lib/python2.7/ihooks.pyc /usr/lib/python2.7/imaplib.py /usr/lib/python2.7/imaplib.pyc /usr/lib/python2.7/imghdr.py /usr/lib/python2.7/imghdr.pyc /usr/lib/python2.7/importlib /usr/lib/python2.7/imputil.py /usr/lib/python2.7/imputil.pyc /usr/lib/python2.7/inspect.py /usr/lib/python2.7/inspect.pyc /usr/lib/python2.7/io.py /usr/lib/python2.7/io.pyc /usr/lib/python2.7/json /usr/lib/python2.7/keyword.py /usr/lib/python2.7/keyword.pyc /usr/lib/python2.7/lib-dynload /usr/lib/python2.7/lib-tk /usr/lib/python2.7/lib2to3 /usr/lib/python2.7/LICENSE.txt /usr/lib/python2.7/linecache.py /usr/lib/python2.7/linecache.pyc /usr/lib/python2.7/locale.py /usr/lib/python2.7/locale.pyc /usr/lib/python2.7/logging /usr/lib/python2.7/macpath.py /usr/lib/python2.7/macpath.pyc /usr/lib/python2.7/macurl2path.py /usr/lib/python2.7/macurl2path.pyc /usr/lib/python2.7/mailbox.py /usr/lib/python2.7/mailbox.pyc /usr/lib/python2.7/mailcap.py /usr/lib/python2.7/mailcap.pyc /usr/lib/python2.7/markupbase.py /usr/lib/python2.7/markupbase.pyc /usr/lib/python2.7/md5.py /usr/lib/python2.7/md5.pyc /usr/lib/python2.7/mhlib.py /usr/lib/python2.7/mhlib.pyc /usr/lib/python2.7/mimetools.py /usr/lib/python2.7/mimetools.pyc /usr/lib/python2.7/mimetypes.py /usr/lib/python2.7/mimetypes.pyc /usr/lib/python2.7/MimeWriter.py /usr/lib/python2.7/MimeWriter.pyc /usr/lib/python2.7/mimify.py /usr/lib/python2.7/mimify.pyc /usr/lib/python2.7/modulefinder.py /usr/lib/python2.7/modulefinder.pyc /usr/lib/python2.7/multifile.py /usr/lib/python2.7/multifile.pyc /usr/lib/python2.7/multiprocessing /usr/lib/python2.7/mutex.py /usr/lib/python2.7/mutex.pyc /usr/lib/python2.7/netrc.py /usr/lib/python2.7/netrc.pyc /usr/lib/python2.7/new.py /usr/lib/python2.7/new.pyc /usr/lib/python2.7/nntplib.py /usr/lib/python2.7/nntplib.pyc /usr/lib/python2.7/ntpath.py /usr/lib/python2.7/ntpath.pyc /usr/lib/python2.7/nturl2path.py /usr/lib/python2.7/nturl2path.pyc /usr/lib/python2.7/numbers.py /usr/lib/python2.7/numbers.pyc /usr/lib/python2.7/opcode.py /usr/lib/python2.7/opcode.pyc /usr/lib/python2.7/optparse.py /usr/lib/python2.7/optparse.pyc /usr/lib/python2.7/os.py /usr/lib/python2.7/os.pyc /usr/lib/python2.7/os2emxpath.py /usr/lib/python2.7/os2emxpath.pyc /usr/lib/python2.7/pdb.doc /usr/lib/python2.7/pdb.py /usr/lib/python2.7/pdb.pyc /usr/lib/python2.7/pickle.py /usr/lib/python2.7/pickle.pyc /usr/lib/python2.7/pickletools.py /usr/lib/python2.7/pickletools.pyc /usr/lib/python2.7/pipes.py /usr/lib/python2.7/pipes.pyc /usr/lib/python2.7/pkgutil.py /usr/lib/python2.7/pkgutil.pyc /usr/lib/python2.7/plat-x86_64-linux-gnu /usr/lib/python2.7/platform.py /usr/lib/python2.7/platform.pyc /usr/lib/python2.7/plistlib.py /usr/lib/python2.7/plistlib.pyc /usr/lib/python2.7/popen2.py /usr/lib/python2.7/popen2.pyc /usr/lib/python2.7/poplib.py /usr/lib/python2.7/poplib.pyc /usr/lib/python2.7/posixfile.py /usr/lib/python2.7/posixfile.pyc /usr/lib/python2.7/posixpath.py /usr/lib/python2.7/posixpath.pyc /usr/lib/python2.7/pprint.py /usr/lib/python2.7/pprint.pyc /usr/lib/python2.7/profile.py /usr/lib/python2.7/profile.pyc /usr/lib/python2.7/pstats.py /usr/lib/python2.7/pstats.pyc /usr/lib/python2.7/pty.py /usr/lib/python2.7/pty.pyc /usr/lib/python2.7/py_compile.py /usr/lib/python2.7/py_compile.pyc /usr/lib/python2.7/pyclbr.py /usr/lib/python2.7/pyclbr.pyc /usr/lib/python2.7/pydoc_data /usr/lib/python2.7/pydoc.py /usr/lib/python2.7/pydoc.pyc /usr/lib/python2.7/Queue.py /usr/lib/python2.7/Queue.pyc /usr/lib/python2.7/quopri.py /usr/lib/python2.7/quopri.pyc /usr/lib/python2.7/random.py /usr/lib/python2.7/random.pyc /usr/lib/python2.7/re.py /usr/lib/python2.7/re.pyc /usr/lib/python2.7/repr.py /usr/lib/python2.7/repr.pyc /usr/lib/python2.7/rexec.py /usr/lib/python2.7/rexec.pyc /usr/lib/python2.7/rfc822.py /usr/lib/python2.7/rfc822.pyc /usr/lib/python2.7/rlcompleter.py /usr/lib/python2.7/rlcompleter.pyc /usr/lib/python2.7/robotparser.py /usr/lib/python2.7/robotparser.pyc /usr/lib/python2.7/runpy.py /usr/lib/python2.7/runpy.pyc /usr/lib/python2.7/sched.py /usr/lib/python2.7/sched.pyc /usr/lib/python2.7/sets.py /usr/lib/python2.7/sets.pyc /usr/lib/python2.7/sgmllib.py /usr/lib/python2.7/sgmllib.pyc /usr/lib/python2.7/sha.py /usr/lib/python2.7/sha.pyc /usr/lib/python2.7/shelve.py /usr/lib/python2.7/shelve.pyc /usr/lib/python2.7/shlex.py /usr/lib/python2.7/shlex.pyc /usr/lib/python2.7/shutil.py /usr/lib/python2.7/shutil.pyc /usr/lib/python2.7/SimpleHTTPServer.py /usr/lib/python2.7/SimpleHTTPServer.pyc /usr/lib/python2.7/SimpleXMLRPCServer.py /usr/lib/python2.7/SimpleXMLRPCServer.pyc /usr/lib/python2.7/site.py /usr/lib/python2.7/site.pyc /usr/lib/python2.7/sitecustomize.py /usr/lib/python2.7/sitecustomize.pyc /usr/lib/python2.7/smtpd.py /usr/lib/python2.7/smtpd.pyc /usr/lib/python2.7/smtplib.py /usr/lib/python2.7/smtplib.pyc /usr/lib/python2.7/sndhdr.py /usr/lib/python2.7/sndhdr.pyc /usr/lib/python2.7/socket.py /usr/lib/python2.7/socket.pyc /usr/lib/python2.7/SocketServer.py /usr/lib/python2.7/SocketServer.pyc /usr/lib/python2.7/sqlite3 /usr/lib/python2.7/sre_compile.py /usr/lib/python2.7/sre_compile.pyc /usr/lib/python2.7/sre_constants.py /usr/lib/python2.7/sre_constants.pyc /usr/lib/python2.7/sre_parse.py /usr/lib/python2.7/sre_parse.pyc /usr/lib/python2.7/sre.py /usr/lib/python2.7/sre.pyc /usr/lib/python2.7/ssl.py /usr/lib/python2.7/ssl.pyc /usr/lib/python2.7/stat.py /usr/lib/python2.7/stat.pyc /usr/lib/python2.7/statvfs.py /usr/lib/python2.7/statvfs.pyc /usr/lib/python2.7/string.py /usr/lib/python2.7/string.pyc /usr/lib/python2.7/StringIO.py /usr/lib/python2.7/StringIO.pyc /usr/lib/python2.7/stringold.py /usr/lib/python2.7/stringold.pyc /usr/lib/python2.7/stringprep.py /usr/lib/python2.7/stringprep.pyc /usr/lib/python2.7/struct.py /usr/lib/python2.7/struct.pyc /usr/lib/python2.7/subprocess.py /usr/lib/python2.7/subprocess.pyc /usr/lib/python2.7/sunau.py /usr/lib/python2.7/sunau.pyc /usr/lib/python2.7/sunaudio.py /usr/lib/python2.7/sunaudio.pyc /usr/lib/python2.7/symbol.py /usr/lib/python2.7/symbol.pyc /usr/lib/python2.7/symtable.py /usr/lib/python2.7/symtable.pyc /usr/lib/python2.7/sysconfig.py /usr/lib/python2.7/sysconfig.pyc /usr/lib/python2.7/tabnanny.py /usr/lib/python2.7/tabnanny.pyc /usr/lib/python2.7/tarfile.py /usr/lib/python2.7/tarfile.pyc /usr/lib/python2.7/telnetlib.py /usr/lib/python2.7/telnetlib.pyc /usr/lib/python2.7/tempfile.py /usr/lib/python2.7/tempfile.pyc /usr/lib/python2.7/test /usr/lib/python2.7/textwrap.py /usr/lib/python2.7/textwrap.pyc /usr/lib/python2.7/this.py /usr/lib/python2.7/this.pyc /usr/lib/python2.7/threading.py /usr/lib/python2.7/threading.pyc /usr/lib/python2.7/timeit.py /usr/lib/python2.7/timeit.pyc /usr/lib/python2.7/toaiff.py /usr/lib/python2.7/toaiff.pyc /usr/lib/python2.7/token.py /usr/lib/python2.7/token.pyc /usr/lib/python2.7/tokenize.py /usr/lib/python2.7/tokenize.pyc /usr/lib/python2.7/trace.py /usr/lib/python2.7/trace.pyc /usr/lib/python2.7/traceback.py /usr/lib/python2.7/traceback.pyc /usr/lib/python2.7/tty.py /usr/lib/python2.7/tty.pyc /usr/lib/python2.7/types.py /usr/lib/python2.7/types.pyc /usr/lib/python2.7/unittest /usr/lib/python2.7/urllib.py /usr/lib/python2.7/urllib.pyc /usr/lib/python2.7/urllib2.py /usr/lib/python2.7/urllib2.pyc /usr/lib/python2.7/urlparse.py /usr/lib/python2.7/urlparse.pyc /usr/lib/python2.7/user.py /usr/lib/python2.7/user.pyc /usr/lib/python2.7/UserDict.py /usr/lib/python2.7/UserDict.pyc /usr/lib/python2.7/UserList.py /usr/lib/python2.7/UserList.pyc /usr/lib/python2.7/UserString.py /usr/lib/python2.7/UserString.pyc /usr/lib/python2.7/uu.py /usr/lib/python2.7/uu.pyc /usr/lib/python2.7/uuid.py /usr/lib/python2.7/uuid.pyc /usr/lib/python2.7/warnings.py /usr/lib/python2.7/warnings.pyc /usr/lib/python2.7/wave.py /usr/lib/python2.7/wave.pyc /usr/lib/python2.7/weakref.py /usr/lib/python2.7/weakref.pyc /usr/lib/python2.7/webbrowser.py /usr/lib/python2.7/webbrowser.pyc /usr/lib/python2.7/whichdb.py /usr/lib/python2.7/whichdb.pyc /usr/lib/python2.7/wsgiref.egg-info /usr/lib/python2.7/wsgiref /usr/lib/python2.7/xdrlib.py /usr/lib/python2.7/xdrlib.pyc /usr/lib/python2.7/xml /usr/lib/python2.7/xmllib.py /usr/lib/python2.7/xmllib.pyc /usr/lib/python2.7/xmlrpclib.py /usr/lib/python2.7/xmlrpclib.pyc /usr/lib/python2.7/zipfile.py /usr/lib/python2.7/zipfile.pyc /exports/usr/lib/python2.7/ && \
  mv /usr/lib/python2.7/dist-packages/README /exports/usr/lib/python2.7/dist-packages/ && \
  mv /usr/local/bin/apteryx /exports/usr/local/bin/ && \
  mv /usr/local/lib/python2.7 /exports/usr/local/lib/ && \
  mv /usr/share/applications/python2.7.desktop /exports/usr/share/applications/ && \
  mv /usr/share/binfmts/python2.7 /exports/usr/share/binfmts/ && \
  mv /usr/share/doc/libpython2.7-minimal /usr/share/doc/libpython2.7-stdlib /usr/share/doc/python2.7-minimal /usr/share/doc/python2.7 /exports/usr/share/doc/ && \
  mv /usr/share/lintian/overrides/libpython2.7-minimal /usr/share/lintian/overrides/libpython2.7-stdlib /usr/share/lintian/overrides/python2.7 /usr/share/lintian/overrides/python2.7-minimal /exports/usr/share/lintian/overrides/ && \
  mv /usr/share/man/man1/2to3-2.7.1.gz /usr/share/man/man1/pdb2.7.1.gz /usr/share/man/man1/pydoc2.7.1.gz /usr/share/man/man1/pygettext2.7.1.gz /usr/share/man/man1/python2.7.1.gz /exports/usr/share/man/man1/ && \
  mv /usr/share/pixmaps/python2.7.xpm /exports/usr/share/pixmaps/

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

# SHELL-ADMIN
FROM shell-root AS shell-admin
USER admin
WORKDIR /home/admin
ENV \
  PATH=/home/admin/dotfiles/bin:${PATH}
RUN \
  mkdir -p /home/admin/exports && \
  mkdir -p /home/admin/.local/tmp

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
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/include/ /exports/usr/local/lib/python3.8/dist-packages/ /exports/usr/local/share/man/ /exports/usr/local/share/ && \
  mv /usr/local/bin/nvim /exports/usr/local/bin/ && \
  mv /usr/local/include/python3.8 /exports/usr/local/include/ && \
  mv /usr/local/lib/python3.8/dist-packages/greenlet-1.1.0.dist-info /usr/local/lib/python3.8/dist-packages/greenlet /usr/local/lib/python3.8/dist-packages/msgpack-1.0.2.dist-info /usr/local/lib/python3.8/dist-packages/msgpack /usr/local/lib/python3.8/dist-packages/neovim-0.3.1.dist-info /usr/local/lib/python3.8/dist-packages/neovim /usr/local/lib/python3.8/dist-packages/pynvim-0.4.3.dist-info /usr/local/lib/python3.8/dist-packages/pynvim /exports/usr/local/lib/python3.8/dist-packages/ && \
  mv /usr/local/share/man/man1 /exports/usr/local/share/man/ && \
  mv /usr/local/share/nvim /exports/usr/local/share/

# TMUX
FROM base AS tmux
COPY --from=apteryx /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=make /exports/ /
COPY --from=wget /exports/ /
RUN \
  apteryx libncurses5-dev libevent-dev && \
  cd /root && \
  wget -O /tmp/tmux.tgz 'https://github.com/tmux/tmux/releases/download/3.2/tmux-3.2.tar.gz' && \
  tar xzvf /tmp/tmux.tgz && \
  rm /tmp/tmux.tgz && \
  cd 'tmux-3.2' && \
  ./configure && \
  make && \
  make install && \
  cd .. && \
  rm -r 'tmux-3.2'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/include/ /exports/usr/lib/valgrind/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ /exports/usr/local/bin/ /exports/usr/local/share/man/ /exports/usr/share/doc/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ && \
  mv /usr/bin/ncurses5-config /usr/bin/ncurses6-config /usr/bin/ncursesw5-config /usr/bin/ncursesw6-config /exports/usr/bin/ && \
  mv /usr/include/curses.h /usr/include/cursesapp.h /usr/include/cursesf.h /usr/include/cursesm.h /usr/include/cursesp.h /usr/include/cursesw.h /usr/include/cursslk.h /usr/include/eti.h /usr/include/etip.h /usr/include/evdns.h /usr/include/event.h /usr/include/event2 /usr/include/evhttp.h /usr/include/evrpc.h /usr/include/evutil.h /usr/include/form.h /usr/include/menu.h /usr/include/nc_tparm.h /usr/include/ncurses_dll.h /usr/include/ncurses.h /usr/include/ncursesw /usr/include/panel.h /usr/include/term_entry.h /usr/include/term.h /usr/include/termcap.h /usr/include/tic.h /usr/include/unctrl.h /exports/usr/include/ && \
  mv /usr/lib/valgrind/ncurses.supp /exports/usr/lib/valgrind/ && \
  mv /usr/lib/x86_64-linux-gnu/libcurses.a /usr/lib/x86_64-linux-gnu/libcurses.so /usr/lib/x86_64-linux-gnu/libevent_core-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent_core-2.1.so.7.0.0 /usr/lib/x86_64-linux-gnu/libevent_core.a /usr/lib/x86_64-linux-gnu/libevent_core.so /usr/lib/x86_64-linux-gnu/libevent_extra-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent_extra-2.1.so.7.0.0 /usr/lib/x86_64-linux-gnu/libevent_extra.a /usr/lib/x86_64-linux-gnu/libevent_extra.so /usr/lib/x86_64-linux-gnu/libevent_openssl-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent_openssl-2.1.so.7.0.0 /usr/lib/x86_64-linux-gnu/libevent_openssl.a /usr/lib/x86_64-linux-gnu/libevent_openssl.so /usr/lib/x86_64-linux-gnu/libevent_pthreads-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent_pthreads-2.1.so.7.0.0 /usr/lib/x86_64-linux-gnu/libevent_pthreads.a /usr/lib/x86_64-linux-gnu/libevent_pthreads.so /usr/lib/x86_64-linux-gnu/libevent-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent-2.1.so.7.0.0 /usr/lib/x86_64-linux-gnu/libevent.a /usr/lib/x86_64-linux-gnu/libevent.so /usr/lib/x86_64-linux-gnu/libform.a /usr/lib/x86_64-linux-gnu/libform.so /usr/lib/x86_64-linux-gnu/libformw.a /usr/lib/x86_64-linux-gnu/libformw.so /usr/lib/x86_64-linux-gnu/libmenu.a /usr/lib/x86_64-linux-gnu/libmenu.so /usr/lib/x86_64-linux-gnu/libmenuw.a /usr/lib/x86_64-linux-gnu/libmenuw.so /usr/lib/x86_64-linux-gnu/libncurses.a /usr/lib/x86_64-linux-gnu/libncurses.so /usr/lib/x86_64-linux-gnu/libncurses++.a /usr/lib/x86_64-linux-gnu/libncurses++w.a /usr/lib/x86_64-linux-gnu/libncursesw.a /usr/lib/x86_64-linux-gnu/libncursesw.so /usr/lib/x86_64-linux-gnu/libpanel.a /usr/lib/x86_64-linux-gnu/libpanel.so /usr/lib/x86_64-linux-gnu/libpanelw.a /usr/lib/x86_64-linux-gnu/libpanelw.so /usr/lib/x86_64-linux-gnu/libtermcap.a /usr/lib/x86_64-linux-gnu/libtermcap.so /usr/lib/x86_64-linux-gnu/libtic.a /usr/lib/x86_64-linux-gnu/libtic.so /usr/lib/x86_64-linux-gnu/libtinfo.a /usr/lib/x86_64-linux-gnu/libtinfo.so /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/lib/x86_64-linux-gnu/pkgconfig/form.pc /usr/lib/x86_64-linux-gnu/pkgconfig/formw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent_core.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent_extra.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent_openssl.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent_pthreads.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent.pc /usr/lib/x86_64-linux-gnu/pkgconfig/menu.pc /usr/lib/x86_64-linux-gnu/pkgconfig/menuw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncurses.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncurses++.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncurses++w.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncursesw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/panel.pc /usr/lib/x86_64-linux-gnu/pkgconfig/panelw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/tic.pc /usr/lib/x86_64-linux-gnu/pkgconfig/tinfo.pc /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ && \
  mv /usr/local/bin/tmux /exports/usr/local/bin/ && \
  mv /usr/local/share/man/man1 /exports/usr/local/share/man/ && \
  mv /usr/share/doc/libevent-2.1-7 /usr/share/doc/libevent-core-2.1-7 /usr/share/doc/libevent-dev /usr/share/doc/libevent-extra-2.1-7 /usr/share/doc/libevent-openssl-2.1-7 /usr/share/doc/libevent-pthreads-2.1-7 /usr/share/doc/libncurses-dev /usr/share/doc/libncurses5-dev /exports/usr/share/doc/ && \
  mv /usr/share/lintian/overrides/libevent-openssl-2.1-7 /exports/usr/share/lintian/overrides/ && \
  mv /usr/share/man/man1/ncurses5-config.1.gz /usr/share/man/man1/ncurses6-config.1.gz /usr/share/man/man1/ncursesw5-config.1.gz /usr/share/man/man1/ncursesw6-config.1.gz /exports/usr/share/man/man1/

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
  GOPATH=/root \
  GO111MODULE=auto
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
RUN \
  npm install -g 'diff-so-fancy@1.3.0'
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/ && \
  mv /usr/local/bin/diff-so-fancy /exports/usr/local/bin/ && \
  mv /usr/local/lib/node_modules/diff-so-fancy /exports/usr/local/lib/node_modules/

# UNZIP
FROM base AS unzip
COPY --from=apteryx /exports/ /
RUN \
  apteryx unzip='6.0-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/share/man/man1/ && \
  mv /usr/bin/unzip /exports/usr/bin/ && \
  mv /usr/share/man/man1/unzip.1.gz /exports/usr/share/man/man1/

# PING
FROM base AS ping
COPY --from=apteryx /exports/ /
RUN \
  apteryx iputils-ping='3:20190709-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man8/ && \
  mv /usr/bin/ping /usr/bin/ping4 /usr/bin/ping6 /exports/usr/bin/ && \
  mv /usr/share/doc/iputils-ping /exports/usr/share/doc/ && \
  mv /usr/share/man/man8/ping.8.gz /usr/share/man/man8/ping4.8.gz /usr/share/man/man8/ping6.8.gz /exports/usr/share/man/man8/

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
  mkdir -p /exports/etc/alternatives/ /exports/etc/ /exports/usr/bin/ /exports/usr/lib/python2.7/ /exports/usr/lib/python2.7/dist-packages/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ /exports/usr/local/lib/ /exports/usr/local/share/ /exports/usr/share/applications/ /exports/usr/share/binfmts/ /exports/usr/share/bug/ /exports/usr/share/doc/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ /exports/usr/share/menu/ /exports/usr/share/pixmaps/ /exports/usr/share/zsh/ && \
  mv /etc/alternatives/python /exports/etc/alternatives/ && \
  mv /etc/python2.7 /etc/shells /etc/zsh /exports/etc/ && \
  mv /usr/bin/2to3-2.7 /usr/bin/lua5.3 /usr/bin/pdb2.7 /usr/bin/pydoc2.7 /usr/bin/pygettext2.7 /usr/bin/python /usr/bin/python2.7 /usr/bin/rzsh /usr/bin/zsh /usr/bin/zsh5 /exports/usr/bin/ && \
  mv /usr/lib/python2.7/__future__.py /usr/lib/python2.7/__future__.pyc /usr/lib/python2.7/__phello__.foo.py /usr/lib/python2.7/__phello__.foo.pyc /usr/lib/python2.7/_abcoll.py /usr/lib/python2.7/_abcoll.pyc /usr/lib/python2.7/_LWPCookieJar.py /usr/lib/python2.7/_LWPCookieJar.pyc /usr/lib/python2.7/_MozillaCookieJar.py /usr/lib/python2.7/_MozillaCookieJar.pyc /usr/lib/python2.7/_osx_support.py /usr/lib/python2.7/_osx_support.pyc /usr/lib/python2.7/_pyio.py /usr/lib/python2.7/_pyio.pyc /usr/lib/python2.7/_strptime.py /usr/lib/python2.7/_strptime.pyc /usr/lib/python2.7/_sysconfigdata.py /usr/lib/python2.7/_sysconfigdata.pyc /usr/lib/python2.7/_threading_local.py /usr/lib/python2.7/_threading_local.pyc /usr/lib/python2.7/_weakrefset.py /usr/lib/python2.7/_weakrefset.pyc /usr/lib/python2.7/abc.py /usr/lib/python2.7/abc.pyc /usr/lib/python2.7/aifc.py /usr/lib/python2.7/aifc.pyc /usr/lib/python2.7/antigravity.py /usr/lib/python2.7/antigravity.pyc /usr/lib/python2.7/anydbm.py /usr/lib/python2.7/anydbm.pyc /usr/lib/python2.7/argparse.egg-info /usr/lib/python2.7/argparse.py /usr/lib/python2.7/argparse.pyc /usr/lib/python2.7/ast.py /usr/lib/python2.7/ast.pyc /usr/lib/python2.7/asynchat.py /usr/lib/python2.7/asynchat.pyc /usr/lib/python2.7/asyncore.py /usr/lib/python2.7/asyncore.pyc /usr/lib/python2.7/atexit.py /usr/lib/python2.7/atexit.pyc /usr/lib/python2.7/audiodev.py /usr/lib/python2.7/audiodev.pyc /usr/lib/python2.7/base64.py /usr/lib/python2.7/base64.pyc /usr/lib/python2.7/BaseHTTPServer.py /usr/lib/python2.7/BaseHTTPServer.pyc /usr/lib/python2.7/Bastion.py /usr/lib/python2.7/Bastion.pyc /usr/lib/python2.7/bdb.py /usr/lib/python2.7/bdb.pyc /usr/lib/python2.7/binhex.py /usr/lib/python2.7/binhex.pyc /usr/lib/python2.7/bisect.py /usr/lib/python2.7/bisect.pyc /usr/lib/python2.7/bsddb /usr/lib/python2.7/calendar.py /usr/lib/python2.7/calendar.pyc /usr/lib/python2.7/cgi.py /usr/lib/python2.7/cgi.pyc /usr/lib/python2.7/CGIHTTPServer.py /usr/lib/python2.7/CGIHTTPServer.pyc /usr/lib/python2.7/cgitb.py /usr/lib/python2.7/cgitb.pyc /usr/lib/python2.7/chunk.py /usr/lib/python2.7/chunk.pyc /usr/lib/python2.7/cmd.py /usr/lib/python2.7/cmd.pyc /usr/lib/python2.7/code.py /usr/lib/python2.7/code.pyc /usr/lib/python2.7/codecs.py /usr/lib/python2.7/codecs.pyc /usr/lib/python2.7/codeop.py /usr/lib/python2.7/codeop.pyc /usr/lib/python2.7/collections.py /usr/lib/python2.7/collections.pyc /usr/lib/python2.7/colorsys.py /usr/lib/python2.7/colorsys.pyc /usr/lib/python2.7/commands.py /usr/lib/python2.7/commands.pyc /usr/lib/python2.7/compileall.py /usr/lib/python2.7/compileall.pyc /usr/lib/python2.7/compiler /usr/lib/python2.7/ConfigParser.py /usr/lib/python2.7/ConfigParser.pyc /usr/lib/python2.7/contextlib.py /usr/lib/python2.7/contextlib.pyc /usr/lib/python2.7/Cookie.py /usr/lib/python2.7/Cookie.pyc /usr/lib/python2.7/cookielib.py /usr/lib/python2.7/cookielib.pyc /usr/lib/python2.7/copy_reg.py /usr/lib/python2.7/copy_reg.pyc /usr/lib/python2.7/copy.py /usr/lib/python2.7/copy.pyc /usr/lib/python2.7/cProfile.py /usr/lib/python2.7/cProfile.pyc /usr/lib/python2.7/csv.py /usr/lib/python2.7/csv.pyc /usr/lib/python2.7/ctypes /usr/lib/python2.7/curses /usr/lib/python2.7/dbhash.py /usr/lib/python2.7/dbhash.pyc /usr/lib/python2.7/decimal.py /usr/lib/python2.7/decimal.pyc /usr/lib/python2.7/difflib.py /usr/lib/python2.7/difflib.pyc /usr/lib/python2.7/dircache.py /usr/lib/python2.7/dircache.pyc /usr/lib/python2.7/dis.py /usr/lib/python2.7/dis.pyc /usr/lib/python2.7/distutils /usr/lib/python2.7/doctest.py /usr/lib/python2.7/doctest.pyc /usr/lib/python2.7/DocXMLRPCServer.py /usr/lib/python2.7/DocXMLRPCServer.pyc /usr/lib/python2.7/dumbdbm.py /usr/lib/python2.7/dumbdbm.pyc /usr/lib/python2.7/dummy_thread.py /usr/lib/python2.7/dummy_thread.pyc /usr/lib/python2.7/dummy_threading.py /usr/lib/python2.7/dummy_threading.pyc /usr/lib/python2.7/email /usr/lib/python2.7/encodings /usr/lib/python2.7/ensurepip /usr/lib/python2.7/filecmp.py /usr/lib/python2.7/filecmp.pyc /usr/lib/python2.7/fileinput.py /usr/lib/python2.7/fileinput.pyc /usr/lib/python2.7/fnmatch.py /usr/lib/python2.7/fnmatch.pyc /usr/lib/python2.7/formatter.py /usr/lib/python2.7/formatter.pyc /usr/lib/python2.7/fpformat.py /usr/lib/python2.7/fpformat.pyc /usr/lib/python2.7/fractions.py /usr/lib/python2.7/fractions.pyc /usr/lib/python2.7/ftplib.py /usr/lib/python2.7/ftplib.pyc /usr/lib/python2.7/functools.py /usr/lib/python2.7/functools.pyc /usr/lib/python2.7/genericpath.py /usr/lib/python2.7/genericpath.pyc /usr/lib/python2.7/getopt.py /usr/lib/python2.7/getopt.pyc /usr/lib/python2.7/getpass.py /usr/lib/python2.7/getpass.pyc /usr/lib/python2.7/gettext.py /usr/lib/python2.7/gettext.pyc /usr/lib/python2.7/glob.py /usr/lib/python2.7/glob.pyc /usr/lib/python2.7/gzip.py /usr/lib/python2.7/gzip.pyc /usr/lib/python2.7/hashlib.py /usr/lib/python2.7/hashlib.pyc /usr/lib/python2.7/heapq.py /usr/lib/python2.7/heapq.pyc /usr/lib/python2.7/hmac.py /usr/lib/python2.7/hmac.pyc /usr/lib/python2.7/hotshot /usr/lib/python2.7/htmlentitydefs.py /usr/lib/python2.7/htmlentitydefs.pyc /usr/lib/python2.7/htmllib.py /usr/lib/python2.7/htmllib.pyc /usr/lib/python2.7/HTMLParser.py /usr/lib/python2.7/HTMLParser.pyc /usr/lib/python2.7/httplib.py /usr/lib/python2.7/httplib.pyc /usr/lib/python2.7/ihooks.py /usr/lib/python2.7/ihooks.pyc /usr/lib/python2.7/imaplib.py /usr/lib/python2.7/imaplib.pyc /usr/lib/python2.7/imghdr.py /usr/lib/python2.7/imghdr.pyc /usr/lib/python2.7/importlib /usr/lib/python2.7/imputil.py /usr/lib/python2.7/imputil.pyc /usr/lib/python2.7/inspect.py /usr/lib/python2.7/inspect.pyc /usr/lib/python2.7/io.py /usr/lib/python2.7/io.pyc /usr/lib/python2.7/json /usr/lib/python2.7/keyword.py /usr/lib/python2.7/keyword.pyc /usr/lib/python2.7/lib-dynload /usr/lib/python2.7/lib-tk /usr/lib/python2.7/lib2to3 /usr/lib/python2.7/LICENSE.txt /usr/lib/python2.7/linecache.py /usr/lib/python2.7/linecache.pyc /usr/lib/python2.7/locale.py /usr/lib/python2.7/locale.pyc /usr/lib/python2.7/logging /usr/lib/python2.7/macpath.py /usr/lib/python2.7/macpath.pyc /usr/lib/python2.7/macurl2path.py /usr/lib/python2.7/macurl2path.pyc /usr/lib/python2.7/mailbox.py /usr/lib/python2.7/mailbox.pyc /usr/lib/python2.7/mailcap.py /usr/lib/python2.7/mailcap.pyc /usr/lib/python2.7/markupbase.py /usr/lib/python2.7/markupbase.pyc /usr/lib/python2.7/md5.py /usr/lib/python2.7/md5.pyc /usr/lib/python2.7/mhlib.py /usr/lib/python2.7/mhlib.pyc /usr/lib/python2.7/mimetools.py /usr/lib/python2.7/mimetools.pyc /usr/lib/python2.7/mimetypes.py /usr/lib/python2.7/mimetypes.pyc /usr/lib/python2.7/MimeWriter.py /usr/lib/python2.7/MimeWriter.pyc /usr/lib/python2.7/mimify.py /usr/lib/python2.7/mimify.pyc /usr/lib/python2.7/modulefinder.py /usr/lib/python2.7/modulefinder.pyc /usr/lib/python2.7/multifile.py /usr/lib/python2.7/multifile.pyc /usr/lib/python2.7/multiprocessing /usr/lib/python2.7/mutex.py /usr/lib/python2.7/mutex.pyc /usr/lib/python2.7/netrc.py /usr/lib/python2.7/netrc.pyc /usr/lib/python2.7/new.py /usr/lib/python2.7/new.pyc /usr/lib/python2.7/nntplib.py /usr/lib/python2.7/nntplib.pyc /usr/lib/python2.7/ntpath.py /usr/lib/python2.7/ntpath.pyc /usr/lib/python2.7/nturl2path.py /usr/lib/python2.7/nturl2path.pyc /usr/lib/python2.7/numbers.py /usr/lib/python2.7/numbers.pyc /usr/lib/python2.7/opcode.py /usr/lib/python2.7/opcode.pyc /usr/lib/python2.7/optparse.py /usr/lib/python2.7/optparse.pyc /usr/lib/python2.7/os.py /usr/lib/python2.7/os.pyc /usr/lib/python2.7/os2emxpath.py /usr/lib/python2.7/os2emxpath.pyc /usr/lib/python2.7/pdb.doc /usr/lib/python2.7/pdb.py /usr/lib/python2.7/pdb.pyc /usr/lib/python2.7/pickle.py /usr/lib/python2.7/pickle.pyc /usr/lib/python2.7/pickletools.py /usr/lib/python2.7/pickletools.pyc /usr/lib/python2.7/pipes.py /usr/lib/python2.7/pipes.pyc /usr/lib/python2.7/pkgutil.py /usr/lib/python2.7/pkgutil.pyc /usr/lib/python2.7/plat-x86_64-linux-gnu /usr/lib/python2.7/platform.py /usr/lib/python2.7/platform.pyc /usr/lib/python2.7/plistlib.py /usr/lib/python2.7/plistlib.pyc /usr/lib/python2.7/popen2.py /usr/lib/python2.7/popen2.pyc /usr/lib/python2.7/poplib.py /usr/lib/python2.7/poplib.pyc /usr/lib/python2.7/posixfile.py /usr/lib/python2.7/posixfile.pyc /usr/lib/python2.7/posixpath.py /usr/lib/python2.7/posixpath.pyc /usr/lib/python2.7/pprint.py /usr/lib/python2.7/pprint.pyc /usr/lib/python2.7/profile.py /usr/lib/python2.7/profile.pyc /usr/lib/python2.7/pstats.py /usr/lib/python2.7/pstats.pyc /usr/lib/python2.7/pty.py /usr/lib/python2.7/pty.pyc /usr/lib/python2.7/py_compile.py /usr/lib/python2.7/py_compile.pyc /usr/lib/python2.7/pyclbr.py /usr/lib/python2.7/pyclbr.pyc /usr/lib/python2.7/pydoc_data /usr/lib/python2.7/pydoc.py /usr/lib/python2.7/pydoc.pyc /usr/lib/python2.7/Queue.py /usr/lib/python2.7/Queue.pyc /usr/lib/python2.7/quopri.py /usr/lib/python2.7/quopri.pyc /usr/lib/python2.7/random.py /usr/lib/python2.7/random.pyc /usr/lib/python2.7/re.py /usr/lib/python2.7/re.pyc /usr/lib/python2.7/repr.py /usr/lib/python2.7/repr.pyc /usr/lib/python2.7/rexec.py /usr/lib/python2.7/rexec.pyc /usr/lib/python2.7/rfc822.py /usr/lib/python2.7/rfc822.pyc /usr/lib/python2.7/rlcompleter.py /usr/lib/python2.7/rlcompleter.pyc /usr/lib/python2.7/robotparser.py /usr/lib/python2.7/robotparser.pyc /usr/lib/python2.7/runpy.py /usr/lib/python2.7/runpy.pyc /usr/lib/python2.7/sched.py /usr/lib/python2.7/sched.pyc /usr/lib/python2.7/sets.py /usr/lib/python2.7/sets.pyc /usr/lib/python2.7/sgmllib.py /usr/lib/python2.7/sgmllib.pyc /usr/lib/python2.7/sha.py /usr/lib/python2.7/sha.pyc /usr/lib/python2.7/shelve.py /usr/lib/python2.7/shelve.pyc /usr/lib/python2.7/shlex.py /usr/lib/python2.7/shlex.pyc /usr/lib/python2.7/shutil.py /usr/lib/python2.7/shutil.pyc /usr/lib/python2.7/SimpleHTTPServer.py /usr/lib/python2.7/SimpleHTTPServer.pyc /usr/lib/python2.7/SimpleXMLRPCServer.py /usr/lib/python2.7/SimpleXMLRPCServer.pyc /usr/lib/python2.7/site.py /usr/lib/python2.7/site.pyc /usr/lib/python2.7/sitecustomize.py /usr/lib/python2.7/sitecustomize.pyc /usr/lib/python2.7/smtpd.py /usr/lib/python2.7/smtpd.pyc /usr/lib/python2.7/smtplib.py /usr/lib/python2.7/smtplib.pyc /usr/lib/python2.7/sndhdr.py /usr/lib/python2.7/sndhdr.pyc /usr/lib/python2.7/socket.py /usr/lib/python2.7/socket.pyc /usr/lib/python2.7/SocketServer.py /usr/lib/python2.7/SocketServer.pyc /usr/lib/python2.7/sqlite3 /usr/lib/python2.7/sre_compile.py /usr/lib/python2.7/sre_compile.pyc /usr/lib/python2.7/sre_constants.py /usr/lib/python2.7/sre_constants.pyc /usr/lib/python2.7/sre_parse.py /usr/lib/python2.7/sre_parse.pyc /usr/lib/python2.7/sre.py /usr/lib/python2.7/sre.pyc /usr/lib/python2.7/ssl.py /usr/lib/python2.7/ssl.pyc /usr/lib/python2.7/stat.py /usr/lib/python2.7/stat.pyc /usr/lib/python2.7/statvfs.py /usr/lib/python2.7/statvfs.pyc /usr/lib/python2.7/string.py /usr/lib/python2.7/string.pyc /usr/lib/python2.7/StringIO.py /usr/lib/python2.7/StringIO.pyc /usr/lib/python2.7/stringold.py /usr/lib/python2.7/stringold.pyc /usr/lib/python2.7/stringprep.py /usr/lib/python2.7/stringprep.pyc /usr/lib/python2.7/struct.py /usr/lib/python2.7/struct.pyc /usr/lib/python2.7/subprocess.py /usr/lib/python2.7/subprocess.pyc /usr/lib/python2.7/sunau.py /usr/lib/python2.7/sunau.pyc /usr/lib/python2.7/sunaudio.py /usr/lib/python2.7/sunaudio.pyc /usr/lib/python2.7/symbol.py /usr/lib/python2.7/symbol.pyc /usr/lib/python2.7/symtable.py /usr/lib/python2.7/symtable.pyc /usr/lib/python2.7/sysconfig.py /usr/lib/python2.7/sysconfig.pyc /usr/lib/python2.7/tabnanny.py /usr/lib/python2.7/tabnanny.pyc /usr/lib/python2.7/tarfile.py /usr/lib/python2.7/tarfile.pyc /usr/lib/python2.7/telnetlib.py /usr/lib/python2.7/telnetlib.pyc /usr/lib/python2.7/tempfile.py /usr/lib/python2.7/tempfile.pyc /usr/lib/python2.7/test /usr/lib/python2.7/textwrap.py /usr/lib/python2.7/textwrap.pyc /usr/lib/python2.7/this.py /usr/lib/python2.7/this.pyc /usr/lib/python2.7/threading.py /usr/lib/python2.7/threading.pyc /usr/lib/python2.7/timeit.py /usr/lib/python2.7/timeit.pyc /usr/lib/python2.7/toaiff.py /usr/lib/python2.7/toaiff.pyc /usr/lib/python2.7/token.py /usr/lib/python2.7/token.pyc /usr/lib/python2.7/tokenize.py /usr/lib/python2.7/tokenize.pyc /usr/lib/python2.7/trace.py /usr/lib/python2.7/trace.pyc /usr/lib/python2.7/traceback.py /usr/lib/python2.7/traceback.pyc /usr/lib/python2.7/tty.py /usr/lib/python2.7/tty.pyc /usr/lib/python2.7/types.py /usr/lib/python2.7/types.pyc /usr/lib/python2.7/unittest /usr/lib/python2.7/urllib.py /usr/lib/python2.7/urllib.pyc /usr/lib/python2.7/urllib2.py /usr/lib/python2.7/urllib2.pyc /usr/lib/python2.7/urlparse.py /usr/lib/python2.7/urlparse.pyc /usr/lib/python2.7/user.py /usr/lib/python2.7/user.pyc /usr/lib/python2.7/UserDict.py /usr/lib/python2.7/UserDict.pyc /usr/lib/python2.7/UserList.py /usr/lib/python2.7/UserList.pyc /usr/lib/python2.7/UserString.py /usr/lib/python2.7/UserString.pyc /usr/lib/python2.7/uu.py /usr/lib/python2.7/uu.pyc /usr/lib/python2.7/uuid.py /usr/lib/python2.7/uuid.pyc /usr/lib/python2.7/warnings.py /usr/lib/python2.7/warnings.pyc /usr/lib/python2.7/wave.py /usr/lib/python2.7/wave.pyc /usr/lib/python2.7/weakref.py /usr/lib/python2.7/weakref.pyc /usr/lib/python2.7/webbrowser.py /usr/lib/python2.7/webbrowser.pyc /usr/lib/python2.7/whichdb.py /usr/lib/python2.7/whichdb.pyc /usr/lib/python2.7/wsgiref.egg-info /usr/lib/python2.7/wsgiref /usr/lib/python2.7/xdrlib.py /usr/lib/python2.7/xdrlib.pyc /usr/lib/python2.7/xml /usr/lib/python2.7/xmllib.py /usr/lib/python2.7/xmllib.pyc /usr/lib/python2.7/xmlrpclib.py /usr/lib/python2.7/xmlrpclib.pyc /usr/lib/python2.7/zipfile.py /usr/lib/python2.7/zipfile.pyc /exports/usr/lib/python2.7/ && \
  mv /usr/lib/python2.7/dist-packages/README /exports/usr/lib/python2.7/dist-packages/ && \
  mv /usr/lib/x86_64-linux-gnu/zsh /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/bin/apteryx /usr/local/bin/z.lua /exports/usr/local/bin/ && \
  mv /usr/local/lib/python2.7 /exports/usr/local/lib/ && \
  mv /usr/local/share/fzf /usr/local/share/zsh /exports/usr/local/share/ && \
  mv /usr/share/applications/python2.7.desktop /exports/usr/share/applications/ && \
  mv /usr/share/binfmts/python2.7 /exports/usr/share/binfmts/ && \
  mv /usr/share/bug/zsh /usr/share/bug/zsh-common /exports/usr/share/bug/ && \
  mv /usr/share/doc/libpython2.7-minimal /usr/share/doc/libpython2.7-stdlib /usr/share/doc/python2.7-minimal /usr/share/doc/python2.7 /usr/share/doc/zsh-common /usr/share/doc/zsh /exports/usr/share/doc/ && \
  mv /usr/share/lintian/overrides/libpython2.7-minimal /usr/share/lintian/overrides/libpython2.7-stdlib /usr/share/lintian/overrides/python2.7 /usr/share/lintian/overrides/python2.7-minimal /usr/share/lintian/overrides/zsh /usr/share/lintian/overrides/zsh-common /exports/usr/share/lintian/overrides/ && \
  mv /usr/share/man/man1/2to3-2.7.1.gz /usr/share/man/man1/lua5.3.1.gz /usr/share/man/man1/pdb2.7.1.gz /usr/share/man/man1/pydoc2.7.1.gz /usr/share/man/man1/pygettext2.7.1.gz /usr/share/man/man1/python2.7.1.gz /usr/share/man/man1/rzsh.1.gz /usr/share/man/man1/zsh.1.gz /usr/share/man/man1/zshall.1.gz /usr/share/man/man1/zshbuiltins.1.gz /usr/share/man/man1/zshcalsys.1.gz /usr/share/man/man1/zshcompctl.1.gz /usr/share/man/man1/zshcompsys.1.gz /usr/share/man/man1/zshcompwid.1.gz /usr/share/man/man1/zshcontrib.1.gz /usr/share/man/man1/zshexpn.1.gz /usr/share/man/man1/zshmisc.1.gz /usr/share/man/man1/zshmodules.1.gz /usr/share/man/man1/zshoptions.1.gz /usr/share/man/man1/zshparam.1.gz /usr/share/man/man1/zshroadmap.1.gz /usr/share/man/man1/zshtcpsys.1.gz /usr/share/man/man1/zshzftpsys.1.gz /usr/share/man/man1/zshzle.1.gz /exports/usr/share/man/man1/ && \
  mv /usr/share/menu/zsh-common /exports/usr/share/menu/ && \
  mv /usr/share/pixmaps/python2.7.xpm /exports/usr/share/pixmaps/ && \
  mv /usr/share/zsh/5.8 /usr/share/zsh/functions /usr/share/zsh/help /exports/usr/share/zsh/

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
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/include/ /exports/usr/local/lib/python3.8/dist-packages/ /exports/usr/local/share/man/ /exports/usr/local/share/ && \
  mv /usr/local/bin/nvim /exports/usr/local/bin/ && \
  mv /usr/local/include/python3.8 /exports/usr/local/include/ && \
  mv /usr/local/lib/python3.8/dist-packages/greenlet-1.1.0.dist-info /usr/local/lib/python3.8/dist-packages/greenlet /usr/local/lib/python3.8/dist-packages/msgpack-1.0.2.dist-info /usr/local/lib/python3.8/dist-packages/msgpack /usr/local/lib/python3.8/dist-packages/neovim-0.3.1.dist-info /usr/local/lib/python3.8/dist-packages/neovim /usr/local/lib/python3.8/dist-packages/pynvim-0.4.3.dist-info /usr/local/lib/python3.8/dist-packages/pynvim /exports/usr/local/lib/python3.8/dist-packages/ && \
  mv /usr/local/share/man/man1 /exports/usr/local/share/man/ && \
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
  mkdir -p /exports/usr/bin/ /exports/usr/include/ /exports/usr/lib/valgrind/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ /exports/usr/local/bin/ /exports/usr/local/share/man/ /exports/usr/share/doc/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ && \
  mv /usr/bin/ncurses5-config /usr/bin/ncurses6-config /usr/bin/ncursesw5-config /usr/bin/ncursesw6-config /exports/usr/bin/ && \
  mv /usr/include/curses.h /usr/include/cursesapp.h /usr/include/cursesf.h /usr/include/cursesm.h /usr/include/cursesp.h /usr/include/cursesw.h /usr/include/cursslk.h /usr/include/eti.h /usr/include/etip.h /usr/include/evdns.h /usr/include/event.h /usr/include/event2 /usr/include/evhttp.h /usr/include/evrpc.h /usr/include/evutil.h /usr/include/form.h /usr/include/menu.h /usr/include/nc_tparm.h /usr/include/ncurses_dll.h /usr/include/ncurses.h /usr/include/ncursesw /usr/include/panel.h /usr/include/term_entry.h /usr/include/term.h /usr/include/termcap.h /usr/include/tic.h /usr/include/unctrl.h /exports/usr/include/ && \
  mv /usr/lib/valgrind/ncurses.supp /exports/usr/lib/valgrind/ && \
  mv /usr/lib/x86_64-linux-gnu/libcurses.a /usr/lib/x86_64-linux-gnu/libcurses.so /usr/lib/x86_64-linux-gnu/libevent_core-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent_core-2.1.so.7.0.0 /usr/lib/x86_64-linux-gnu/libevent_core.a /usr/lib/x86_64-linux-gnu/libevent_core.so /usr/lib/x86_64-linux-gnu/libevent_extra-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent_extra-2.1.so.7.0.0 /usr/lib/x86_64-linux-gnu/libevent_extra.a /usr/lib/x86_64-linux-gnu/libevent_extra.so /usr/lib/x86_64-linux-gnu/libevent_openssl-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent_openssl-2.1.so.7.0.0 /usr/lib/x86_64-linux-gnu/libevent_openssl.a /usr/lib/x86_64-linux-gnu/libevent_openssl.so /usr/lib/x86_64-linux-gnu/libevent_pthreads-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent_pthreads-2.1.so.7.0.0 /usr/lib/x86_64-linux-gnu/libevent_pthreads.a /usr/lib/x86_64-linux-gnu/libevent_pthreads.so /usr/lib/x86_64-linux-gnu/libevent-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent-2.1.so.7.0.0 /usr/lib/x86_64-linux-gnu/libevent.a /usr/lib/x86_64-linux-gnu/libevent.so /usr/lib/x86_64-linux-gnu/libform.a /usr/lib/x86_64-linux-gnu/libform.so /usr/lib/x86_64-linux-gnu/libformw.a /usr/lib/x86_64-linux-gnu/libformw.so /usr/lib/x86_64-linux-gnu/libmenu.a /usr/lib/x86_64-linux-gnu/libmenu.so /usr/lib/x86_64-linux-gnu/libmenuw.a /usr/lib/x86_64-linux-gnu/libmenuw.so /usr/lib/x86_64-linux-gnu/libncurses.a /usr/lib/x86_64-linux-gnu/libncurses.so /usr/lib/x86_64-linux-gnu/libncurses++.a /usr/lib/x86_64-linux-gnu/libncurses++w.a /usr/lib/x86_64-linux-gnu/libncursesw.a /usr/lib/x86_64-linux-gnu/libncursesw.so /usr/lib/x86_64-linux-gnu/libpanel.a /usr/lib/x86_64-linux-gnu/libpanel.so /usr/lib/x86_64-linux-gnu/libpanelw.a /usr/lib/x86_64-linux-gnu/libpanelw.so /usr/lib/x86_64-linux-gnu/libtermcap.a /usr/lib/x86_64-linux-gnu/libtermcap.so /usr/lib/x86_64-linux-gnu/libtic.a /usr/lib/x86_64-linux-gnu/libtic.so /usr/lib/x86_64-linux-gnu/libtinfo.a /usr/lib/x86_64-linux-gnu/libtinfo.so /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/lib/x86_64-linux-gnu/pkgconfig/form.pc /usr/lib/x86_64-linux-gnu/pkgconfig/formw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent_core.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent_extra.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent_openssl.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent_pthreads.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent.pc /usr/lib/x86_64-linux-gnu/pkgconfig/menu.pc /usr/lib/x86_64-linux-gnu/pkgconfig/menuw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncurses.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncurses++.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncurses++w.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncursesw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/panel.pc /usr/lib/x86_64-linux-gnu/pkgconfig/panelw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/tic.pc /usr/lib/x86_64-linux-gnu/pkgconfig/tinfo.pc /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ && \
  mv /usr/local/bin/tmux /exports/usr/local/bin/ && \
  mv /usr/local/share/man/man1 /exports/usr/local/share/man/ && \
  mv /usr/share/doc/libevent-2.1-7 /usr/share/doc/libevent-core-2.1-7 /usr/share/doc/libevent-dev /usr/share/doc/libevent-extra-2.1-7 /usr/share/doc/libevent-openssl-2.1-7 /usr/share/doc/libevent-pthreads-2.1-7 /usr/share/doc/libncurses-dev /usr/share/doc/libncurses5-dev /exports/usr/share/doc/ && \
  mv /usr/share/lintian/overrides/libevent-openssl-2.1-7 /exports/usr/share/lintian/overrides/ && \
  mv /usr/share/man/man1/ncurses5-config.1.gz /usr/share/man/man1/ncurses6-config.1.gz /usr/share/man/man1/ncursesw5-config.1.gz /usr/share/man/man1/ncursesw6-config.1.gz /exports/usr/share/man/man1/

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
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/ /exports/usr/local/share/man/man1/ /exports/usr/share/ /exports/usr/share/perl5/ && \
  mv /usr/bin/git /exports/usr/bin/ && \
  mv /usr/lib/git-core /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.* /usr/lib/x86_64-linux-gnu/libgdbm_compat.so.* /usr/lib/x86_64-linux-gnu/libgdbm.so.* /usr/lib/x86_64-linux-gnu/libperl.so.* /usr/lib/x86_64-linux-gnu/perl /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/bin/diff-so-fancy /usr/local/bin/git-crypt /exports/usr/local/bin/ && \
  mv /usr/local/lib/node_modules/diff-so-fancy /exports/usr/local/lib/node_modules/ && \
  mv /usr/local/share/man/man1/git-crypt.1 /exports/usr/local/share/man/man1/ && \
  mv /usr/share/git-core /usr/share/man /usr/share/perl /exports/usr/share/ && \
  mv /usr/share/perl5/Error.pm /usr/share/perl5/Error /usr/share/perl5/Git.pm /usr/share/perl5/Git /exports/usr/share/perl5/

# XSV
FROM base AS xsv
COPY --from=wget /exports/ /
RUN \
  wget -O /tmp/xsv.tgz https://github.com/BurntSushi/xsv/releases/download/0.13.0/xsv-0.13.0-i686-unknown-linux-musl.tar.gz && \
  tar xzvf /tmp/xsv.tgz -C /tmp && \
  mv /tmp/xsv /usr/local/bin && \
  rm -r /tmp/xsv*
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/xsv /exports/usr/local/bin/

# TREE
FROM base AS tree
COPY --from=apteryx /exports/ /
RUN \
  apteryx tree='1.8.0-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man1/ && \
  mv /usr/bin/tree /exports/usr/bin/ && \
  mv /usr/share/doc/tree /exports/usr/share/doc/ && \
  mv /usr/share/man/man1/tree.1.gz /exports/usr/share/man/man1/

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
  apteryx sudo='1.8.31-*'
RUN \
  mkdir -p /exports/etc/ /exports/usr/bin/ /exports/usr/lib/ /exports/var/lib/ /exports/usr/share/doc/ /exports/usr/share/man/man5/ /exports/usr/share/man/man8/ && \
  mv /etc/sudoers /exports/etc/ && \
  mv /usr/bin/sudo /exports/usr/bin/ && \
  mv /usr/lib/sudo /exports/usr/lib/ && \
  mv /var/lib/sudo /exports/var/lib/ && \
  mv /usr/share/doc/sudo /exports/usr/share/doc/ && \
  mv /usr/share/man/man5/sudo.conf.5.gz /usr/share/man/man5/sudoers.5.gz /exports/usr/share/man/man5/ && \
  mv /usr/share/man/man8/sudo.8.gz /usr/share/man/man8/sudo_plugin.8.gz /usr/share/man/man8/sudo_root.8.gz /usr/share/man/man8/sudoedit.8.gz /usr/share/man/man8/sudoreplay.8.gz /usr/share/man/man8/visudo.8.gz /exports/usr/share/man/man8/

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

# RIPGREP
FROM base AS ripgrep
COPY --from=wget /exports/ /
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
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/share/man/man1/ && \
  mv /usr/local/bin/rg /exports/usr/local/bin/ && \
  mv /usr/local/share/man/man1/rg.1 /exports/usr/local/share/man/man1/

# PRETTYPING
FROM base AS prettyping
COPY --from=wget /exports/ /
COPY --from=ping /exports/ /
RUN \
  wget -O /usr/local/bin/prettyping 'https://raw.githubusercontent.com/denilsonsa/prettyping/v1.0.1/prettyping' && \
  chmod +x /usr/local/bin/prettyping
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/local/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man8/ && \
  mv /usr/bin/ping /usr/bin/ping4 /usr/bin/ping6 /exports/usr/bin/ && \
  mv /usr/local/bin/prettyping /exports/usr/local/bin/ && \
  mv /usr/share/doc/iputils-ping /exports/usr/share/doc/ && \
  mv /usr/share/man/man8/ping.8.gz /usr/share/man/man8/ping4.8.gz /usr/share/man/man8/ping6.8.gz /exports/usr/share/man/man8/

# MOREUTILS
FROM base AS moreutils
COPY --from=apteryx /exports/ /
RUN \
  apteryx moreutils='0.63-*'
RUN \
  mkdir -p /exports/usr/share/ /exports/usr/share/perl5/ /exports/usr/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man1/ && \
  mv /usr/share/perl /exports/usr/share/ && \
  mv /usr/share/perl5/IPC /exports/usr/share/perl5/ && \
  mv /usr/bin/chronic /usr/bin/combine /usr/bin/errno /usr/bin/ifdata /usr/bin/ifne /usr/bin/isutf8 /usr/bin/lckdo /usr/bin/mispipe /usr/bin/parallel /usr/bin/pee /usr/bin/sponge /usr/bin/ts /usr/bin/vidir /usr/bin/vipe /usr/bin/zrun /exports/usr/bin/ && \
  mv /usr/share/doc/moreutils /exports/usr/share/doc/ && \
  mv /usr/share/man/man1/chronic.1.gz /usr/share/man/man1/combine.1.gz /usr/share/man/man1/errno.1.gz /usr/share/man/man1/ifdata.1.gz /usr/share/man/man1/ifne.1.gz /usr/share/man/man1/isutf8.1.gz /usr/share/man/man1/lckdo.1.gz /usr/share/man/man1/mispipe.1.gz /usr/share/man/man1/parallel.1.gz /usr/share/man/man1/pee.1.gz /usr/share/man/man1/sponge.1.gz /usr/share/man/man1/ts.1.gz /usr/share/man/man1/vidir.1.gz /usr/share/man/man1/vipe.1.gz /usr/share/man/man1/zrun.1.gz /exports/usr/share/man/man1/

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
  apteryx htop='2.2.0-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man1/ && \
  mv /usr/bin/htop /exports/usr/bin/ && \
  mv /usr/share/doc/htop /exports/usr/share/doc/ && \
  mv /usr/share/man/man1/htop.1.gz /exports/usr/share/man/man1/

# GH
FROM base AS gh
COPY --from=wget /exports/ /
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
  apteryx file='1:5.38-*'
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
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/share/man/man1/ && \
  mv /usr/local/bin/fd /exports/usr/local/bin/ && \
  mv /usr/local/share/man/man1/fd.1 /exports/usr/local/share/man/man1/

# DOCKER
FROM base AS docker
COPY --from=apteryx /exports/ /
COPY --from=wget /exports/ /
RUN \
  wget -O /tmp/docker.gpg https://download.docker.com/linux/ubuntu/gpg && \
  apt-key add /tmp/docker.gpg && \
  apt-add-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable' && \
  apteryx docker-ce='5:20.10.6*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/share/zsh/vendor-completions/ && \
  mv /usr/bin/docker /exports/usr/bin/ && \
  mv /usr/share/zsh/vendor-completions/_docker /exports/usr/share/zsh/vendor-completions/

# BAT
FROM base AS bat
COPY --from=wget /exports/ /
RUN \
  wget -O bat.tgz 'https://github.com/sharkdp/bat/releases/download/v0.16.0/bat-v0.16.0-x86_64-unknown-linux-gnu.tar.gz' && \
  tar -xzvf bat.tgz && \
  rm bat.tgz && \
  mv 'bat-v0.16.0-x86_64-unknown-linux-gnu/bat' /usr/local/bin/bat && \
  rm -rf 'bat-v0.16.0-x86_64-unknown-linux-gnu'
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/bat /exports/usr/local/bin/

# MY-CHROMEBOOK
FROM shell-admin AS my-chromebook
COPY --from=python3-pip /exports/ /
COPY --from=bat /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=clone /exports/ /
COPY --from=docker /exports/ /
COPY --from=fd /exports/ /
COPY --from=file /exports/ /
COPY --from=fzf /exports/ /
COPY --from=gh /exports/ /
COPY --from=htop /exports/ /
COPY --from=httpie /exports/ /
COPY --from=jq /exports/ /
COPY --from=make /exports/ /
COPY --from=moreutils /exports/ /
COPY --from=prettyping /exports/ /
COPY --from=ripgrep /exports/ /
COPY --from=safe-rm /exports/ /
COPY --from=sd /exports/ /
COPY --from=sudo /exports/ /
COPY --from=tig /exports/ /
COPY --from=tree /exports/ /
COPY --from=unzip /exports/ /
COPY --from=wget /exports/ /
COPY --from=xsv /exports/ /
COPY --from=shell-git --chown=admin /home/admin/exports/ /
COPY --from=shell-git /exports/ /
COPY --from=shell-passwords --chown=admin /home/admin/exports/ /
COPY --from=shell-passwords /exports/ /
COPY --from=shell-ranger --chown=admin /home/admin/exports/ /
COPY --from=shell-ranger /exports/ /
COPY --from=shell-ssh --chown=admin /home/admin/exports/ /
COPY --from=shell-tmux --chown=admin /home/admin/exports/ /
COPY --from=shell-tmux /exports/ /
COPY --from=shell-vim --chown=admin /home/admin/exports/ /
COPY --from=shell-vim /exports/ /
COPY --from=shell-zsh --chown=admin /home/admin/exports/ /
COPY --from=shell-zsh /exports/ /
RUN \
  chmod 0600 /home/admin/.ssh/*
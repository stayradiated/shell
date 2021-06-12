

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
  mkdir -p /exports/etc/ /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/share/ /exports/usr/share/bug/ /exports/usr/share/doc/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ /exports/usr/share/menu/ /exports/usr/share/zsh/ && \
  mv /etc/shells /etc/zsh /exports/etc/ && \
  mv /usr/bin/rzsh /usr/bin/zsh /usr/bin/zsh5 /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu/zsh /exports/usr/lib/x86_64-linux-gnu/ && \
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
  clone --https --shallow --tag 'v1.65.1' https://github.com/stayradiated/dotfiles && \
  cd /root/src/github.com/stayradiated/dotfiles && \
  git-crypt unlock /tmp/dotfiles-key && \
  rm /tmp/dotfiles-key && \
  mv /root/src/github.com/stayradiated/dotfiles /root/dotfiles && \
  rm -rf src
RUN \
  mkdir -p /exports/root/ && \
  mv /root/dotfiles /exports/root/

# N
FROM base AS n
RUN \
  curl -L https://raw.githubusercontent.com/tj/n/v7.2.2/bin/n -o /usr/local/bin/n && \
  chmod +x /usr/local/bin/n
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/n /exports/usr/local/bin/

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

# LUA
FROM base AS lua
COPY --from=apteryx /exports/ /
RUN \
  apteryx lua5.3='5.3.3-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/share/man/man1/ && \
  mv /usr/bin/lua5.3 /exports/usr/bin/ && \
  mv /usr/share/man/man1/lua5.3.1.gz /exports/usr/share/man/man1/

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

# XZ
FROM base AS xz
COPY --from=apteryx /exports/ /
RUN \
  apteryx xz-utils='5.2.4-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/share/man/man1/ && \
  mv /usr/bin/xz /exports/usr/bin/ && \
  mv /usr/share/man/man1/xz.1.gz /exports/usr/share/man/man1/

# SOCKSIFY
FROM base AS socksify
COPY --from=build-essential /exports/ /
COPY --from=wget /exports/ /
RUN \
  wget "https://www.inet.no/dante/files/dante-1.4.2.tar.gz" && \
  tar xzvf "dante-1.4.2.tar.gz" && \
  cd "dante-1.4.2" && \
  ./configure && \
  make && \
  make check && \
  make install && \
  cd .. && \
  rm -rf "dante-1.4.2.tar.gz" "dante-1.4.2"
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/include/ /exports/usr/local/lib/ /exports/usr/local/sbin/ /exports/usr/local/share/man/man1/ /exports/usr/local/share/man/man5/ /exports/usr/local/share/man/man8/ && \
  mv /usr/local/bin/socksify /exports/usr/local/bin/ && \
  mv /usr/local/include/socks.h /exports/usr/local/include/ && \
  mv /usr/local/lib/libdsocks.la /usr/local/lib/libdsocks.so /usr/local/lib/libsocks.a /usr/local/lib/libsocks.la /usr/local/lib/libsocks.so /usr/local/lib/libsocks.so.0 /usr/local/lib/libsocks.so.0.1.1 /exports/usr/local/lib/ && \
  mv /usr/local/sbin/sockd /exports/usr/local/sbin/ && \
  mv /usr/local/share/man/man1/socksify.1 /exports/usr/local/share/man/man1/ && \
  mv /usr/local/share/man/man5/sockd.conf.5 /usr/local/share/man/man5/socks.conf.5 /exports/usr/local/share/man/man5/ && \
  mv /usr/local/share/man/man8/sockd.8 /exports/usr/local/share/man/man8/

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
  apteryx firefox='89.0+*'
RUN \
  mkdir -p /exports/etc/alternatives/ /exports/etc/ /exports/etc/init.d/ /exports/etc/rcS.d/ /exports/etc/X11/ /exports/etc/X11/Xsession.d/ /exports/usr/bin/ /exports/usr/include/ /exports/usr/lib/ /exports/usr/lib/python3/dist-packages/__pycache__/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/share/ /exports/usr/sbin/ /exports/usr/share/applications/ /exports/usr/share/apport/package-hooks/ /exports/usr/share/bug/ /exports/usr/share/doc-base/ /exports/usr/share/doc/ /exports/usr/share/ /exports/usr/share/glib-2.0/schemas/ /exports/usr/share/icons/ /exports/usr/share/icons/hicolor/ /exports/usr/share/icons/hicolor/48x48/ /exports/usr/share/icons/hicolor/48x48/apps/ /exports/usr/share/icons/hicolor/scalable/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ /exports/usr/share/man/man5/ /exports/usr/share/man/man7/ /exports/usr/share/man/man8/ /exports/usr/share/pkgconfig/ /exports/usr/share/xml/ && \
  mv /etc/alternatives/gnome-www-browser /etc/alternatives/x-cursor-theme /etc/alternatives/x-www-browser /exports/etc/alternatives/ && \
  mv /etc/apparmor.d /etc/apport /etc/firefox /etc/gtk-3.0 /etc/ld.so.cache /etc/mailcap /exports/etc/ && \
  mv /etc/init.d/x11-common /exports/etc/init.d/ && \
  mv /etc/rcS.d/S01x11-common /exports/etc/rcS.d/ && \
  mv /etc/X11/rgb.txt /etc/X11/xkb /etc/X11/Xreset /etc/X11/Xreset.d /etc/X11/Xresources /etc/X11/Xsession /etc/X11/Xsession.options /exports/etc/X11/ && \
  mv /etc/X11/Xsession.d/20x11-common_process-args /etc/X11/Xsession.d/30x11-common_xresources /etc/X11/Xsession.d/35x11-common_xhost-local /etc/X11/Xsession.d/40x11-common_xsessionrc /etc/X11/Xsession.d/50x11-common_determine-startup /etc/X11/Xsession.d/60x11-common_localhost /etc/X11/Xsession.d/60x11-common_xdg_path /etc/X11/Xsession.d/90x11-common_ssh-agent /etc/X11/Xsession.d/99x11-common_start /exports/etc/X11/Xsession.d/ && \
  mv /usr/bin/fc-cache /usr/bin/fc-cat /usr/bin/fc-conflist /usr/bin/fc-list /usr/bin/fc-match /usr/bin/fc-pattern /usr/bin/fc-query /usr/bin/fc-scan /usr/bin/fc-validate /usr/bin/firefox /usr/bin/gnome-www-browser /usr/bin/gtk-update-icon-cache /usr/bin/update-mime-database /usr/bin/x-www-browser /usr/bin/X11 /exports/usr/bin/ && \
  mv /usr/include/X11 /exports/usr/include/ && \
  mv /usr/lib/firefox-addons /usr/lib/firefox /usr/lib/X11 /exports/usr/lib/ && \
  mv /usr/lib/python3/dist-packages/__pycache__/lsb_release.cpython-38.pyc /exports/usr/lib/python3/dist-packages/__pycache__/ && \
  mv /usr/lib/x86_64-linux-gnu/avahi /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0 /usr/lib/x86_64-linux-gnu/gtk-3.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0.23510.1 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0.0.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0.0.1 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3.2.9 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3.5.3 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcairo.so.2 /usr/lib/x86_64-linux-gnu/libcairo.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcolord.so.2 /usr/lib/x86_64-linux-gnu/libcolord.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcups.so.2 /usr/lib/x86_64-linux-gnu/libdatrie.so.1 /usr/lib/x86_64-linux-gnu/libdatrie.so.1.3.5 /usr/lib/x86_64-linux-gnu/libdbus-glib-1.so.2 /usr/lib/x86_64-linux-gnu/libdbus-glib-1.so.2.3.4 /usr/lib/x86_64-linux-gnu/libepoxy.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0.0.0 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.0 /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.17.1 /usr/lib/x86_64-linux-gnu/libfribidi.so.0 /usr/lib/x86_64-linux-gnu/libfribidi.so.0.4.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf_xlib-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf_xlib-2.0.so.0.4000.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0.4000.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0.2404.16 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgtk-3-0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0.2404.16 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.20600.4 /usr/lib/x86_64-linux-gnu/libICE.so.6 /usr/lib/x86_64-linux-gnu/libICE.so.6.3.0 /usr/lib/x86_64-linux-gnu/libjbig.so.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/libjson-glib-1.0.so.0 /usr/lib/x86_64-linux-gnu/libjson-glib-1.0.so.0.400.4 /usr/lib/x86_64-linux-gnu/liblcms2.so.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2.0.8 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0.4400.7 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0.4400.7 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0.4400.7 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0.38.4 /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.37.0 /usr/lib/x86_64-linux-gnu/librest-0.7.so.0 /usr/lib/x86_64-linux-gnu/librest-0.7.so.0.0.0 /usr/lib/x86_64-linux-gnu/librsvg-2.so.2 /usr/lib/x86_64-linux-gnu/librsvg-2.so.2.47.0 /usr/lib/x86_64-linux-gnu/libSM.so.6 /usr/lib/x86_64-linux-gnu/libSM.so.6.0.1 /usr/lib/x86_64-linux-gnu/libsoup-gnome-2.4.so.1 /usr/lib/x86_64-linux-gnu/libsoup-gnome-2.4.so.1.9.0 /usr/lib/x86_64-linux-gnu/libthai.so.0 /usr/lib/x86_64-linux-gnu/libthai.so.0.3.1 /usr/lib/x86_64-linux-gnu/libtiff.so.5 /usr/lib/x86_64-linux-gnu/libtiff.so.5.5.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.3.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0.0.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.0.0 /usr/lib/x86_64-linux-gnu/libwebp.so.6 /usr/lib/x86_64-linux-gnu/libwebp.so.6.0.2 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1.0.0 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.3.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXcursor.so.1 /usr/lib/x86_64-linux-gnu/libXcursor.so.1.0.2 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libXi.so.6 /usr/lib/x86_64-linux-gnu/libXi.so.6.1.0 /usr/lib/x86_64-linux-gnu/libXinerama.so.1 /usr/lib/x86_64-linux-gnu/libXinerama.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrandr.so.2 /usr/lib/x86_64-linux-gnu/libXrandr.so.2.2.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /usr/lib/x86_64-linux-gnu/libXt.so.6 /usr/lib/x86_64-linux-gnu/libXt.so.6.0.0 /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/share/fonts /exports/usr/local/share/ && \
  mv /usr/sbin/update-icon-caches /exports/usr/sbin/ && \
  mv /usr/share/applications/firefox.desktop /exports/usr/share/applications/ && \
  mv /usr/share/apport/package-hooks/source_firefox.py /usr/share/apport/package-hooks/source_fontconfig.py /exports/usr/share/apport/package-hooks/ && \
  mv /usr/share/bug/libgtk-3-0 /exports/usr/share/bug/ && \
  mv /usr/share/doc-base/fontconfig-user /usr/share/doc-base/libpng16 /usr/share/doc-base/shared-mime-info /exports/usr/share/doc-base/ && \
  mv /usr/share/doc/adwaita-icon-theme /usr/share/doc/firefox /usr/share/doc/fontconfig-config /usr/share/doc/fontconfig /usr/share/doc/fonts-dejavu-core /usr/share/doc/gtk-update-icon-cache /usr/share/doc/hicolor-icon-theme /usr/share/doc/humanity-icon-theme /usr/share/doc/libatk-bridge2.0-0 /usr/share/doc/libatk1.0-0 /usr/share/doc/libatk1.0-data /usr/share/doc/libatspi2.0-0 /usr/share/doc/libavahi-client3 /usr/share/doc/libavahi-common-data /usr/share/doc/libavahi-common3 /usr/share/doc/libcairo-gobject2 /usr/share/doc/libcairo2 /usr/share/doc/libcolord2 /usr/share/doc/libcups2 /usr/share/doc/libdatrie1 /usr/share/doc/libdbus-glib-1-2 /usr/share/doc/libepoxy0 /usr/share/doc/libfontconfig1 /usr/share/doc/libfreetype6 /usr/share/doc/libfribidi0 /usr/share/doc/libgdk-pixbuf2.0-0 /usr/share/doc/libgdk-pixbuf2.0-common /usr/share/doc/libgraphite2-3 /usr/share/doc/libgtk-3-0 /usr/share/doc/libgtk-3-common /usr/share/doc/libharfbuzz0b /usr/share/doc/libice6 /usr/share/doc/libjbig0 /usr/share/doc/libjpeg-turbo8 /usr/share/doc/libjpeg8 /usr/share/doc/libjson-glib-1.0-0 /usr/share/doc/libjson-glib-1.0-common /usr/share/doc/liblcms2-2 /usr/share/doc/libpango-1.0-0 /usr/share/doc/libpangocairo-1.0-0 /usr/share/doc/libpangoft2-1.0-0 /usr/share/doc/libpixman-1-0 /usr/share/doc/libpng16-16 /usr/share/doc/librest-0.7-0 /usr/share/doc/librsvg2-2 /usr/share/doc/librsvg2-common /usr/share/doc/libsm6 /usr/share/doc/libsoup-gnome2.4-1 /usr/share/doc/libthai-data /usr/share/doc/libthai0 /usr/share/doc/libtiff5 /usr/share/doc/libwayland-client0 /usr/share/doc/libwayland-cursor0 /usr/share/doc/libwayland-egl1 /usr/share/doc/libwebp6 /usr/share/doc/libx11-6 /usr/share/doc/libx11-data /usr/share/doc/libx11-xcb1 /usr/share/doc/libxau6 /usr/share/doc/libxcb-render0 /usr/share/doc/libxcb-shm0 /usr/share/doc/libxcb1 /usr/share/doc/libxcomposite1 /usr/share/doc/libxcursor1 /usr/share/doc/libxdamage1 /usr/share/doc/libxdmcp6 /usr/share/doc/libxext6 /usr/share/doc/libxfixes3 /usr/share/doc/libxi6 /usr/share/doc/libxinerama1 /usr/share/doc/libxkbcommon0 /usr/share/doc/libxrandr2 /usr/share/doc/libxrender1 /usr/share/doc/libxt6 /usr/share/doc/shared-mime-info /usr/share/doc/ubuntu-mono /usr/share/doc/x11-common /usr/share/doc/xkb-data /exports/usr/share/doc/ && \
  mv /usr/share/fonts /usr/share/libthai /usr/share/mime /usr/share/themes /usr/share/thumbnailers /usr/share/X11 /exports/usr/share/ && \
  mv /usr/share/glib-2.0/schemas/gschemas.compiled /usr/share/glib-2.0/schemas/org.gtk.Settings.ColorChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.EmojiChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.FileChooser.gschema.xml /exports/usr/share/glib-2.0/schemas/ && \
  mv /usr/share/icons/Adwaita /usr/share/icons/default /usr/share/icons/Humanity-Dark /usr/share/icons/Humanity /usr/share/icons/LoginIcons /usr/share/icons/ubuntu-mono-dark /usr/share/icons/ubuntu-mono-light /exports/usr/share/icons/ && \
  mv /usr/share/icons/hicolor/128x128 /usr/share/icons/hicolor/16x16 /usr/share/icons/hicolor/192x192 /usr/share/icons/hicolor/22x22 /usr/share/icons/hicolor/24x24 /usr/share/icons/hicolor/256x256 /usr/share/icons/hicolor/32x32 /usr/share/icons/hicolor/36x36 /usr/share/icons/hicolor/512x512 /usr/share/icons/hicolor/64x64 /usr/share/icons/hicolor/72x72 /usr/share/icons/hicolor/96x96 /usr/share/icons/hicolor/icon-theme.cache /usr/share/icons/hicolor/index.theme /usr/share/icons/hicolor/symbolic /exports/usr/share/icons/hicolor/ && \
  mv /usr/share/icons/hicolor/48x48/actions /usr/share/icons/hicolor/48x48/animations /usr/share/icons/hicolor/48x48/categories /usr/share/icons/hicolor/48x48/devices /usr/share/icons/hicolor/48x48/emblems /usr/share/icons/hicolor/48x48/emotes /usr/share/icons/hicolor/48x48/filesystems /usr/share/icons/hicolor/48x48/intl /usr/share/icons/hicolor/48x48/mimetypes /usr/share/icons/hicolor/48x48/places /usr/share/icons/hicolor/48x48/status /usr/share/icons/hicolor/48x48/stock /exports/usr/share/icons/hicolor/48x48/ && \
  mv /usr/share/icons/hicolor/48x48/apps/firefox.png /exports/usr/share/icons/hicolor/48x48/apps/ && \
  mv /usr/share/icons/hicolor/scalable/actions /usr/share/icons/hicolor/scalable/animations /usr/share/icons/hicolor/scalable/categories /usr/share/icons/hicolor/scalable/devices /usr/share/icons/hicolor/scalable/emblems /usr/share/icons/hicolor/scalable/emotes /usr/share/icons/hicolor/scalable/filesystems /usr/share/icons/hicolor/scalable/intl /usr/share/icons/hicolor/scalable/mimetypes /usr/share/icons/hicolor/scalable/places /usr/share/icons/hicolor/scalable/status /usr/share/icons/hicolor/scalable/stock /exports/usr/share/icons/hicolor/scalable/ && \
  mv /usr/share/lintian/overrides/firefox /usr/share/lintian/overrides/fontconfig /usr/share/lintian/overrides/hicolor-icon-theme /usr/share/lintian/overrides/libdbus-glib-1-2 /usr/share/lintian/overrides/libgdk-pixbuf2.0-0 /usr/share/lintian/overrides/libjpeg-turbo8 /usr/share/lintian/overrides/libpixman-1-0 /usr/share/lintian/overrides/librsvg2-2 /usr/share/lintian/overrides/librsvg2-common /usr/share/lintian/overrides/libsoup-gnome2.4-1 /usr/share/lintian/overrides/libtiff5 /usr/share/lintian/overrides/libx11-6 /usr/share/lintian/overrides/x11-common /exports/usr/share/lintian/overrides/ && \
  mv /usr/share/man/man1/fc-cache.1.gz /usr/share/man/man1/fc-cat.1.gz /usr/share/man/man1/fc-conflist.1.gz /usr/share/man/man1/fc-list.1.gz /usr/share/man/man1/fc-match.1.gz /usr/share/man/man1/fc-pattern.1.gz /usr/share/man/man1/fc-query.1.gz /usr/share/man/man1/fc-scan.1.gz /usr/share/man/man1/fc-validate.1.gz /usr/share/man/man1/firefox.1.gz /usr/share/man/man1/gtk-update-icon-cache.1.gz /usr/share/man/man1/update-mime-database.1.gz /exports/usr/share/man/man1/ && \
  mv /usr/share/man/man5/Compose.5.gz /usr/share/man/man5/fonts-conf.5.gz /usr/share/man/man5/XCompose.5.gz /usr/share/man/man5/Xsession.5.gz /usr/share/man/man5/Xsession.options.5.gz /exports/usr/share/man/man5/ && \
  mv /usr/share/man/man7/xkeyboard-config.7.gz /exports/usr/share/man/man7/ && \
  mv /usr/share/man/man8/update-icon-caches.8.gz /exports/usr/share/man/man8/ && \
  mv /usr/share/pkgconfig/adwaita-icon-theme.pc /usr/share/pkgconfig/shared-mime-info.pc /usr/share/pkgconfig/xkeyboard-config.pc /exports/usr/share/pkgconfig/ && \
  mv /usr/share/xml/fontconfig /exports/usr/share/xml/

# GOOGLE-CHROME
FROM base AS google-chrome
COPY --from=wget /exports/ /
COPY --from=apteryx /exports/ /
RUN \
  curl -s https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
  sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' && \
  apt-get update && \
  apteryx google-chrome-stable='91.0.4472.77-*'
RUN \
  mkdir -p /exports/etc/alternatives/ /exports/etc/cron.daily/ /exports/etc/default/ /exports/etc/ /exports/etc/X11/ /exports/opt/ /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/share/ /exports/usr/sbin/ /exports/usr/share/ /exports/usr/share/applications/ /exports/usr/share/doc/ /exports/usr/share/man/man1/ /exports/usr/share/menu/ && \
  mv /etc/alternatives/gnome-www-browser /etc/alternatives/google-chrome /etc/alternatives/x-cursor-theme /etc/alternatives/x-www-browser /exports/etc/alternatives/ && \
  mv /etc/cron.daily/google-chrome /exports/etc/cron.daily/ && \
  mv /etc/default/google-chrome /exports/etc/default/ && \
  mv /etc/gtk-3.0 /etc/ld.so.cache /etc/mailcap /exports/etc/ && \
  mv /etc/X11/xkb /exports/etc/X11/ && \
  mv /opt/google /exports/opt/ && \
  mv /usr/bin/browse /usr/bin/fc-cache /usr/bin/fc-cat /usr/bin/fc-conflist /usr/bin/fc-list /usr/bin/fc-match /usr/bin/fc-pattern /usr/bin/fc-query /usr/bin/fc-scan /usr/bin/fc-validate /usr/bin/gnome-www-browser /usr/bin/google-chrome /usr/bin/google-chrome-stable /usr/bin/gtk-update-icon-cache /usr/bin/update-mime-database /usr/bin/x-www-browser /usr/bin/xdg-desktop-icon /usr/bin/xdg-desktop-menu /usr/bin/xdg-email /usr/bin/xdg-icon-resource /usr/bin/xdg-mime /usr/bin/xdg-open /usr/bin/xdg-screensaver /usr/bin/xdg-settings /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu/avahi /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0 /usr/lib/x86_64-linux-gnu/gtk-3.0 /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libasound.so.2.0.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0.23510.1 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0.0.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0.0.1 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3.2.9 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3.5.3 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcairo.so.2 /usr/lib/x86_64-linux-gnu/libcairo.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcolord.so.2 /usr/lib/x86_64-linux-gnu/libcolord.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcups.so.2 /usr/lib/x86_64-linux-gnu/libdatrie.so.1 /usr/lib/x86_64-linux-gnu/libdatrie.so.1.3.5 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0.0.0 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.0 /usr/lib/x86_64-linux-gnu/libfreebl3.chk /usr/lib/x86_64-linux-gnu/libfreebl3.so /usr/lib/x86_64-linux-gnu/libfreeblpriv3.chk /usr/lib/x86_64-linux-gnu/libfreeblpriv3.so /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.17.1 /usr/lib/x86_64-linux-gnu/libfribidi.so.0 /usr/lib/x86_64-linux-gnu/libfribidi.so.0.4.0 /usr/lib/x86_64-linux-gnu/libgbm.so.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf_xlib-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf_xlib-2.0.so.0.4000.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0.4000.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0.2404.16 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgtk-3-0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0.2404.16 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.20600.4 /usr/lib/x86_64-linux-gnu/libjbig.so.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/libjson-glib-1.0.so.0 /usr/lib/x86_64-linux-gnu/libjson-glib-1.0.so.0.400.4 /usr/lib/x86_64-linux-gnu/liblcms2.so.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2.0.8 /usr/lib/x86_64-linux-gnu/libnspr4.so /usr/lib/x86_64-linux-gnu/libnss3.so /usr/lib/x86_64-linux-gnu/libnssutil3.so /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0.4400.7 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0.4400.7 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0.4400.7 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0.38.4 /usr/lib/x86_64-linux-gnu/libplc4.so /usr/lib/x86_64-linux-gnu/libplds4.so /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.37.0 /usr/lib/x86_64-linux-gnu/librest-0.7.so.0 /usr/lib/x86_64-linux-gnu/librest-0.7.so.0.0.0 /usr/lib/x86_64-linux-gnu/librsvg-2.so.2 /usr/lib/x86_64-linux-gnu/librsvg-2.so.2.47.0 /usr/lib/x86_64-linux-gnu/libsmime3.so /usr/lib/x86_64-linux-gnu/libsoup-gnome-2.4.so.1 /usr/lib/x86_64-linux-gnu/libsoup-gnome-2.4.so.1.9.0 /usr/lib/x86_64-linux-gnu/libssl3.so /usr/lib/x86_64-linux-gnu/libthai.so.0 /usr/lib/x86_64-linux-gnu/libthai.so.0.3.1 /usr/lib/x86_64-linux-gnu/libtiff.so.5 /usr/lib/x86_64-linux-gnu/libtiff.so.5.5.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.3.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0.0.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.0.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0.1.0 /usr/lib/x86_64-linux-gnu/libwebp.so.6 /usr/lib/x86_64-linux-gnu/libwebp.so.6.0.2 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.3.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXcursor.so.1 /usr/lib/x86_64-linux-gnu/libXcursor.so.1.0.2 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libXi.so.6 /usr/lib/x86_64-linux-gnu/libXi.so.6.1.0 /usr/lib/x86_64-linux-gnu/libXinerama.so.1 /usr/lib/x86_64-linux-gnu/libXinerama.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrandr.so.2 /usr/lib/x86_64-linux-gnu/libXrandr.so.2.2.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1.0.0 /usr/lib/x86_64-linux-gnu/nss /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/share/fonts /exports/usr/local/share/ && \
  mv /usr/sbin/update-icon-caches /exports/usr/sbin/ && \
  mv /usr/share/alsa /usr/share/appdata /exports/usr/share/ && \
  mv /usr/share/applications/google-chrome.desktop /exports/usr/share/applications/ && \
  mv /usr/share/doc/google-chrome-stable /exports/usr/share/doc/ && \
  mv /usr/share/man/man1/google-chrome-stable.1.gz /usr/share/man/man1/google-chrome.1.gz /exports/usr/share/man/man1/ && \
  mv /usr/share/menu/google-chrome.menu /exports/usr/share/menu/

# XDG-UTILS
FROM base AS xdg-utils
COPY --from=apteryx /exports/ /
RUN \
  apteryx xdg-utils='1.1.3-*'
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
  mkdir -p /exports/etc/alternatives/ /exports/etc/ /exports/usr/bin/ /exports/usr/lib/python2.7/ /exports/usr/lib/python2.7/dist-packages/ /exports/usr/local/lib/ /exports/usr/share/applications/ /exports/usr/share/binfmts/ /exports/usr/share/doc/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ /exports/usr/share/pixmaps/ && \
  mv /etc/alternatives/python /exports/etc/alternatives/ && \
  mv /etc/python2.7 /exports/etc/ && \
  mv /usr/bin/2to3-2.7 /usr/bin/pdb2.7 /usr/bin/pydoc2.7 /usr/bin/pygettext2.7 /usr/bin/python /usr/bin/python2.7 /exports/usr/bin/ && \
  mv /usr/lib/python2.7/__future__.py /usr/lib/python2.7/__future__.pyc /usr/lib/python2.7/__phello__.foo.py /usr/lib/python2.7/__phello__.foo.pyc /usr/lib/python2.7/_abcoll.py /usr/lib/python2.7/_abcoll.pyc /usr/lib/python2.7/_LWPCookieJar.py /usr/lib/python2.7/_LWPCookieJar.pyc /usr/lib/python2.7/_MozillaCookieJar.py /usr/lib/python2.7/_MozillaCookieJar.pyc /usr/lib/python2.7/_osx_support.py /usr/lib/python2.7/_osx_support.pyc /usr/lib/python2.7/_pyio.py /usr/lib/python2.7/_pyio.pyc /usr/lib/python2.7/_strptime.py /usr/lib/python2.7/_strptime.pyc /usr/lib/python2.7/_sysconfigdata.py /usr/lib/python2.7/_sysconfigdata.pyc /usr/lib/python2.7/_threading_local.py /usr/lib/python2.7/_threading_local.pyc /usr/lib/python2.7/_weakrefset.py /usr/lib/python2.7/_weakrefset.pyc /usr/lib/python2.7/abc.py /usr/lib/python2.7/abc.pyc /usr/lib/python2.7/aifc.py /usr/lib/python2.7/aifc.pyc /usr/lib/python2.7/antigravity.py /usr/lib/python2.7/antigravity.pyc /usr/lib/python2.7/anydbm.py /usr/lib/python2.7/anydbm.pyc /usr/lib/python2.7/argparse.egg-info /usr/lib/python2.7/argparse.py /usr/lib/python2.7/argparse.pyc /usr/lib/python2.7/ast.py /usr/lib/python2.7/ast.pyc /usr/lib/python2.7/asynchat.py /usr/lib/python2.7/asynchat.pyc /usr/lib/python2.7/asyncore.py /usr/lib/python2.7/asyncore.pyc /usr/lib/python2.7/atexit.py /usr/lib/python2.7/atexit.pyc /usr/lib/python2.7/audiodev.py /usr/lib/python2.7/audiodev.pyc /usr/lib/python2.7/base64.py /usr/lib/python2.7/base64.pyc /usr/lib/python2.7/BaseHTTPServer.py /usr/lib/python2.7/BaseHTTPServer.pyc /usr/lib/python2.7/Bastion.py /usr/lib/python2.7/Bastion.pyc /usr/lib/python2.7/bdb.py /usr/lib/python2.7/bdb.pyc /usr/lib/python2.7/binhex.py /usr/lib/python2.7/binhex.pyc /usr/lib/python2.7/bisect.py /usr/lib/python2.7/bisect.pyc /usr/lib/python2.7/bsddb /usr/lib/python2.7/calendar.py /usr/lib/python2.7/calendar.pyc /usr/lib/python2.7/cgi.py /usr/lib/python2.7/cgi.pyc /usr/lib/python2.7/CGIHTTPServer.py /usr/lib/python2.7/CGIHTTPServer.pyc /usr/lib/python2.7/cgitb.py /usr/lib/python2.7/cgitb.pyc /usr/lib/python2.7/chunk.py /usr/lib/python2.7/chunk.pyc /usr/lib/python2.7/cmd.py /usr/lib/python2.7/cmd.pyc /usr/lib/python2.7/code.py /usr/lib/python2.7/code.pyc /usr/lib/python2.7/codecs.py /usr/lib/python2.7/codecs.pyc /usr/lib/python2.7/codeop.py /usr/lib/python2.7/codeop.pyc /usr/lib/python2.7/collections.py /usr/lib/python2.7/collections.pyc /usr/lib/python2.7/colorsys.py /usr/lib/python2.7/colorsys.pyc /usr/lib/python2.7/commands.py /usr/lib/python2.7/commands.pyc /usr/lib/python2.7/compileall.py /usr/lib/python2.7/compileall.pyc /usr/lib/python2.7/compiler /usr/lib/python2.7/ConfigParser.py /usr/lib/python2.7/ConfigParser.pyc /usr/lib/python2.7/contextlib.py /usr/lib/python2.7/contextlib.pyc /usr/lib/python2.7/Cookie.py /usr/lib/python2.7/Cookie.pyc /usr/lib/python2.7/cookielib.py /usr/lib/python2.7/cookielib.pyc /usr/lib/python2.7/copy_reg.py /usr/lib/python2.7/copy_reg.pyc /usr/lib/python2.7/copy.py /usr/lib/python2.7/copy.pyc /usr/lib/python2.7/cProfile.py /usr/lib/python2.7/cProfile.pyc /usr/lib/python2.7/csv.py /usr/lib/python2.7/csv.pyc /usr/lib/python2.7/ctypes /usr/lib/python2.7/curses /usr/lib/python2.7/dbhash.py /usr/lib/python2.7/dbhash.pyc /usr/lib/python2.7/decimal.py /usr/lib/python2.7/decimal.pyc /usr/lib/python2.7/difflib.py /usr/lib/python2.7/difflib.pyc /usr/lib/python2.7/dircache.py /usr/lib/python2.7/dircache.pyc /usr/lib/python2.7/dis.py /usr/lib/python2.7/dis.pyc /usr/lib/python2.7/distutils /usr/lib/python2.7/doctest.py /usr/lib/python2.7/doctest.pyc /usr/lib/python2.7/DocXMLRPCServer.py /usr/lib/python2.7/DocXMLRPCServer.pyc /usr/lib/python2.7/dumbdbm.py /usr/lib/python2.7/dumbdbm.pyc /usr/lib/python2.7/dummy_thread.py /usr/lib/python2.7/dummy_thread.pyc /usr/lib/python2.7/dummy_threading.py /usr/lib/python2.7/dummy_threading.pyc /usr/lib/python2.7/email /usr/lib/python2.7/encodings /usr/lib/python2.7/ensurepip /usr/lib/python2.7/filecmp.py /usr/lib/python2.7/filecmp.pyc /usr/lib/python2.7/fileinput.py /usr/lib/python2.7/fileinput.pyc /usr/lib/python2.7/fnmatch.py /usr/lib/python2.7/fnmatch.pyc /usr/lib/python2.7/formatter.py /usr/lib/python2.7/formatter.pyc /usr/lib/python2.7/fpformat.py /usr/lib/python2.7/fpformat.pyc /usr/lib/python2.7/fractions.py /usr/lib/python2.7/fractions.pyc /usr/lib/python2.7/ftplib.py /usr/lib/python2.7/ftplib.pyc /usr/lib/python2.7/functools.py /usr/lib/python2.7/functools.pyc /usr/lib/python2.7/genericpath.py /usr/lib/python2.7/genericpath.pyc /usr/lib/python2.7/getopt.py /usr/lib/python2.7/getopt.pyc /usr/lib/python2.7/getpass.py /usr/lib/python2.7/getpass.pyc /usr/lib/python2.7/gettext.py /usr/lib/python2.7/gettext.pyc /usr/lib/python2.7/glob.py /usr/lib/python2.7/glob.pyc /usr/lib/python2.7/gzip.py /usr/lib/python2.7/gzip.pyc /usr/lib/python2.7/hashlib.py /usr/lib/python2.7/hashlib.pyc /usr/lib/python2.7/heapq.py /usr/lib/python2.7/heapq.pyc /usr/lib/python2.7/hmac.py /usr/lib/python2.7/hmac.pyc /usr/lib/python2.7/hotshot /usr/lib/python2.7/htmlentitydefs.py /usr/lib/python2.7/htmlentitydefs.pyc /usr/lib/python2.7/htmllib.py /usr/lib/python2.7/htmllib.pyc /usr/lib/python2.7/HTMLParser.py /usr/lib/python2.7/HTMLParser.pyc /usr/lib/python2.7/httplib.py /usr/lib/python2.7/httplib.pyc /usr/lib/python2.7/ihooks.py /usr/lib/python2.7/ihooks.pyc /usr/lib/python2.7/imaplib.py /usr/lib/python2.7/imaplib.pyc /usr/lib/python2.7/imghdr.py /usr/lib/python2.7/imghdr.pyc /usr/lib/python2.7/importlib /usr/lib/python2.7/imputil.py /usr/lib/python2.7/imputil.pyc /usr/lib/python2.7/inspect.py /usr/lib/python2.7/inspect.pyc /usr/lib/python2.7/io.py /usr/lib/python2.7/io.pyc /usr/lib/python2.7/json /usr/lib/python2.7/keyword.py /usr/lib/python2.7/keyword.pyc /usr/lib/python2.7/lib-dynload /usr/lib/python2.7/lib-tk /usr/lib/python2.7/lib2to3 /usr/lib/python2.7/LICENSE.txt /usr/lib/python2.7/linecache.py /usr/lib/python2.7/linecache.pyc /usr/lib/python2.7/locale.py /usr/lib/python2.7/locale.pyc /usr/lib/python2.7/logging /usr/lib/python2.7/macpath.py /usr/lib/python2.7/macpath.pyc /usr/lib/python2.7/macurl2path.py /usr/lib/python2.7/macurl2path.pyc /usr/lib/python2.7/mailbox.py /usr/lib/python2.7/mailbox.pyc /usr/lib/python2.7/mailcap.py /usr/lib/python2.7/mailcap.pyc /usr/lib/python2.7/markupbase.py /usr/lib/python2.7/markupbase.pyc /usr/lib/python2.7/md5.py /usr/lib/python2.7/md5.pyc /usr/lib/python2.7/mhlib.py /usr/lib/python2.7/mhlib.pyc /usr/lib/python2.7/mimetools.py /usr/lib/python2.7/mimetools.pyc /usr/lib/python2.7/mimetypes.py /usr/lib/python2.7/mimetypes.pyc /usr/lib/python2.7/MimeWriter.py /usr/lib/python2.7/MimeWriter.pyc /usr/lib/python2.7/mimify.py /usr/lib/python2.7/mimify.pyc /usr/lib/python2.7/modulefinder.py /usr/lib/python2.7/modulefinder.pyc /usr/lib/python2.7/multifile.py /usr/lib/python2.7/multifile.pyc /usr/lib/python2.7/multiprocessing /usr/lib/python2.7/mutex.py /usr/lib/python2.7/mutex.pyc /usr/lib/python2.7/netrc.py /usr/lib/python2.7/netrc.pyc /usr/lib/python2.7/new.py /usr/lib/python2.7/new.pyc /usr/lib/python2.7/nntplib.py /usr/lib/python2.7/nntplib.pyc /usr/lib/python2.7/ntpath.py /usr/lib/python2.7/ntpath.pyc /usr/lib/python2.7/nturl2path.py /usr/lib/python2.7/nturl2path.pyc /usr/lib/python2.7/numbers.py /usr/lib/python2.7/numbers.pyc /usr/lib/python2.7/opcode.py /usr/lib/python2.7/opcode.pyc /usr/lib/python2.7/optparse.py /usr/lib/python2.7/optparse.pyc /usr/lib/python2.7/os.py /usr/lib/python2.7/os.pyc /usr/lib/python2.7/os2emxpath.py /usr/lib/python2.7/os2emxpath.pyc /usr/lib/python2.7/pdb.doc /usr/lib/python2.7/pdb.py /usr/lib/python2.7/pdb.pyc /usr/lib/python2.7/pickle.py /usr/lib/python2.7/pickle.pyc /usr/lib/python2.7/pickletools.py /usr/lib/python2.7/pickletools.pyc /usr/lib/python2.7/pipes.py /usr/lib/python2.7/pipes.pyc /usr/lib/python2.7/pkgutil.py /usr/lib/python2.7/pkgutil.pyc /usr/lib/python2.7/plat-x86_64-linux-gnu /usr/lib/python2.7/platform.py /usr/lib/python2.7/platform.pyc /usr/lib/python2.7/plistlib.py /usr/lib/python2.7/plistlib.pyc /usr/lib/python2.7/popen2.py /usr/lib/python2.7/popen2.pyc /usr/lib/python2.7/poplib.py /usr/lib/python2.7/poplib.pyc /usr/lib/python2.7/posixfile.py /usr/lib/python2.7/posixfile.pyc /usr/lib/python2.7/posixpath.py /usr/lib/python2.7/posixpath.pyc /usr/lib/python2.7/pprint.py /usr/lib/python2.7/pprint.pyc /usr/lib/python2.7/profile.py /usr/lib/python2.7/profile.pyc /usr/lib/python2.7/pstats.py /usr/lib/python2.7/pstats.pyc /usr/lib/python2.7/pty.py /usr/lib/python2.7/pty.pyc /usr/lib/python2.7/py_compile.py /usr/lib/python2.7/py_compile.pyc /usr/lib/python2.7/pyclbr.py /usr/lib/python2.7/pyclbr.pyc /usr/lib/python2.7/pydoc_data /usr/lib/python2.7/pydoc.py /usr/lib/python2.7/pydoc.pyc /usr/lib/python2.7/Queue.py /usr/lib/python2.7/Queue.pyc /usr/lib/python2.7/quopri.py /usr/lib/python2.7/quopri.pyc /usr/lib/python2.7/random.py /usr/lib/python2.7/random.pyc /usr/lib/python2.7/re.py /usr/lib/python2.7/re.pyc /usr/lib/python2.7/repr.py /usr/lib/python2.7/repr.pyc /usr/lib/python2.7/rexec.py /usr/lib/python2.7/rexec.pyc /usr/lib/python2.7/rfc822.py /usr/lib/python2.7/rfc822.pyc /usr/lib/python2.7/rlcompleter.py /usr/lib/python2.7/rlcompleter.pyc /usr/lib/python2.7/robotparser.py /usr/lib/python2.7/robotparser.pyc /usr/lib/python2.7/runpy.py /usr/lib/python2.7/runpy.pyc /usr/lib/python2.7/sched.py /usr/lib/python2.7/sched.pyc /usr/lib/python2.7/sets.py /usr/lib/python2.7/sets.pyc /usr/lib/python2.7/sgmllib.py /usr/lib/python2.7/sgmllib.pyc /usr/lib/python2.7/sha.py /usr/lib/python2.7/sha.pyc /usr/lib/python2.7/shelve.py /usr/lib/python2.7/shelve.pyc /usr/lib/python2.7/shlex.py /usr/lib/python2.7/shlex.pyc /usr/lib/python2.7/shutil.py /usr/lib/python2.7/shutil.pyc /usr/lib/python2.7/SimpleHTTPServer.py /usr/lib/python2.7/SimpleHTTPServer.pyc /usr/lib/python2.7/SimpleXMLRPCServer.py /usr/lib/python2.7/SimpleXMLRPCServer.pyc /usr/lib/python2.7/site.py /usr/lib/python2.7/site.pyc /usr/lib/python2.7/sitecustomize.py /usr/lib/python2.7/sitecustomize.pyc /usr/lib/python2.7/smtpd.py /usr/lib/python2.7/smtpd.pyc /usr/lib/python2.7/smtplib.py /usr/lib/python2.7/smtplib.pyc /usr/lib/python2.7/sndhdr.py /usr/lib/python2.7/sndhdr.pyc /usr/lib/python2.7/socket.py /usr/lib/python2.7/socket.pyc /usr/lib/python2.7/SocketServer.py /usr/lib/python2.7/SocketServer.pyc /usr/lib/python2.7/sqlite3 /usr/lib/python2.7/sre_compile.py /usr/lib/python2.7/sre_compile.pyc /usr/lib/python2.7/sre_constants.py /usr/lib/python2.7/sre_constants.pyc /usr/lib/python2.7/sre_parse.py /usr/lib/python2.7/sre_parse.pyc /usr/lib/python2.7/sre.py /usr/lib/python2.7/sre.pyc /usr/lib/python2.7/ssl.py /usr/lib/python2.7/ssl.pyc /usr/lib/python2.7/stat.py /usr/lib/python2.7/stat.pyc /usr/lib/python2.7/statvfs.py /usr/lib/python2.7/statvfs.pyc /usr/lib/python2.7/string.py /usr/lib/python2.7/string.pyc /usr/lib/python2.7/StringIO.py /usr/lib/python2.7/StringIO.pyc /usr/lib/python2.7/stringold.py /usr/lib/python2.7/stringold.pyc /usr/lib/python2.7/stringprep.py /usr/lib/python2.7/stringprep.pyc /usr/lib/python2.7/struct.py /usr/lib/python2.7/struct.pyc /usr/lib/python2.7/subprocess.py /usr/lib/python2.7/subprocess.pyc /usr/lib/python2.7/sunau.py /usr/lib/python2.7/sunau.pyc /usr/lib/python2.7/sunaudio.py /usr/lib/python2.7/sunaudio.pyc /usr/lib/python2.7/symbol.py /usr/lib/python2.7/symbol.pyc /usr/lib/python2.7/symtable.py /usr/lib/python2.7/symtable.pyc /usr/lib/python2.7/sysconfig.py /usr/lib/python2.7/sysconfig.pyc /usr/lib/python2.7/tabnanny.py /usr/lib/python2.7/tabnanny.pyc /usr/lib/python2.7/tarfile.py /usr/lib/python2.7/tarfile.pyc /usr/lib/python2.7/telnetlib.py /usr/lib/python2.7/telnetlib.pyc /usr/lib/python2.7/tempfile.py /usr/lib/python2.7/tempfile.pyc /usr/lib/python2.7/test /usr/lib/python2.7/textwrap.py /usr/lib/python2.7/textwrap.pyc /usr/lib/python2.7/this.py /usr/lib/python2.7/this.pyc /usr/lib/python2.7/threading.py /usr/lib/python2.7/threading.pyc /usr/lib/python2.7/timeit.py /usr/lib/python2.7/timeit.pyc /usr/lib/python2.7/toaiff.py /usr/lib/python2.7/toaiff.pyc /usr/lib/python2.7/token.py /usr/lib/python2.7/token.pyc /usr/lib/python2.7/tokenize.py /usr/lib/python2.7/tokenize.pyc /usr/lib/python2.7/trace.py /usr/lib/python2.7/trace.pyc /usr/lib/python2.7/traceback.py /usr/lib/python2.7/traceback.pyc /usr/lib/python2.7/tty.py /usr/lib/python2.7/tty.pyc /usr/lib/python2.7/types.py /usr/lib/python2.7/types.pyc /usr/lib/python2.7/unittest /usr/lib/python2.7/urllib.py /usr/lib/python2.7/urllib.pyc /usr/lib/python2.7/urllib2.py /usr/lib/python2.7/urllib2.pyc /usr/lib/python2.7/urlparse.py /usr/lib/python2.7/urlparse.pyc /usr/lib/python2.7/user.py /usr/lib/python2.7/user.pyc /usr/lib/python2.7/UserDict.py /usr/lib/python2.7/UserDict.pyc /usr/lib/python2.7/UserList.py /usr/lib/python2.7/UserList.pyc /usr/lib/python2.7/UserString.py /usr/lib/python2.7/UserString.pyc /usr/lib/python2.7/uu.py /usr/lib/python2.7/uu.pyc /usr/lib/python2.7/uuid.py /usr/lib/python2.7/uuid.pyc /usr/lib/python2.7/warnings.py /usr/lib/python2.7/warnings.pyc /usr/lib/python2.7/wave.py /usr/lib/python2.7/wave.pyc /usr/lib/python2.7/weakref.py /usr/lib/python2.7/weakref.pyc /usr/lib/python2.7/webbrowser.py /usr/lib/python2.7/webbrowser.pyc /usr/lib/python2.7/whichdb.py /usr/lib/python2.7/whichdb.pyc /usr/lib/python2.7/wsgiref.egg-info /usr/lib/python2.7/wsgiref /usr/lib/python2.7/xdrlib.py /usr/lib/python2.7/xdrlib.pyc /usr/lib/python2.7/xml /usr/lib/python2.7/xmllib.py /usr/lib/python2.7/xmllib.pyc /usr/lib/python2.7/xmlrpclib.py /usr/lib/python2.7/xmlrpclib.pyc /usr/lib/python2.7/zipfile.py /usr/lib/python2.7/zipfile.pyc /exports/usr/lib/python2.7/ && \
  mv /usr/lib/python2.7/dist-packages/README /exports/usr/lib/python2.7/dist-packages/ && \
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

# YARN
FROM base AS yarn
COPY --from=node /exports/ /
RUN \
  npm install -g 'yarn@1.22.10'
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/ && \
  mv /usr/local/bin/yarn /exports/usr/local/bin/ && \
  mv /usr/local/lib/node_modules/yarn /exports/usr/local/lib/node_modules/

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
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/share/man/man1/ && \
  mv /usr/local/bin/sxhkd /exports/usr/local/bin/ && \
  mv /usr/local/share/man/man1/sxhkd.1 /exports/usr/local/share/man/man1/

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
  mkdir -p /exports/usr/include/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ /exports/usr/local/bin/ && \
  mv /usr/include/GL /usr/include/X11 /usr/include/xcb /exports/usr/include/ && \
  mv /usr/lib/x86_64-linux-gnu/libXau.a /usr/lib/x86_64-linux-gnu/libXau.so /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-ewmh.a /usr/lib/x86_64-linux-gnu/libxcb-ewmh.so /usr/lib/x86_64-linux-gnu/libxcb-ewmh.so.2 /usr/lib/x86_64-linux-gnu/libxcb-ewmh.so.2.0.0 /usr/lib/x86_64-linux-gnu/libxcb-icccm.a /usr/lib/x86_64-linux-gnu/libxcb-icccm.so /usr/lib/x86_64-linux-gnu/libxcb-icccm.so.4 /usr/lib/x86_64-linux-gnu/libxcb-icccm.so.4.0.0 /usr/lib/x86_64-linux-gnu/libxcb-keysyms.a /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so.1 /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.a /usr/lib/x86_64-linux-gnu/libxcb-randr.so /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-render.a /usr/lib/x86_64-linux-gnu/libxcb-render.so /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.a /usr/lib/x86_64-linux-gnu/libxcb-shape.so /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-util.a /usr/lib/x86_64-linux-gnu/libxcb-util.so /usr/lib/x86_64-linux-gnu/libxcb-util.so.1 /usr/lib/x86_64-linux-gnu/libxcb-util.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xinerama.a /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.a /usr/lib/x86_64-linux-gnu/libxcb.so /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.a /usr/lib/x86_64-linux-gnu/libXdmcp.so /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/lib/x86_64-linux-gnu/pkgconfig/pthread-stubs.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xau.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-atom.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-aux.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-event.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-ewmh.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-icccm.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-keysyms.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-randr.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-render.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-shape.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-util.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-xinerama.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xdmcp.pc /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ && \
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

# FFMPEG
FROM base AS ffmpeg
COPY --from=wget /exports/ /
COPY --from=xz /exports/ /
RUN \
  wget -O /tmp/ffmpeg.txz 'https://www.johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz' && \
  tar -xvf /tmp/ffmpeg.txz && \
  rm /tmp/ffmpeg.txz && \
  mv 'ffmpeg-4.4-amd64-static' ffmpeg && \
  mv ffmpeg/ffmpeg /usr/local/bin/ffmpeg && \
  mv ffmpeg/ffprobe /usr/local/bin/ffprobe && \
  rm -r ffmpeg
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /exports/usr/local/bin/

# RUST
FROM base AS rust
COPY --from=wget /exports/ /
RUN \
  wget -O rust.sh 'https://sh.rustup.rs' && \
  sh rust.sh -y --default-toolchain '1.48.0' && \
  rm rust.sh
RUN \
  mkdir -p /exports/root/ && \
  mv /root/.cargo /root/.rustup /exports/root/

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

# ELECTRUM
FROM base AS electrum
COPY --from=apteryx /exports/ /
COPY --from=python3-pip /exports/ /
COPY --from=wget /exports/ /
RUN \
  wget https://raw.githubusercontent.com/spesmilo/electrum/master/pubkeys/ThomasV.asc && \
  gpg --import ThomasV.asc && \
  wget https://download.electrum.org/4.1.2/Electrum-4.1.2.tar.gz && \
  wget https://download.electrum.org/4.1.2/Electrum-4.1.2.tar.gz.asc && \
  gpg --verify Electrum-4.1.2.tar.gz.asc && \
  apteryx python3-pyqt5 libsecp256k1-0 python3-cryptography && \
  python3 -m pip install ./Electrum-4.1.2.tar.gz && \
  rm ThomasV.asc && \
  rm Electrum-4.1.2.tar.gz && \
  rm Electrum-4.1.2.tar.gz.asc
RUN \
  mkdir -p /exports/usr/lib/python3/dist-packages/ /exports/usr/lib/udev/ /exports/usr/lib/udev/rules.d/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ /exports/usr/local/lib/python3.8/dist-packages/ && \
  mv /usr/lib/python3/dist-packages/_cffi_backend.cpython-38-x86_64-linux-gnu.so /usr/lib/python3/dist-packages/cryptography-2.8.egg-info /usr/lib/python3/dist-packages/cryptography /usr/lib/python3/dist-packages/PyQt5-5.14.1.dist-info /usr/lib/python3/dist-packages/PyQt5 /usr/lib/python3/dist-packages/sip-4.19.21.dist-info /usr/lib/python3/dist-packages/sip.cpython-38-x86_64-linux-gnu.so /usr/lib/python3/dist-packages/sip.pyi /usr/lib/python3/dist-packages/sipconfig_nd8.py /usr/lib/python3/dist-packages/sipconfig.py /exports/usr/lib/python3/dist-packages/ && \
  mv /usr/lib/udev/libinput-device-group /usr/lib/udev/libinput-fuzz-extract /usr/lib/udev/libinput-fuzz-to-zero /exports/usr/lib/udev/ && \
  mv /usr/lib/udev/rules.d/65-libwacom.rules /usr/lib/udev/rules.d/80-libinput-device-groups.rules /usr/lib/udev/rules.d/90-libinput-fuzz-override.rules /exports/usr/lib/udev/rules.d/ && \
  mv /usr/lib/X11 /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/avahi /usr/lib/x86_64-linux-gnu/dri /usr/lib/x86_64-linux-gnu/libavahi-client.so.3 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3.2.9 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3.5.3 /usr/lib/x86_64-linux-gnu/libcups.so.2 /usr/lib/x86_64-linux-gnu/libdouble-conversion.so.3 /usr/lib/x86_64-linux-gnu/libdouble-conversion.so.3.1 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_intel.so.1 /usr/lib/x86_64-linux-gnu/libdrm_intel.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2.0.0 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1.0.1 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libEGL_mesa.so.0 /usr/lib/x86_64-linux-gnu/libEGL_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libEGL.so.1 /usr/lib/x86_64-linux-gnu/libEGL.so.1.1.0 /usr/lib/x86_64-linux-gnu/libevdev.so.2 /usr/lib/x86_64-linux-gnu/libevdev.so.2.3.0 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.0 /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.17.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libGL.so.1 /usr/lib/x86_64-linux-gnu/libGL.so.1.7.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX_indirect.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgudev-1.0.so.0 /usr/lib/x86_64-linux-gnu/libgudev-1.0.so.0.2.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.20600.4 /usr/lib/x86_64-linux-gnu/libICE.so.6 /usr/lib/x86_64-linux-gnu/libICE.so.6.3.0 /usr/lib/x86_64-linux-gnu/libinput.so.10 /usr/lib/x86_64-linux-gnu/libinput.so.10.13.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/libLLVM-11.so /usr/lib/x86_64-linux-gnu/libLLVM-11.so.1 /usr/lib/x86_64-linux-gnu/libmtdev.so.1 /usr/lib/x86_64-linux-gnu/libmtdev.so.1.0.0 /usr/lib/x86_64-linux-gnu/libpciaccess.so.0 /usr/lib/x86_64-linux-gnu/libpciaccess.so.0.11.1 /usr/lib/x86_64-linux-gnu/libpcre2-16.so.0 /usr/lib/x86_64-linux-gnu/libpcre2-16.so.0.9.0 /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.37.0 /usr/lib/x86_64-linux-gnu/libQt5Core.so.5 /usr/lib/x86_64-linux-gnu/libQt5Core.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5Core.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5DBus.so.5 /usr/lib/x86_64-linux-gnu/libQt5DBus.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5DBus.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5Designer.so.5 /usr/lib/x86_64-linux-gnu/libQt5Designer.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5Designer.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5EglFSDeviceIntegration.so.5 /usr/lib/x86_64-linux-gnu/libQt5EglFSDeviceIntegration.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5EglFSDeviceIntegration.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5EglFsKmsSupport.so.5 /usr/lib/x86_64-linux-gnu/libQt5EglFsKmsSupport.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5EglFsKmsSupport.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5Gui.so.5 /usr/lib/x86_64-linux-gnu/libQt5Gui.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5Gui.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5Help.so.5 /usr/lib/x86_64-linux-gnu/libQt5Help.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5Help.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5Network.so.5 /usr/lib/x86_64-linux-gnu/libQt5Network.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5Network.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5PrintSupport.so.5 /usr/lib/x86_64-linux-gnu/libQt5PrintSupport.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5PrintSupport.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5Sql.so.5 /usr/lib/x86_64-linux-gnu/libQt5Sql.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5Sql.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5Test.so.5 /usr/lib/x86_64-linux-gnu/libQt5Test.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5Test.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5Widgets.so.5 /usr/lib/x86_64-linux-gnu/libQt5Widgets.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5Widgets.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5XcbQpa.so.5 /usr/lib/x86_64-linux-gnu/libQt5XcbQpa.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5XcbQpa.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5Xml.so.5 /usr/lib/x86_64-linux-gnu/libQt5Xml.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5Xml.so.5.12.8 /usr/lib/x86_64-linux-gnu/libsecp256k1.so.0 /usr/lib/x86_64-linux-gnu/libsecp256k1.so.0.0.0 /usr/lib/x86_64-linux-gnu/libsensors.so.5 /usr/lib/x86_64-linux-gnu/libsensors.so.5.0.0 /usr/lib/x86_64-linux-gnu/libSM.so.6 /usr/lib/x86_64-linux-gnu/libSM.so.6.0.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1.2.131 /usr/lib/x86_64-linux-gnu/libwacom.so.2 /usr/lib/x86_64-linux-gnu/libwacom.so.2.6.1 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.3.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0.1.0 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1.0.0 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.3.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-icccm.so.4 /usr/lib/x86_64-linux-gnu/libxcb-icccm.so.4.0.0 /usr/lib/x86_64-linux-gnu/libxcb-image.so.0 /usr/lib/x86_64-linux-gnu/libxcb-image.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so.1 /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-render-util.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render-util.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-util.so.1 /usr/lib/x86_64-linux-gnu/libxcb-util.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xinput.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xinput.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-xkb.so.1 /usr/lib/x86_64-linux-gnu/libxcb-xkb.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libxkbcommon-x11.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon-x11.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1.0.0 /usr/lib/x86_64-linux-gnu/qt-default /usr/lib/x86_64-linux-gnu/qt5 /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/bin/electrum /usr/local/bin/helpdev /usr/local/bin/qdarkstyle /usr/local/bin/qr /exports/usr/local/bin/ && \
  mv /usr/local/lib/python3.8/dist-packages/__pycache__ /usr/local/lib/python3.8/dist-packages/aiohttp_socks-0.6.0.dist-info /usr/local/lib/python3.8/dist-packages/aiohttp_socks /usr/local/lib/python3.8/dist-packages/aiohttp-3.7.4.post0.dist-info /usr/local/lib/python3.8/dist-packages/aiohttp /usr/local/lib/python3.8/dist-packages/aiorpcX-0.18.7.dist-info /usr/local/lib/python3.8/dist-packages/aiorpcx /usr/local/lib/python3.8/dist-packages/async_timeout-3.0.1.dist-info /usr/local/lib/python3.8/dist-packages/async_timeout /usr/local/lib/python3.8/dist-packages/attr /usr/local/lib/python3.8/dist-packages/attrs-21.2.0.dist-info /usr/local/lib/python3.8/dist-packages/bitstring-3.1.7.dist-info /usr/local/lib/python3.8/dist-packages/bitstring.py /usr/local/lib/python3.8/dist-packages/dns /usr/local/lib/python3.8/dist-packages/dnspython-2.0.0.dist-info /usr/local/lib/python3.8/dist-packages/Electrum-4.1.2.dist-info /usr/local/lib/python3.8/dist-packages/electrum /usr/local/lib/python3.8/dist-packages/google /usr/local/lib/python3.8/dist-packages/helpdev-0.7.1.dist-info /usr/local/lib/python3.8/dist-packages/helpdev /usr/local/lib/python3.8/dist-packages/multidict-5.1.0.dist-info /usr/local/lib/python3.8/dist-packages/multidict /usr/local/lib/python3.8/dist-packages/protobuf-3.17.3-py3.8-nspkg.pth /usr/local/lib/python3.8/dist-packages/protobuf-3.17.3.dist-info /usr/local/lib/python3.8/dist-packages/python_socks-1.2.4.dist-info /usr/local/lib/python3.8/dist-packages/python_socks /usr/local/lib/python3.8/dist-packages/QDarkStyle-2.8.1.dist-info /usr/local/lib/python3.8/dist-packages/qdarkstyle /usr/local/lib/python3.8/dist-packages/qrcode-6.1.dist-info /usr/local/lib/python3.8/dist-packages/qrcode /usr/local/lib/python3.8/dist-packages/QtPy-1.9.0.dist-info /usr/local/lib/python3.8/dist-packages/qtpy /usr/local/lib/python3.8/dist-packages/typing_extensions-3.10.0.0.dist-info /usr/local/lib/python3.8/dist-packages/typing_extensions.py /usr/local/lib/python3.8/dist-packages/usr /usr/local/lib/python3.8/dist-packages/yarl-1.6.3.dist-info /usr/local/lib/python3.8/dist-packages/yarl /exports/usr/local/lib/python3.8/dist-packages/

# MILLER
FROM base AS miller
COPY --from=wget /exports/ /
RUN \
  wget -O /usr/local/bin/mlr https://github.com/johnkerl/miller/releases/download/v5.10.2/mlr.linux.x86_64 && \
  chmod +x /usr/local/bin/mlr
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/mlr /exports/usr/local/bin/

# AUTOTAG
FROM base AS autotag
COPY --from=wget /exports/ /
RUN \
  wget -O /tmp/autotag.tgz "https://github.com/pantheon-systems/autotag/releases/download/v1.3.9/autotag_linux_amd64.tar.gz" && \
  tar xzvf /tmp/autotag.tgz autotag && \
  mv autotag /usr/local/bin/autotag && \
  rm /tmp/autotag.tgz
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/autotag /exports/usr/local/bin/

# MBSYNC
FROM base AS mbsync
COPY --from=wget /exports/ /
COPY --from=apteryx /exports/ /
COPY --from=build-essential /exports/ /
RUN \
  apteryx libssl-dev && \
  wget -O /tmp/isync.tgz "https://sourceforge.net/projects/isync/files/isync/1.4.1/isync-1.4.1.tar.gz/download" && \
  tar xzvf /tmp/isync.tgz -C /tmp && \
  rm /tmp/isync.tgz && \
  cd "/tmp/isync-1.4.1" && \
  ls -alh && \
  ./configure && \
  make && \
  mv src/mbsync /usr/local/bin/mbsync && \
  rm -r "/tmp/isync-1.4.1"
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/mbsync /exports/usr/local/bin/

# ZX
FROM base AS zx
COPY --from=node /exports/ /
RUN \
  npm install -g 'zx@1.14.1'
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/ && \
  mv /usr/local/bin/zx /exports/usr/local/bin/ && \
  mv /usr/local/lib/node_modules/zx /exports/usr/local/lib/node_modules/

# XDO
FROM base AS xdo
COPY --from=apteryx /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=clone /exports/ /
COPY --from=make /exports/ /
RUN \
  apteryx libxcb-ewmh-dev libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-randr0-dev libxcb-shape0-dev libxcb-util-dev libxcb-xinerama0-dev libxcb-xtest0-dev && \
  clone --https --shallow --tag '0.5.7' https://github.com/baskerville/xdo && \
  cd /root/src/github.com/baskerville/xdo && \
  make all && \
  make install && \
  rm -rf /root/src
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/xdo /exports/usr/local/bin/

# MYCLI
FROM base AS mycli
COPY --from=python3-pip /exports/ /
COPY --from=pipx /exports/ /
ENV \
  PIPX_HOME=/usr/local/pipx \
  PIPX_BIN_DIR=/usr/local/bin
RUN \
  pipx install mycli==1.24.1
RUN \
  mkdir -p /exports/usr/local/ /exports/usr/local/bin/ && \
  mv /usr/local/pipx /exports/usr/local/ && \
  mv /usr/local/bin/mycli /exports/usr/local/bin/

# BANDWHICH
FROM base AS bandwhich
COPY --from=wget /exports/ /
RUN \
  wget -O /tmp/bandwhich.tgz 'https://github.com/imsnif/bandwhich/releases/download/0.20.0/bandwhich-v0.20.0-x86_64-unknown-linux-musl.tar.gz' && \
  tar -xvf /tmp/bandwhich.tgz && \
  rm /tmp/bandwhich.tgz && \
  mv bandwhich /usr/local/bin/bandwhich
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/bandwhich /exports/usr/local/bin/

# LIBGLIB
FROM base AS libglib
COPY --from=apteryx /exports/ /
RUN \
  apteryx libglib2.0-bin='2.64.6-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/bin/gapplication /usr/bin/gdbus /usr/bin/gio /usr/bin/gio-querymodules /usr/bin/glib-compile-schemas /usr/bin/gresource /usr/bin/gsettings /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu/libelf-*.so /usr/lib/x86_64-linux-gnu/libelf.so.1 /exports/usr/lib/x86_64-linux-gnu/

# YOUTUBE-DL
FROM base AS youtube-dl
COPY --from=wget /exports/ /
RUN \
  wget -O /usr/local/bin/youtube-dl "https://github.com/ytdl-org/youtube-dl/releases/download/2020.12.14/youtube-dl" && \
  chmod a+rx /usr/local/bin/youtube-dl
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/youtube-dl /exports/usr/local/bin/

# CHS
FROM base AS chs
COPY --from=clone /exports/ /
COPY --from=python3-pip /exports/ /
COPY --from=build-essential /exports/ /
RUN \
  clone --shallow --https --tag 'v3.0.0' 'https://github.com/nickzuber/chs' && \
  cd /root/src/github.com/nickzuber/chs && \
  pip3 install -r requirements.txt && \
  sed -i 's/python/python3/' chs.py && \
  mv /root/src/github.com/nickzuber/chs /usr/local/lib/python3.*/dist-packages/ && \
  ln -s /usr/local/lib/python3.*/dist-packages/chs/chs.py /usr/local/bin/chs && \
  chmod +x /usr/local/bin/chs
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/python3.*/dist-packages/ && \
  mv /usr/local/bin/chs /exports/usr/local/bin/ && \
  mv /usr/local/lib/python3.*/dist-packages/chess /usr/local/lib/python3.*/dist-packages/chs /usr/local/lib/python3.*/dist-packages/editdistance /exports/usr/local/lib/python3.*/dist-packages/

# HYPERFINE
FROM base AS hyperfine
COPY --from=wget /exports/ /
RUN \
  wget -O hyperfine.tgz https://github.com/sharkdp/hyperfine/releases/download/v1.11.0/hyperfine-v1.11.0-x86_64-unknown-linux-musl.tar.gz && \
  tar xzf ./hyperfine.tgz && \
  mkdir -p /usr/local/man/man1 && \
  mv ./hyperfine-v1.11.0-x86_64-unknown-linux-musl/hyperfine /usr/local/bin/ && \
  mv ./hyperfine-v1.11.0-x86_64-unknown-linux-musl/hyperfine.1 /usr/local/man/man1/ && \
  rm -r ./hyperfine.tgz ./hyperfine-v1.11.0-x86_64-unknown-linux-musl
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/man/man1/ && \
  mv /usr/local/bin/hyperfine /exports/usr/local/bin/ && \
  mv /usr/local/man/man1/hyperfine.1 /exports/usr/local/man/man1/

# W3M
FROM base AS w3m
COPY --from=apteryx /exports/ /
RUN \
  apteryx w3m='0.5.3-*'
RUN \
  mkdir -p /exports/etc/ /exports/usr/bin/ /exports/usr/lib/mime/packages/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /etc/w3m /exports/etc/ && \
  mv /usr/bin/w3m /usr/bin/w3mman /usr/bin/www-browser /exports/usr/bin/ && \
  mv /usr/lib/mime/packages/w3m /exports/usr/lib/mime/packages/ && \
  mv /usr/lib/w3m /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/libgc.so.* /usr/lib/x86_64-linux-gnu/libgccpp.so.* /usr/lib/x86_64-linux-gnu/libgpm.so.* /exports/usr/lib/x86_64-linux-gnu/

# AERC
FROM base AS aerc
COPY --from=build-essential /exports/ /
COPY --from=clone /exports/ /
COPY --from=go /exports/ /
COPY --from=scdoc /exports/ /
COPY --from=socksify /exports/ /
ENV \
  PATH=/usr/local/go/bin:${PATH} \
  GOPATH=/root \
  GO111MODULE=auto
RUN \
  clone --https --shallow --tag "${VERSION}" https://git.sr.ht/~sircmpwn/aerc && \
  cd ~/src/git.sr.ht/~sircmpwn/aerc && \
  make && \
  make install && \
  rm -rf ~/src
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/include/ /exports/usr/local/lib/ /exports/usr/local/sbin/ /exports/usr/local/share/ /exports/usr/local/share/man/man1/ /exports/usr/local/share/man/man5/ /exports/usr/local/share/man/man7/ /exports/usr/local/share/man/man8/ && \
  mv /usr/local/bin/aerc /usr/local/bin/socksify /exports/usr/local/bin/ && \
  mv /usr/local/include/socks.h /exports/usr/local/include/ && \
  mv /usr/local/lib/libdsocks.la /usr/local/lib/libdsocks.so /usr/local/lib/libsocks.a /usr/local/lib/libsocks.la /usr/local/lib/libsocks.so /usr/local/lib/libsocks.so.0 /usr/local/lib/libsocks.so.0.1.1 /exports/usr/local/lib/ && \
  mv /usr/local/sbin/sockd /exports/usr/local/sbin/ && \
  mv /usr/local/share/aerc /exports/usr/local/share/ && \
  mv /usr/local/share/man/man1/aerc-* /usr/local/share/man/man1/socksify.1 /exports/usr/local/share/man/man1/ && \
  mv /usr/local/share/man/man5/aerc-* /usr/local/share/man/man5/sockd.conf.5 /usr/local/share/man/man5/socks.conf.5 /exports/usr/local/share/man/man5/ && \
  mv /usr/local/share/man/man7/aerc-* /exports/usr/local/share/man/man7/ && \
  mv /usr/local/share/man/man8/sockd.8 /exports/usr/local/share/man/man8/

# MAN
FROM base AS man
COPY --from=apteryx /exports/ /
RUN \
  apteryx man-db='2.9.1-*'
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
  apteryx xournalpp='1.0.20-*'
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
COPY --from=build-essential /exports/ /
RUN \
  add-apt-repository ppa:ubuntu-toolchain-r/test && \
  apt-get update -q && \
  apt-get install -y --no-install-recommends --auto-remove cmake libpthread-stubs0-dev libicu-dev gcc-9 g++-9 && \
  clone --https --shallow --tag '0.4.3' https://github.com/octobanana/peaclock && \
  cd /root/src/github.com/octobanana/peaclock && \
  ./RUNME.sh build --release -- -DCMAKE_CXX_COMPILER=/usr/bin/g++-9 && \
  ./RUNME.sh install --release && \
  rm -rf /root/src && \
  apt purge -y cmake libpthread-stubs0-dev libicu-dev gcc-9 g++-9 && \
  apt autoremove -y && \
  apt-get -q clean
RUN \
  mkdir -p /exports/usr/local/bin/ && \
  mv /usr/local/bin/peaclock /exports/usr/local/bin/

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
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ /exports/usr/local/lib/python3.8/dist-packages/ /exports/usr/share/doc/ /exports/usr/share/lintian/overrides/ /exports/usr/share/locale/cs/LC_MESSAGES/ /exports/usr/share/locale/de/LC_MESSAGES/ /exports/usr/share/locale/es/LC_MESSAGES/ /exports/usr/share/locale/fr/LC_MESSAGES/ /exports/usr/share/locale/hu/LC_MESSAGES/ /exports/usr/share/locale/it/LC_MESSAGES/ /exports/usr/share/locale/ja/LC_MESSAGES/ /exports/usr/share/locale/pl/LC_MESSAGES/ /exports/usr/share/locale/pt_BR/LC_MESSAGES/ /exports/usr/share/locale/pt/LC_MESSAGES/ /exports/usr/share/locale/ru/LC_MESSAGES/ /exports/usr/share/locale/tr/LC_MESSAGES/ /exports/usr/share/man/cs/man1/ /exports/usr/share/man/de/man1/ /exports/usr/share/man/fr/man1/ /exports/usr/share/man/it/man1/ /exports/usr/share/man/ja/man1/ /exports/usr/share/man/man1/ /exports/usr/share/man/pl/man1/ /exports/usr/share/man/ru/man1/ /exports/usr/share/menu/ /exports/usr/share/ /exports/usr/share/pixmaps/ && \
  mv /usr/bin/cpan5.30-x86_64-linux-gnu /usr/bin/perl5.30-x86_64-linux-gnu /usr/bin/weechat /usr/bin/weechat-curses /exports/usr/bin/ && \
  mv /usr/lib/aspell /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/libaspell.so.15 /usr/lib/x86_64-linux-gnu/libaspell.so.15.3.1 /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.3 /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.4 /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.4.6.0 /usr/lib/x86_64-linux-gnu/libgdbm_compat.so.4 /usr/lib/x86_64-linux-gnu/libgdbm_compat.so.4.0.0 /usr/lib/x86_64-linux-gnu/libgdbm.so.6 /usr/lib/x86_64-linux-gnu/libgdbm.so.6.0.0 /usr/lib/x86_64-linux-gnu/libperl.so.5.30 /usr/lib/x86_64-linux-gnu/libperl.so.5.30.0 /usr/lib/x86_64-linux-gnu/libpspell.so.15 /usr/lib/x86_64-linux-gnu/libpspell.so.15.3.1 /usr/lib/x86_64-linux-gnu/perl /usr/lib/x86_64-linux-gnu/weechat /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/bin/__pycache__ /usr/local/bin/wsdump.py /exports/usr/local/bin/ && \
  mv /usr/local/lib/python3.8/dist-packages/websocket_client-1.0.1.dist-info /usr/local/lib/python3.8/dist-packages/websocket /exports/usr/local/lib/python3.8/dist-packages/ && \
  mv /usr/share/doc/libaspell15 /usr/share/doc/libcurl3-gnutls /usr/share/doc/libgdbm-compat4 /usr/share/doc/libgdbm6 /usr/share/doc/libperl5.30 /usr/share/doc/perl-modules-5.30 /usr/share/doc/weechat-core /usr/share/doc/weechat-curses /usr/share/doc/weechat-perl /usr/share/doc/weechat-plugins /usr/share/doc/weechat-python /exports/usr/share/doc/ && \
  mv /usr/share/lintian/overrides/libcurl3-gnutls /usr/share/lintian/overrides/perl-modules-5.30 /exports/usr/share/lintian/overrides/ && \
  mv /usr/share/locale/cs/LC_MESSAGES/weechat.mo /exports/usr/share/locale/cs/LC_MESSAGES/ && \
  mv /usr/share/locale/de/LC_MESSAGES/weechat.mo /exports/usr/share/locale/de/LC_MESSAGES/ && \
  mv /usr/share/locale/es/LC_MESSAGES/weechat.mo /exports/usr/share/locale/es/LC_MESSAGES/ && \
  mv /usr/share/locale/fr/LC_MESSAGES/weechat.mo /exports/usr/share/locale/fr/LC_MESSAGES/ && \
  mv /usr/share/locale/hu/LC_MESSAGES/weechat.mo /exports/usr/share/locale/hu/LC_MESSAGES/ && \
  mv /usr/share/locale/it/LC_MESSAGES/weechat.mo /exports/usr/share/locale/it/LC_MESSAGES/ && \
  mv /usr/share/locale/ja/LC_MESSAGES/weechat.mo /exports/usr/share/locale/ja/LC_MESSAGES/ && \
  mv /usr/share/locale/pl/LC_MESSAGES/weechat.mo /exports/usr/share/locale/pl/LC_MESSAGES/ && \
  mv /usr/share/locale/pt_BR/LC_MESSAGES/weechat.mo /exports/usr/share/locale/pt_BR/LC_MESSAGES/ && \
  mv /usr/share/locale/pt/LC_MESSAGES/weechat.mo /exports/usr/share/locale/pt/LC_MESSAGES/ && \
  mv /usr/share/locale/ru/LC_MESSAGES/weechat.mo /exports/usr/share/locale/ru/LC_MESSAGES/ && \
  mv /usr/share/locale/tr/LC_MESSAGES/weechat.mo /exports/usr/share/locale/tr/LC_MESSAGES/ && \
  mv /usr/share/man/cs/man1/weechat-curses.1.gz /usr/share/man/cs/man1/weechat.1.gz /exports/usr/share/man/cs/man1/ && \
  mv /usr/share/man/de/man1/weechat-curses.1.gz /usr/share/man/de/man1/weechat.1.gz /exports/usr/share/man/de/man1/ && \
  mv /usr/share/man/fr/man1/weechat-curses.1.gz /usr/share/man/fr/man1/weechat.1.gz /exports/usr/share/man/fr/man1/ && \
  mv /usr/share/man/it/man1/weechat-curses.1.gz /usr/share/man/it/man1/weechat.1.gz /exports/usr/share/man/it/man1/ && \
  mv /usr/share/man/ja/man1/weechat-curses.1.gz /usr/share/man/ja/man1/weechat.1.gz /exports/usr/share/man/ja/man1/ && \
  mv /usr/share/man/man1/cpan5.30-x86_64-linux-gnu.1.gz /usr/share/man/man1/perl5.30-x86_64-linux-gnu.1.gz /usr/share/man/man1/weechat-curses.1.gz /usr/share/man/man1/weechat.1.gz /exports/usr/share/man/man1/ && \
  mv /usr/share/man/pl/man1/weechat-curses.1.gz /usr/share/man/pl/man1/weechat.1.gz /exports/usr/share/man/pl/man1/ && \
  mv /usr/share/man/ru/man1/weechat-curses.1.gz /usr/share/man/ru/man1/weechat.1.gz /exports/usr/share/man/ru/man1/ && \
  mv /usr/share/menu/weechat-curses /exports/usr/share/menu/ && \
  mv /usr/share/perl /exports/usr/share/ && \
  mv /usr/share/pixmaps/weechat.xpm /exports/usr/share/pixmaps/

# XINPUT
FROM base AS xinput
COPY --from=apteryx /exports/ /
RUN \
  apteryx xinput='1.6.3-*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/xinput /exports/usr/bin/

# ALSA-UTILS
FROM base AS alsa-utils
COPY --from=apteryx /exports/ /
RUN \
  apteryx alsa-utils='1.2.2-*'
RUN \
  mkdir -p /exports/etc/ /exports/etc/init.d/ /exports/etc/rc0.d/ /exports/etc/rc1.d/ /exports/etc/rc6.d/ /exports/etc/rcS.d/ /exports/usr/bin/ /exports/usr/lib/modprobe.d/ /exports/usr/lib/systemd/system/ /exports/usr/lib/udev/rules.d/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/sbin/ /exports/usr/share/ /exports/usr/share/bash-completion/completions/ /exports/usr/share/doc/ /exports/usr/share/doc/libkmod2/ /exports/usr/share/man/fr/man5/ /exports/usr/share/man/man1/ /exports/usr/share/man/man5/ /exports/usr/share/man/man7/ /exports/usr/share/man/man8/ && \
  mv /etc/depmod.d /etc/ld.so.cache /etc/modprobe.d /etc/modules /exports/etc/ && \
  mv /etc/init.d/alsa-utils /etc/init.d/kmod /exports/etc/init.d/ && \
  mv /etc/rc0.d/K01alsa-utils /exports/etc/rc0.d/ && \
  mv /etc/rc1.d/K01alsa-utils /exports/etc/rc1.d/ && \
  mv /etc/rc6.d/K01alsa-utils /exports/etc/rc6.d/ && \
  mv /etc/rcS.d/S01alsa-utils /etc/rcS.d/S01kmod /exports/etc/rcS.d/ && \
  mv /usr/bin/aconnect /usr/bin/alsabat /usr/bin/alsaloop /usr/bin/alsamixer /usr/bin/alsatplg /usr/bin/alsaucm /usr/bin/amidi /usr/bin/amixer /usr/bin/aplay /usr/bin/aplaymidi /usr/bin/arecord /usr/bin/arecordmidi /usr/bin/aseqdump /usr/bin/aseqnet /usr/bin/axfer /usr/bin/iecset /usr/bin/kmod /usr/bin/lsmod /usr/bin/speaker-test /exports/usr/bin/ && \
  mv /usr/lib/modprobe.d/aliases.conf /exports/usr/lib/modprobe.d/ && \
  mv /usr/lib/systemd/system/alsa-restore.service /usr/lib/systemd/system/alsa-state.service /usr/lib/systemd/system/alsa-utils.service /usr/lib/systemd/system/sound.target.wants /exports/usr/lib/systemd/system/ && \
  mv /usr/lib/udev/rules.d/90-alsa-restore.rules /exports/usr/lib/udev/rules.d/ && \
  mv /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libasound.so.2.0.0 /usr/lib/x86_64-linux-gnu/libatopology.so.2 /usr/lib/x86_64-linux-gnu/libatopology.so.2.0.0 /usr/lib/x86_64-linux-gnu/libfftw3f_omp.so.3 /usr/lib/x86_64-linux-gnu/libfftw3f_omp.so.3.5.8 /usr/lib/x86_64-linux-gnu/libfftw3f_threads.so.3 /usr/lib/x86_64-linux-gnu/libfftw3f_threads.so.3.5.8 /usr/lib/x86_64-linux-gnu/libfftw3f.so.3 /usr/lib/x86_64-linux-gnu/libfftw3f.so.3.5.8 /usr/lib/x86_64-linux-gnu/libgomp.so.1 /usr/lib/x86_64-linux-gnu/libgomp.so.1.0.0 /usr/lib/x86_64-linux-gnu/libsamplerate.so.0 /usr/lib/x86_64-linux-gnu/libsamplerate.so.0.1.8 /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/sbin/alsa-info /usr/sbin/alsabat-test /usr/sbin/alsactl /usr/sbin/depmod /usr/sbin/insmod /usr/sbin/lsmod /usr/sbin/modinfo /usr/sbin/modprobe /usr/sbin/rmmod /exports/usr/sbin/ && \
  mv /usr/share/alsa /usr/share/initramfs-tools /usr/share/sounds /exports/usr/share/ && \
  mv /usr/share/bash-completion/completions/kmod /exports/usr/share/bash-completion/completions/ && \
  mv /usr/share/doc/alsa-utils /usr/share/doc/kmod /usr/share/doc/libasound2-data /usr/share/doc/libasound2 /usr/share/doc/libatopology2 /usr/share/doc/libfftw3-single3 /usr/share/doc/libgomp1 /usr/share/doc/libsamplerate0 /exports/usr/share/doc/ && \
  mv /usr/share/doc/libkmod2/README /usr/share/doc/libkmod2/TODO /exports/usr/share/doc/libkmod2/ && \
  mv /usr/share/man/fr/man5/modules.5.gz /exports/usr/share/man/fr/man5/ && \
  mv /usr/share/man/man1/aconnect.1.gz /usr/share/man/man1/alsabat.1.gz /usr/share/man/man1/alsactl.1.gz /usr/share/man/man1/alsaloop.1.gz /usr/share/man/man1/alsamixer.1.gz /usr/share/man/man1/alsatplg.1.gz /usr/share/man/man1/alsaucm.1.gz /usr/share/man/man1/amidi.1.gz /usr/share/man/man1/amixer.1.gz /usr/share/man/man1/aplay.1.gz /usr/share/man/man1/aplaymidi.1.gz /usr/share/man/man1/arecord.1.gz /usr/share/man/man1/arecordmidi.1.gz /usr/share/man/man1/aseqdump.1.gz /usr/share/man/man1/aseqnet.1.gz /usr/share/man/man1/axfer-list.1.gz /usr/share/man/man1/axfer-transfer.1.gz /usr/share/man/man1/axfer.1.gz /usr/share/man/man1/iecset.1.gz /usr/share/man/man1/speaker-test.1.gz /exports/usr/share/man/man1/ && \
  mv /usr/share/man/man5/depmod.d.5.gz /usr/share/man/man5/modprobe.d.5.gz /usr/share/man/man5/modules.5.gz /usr/share/man/man5/modules.dep.5.gz /usr/share/man/man5/modules.dep.bin.5.gz /exports/usr/share/man/man5/ && \
  mv /usr/share/man/man7/alsactl_init.7.gz /exports/usr/share/man/man7/ && \
  mv /usr/share/man/man8/alsa-info.8.gz /usr/share/man/man8/depmod.8.gz /usr/share/man/man8/insmod.8.gz /usr/share/man/man8/kmod.8.gz /usr/share/man/man8/lsmod.8.gz /usr/share/man/man8/modinfo.8.gz /usr/share/man/man8/modprobe.8.gz /usr/share/man/man8/rmmod.8.gz /exports/usr/share/man/man8/

# APULSE
FROM base AS apulse
COPY --from=apteryx /exports/ /
RUN \
  apteryx apulse='0.1.12-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/ /exports/usr/share/doc/ /exports/usr/share/man/man1/ && \
  mv /usr/bin/apulse /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu/apulse /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libasound.so.2.0.0 /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/share/alsa /exports/usr/share/ && \
  mv /usr/share/doc/apulse /usr/share/doc/libasound2-data /usr/share/doc/libasound2 /exports/usr/share/doc/ && \
  mv /usr/share/man/man1/apulse.1.gz /exports/usr/share/man/man1/

# WACOM
FROM base AS wacom
COPY --from=apteryx /exports/ /
RUN \
  apteryx xserver-xorg-input-wacom='1:0.39.0-*'
RUN \
  mkdir -p /exports/etc/default/ /exports/etc/init.d/ /exports/etc/ /exports/etc/rc0.d/ /exports/etc/rc6.d/ /exports/etc/rcS.d/ /exports/etc/X11/ /exports/etc/X11/Xsession.d/ /exports/usr/bin/ /exports/usr/include/ /exports/usr/lib/modprobe.d/ /exports/usr/lib/systemd/network/ /exports/usr/lib/systemd/system/sockets.target.wants/ /exports/usr/lib/systemd/system/sysinit.target.wants/ /exports/usr/lib/systemd/system/ /exports/usr/lib/systemd/ /exports/usr/lib/tmpfiles.d/ /exports/usr/lib/udev/ /exports/usr/lib/udev/rules.d/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ /exports/usr/share/apport/package-hooks/ /exports/usr/share/bash-completion/completions/ /exports/usr/share/bug/ /exports/usr/share/ /exports/usr/share/doc-base/ /exports/usr/share/doc/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ /exports/usr/share/man/man3/ /exports/usr/share/man/ /exports/usr/share/man/man5/ /exports/usr/share/man/man7/ /exports/usr/share/man/man8/ /exports/usr/share/pkgconfig/ /exports/usr/share/zsh/vendor-completions/ && \
  mv /etc/default/keyboard /exports/etc/default/ && \
  mv /etc/init.d/udev /etc/init.d/x11-common /exports/etc/init.d/ && \
  mv /etc/ld.so.cache /etc/sensors.d /etc/sensors3.conf /etc/udev /etc/vulkan /exports/etc/ && \
  mv /etc/rc0.d/K01udev /exports/etc/rc0.d/ && \
  mv /etc/rc6.d/K01udev /exports/etc/rc6.d/ && \
  mv /etc/rcS.d/S01udev /etc/rcS.d/S01x11-common /exports/etc/rcS.d/ && \
  mv /etc/X11/rgb.txt /etc/X11/xkb /etc/X11/Xreset /etc/X11/Xreset.d /etc/X11/Xresources /etc/X11/Xsession /etc/X11/Xsession.options /exports/etc/X11/ && \
  mv /etc/X11/Xsession.d/20x11-common_process-args /etc/X11/Xsession.d/30x11-common_xresources /etc/X11/Xsession.d/35x11-common_xhost-local /etc/X11/Xsession.d/40x11-common_xsessionrc /etc/X11/Xsession.d/50x11-common_determine-startup /etc/X11/Xsession.d/60x11-common_localhost /etc/X11/Xsession.d/60x11-common_xdg_path /etc/X11/Xsession.d/90x11-common_ssh-agent /etc/X11/Xsession.d/99x11-common_start /exports/etc/X11/Xsession.d/ && \
  mv /usr/bin/cvt /usr/bin/gtf /usr/bin/isdv4-serial-debugger /usr/bin/isdv4-serial-inputattach /usr/bin/setxkbmap /usr/bin/systemd-hwdb /usr/bin/udevadm /usr/bin/X /usr/bin/X11 /usr/bin/xkbbell /usr/bin/xkbcomp /usr/bin/xkbevd /usr/bin/xkbprint /usr/bin/xkbvleds /usr/bin/xkbwatch /usr/bin/Xorg /usr/bin/xsetwacom /exports/usr/bin/ && \
  mv /usr/include/X11 /usr/include/xorg /exports/usr/include/ && \
  mv /usr/lib/modprobe.d/fbdev-blacklist.conf /exports/usr/lib/modprobe.d/ && \
  mv /usr/lib/systemd/network/73-usb-net-by-mac.link /usr/lib/systemd/network/99-default.link /exports/usr/lib/systemd/network/ && \
  mv /usr/lib/systemd/system/sockets.target.wants/systemd-udevd-control.socket /usr/lib/systemd/system/sockets.target.wants/systemd-udevd-kernel.socket /exports/usr/lib/systemd/system/sockets.target.wants/ && \
  mv /usr/lib/systemd/system/sysinit.target.wants/systemd-hwdb-update.service /usr/lib/systemd/system/sysinit.target.wants/systemd-udev-trigger.service /usr/lib/systemd/system/sysinit.target.wants/systemd-udevd.service /exports/usr/lib/systemd/system/sysinit.target.wants/ && \
  mv /usr/lib/systemd/system/systemd-hwdb-update.service /usr/lib/systemd/system/systemd-udev-settle.service /usr/lib/systemd/system/systemd-udev-trigger.service /usr/lib/systemd/system/systemd-udevd-control.socket /usr/lib/systemd/system/systemd-udevd-kernel.socket /usr/lib/systemd/system/systemd-udevd.service /usr/lib/systemd/system/udev.service /usr/lib/systemd/system/wacom-inputattach@.service /exports/usr/lib/systemd/system/ && \
  mv /usr/lib/systemd/systemd-udevd /exports/usr/lib/systemd/ && \
  mv /usr/lib/tmpfiles.d/static-nodes-permissions.conf /exports/usr/lib/tmpfiles.d/ && \
  mv /usr/lib/udev/ata_id /usr/lib/udev/cdrom_id /usr/lib/udev/fido_id /usr/lib/udev/hwdb.bin /usr/lib/udev/hwdb.d /usr/lib/udev/mtd_probe /usr/lib/udev/scsi_id /usr/lib/udev/v4l_id /exports/usr/lib/udev/ && \
  mv /usr/lib/udev/rules.d/40-vm-hotadd.rules /usr/lib/udev/rules.d/50-firmware.rules /usr/lib/udev/rules.d/50-udev-default.rules /usr/lib/udev/rules.d/60-autosuspend-chromiumos.rules /usr/lib/udev/rules.d/60-block.rules /usr/lib/udev/rules.d/60-cdrom_id.rules /usr/lib/udev/rules.d/60-drm.rules /usr/lib/udev/rules.d/60-evdev.rules /usr/lib/udev/rules.d/60-fido-id.rules /usr/lib/udev/rules.d/60-input-id.rules /usr/lib/udev/rules.d/60-persistent-alsa.rules /usr/lib/udev/rules.d/60-persistent-input.rules /usr/lib/udev/rules.d/60-persistent-storage-tape.rules /usr/lib/udev/rules.d/60-persistent-storage.rules /usr/lib/udev/rules.d/60-persistent-v4l.rules /usr/lib/udev/rules.d/60-sensor.rules /usr/lib/udev/rules.d/60-serial.rules /usr/lib/udev/rules.d/61-autosuspend-manual.rules /usr/lib/udev/rules.d/61-persistent-storage-android.rules /usr/lib/udev/rules.d/64-btrfs.rules /usr/lib/udev/rules.d/64-xorg-xkb.rules /usr/lib/udev/rules.d/69-wacom.rules /usr/lib/udev/rules.d/70-joystick.rules /usr/lib/udev/rules.d/70-mouse.rules /usr/lib/udev/rules.d/70-power-switch.rules /usr/lib/udev/rules.d/70-touchpad.rules /usr/lib/udev/rules.d/71-power-switch-proliant.rules /usr/lib/udev/rules.d/73-special-net-names.rules /usr/lib/udev/rules.d/75-net-description.rules /usr/lib/udev/rules.d/75-probe_mtd.rules /usr/lib/udev/rules.d/78-graphics-card.rules /usr/lib/udev/rules.d/78-sound-card.rules /usr/lib/udev/rules.d/80-debian-compat.rules /usr/lib/udev/rules.d/80-drivers.rules /usr/lib/udev/rules.d/80-net-setup-link.rules /exports/usr/lib/udev/rules.d/ && \
  mv /usr/lib/X11 /usr/lib/xorg /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/dri /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_intel.so.1 /usr/lib/x86_64-linux-gnu/libdrm_intel.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2.0.0 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1.0.1 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libEGL_mesa.so.0 /usr/lib/x86_64-linux-gnu/libEGL_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libEGL.so.1 /usr/lib/x86_64-linux-gnu/libEGL.so.1.1.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0.0.0 /usr/lib/x86_64-linux-gnu/libfontenc.so.1 /usr/lib/x86_64-linux-gnu/libfontenc.so.1.0.0 /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.17.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libGL.so.1 /usr/lib/x86_64-linux-gnu/libGL.so.1.7.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX_indirect.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0.0.0 /usr/lib/x86_64-linux-gnu/libICE.so.6 /usr/lib/x86_64-linux-gnu/libICE.so.6.3.0 /usr/lib/x86_64-linux-gnu/libLLVM-11.so /usr/lib/x86_64-linux-gnu/libLLVM-11.so.1 /usr/lib/x86_64-linux-gnu/libpciaccess.so.0 /usr/lib/x86_64-linux-gnu/libpciaccess.so.0.11.1 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0.38.4 /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.37.0 /usr/lib/x86_64-linux-gnu/libsensors.so.5 /usr/lib/x86_64-linux-gnu/libsensors.so.5.0.0 /usr/lib/x86_64-linux-gnu/libSM.so.6 /usr/lib/x86_64-linux-gnu/libSM.so.6.0.1 /usr/lib/x86_64-linux-gnu/libunwind-coredump.so.0 /usr/lib/x86_64-linux-gnu/libunwind-coredump.so.0.0.0 /usr/lib/x86_64-linux-gnu/libunwind-ptrace.so.0 /usr/lib/x86_64-linux-gnu/libunwind-ptrace.so.0.0.0 /usr/lib/x86_64-linux-gnu/libunwind-x86_64.so.8 /usr/lib/x86_64-linux-gnu/libunwind-x86_64.so.8.0.1 /usr/lib/x86_64-linux-gnu/libunwind.so.8 /usr/lib/x86_64-linux-gnu/libunwind.so.8.0.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1.2.131 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.3.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0.1.0 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1.0.0 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.3.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXaw.so.7 /usr/lib/x86_64-linux-gnu/libXaw7.so.7 /usr/lib/x86_64-linux-gnu/libXaw7.so.7.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libXfont2.so.2 /usr/lib/x86_64-linux-gnu/libXfont2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libXi.so.6 /usr/lib/x86_64-linux-gnu/libXi.so.6.1.0 /usr/lib/x86_64-linux-gnu/libXinerama.so.1 /usr/lib/x86_64-linux-gnu/libXinerama.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxkbfile.so.1 /usr/lib/x86_64-linux-gnu/libxkbfile.so.1.0.2 /usr/lib/x86_64-linux-gnu/libXmu.so.6 /usr/lib/x86_64-linux-gnu/libXmu.so.6.2.0 /usr/lib/x86_64-linux-gnu/libXpm.so.4 /usr/lib/x86_64-linux-gnu/libXpm.so.4.11.0 /usr/lib/x86_64-linux-gnu/libXrandr.so.2 /usr/lib/x86_64-linux-gnu/libXrandr.so.2.2.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXt.so.6 /usr/lib/x86_64-linux-gnu/libXt.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1.0.0 /usr/lib/x86_64-linux-gnu/perl5 /usr/lib/x86_64-linux-gnu/pkgconfig /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/bin/apteryx /exports/usr/local/bin/ && \
  mv /usr/share/apport/package-hooks/source_console-setup.py /usr/share/apport/package-hooks/udev.py /exports/usr/share/apport/package-hooks/ && \
  mv /usr/share/bash-completion/completions/udevadm /exports/usr/share/bash-completion/completions/ && \
  mv /usr/share/bug/keyboard-configuration /usr/share/bug/libegl-mesa0 /usr/share/bug/libegl1 /usr/share/bug/libgbm1 /usr/share/bug/libgl1-mesa-dri /usr/share/bug/libgl1 /usr/share/bug/libglapi-mesa /usr/share/bug/libglvnd0 /usr/share/bug/libglx-mesa0 /usr/share/bug/libglx0 /usr/share/bug/udev /usr/share/bug/xserver-xorg-core /exports/usr/share/bug/ && \
  mv /usr/share/console-setup /usr/share/drirc.d /usr/share/glvnd /usr/share/initramfs-tools /usr/share/libdrm /usr/share/X11 /exports/usr/share/ && \
  mv /usr/share/doc-base/libpng16 /exports/usr/share/doc-base/ && \
  mv /usr/share/doc/keyboard-configuration /usr/share/doc/libdrm-amdgpu1 /usr/share/doc/libdrm-common /usr/share/doc/libdrm-intel1 /usr/share/doc/libdrm-nouveau2 /usr/share/doc/libdrm-radeon1 /usr/share/doc/libdrm2 /usr/share/doc/libegl-mesa0 /usr/share/doc/libegl1 /usr/share/doc/libepoxy0 /usr/share/doc/libfontenc1 /usr/share/doc/libfreetype6 /usr/share/doc/libgbm1 /usr/share/doc/libgl1-mesa-dri /usr/share/doc/libgl1 /usr/share/doc/libglapi-mesa /usr/share/doc/libglvnd0 /usr/share/doc/libglx-mesa0 /usr/share/doc/libglx0 /usr/share/doc/libice6 /usr/share/doc/libllvm11 /usr/share/doc/liblocale-gettext-perl /usr/share/doc/libpciaccess0 /usr/share/doc/libpixman-1-0 /usr/share/doc/libpng16-16 /usr/share/doc/libsensors-config /usr/share/doc/libsensors5 /usr/share/doc/libsm6 /usr/share/doc/libunwind8 /usr/share/doc/libvulkan1 /usr/share/doc/libwayland-client0 /usr/share/doc/libwayland-server0 /usr/share/doc/libx11-6 /usr/share/doc/libx11-data /usr/share/doc/libx11-xcb1 /usr/share/doc/libxau6 /usr/share/doc/libxaw7 /usr/share/doc/libxcb-dri2-0 /usr/share/doc/libxcb-dri3-0 /usr/share/doc/libxcb-glx0 /usr/share/doc/libxcb-present0 /usr/share/doc/libxcb-sync1 /usr/share/doc/libxcb-xfixes0 /usr/share/doc/libxcb1 /usr/share/doc/libxdamage1 /usr/share/doc/libxdmcp6 /usr/share/doc/libxext6 /usr/share/doc/libxfixes3 /usr/share/doc/libxfont2 /usr/share/doc/libxi6 /usr/share/doc/libxinerama1 /usr/share/doc/libxkbfile1 /usr/share/doc/libxmu6 /usr/share/doc/libxpm4 /usr/share/doc/libxrandr2 /usr/share/doc/libxrender1 /usr/share/doc/libxshmfence1 /usr/share/doc/libxt6 /usr/share/doc/libxxf86vm1 /usr/share/doc/udev /usr/share/doc/x11-common /usr/share/doc/x11-xkb-utils /usr/share/doc/xkb-data /usr/share/doc/xserver-common /usr/share/doc/xserver-xorg-core /usr/share/doc/xserver-xorg-input-wacom /exports/usr/share/doc/ && \
  mv /usr/share/lintian/overrides/keyboard-configuration /usr/share/lintian/overrides/libdrm-nouveau2 /usr/share/lintian/overrides/libgbm1 /usr/share/lintian/overrides/libglapi-mesa /usr/share/lintian/overrides/libglvnd0 /usr/share/lintian/overrides/libllvm11 /usr/share/lintian/overrides/libpixman-1-0 /usr/share/lintian/overrides/libx11-6 /usr/share/lintian/overrides/udev /usr/share/lintian/overrides/x11-common /exports/usr/share/lintian/overrides/ && \
  mv /usr/share/man/man1/cvt.1.gz /usr/share/man/man1/gtf.1.gz /usr/share/man/man1/setxkbmap.1.gz /usr/share/man/man1/xkbbell.1.gz /usr/share/man/man1/xkbcomp.1.gz /usr/share/man/man1/xkbevd.1.gz /usr/share/man/man1/xkbprint.1.gz /usr/share/man/man1/xkbvleds.1.gz /usr/share/man/man1/xkbwatch.1.gz /usr/share/man/man1/Xorg.1.gz /usr/share/man/man1/Xserver.1.gz /usr/share/man/man1/xsetwacom.1.gz /exports/usr/share/man/man1/ && \
  mv /usr/share/man/man3/Locale::gettext.3pm.gz /exports/usr/share/man/man3/ && \
  mv /usr/share/man/man4 /exports/usr/share/man/ && \
  mv /usr/share/man/man5/Compose.5.gz /usr/share/man/man5/keyboard.5.gz /usr/share/man/man5/systemd.link.5.gz /usr/share/man/man5/udev.conf.5.gz /usr/share/man/man5/XCompose.5.gz /usr/share/man/man5/xorg.conf.5.gz /usr/share/man/man5/xorg.conf.d.5.gz /usr/share/man/man5/Xsession.5.gz /usr/share/man/man5/Xsession.options.5.gz /exports/usr/share/man/man5/ && \
  mv /usr/share/man/man7/hwdb.7.gz /usr/share/man/man7/udev.7.gz /usr/share/man/man7/xkeyboard-config.7.gz /exports/usr/share/man/man7/ && \
  mv /usr/share/man/man8/systemd-hwdb.8.gz /usr/share/man/man8/systemd-udevd-control.socket.8.gz /usr/share/man/man8/systemd-udevd-kernel.socket.8.gz /usr/share/man/man8/systemd-udevd.8.gz /usr/share/man/man8/systemd-udevd.service.8.gz /usr/share/man/man8/udevadm.8.gz /exports/usr/share/man/man8/ && \
  mv /usr/share/pkgconfig/udev.pc /usr/share/pkgconfig/xkbcomp.pc /usr/share/pkgconfig/xkeyboard-config.pc /exports/usr/share/pkgconfig/ && \
  mv /usr/share/zsh/vendor-completions/_udevadm /exports/usr/share/zsh/vendor-completions/

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
  mkdir -p /exports/etc/alternatives/ /exports/etc/ /exports/etc/cron.daily/ /exports/etc/default/ /exports/etc/init.d/ /exports/etc/rcS.d/ /exports/etc/X11/ /exports/etc/X11/Xsession.d/ /exports/opt/ /exports/usr/bin/ /exports/usr/include/ /exports/usr/lib/ /exports/usr/lib/python3/dist-packages/__pycache__/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/share/ /exports/usr/sbin/ /exports/usr/share/ /exports/usr/share/applications/ /exports/usr/share/apport/package-hooks/ /exports/usr/share/bug/ /exports/usr/share/doc-base/ /exports/usr/share/doc/ /exports/usr/share/glib-2.0/schemas/ /exports/usr/share/icons/ /exports/usr/share/icons/hicolor/ /exports/usr/share/icons/hicolor/48x48/ /exports/usr/share/icons/hicolor/48x48/apps/ /exports/usr/share/icons/hicolor/scalable/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ /exports/usr/share/man/man5/ /exports/usr/share/man/man7/ /exports/usr/share/man/man8/ /exports/usr/share/menu/ /exports/usr/share/pkgconfig/ /exports/usr/share/xml/ && \
  mv /etc/alternatives/gnome-www-browser /etc/alternatives/google-chrome /etc/alternatives/x-cursor-theme /etc/alternatives/x-www-browser /exports/etc/alternatives/ && \
  mv /etc/apparmor.d /etc/apport /etc/firefox /etc/gtk-3.0 /etc/ld.so.cache /etc/mailcap /exports/etc/ && \
  mv /etc/cron.daily/google-chrome /exports/etc/cron.daily/ && \
  mv /etc/default/google-chrome /exports/etc/default/ && \
  mv /etc/init.d/x11-common /exports/etc/init.d/ && \
  mv /etc/rcS.d/S01x11-common /exports/etc/rcS.d/ && \
  mv /etc/X11/rgb.txt /etc/X11/xkb /etc/X11/Xreset /etc/X11/Xreset.d /etc/X11/Xresources /etc/X11/Xsession /etc/X11/Xsession.options /exports/etc/X11/ && \
  mv /etc/X11/Xsession.d/20x11-common_process-args /etc/X11/Xsession.d/30x11-common_xresources /etc/X11/Xsession.d/35x11-common_xhost-local /etc/X11/Xsession.d/40x11-common_xsessionrc /etc/X11/Xsession.d/50x11-common_determine-startup /etc/X11/Xsession.d/60x11-common_localhost /etc/X11/Xsession.d/60x11-common_xdg_path /etc/X11/Xsession.d/90x11-common_ssh-agent /etc/X11/Xsession.d/99x11-common_start /exports/etc/X11/Xsession.d/ && \
  mv /opt/google /exports/opt/ && \
  mv /usr/bin/browse /usr/bin/fc-cache /usr/bin/fc-cat /usr/bin/fc-conflist /usr/bin/fc-list /usr/bin/fc-match /usr/bin/fc-pattern /usr/bin/fc-query /usr/bin/fc-scan /usr/bin/fc-validate /usr/bin/firefox /usr/bin/gnome-www-browser /usr/bin/google-chrome /usr/bin/google-chrome-stable /usr/bin/gtk-update-icon-cache /usr/bin/update-mime-database /usr/bin/x-www-browser /usr/bin/X11 /usr/bin/xdg-desktop-icon /usr/bin/xdg-desktop-menu /usr/bin/xdg-email /usr/bin/xdg-icon-resource /usr/bin/xdg-mime /usr/bin/xdg-open /usr/bin/xdg-screensaver /usr/bin/xdg-settings /exports/usr/bin/ && \
  mv /usr/include/X11 /exports/usr/include/ && \
  mv /usr/lib/firefox-addons /usr/lib/firefox /usr/lib/X11 /exports/usr/lib/ && \
  mv /usr/lib/python3/dist-packages/__pycache__/lsb_release.cpython-38.pyc /exports/usr/lib/python3/dist-packages/__pycache__/ && \
  mv /usr/lib/x86_64-linux-gnu/avahi /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0 /usr/lib/x86_64-linux-gnu/gtk-3.0 /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libasound.so.2.0.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0.23510.1 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0.0.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0.0.1 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3.2.9 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3.5.3 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcairo.so.2 /usr/lib/x86_64-linux-gnu/libcairo.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcolord.so.2 /usr/lib/x86_64-linux-gnu/libcolord.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcups.so.2 /usr/lib/x86_64-linux-gnu/libdatrie.so.1 /usr/lib/x86_64-linux-gnu/libdatrie.so.1.3.5 /usr/lib/x86_64-linux-gnu/libdbus-glib-1.so.2 /usr/lib/x86_64-linux-gnu/libdbus-glib-1.so.2.3.4 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0.0.0 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.0 /usr/lib/x86_64-linux-gnu/libfreebl3.chk /usr/lib/x86_64-linux-gnu/libfreebl3.so /usr/lib/x86_64-linux-gnu/libfreeblpriv3.chk /usr/lib/x86_64-linux-gnu/libfreeblpriv3.so /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.17.1 /usr/lib/x86_64-linux-gnu/libfribidi.so.0 /usr/lib/x86_64-linux-gnu/libfribidi.so.0.4.0 /usr/lib/x86_64-linux-gnu/libgbm.so.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf_xlib-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf_xlib-2.0.so.0.4000.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0.4000.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0.2404.16 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgtk-3-0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0.2404.16 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.20600.4 /usr/lib/x86_64-linux-gnu/libICE.so.6 /usr/lib/x86_64-linux-gnu/libICE.so.6.3.0 /usr/lib/x86_64-linux-gnu/libjbig.so.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/libjson-glib-1.0.so.0 /usr/lib/x86_64-linux-gnu/libjson-glib-1.0.so.0.400.4 /usr/lib/x86_64-linux-gnu/liblcms2.so.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2.0.8 /usr/lib/x86_64-linux-gnu/libnspr4.so /usr/lib/x86_64-linux-gnu/libnss3.so /usr/lib/x86_64-linux-gnu/libnssutil3.so /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0.4400.7 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0.4400.7 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0.4400.7 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0.38.4 /usr/lib/x86_64-linux-gnu/libplc4.so /usr/lib/x86_64-linux-gnu/libplds4.so /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.37.0 /usr/lib/x86_64-linux-gnu/librest-0.7.so.0 /usr/lib/x86_64-linux-gnu/librest-0.7.so.0.0.0 /usr/lib/x86_64-linux-gnu/librsvg-2.so.2 /usr/lib/x86_64-linux-gnu/librsvg-2.so.2.47.0 /usr/lib/x86_64-linux-gnu/libSM.so.6 /usr/lib/x86_64-linux-gnu/libSM.so.6.0.1 /usr/lib/x86_64-linux-gnu/libsmime3.so /usr/lib/x86_64-linux-gnu/libsoup-gnome-2.4.so.1 /usr/lib/x86_64-linux-gnu/libsoup-gnome-2.4.so.1.9.0 /usr/lib/x86_64-linux-gnu/libssl3.so /usr/lib/x86_64-linux-gnu/libthai.so.0 /usr/lib/x86_64-linux-gnu/libthai.so.0.3.1 /usr/lib/x86_64-linux-gnu/libtiff.so.5 /usr/lib/x86_64-linux-gnu/libtiff.so.5.5.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.3.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0.0.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.0.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0.1.0 /usr/lib/x86_64-linux-gnu/libwebp.so.6 /usr/lib/x86_64-linux-gnu/libwebp.so.6.0.2 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1.0.0 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.3.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXcursor.so.1 /usr/lib/x86_64-linux-gnu/libXcursor.so.1.0.2 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libXi.so.6 /usr/lib/x86_64-linux-gnu/libXi.so.6.1.0 /usr/lib/x86_64-linux-gnu/libXinerama.so.1 /usr/lib/x86_64-linux-gnu/libXinerama.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrandr.so.2 /usr/lib/x86_64-linux-gnu/libXrandr.so.2.2.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXt.so.6 /usr/lib/x86_64-linux-gnu/libXt.so.6.0.0 /usr/lib/x86_64-linux-gnu/nss /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/share/fonts /exports/usr/local/share/ && \
  mv /usr/sbin/update-icon-caches /exports/usr/sbin/ && \
  mv /usr/share/alsa /usr/share/appdata /usr/share/fonts /usr/share/libthai /usr/share/mime /usr/share/themes /usr/share/thumbnailers /usr/share/X11 /exports/usr/share/ && \
  mv /usr/share/applications/firefox.desktop /usr/share/applications/google-chrome.desktop /exports/usr/share/applications/ && \
  mv /usr/share/apport/package-hooks/source_firefox.py /usr/share/apport/package-hooks/source_fontconfig.py /exports/usr/share/apport/package-hooks/ && \
  mv /usr/share/bug/libgtk-3-0 /exports/usr/share/bug/ && \
  mv /usr/share/doc-base/fontconfig-user /usr/share/doc-base/libpng16 /usr/share/doc-base/shared-mime-info /exports/usr/share/doc-base/ && \
  mv /usr/share/doc/adwaita-icon-theme /usr/share/doc/firefox /usr/share/doc/fontconfig-config /usr/share/doc/fontconfig /usr/share/doc/fonts-dejavu-core /usr/share/doc/google-chrome-stable /usr/share/doc/gtk-update-icon-cache /usr/share/doc/hicolor-icon-theme /usr/share/doc/humanity-icon-theme /usr/share/doc/libatk-bridge2.0-0 /usr/share/doc/libatk1.0-0 /usr/share/doc/libatk1.0-data /usr/share/doc/libatspi2.0-0 /usr/share/doc/libavahi-client3 /usr/share/doc/libavahi-common-data /usr/share/doc/libavahi-common3 /usr/share/doc/libcairo-gobject2 /usr/share/doc/libcairo2 /usr/share/doc/libcolord2 /usr/share/doc/libcups2 /usr/share/doc/libdatrie1 /usr/share/doc/libdbus-glib-1-2 /usr/share/doc/libepoxy0 /usr/share/doc/libfontconfig1 /usr/share/doc/libfreetype6 /usr/share/doc/libfribidi0 /usr/share/doc/libgdk-pixbuf2.0-0 /usr/share/doc/libgdk-pixbuf2.0-common /usr/share/doc/libgraphite2-3 /usr/share/doc/libgtk-3-0 /usr/share/doc/libgtk-3-common /usr/share/doc/libharfbuzz0b /usr/share/doc/libice6 /usr/share/doc/libjbig0 /usr/share/doc/libjpeg-turbo8 /usr/share/doc/libjpeg8 /usr/share/doc/libjson-glib-1.0-0 /usr/share/doc/libjson-glib-1.0-common /usr/share/doc/liblcms2-2 /usr/share/doc/libpango-1.0-0 /usr/share/doc/libpangocairo-1.0-0 /usr/share/doc/libpangoft2-1.0-0 /usr/share/doc/libpixman-1-0 /usr/share/doc/libpng16-16 /usr/share/doc/librest-0.7-0 /usr/share/doc/librsvg2-2 /usr/share/doc/librsvg2-common /usr/share/doc/libsm6 /usr/share/doc/libsoup-gnome2.4-1 /usr/share/doc/libthai-data /usr/share/doc/libthai0 /usr/share/doc/libtiff5 /usr/share/doc/libwayland-client0 /usr/share/doc/libwayland-cursor0 /usr/share/doc/libwayland-egl1 /usr/share/doc/libwebp6 /usr/share/doc/libx11-6 /usr/share/doc/libx11-data /usr/share/doc/libx11-xcb1 /usr/share/doc/libxau6 /usr/share/doc/libxcb-render0 /usr/share/doc/libxcb-shm0 /usr/share/doc/libxcb1 /usr/share/doc/libxcomposite1 /usr/share/doc/libxcursor1 /usr/share/doc/libxdamage1 /usr/share/doc/libxdmcp6 /usr/share/doc/libxext6 /usr/share/doc/libxfixes3 /usr/share/doc/libxi6 /usr/share/doc/libxinerama1 /usr/share/doc/libxkbcommon0 /usr/share/doc/libxrandr2 /usr/share/doc/libxrender1 /usr/share/doc/libxt6 /usr/share/doc/shared-mime-info /usr/share/doc/ubuntu-mono /usr/share/doc/x11-common /usr/share/doc/xkb-data /exports/usr/share/doc/ && \
  mv /usr/share/glib-2.0/schemas/gschemas.compiled /usr/share/glib-2.0/schemas/org.gtk.Settings.ColorChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.EmojiChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.FileChooser.gschema.xml /exports/usr/share/glib-2.0/schemas/ && \
  mv /usr/share/icons/Adwaita /usr/share/icons/default /usr/share/icons/Humanity-Dark /usr/share/icons/Humanity /usr/share/icons/LoginIcons /usr/share/icons/ubuntu-mono-dark /usr/share/icons/ubuntu-mono-light /exports/usr/share/icons/ && \
  mv /usr/share/icons/hicolor/128x128 /usr/share/icons/hicolor/16x16 /usr/share/icons/hicolor/192x192 /usr/share/icons/hicolor/22x22 /usr/share/icons/hicolor/24x24 /usr/share/icons/hicolor/256x256 /usr/share/icons/hicolor/32x32 /usr/share/icons/hicolor/36x36 /usr/share/icons/hicolor/512x512 /usr/share/icons/hicolor/64x64 /usr/share/icons/hicolor/72x72 /usr/share/icons/hicolor/96x96 /usr/share/icons/hicolor/icon-theme.cache /usr/share/icons/hicolor/index.theme /usr/share/icons/hicolor/symbolic /exports/usr/share/icons/hicolor/ && \
  mv /usr/share/icons/hicolor/48x48/actions /usr/share/icons/hicolor/48x48/animations /usr/share/icons/hicolor/48x48/categories /usr/share/icons/hicolor/48x48/devices /usr/share/icons/hicolor/48x48/emblems /usr/share/icons/hicolor/48x48/emotes /usr/share/icons/hicolor/48x48/filesystems /usr/share/icons/hicolor/48x48/intl /usr/share/icons/hicolor/48x48/mimetypes /usr/share/icons/hicolor/48x48/places /usr/share/icons/hicolor/48x48/status /usr/share/icons/hicolor/48x48/stock /exports/usr/share/icons/hicolor/48x48/ && \
  mv /usr/share/icons/hicolor/48x48/apps/firefox.png /exports/usr/share/icons/hicolor/48x48/apps/ && \
  mv /usr/share/icons/hicolor/scalable/actions /usr/share/icons/hicolor/scalable/animations /usr/share/icons/hicolor/scalable/categories /usr/share/icons/hicolor/scalable/devices /usr/share/icons/hicolor/scalable/emblems /usr/share/icons/hicolor/scalable/emotes /usr/share/icons/hicolor/scalable/filesystems /usr/share/icons/hicolor/scalable/intl /usr/share/icons/hicolor/scalable/mimetypes /usr/share/icons/hicolor/scalable/places /usr/share/icons/hicolor/scalable/status /usr/share/icons/hicolor/scalable/stock /exports/usr/share/icons/hicolor/scalable/ && \
  mv /usr/share/lintian/overrides/firefox /usr/share/lintian/overrides/fontconfig /usr/share/lintian/overrides/hicolor-icon-theme /usr/share/lintian/overrides/libdbus-glib-1-2 /usr/share/lintian/overrides/libgdk-pixbuf2.0-0 /usr/share/lintian/overrides/libjpeg-turbo8 /usr/share/lintian/overrides/libpixman-1-0 /usr/share/lintian/overrides/librsvg2-2 /usr/share/lintian/overrides/librsvg2-common /usr/share/lintian/overrides/libsoup-gnome2.4-1 /usr/share/lintian/overrides/libtiff5 /usr/share/lintian/overrides/libx11-6 /usr/share/lintian/overrides/x11-common /exports/usr/share/lintian/overrides/ && \
  mv /usr/share/man/man1/fc-cache.1.gz /usr/share/man/man1/fc-cat.1.gz /usr/share/man/man1/fc-conflist.1.gz /usr/share/man/man1/fc-list.1.gz /usr/share/man/man1/fc-match.1.gz /usr/share/man/man1/fc-pattern.1.gz /usr/share/man/man1/fc-query.1.gz /usr/share/man/man1/fc-scan.1.gz /usr/share/man/man1/fc-validate.1.gz /usr/share/man/man1/firefox.1.gz /usr/share/man/man1/google-chrome-stable.1.gz /usr/share/man/man1/google-chrome.1.gz /usr/share/man/man1/gtk-update-icon-cache.1.gz /usr/share/man/man1/update-mime-database.1.gz /exports/usr/share/man/man1/ && \
  mv /usr/share/man/man5/Compose.5.gz /usr/share/man/man5/fonts-conf.5.gz /usr/share/man/man5/XCompose.5.gz /usr/share/man/man5/Xsession.5.gz /usr/share/man/man5/Xsession.options.5.gz /exports/usr/share/man/man5/ && \
  mv /usr/share/man/man7/xkeyboard-config.7.gz /exports/usr/share/man/man7/ && \
  mv /usr/share/man/man8/update-icon-caches.8.gz /exports/usr/share/man/man8/ && \
  mv /usr/share/menu/google-chrome.menu /exports/usr/share/menu/ && \
  mv /usr/share/pkgconfig/adwaita-icon-theme.pc /usr/share/pkgconfig/shared-mime-info.pc /usr/share/pkgconfig/xkeyboard-config.pc /exports/usr/share/pkgconfig/ && \
  mv /usr/share/xml/fontconfig /exports/usr/share/xml/

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
  mv /usr/local/bin/z.lua /exports/usr/local/bin/ && \
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

# SHELL-YARN
FROM shell-admin AS shell-yarn
COPY --from=yarn /exports/ /
USER root
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/ && \
  mv /usr/local/bin/yarn /exports/usr/local/bin/ && \
  mv /usr/local/lib/node_modules/yarn /exports/usr/local/lib/node_modules/

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
  mkdir -p /exports/usr/include/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ /exports/usr/local/bin/ /exports/usr/local/share/man/man1/ && \
  mv /usr/include/GL /usr/include/X11 /usr/include/xcb /exports/usr/include/ && \
  mv /usr/lib/x86_64-linux-gnu/libXau.a /usr/lib/x86_64-linux-gnu/libXau.so /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-ewmh.a /usr/lib/x86_64-linux-gnu/libxcb-ewmh.so /usr/lib/x86_64-linux-gnu/libxcb-ewmh.so.2 /usr/lib/x86_64-linux-gnu/libxcb-ewmh.so.2.0.0 /usr/lib/x86_64-linux-gnu/libxcb-icccm.a /usr/lib/x86_64-linux-gnu/libxcb-icccm.so /usr/lib/x86_64-linux-gnu/libxcb-icccm.so.4 /usr/lib/x86_64-linux-gnu/libxcb-icccm.so.4.0.0 /usr/lib/x86_64-linux-gnu/libxcb-keysyms.a /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so.1 /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.a /usr/lib/x86_64-linux-gnu/libxcb-randr.so /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-render.a /usr/lib/x86_64-linux-gnu/libxcb-render.so /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.a /usr/lib/x86_64-linux-gnu/libxcb-shape.so /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-util.a /usr/lib/x86_64-linux-gnu/libxcb-util.so /usr/lib/x86_64-linux-gnu/libxcb-util.so.1 /usr/lib/x86_64-linux-gnu/libxcb-util.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xinerama.a /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.a /usr/lib/x86_64-linux-gnu/libxcb.so /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.a /usr/lib/x86_64-linux-gnu/libXdmcp.so /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/lib/x86_64-linux-gnu/pkgconfig/pthread-stubs.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xau.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-atom.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-aux.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-event.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-ewmh.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-icccm.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-keysyms.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-randr.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-render.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-shape.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-util.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-xinerama.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xdmcp.pc /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ && \
  mv /usr/local/bin/bspc /usr/local/bin/bspwm /usr/local/bin/sxhkd /exports/usr/local/bin/ && \
  mv /usr/local/share/man/man1/sxhkd.1 /exports/usr/local/share/man/man1/

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

# SHELL-NPM
FROM shell-admin AS shell-npm
COPY --from=make /exports/ /
COPY --from=node /exports/ /
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
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/include/ /exports/usr/local/lib/ /exports/usr/local/ && \
  mv /usr/local/bin/n /usr/local/bin/node /usr/local/bin/npm /usr/local/bin/npx /exports/usr/local/bin/ && \
  mv /usr/local/include/node /exports/usr/local/include/ && \
  mv /usr/local/lib/node_modules /exports/usr/local/lib/ && \
  mv /usr/local/n /exports/usr/local/

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
  apteryx xclip='0.13-*'
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
  apteryx signal-desktop='5.3.0'
RUN \
  mkdir -p /exports/opt/ /exports/usr/bin/ && \
  mv /opt/Signal /exports/opt/ && \
  mv /usr/bin/signal-desktop /exports/usr/bin/

# ROFI
FROM base AS rofi
COPY --from=apteryx /exports/ /
RUN \
  apteryx rofi='1.5.4-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ && \
  mv /usr/bin/rofi /usr/bin/rofi-sensible-terminal /usr/bin/rofi-theme-selector /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# REDSHIFT
FROM base AS redshift
COPY --from=apteryx /exports/ /
RUN \
  apteryx redshift='1.12-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/ && \
  mv /usr/bin/redshift /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# QPDFVIEW
FROM base AS qpdfview
COPY --from=apteryx /exports/ /
RUN \
  apteryx qpdfview='0.4.18-*'
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
  mkdir -p /exports/etc/alternatives/ /exports/etc/ /exports/etc/init.d/ /exports/etc/rcS.d/ /exports/etc/X11/ /exports/etc/X11/Xsession.d/ /exports/usr/bin/ /exports/usr/include/ /exports/usr/lib/python3/dist-packages/__pycache__/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/gstreamer-1.0/ /exports/usr/local/bin/ /exports/usr/local/share/ /exports/usr/sbin/ /exports/usr/share/ /exports/usr/share/applications/ /exports/usr/share/apport/package-hooks/ /exports/usr/share/bug/ /exports/usr/share/dbus-1/services/ /exports/usr/share/doc-base/ /exports/usr/share/doc/ /exports/usr/share/glib-2.0/schemas/ /exports/usr/share/icons/ /exports/usr/share/icons/hicolor/ /exports/usr/share/icons/hicolor/48x48/ /exports/usr/share/icons/hicolor/scalable/ /exports/usr/share/icons/hicolor/scalable/apps/ /exports/usr/share/lintian/overrides/ /exports/usr/share/locale/ar/LC_MESSAGES/ /exports/usr/share/locale/ca/LC_MESSAGES/ /exports/usr/share/locale/cs/LC_MESSAGES/ /exports/usr/share/locale/de/LC_MESSAGES/ /exports/usr/share/locale/el/LC_MESSAGES/ /exports/usr/share/locale/ /exports/usr/share/locale/eo/LC_MESSAGES/ /exports/usr/share/locale/es/LC_MESSAGES/ /exports/usr/share/locale/eu/LC_MESSAGES/ /exports/usr/share/locale/fi/LC_MESSAGES/ /exports/usr/share/locale/fr/LC_MESSAGES/ /exports/usr/share/locale/he/LC_MESSAGES/ /exports/usr/share/locale/hr/LC_MESSAGES/ /exports/usr/share/locale/id/LC_MESSAGES/ /exports/usr/share/locale/it/LC_MESSAGES/ /exports/usr/share/locale/ja/LC_MESSAGES/ /exports/usr/share/locale/kn/LC_MESSAGES/ /exports/usr/share/locale/ko/LC_MESSAGES/ /exports/usr/share/locale/lt/LC_MESSAGES/ /exports/usr/share/locale/nb/LC_MESSAGES/ /exports/usr/share/locale/nl/LC_MESSAGES/ /exports/usr/share/locale/pl/LC_MESSAGES/ /exports/usr/share/locale/pt_BR/LC_MESSAGES/ /exports/usr/share/locale/ru/LC_MESSAGES/ /exports/usr/share/locale/sr/LC_MESSAGES/ /exports/usr/share/locale/sv/LC_MESSAGES/ /exports/usr/share/locale/tr/LC_MESSAGES/ /exports/usr/share/locale/zh_CN/LC_MESSAGES/ /exports/usr/share/locale/zh_TW/LC_MESSAGES/ /exports/usr/share/man/man1/ /exports/usr/share/man/man5/ /exports/usr/share/man/man7/ /exports/usr/share/man/man8/ /exports/usr/share/pkgconfig/ /exports/usr/share/xml/ && \
  mv /etc/alternatives/x-cursor-theme /exports/etc/alternatives/ && \
  mv /etc/gtk-3.0 /etc/ld.so.cache /etc/openal /etc/pulse /etc/sensors.d /etc/sensors3.conf /etc/vdpau_wrapper.cfg /etc/vulkan /exports/etc/ && \
  mv /etc/init.d/x11-common /exports/etc/init.d/ && \
  mv /etc/rcS.d/S01x11-common /exports/etc/rcS.d/ && \
  mv /etc/X11/rgb.txt /etc/X11/xkb /etc/X11/Xreset /etc/X11/Xreset.d /etc/X11/Xresources /etc/X11/Xsession /etc/X11/Xsession.options /exports/etc/X11/ && \
  mv /etc/X11/Xsession.d/20x11-common_process-args /etc/X11/Xsession.d/30x11-common_xresources /etc/X11/Xsession.d/35x11-common_xhost-local /etc/X11/Xsession.d/40x11-common_xsessionrc /etc/X11/Xsession.d/50x11-common_determine-startup /etc/X11/Xsession.d/60x11-common_localhost /etc/X11/Xsession.d/60x11-common_xdg_path /etc/X11/Xsession.d/90x11-common_ssh-agent /etc/X11/Xsession.d/99x11-common_start /exports/etc/X11/Xsession.d/ && \
  mv /usr/bin/fc-cache /usr/bin/fc-cat /usr/bin/fc-conflist /usr/bin/fc-list /usr/bin/fc-match /usr/bin/fc-pattern /usr/bin/fc-query /usr/bin/fc-scan /usr/bin/fc-validate /usr/bin/ffmpeg /usr/bin/ffplay /usr/bin/ffprobe /usr/bin/gtk-update-icon-cache /usr/bin/peek /usr/bin/qt-faststart /usr/bin/update-mime-database /usr/bin/X11 /exports/usr/bin/ && \
  mv /usr/include/X11 /exports/usr/include/ && \
  mv /usr/lib/python3/dist-packages/__pycache__/lsb_release.cpython-38.pyc /exports/usr/lib/python3/dist-packages/__pycache__/ && \
  mv /usr/lib/X11 /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/avahi /usr/lib/x86_64-linux-gnu/caca /usr/lib/x86_64-linux-gnu/dri /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0 /usr/lib/x86_64-linux-gnu/gtk-3.0 /usr/lib/x86_64-linux-gnu/libaa.so.1 /usr/lib/x86_64-linux-gnu/libaa.so.1.0.4 /usr/lib/x86_64-linux-gnu/libaom.so.0 /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libasound.so.2.0.0 /usr/lib/x86_64-linux-gnu/libass.so.9 /usr/lib/x86_64-linux-gnu/libass.so.9.0.2 /usr/lib/x86_64-linux-gnu/libasyncns.so.0 /usr/lib/x86_64-linux-gnu/libasyncns.so.0.3.1 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0.23510.1 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0.0.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0.0.1 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3.2.9 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3.5.3 /usr/lib/x86_64-linux-gnu/libavc1394.so.0 /usr/lib/x86_64-linux-gnu/libavc1394.so.0.3.0 /usr/lib/x86_64-linux-gnu/libavcodec.so.58 /usr/lib/x86_64-linux-gnu/libavcodec.so.58.54.100 /usr/lib/x86_64-linux-gnu/libavdevice.so.58 /usr/lib/x86_64-linux-gnu/libavdevice.so.58.8.100 /usr/lib/x86_64-linux-gnu/libavfilter.so.7 /usr/lib/x86_64-linux-gnu/libavfilter.so.7.57.100 /usr/lib/x86_64-linux-gnu/libavformat.so.58 /usr/lib/x86_64-linux-gnu/libavformat.so.58.29.100 /usr/lib/x86_64-linux-gnu/libavresample.so.4 /usr/lib/x86_64-linux-gnu/libavresample.so.4.0.0 /usr/lib/x86_64-linux-gnu/libavutil.so.56 /usr/lib/x86_64-linux-gnu/libavutil.so.56.31.100 /usr/lib/x86_64-linux-gnu/libbluray.so.2 /usr/lib/x86_64-linux-gnu/libbluray.so.2.2.0 /usr/lib/x86_64-linux-gnu/libbs2b.so.0 /usr/lib/x86_64-linux-gnu/libbs2b.so.0.0.0 /usr/lib/x86_64-linux-gnu/libcaca.so.0 /usr/lib/x86_64-linux-gnu/libcaca.so.0.99.19 /usr/lib/x86_64-linux-gnu/libcaca++.so.0 /usr/lib/x86_64-linux-gnu/libcaca++.so.0.99.19 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcairo.so.2 /usr/lib/x86_64-linux-gnu/libcairo.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcdda_interface.so.0 /usr/lib/x86_64-linux-gnu/libcdda_interface.so.0.10.2 /usr/lib/x86_64-linux-gnu/libcdda_paranoia.so.0 /usr/lib/x86_64-linux-gnu/libcdda_paranoia.so.0.10.2 /usr/lib/x86_64-linux-gnu/libcdio_cdda.so.2 /usr/lib/x86_64-linux-gnu/libcdio_cdda.so.2.0.0 /usr/lib/x86_64-linux-gnu/libcdio_paranoia.so.2 /usr/lib/x86_64-linux-gnu/libcdio_paranoia.so.2.0.0 /usr/lib/x86_64-linux-gnu/libcdio.so.18 /usr/lib/x86_64-linux-gnu/libcdio.so.18.0.0 /usr/lib/x86_64-linux-gnu/libchromaprint.so.1 /usr/lib/x86_64-linux-gnu/libchromaprint.so.1.4.3 /usr/lib/x86_64-linux-gnu/libcodec2.so.0.9 /usr/lib/x86_64-linux-gnu/libcolord.so.2 /usr/lib/x86_64-linux-gnu/libcolord.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcups.so.2 /usr/lib/x86_64-linux-gnu/libdatrie.so.1 /usr/lib/x86_64-linux-gnu/libdatrie.so.1.3.5 /usr/lib/x86_64-linux-gnu/libdc1394.so.22 /usr/lib/x86_64-linux-gnu/libdc1394.so.22.2.1 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_intel.so.1 /usr/lib/x86_64-linux-gnu/libdrm_intel.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2.0.0 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1.0.1 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libdv.so.4 /usr/lib/x86_64-linux-gnu/libdv.so.4.0.3 /usr/lib/x86_64-linux-gnu/libepoxy.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0.0.0 /usr/lib/x86_64-linux-gnu/libfftw3_omp.so.3 /usr/lib/x86_64-linux-gnu/libfftw3_omp.so.3.5.8 /usr/lib/x86_64-linux-gnu/libfftw3_threads.so.3 /usr/lib/x86_64-linux-gnu/libfftw3_threads.so.3.5.8 /usr/lib/x86_64-linux-gnu/libfftw3.so.3 /usr/lib/x86_64-linux-gnu/libfftw3.so.3.5.8 /usr/lib/x86_64-linux-gnu/libFLAC.so.8 /usr/lib/x86_64-linux-gnu/libFLAC.so.8.3.0 /usr/lib/x86_64-linux-gnu/libflite_cmu_grapheme_lang.so.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_grapheme_lang.so.2.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_grapheme_lex.so.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_grapheme_lex.so.2.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_indic_lang.so.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_indic_lang.so.2.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_indic_lex.so.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_indic_lex.so.2.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_time_awb.so.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_time_awb.so.2.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_us_awb.so.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_us_awb.so.2.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_us_kal.so.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_us_kal.so.2.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_us_kal16.so.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_us_kal16.so.2.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_us_rms.so.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_us_rms.so.2.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_us_slt.so.1 /usr/lib/x86_64-linux-gnu/libflite_cmu_us_slt.so.2.1 /usr/lib/x86_64-linux-gnu/libflite_cmulex.so.1 /usr/lib/x86_64-linux-gnu/libflite_cmulex.so.2.1 /usr/lib/x86_64-linux-gnu/libflite_usenglish.so.1 /usr/lib/x86_64-linux-gnu/libflite_usenglish.so.2.1 /usr/lib/x86_64-linux-gnu/libflite.so.1 /usr/lib/x86_64-linux-gnu/libflite.so.2.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.0 /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.17.1 /usr/lib/x86_64-linux-gnu/libfribidi.so.0 /usr/lib/x86_64-linux-gnu/libfribidi.so.0.4.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf_xlib-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf_xlib-2.0.so.0.4000.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0.4000.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0.2404.16 /usr/lib/x86_64-linux-gnu/libGL.so.1 /usr/lib/x86_64-linux-gnu/libGL.so.1.7.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX_indirect.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0.0.0 /usr/lib/x86_64-linux-gnu/libgme.so.0 /usr/lib/x86_64-linux-gnu/libgme.so.0.6.2 /usr/lib/x86_64-linux-gnu/libgomp.so.1 /usr/lib/x86_64-linux-gnu/libgomp.so.1.0.0 /usr/lib/x86_64-linux-gnu/libgpm.so.2 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgsm.so.1 /usr/lib/x86_64-linux-gnu/libgsm.so.1.0.18 /usr/lib/x86_64-linux-gnu/libgstallocators-1.0.so.0 /usr/lib/x86_64-linux-gnu/libgstallocators-1.0.so.0.1602.0 /usr/lib/x86_64-linux-gnu/libgstapp-1.0.so.0 /usr/lib/x86_64-linux-gnu/libgstapp-1.0.so.0.1602.0 /usr/lib/x86_64-linux-gnu/libgstaudio-1.0.so.0 /usr/lib/x86_64-linux-gnu/libgstaudio-1.0.so.0.1602.0 /usr/lib/x86_64-linux-gnu/libgstbasecamerabinsrc-1.0.so.0 /usr/lib/x86_64-linux-gnu/libgstbasecamerabinsrc-1.0.so.0.1602.0 /usr/lib/x86_64-linux-gnu/libgstfft-1.0.so.0 /usr/lib/x86_64-linux-gnu/libgstfft-1.0.so.0.1602.0 /usr/lib/x86_64-linux-gnu/libgstpbutils-1.0.so.0 /usr/lib/x86_64-linux-gnu/libgstpbutils-1.0.so.0.1602.0 /usr/lib/x86_64-linux-gnu/libgstphotography-1.0.so.0 /usr/lib/x86_64-linux-gnu/libgstphotography-1.0.so.0.1602.0 /usr/lib/x86_64-linux-gnu/libgstriff-1.0.so.0 /usr/lib/x86_64-linux-gnu/libgstriff-1.0.so.0.1602.0 /usr/lib/x86_64-linux-gnu/libgstrtp-1.0.so.0 /usr/lib/x86_64-linux-gnu/libgstrtp-1.0.so.0.1602.0 /usr/lib/x86_64-linux-gnu/libgstrtsp-1.0.so.0 /usr/lib/x86_64-linux-gnu/libgstrtsp-1.0.so.0.1602.0 /usr/lib/x86_64-linux-gnu/libgstsdp-1.0.so.0 /usr/lib/x86_64-linux-gnu/libgstsdp-1.0.so.0.1602.0 /usr/lib/x86_64-linux-gnu/libgsttag-1.0.so.0 /usr/lib/x86_64-linux-gnu/libgsttag-1.0.so.0.1602.0 /usr/lib/x86_64-linux-gnu/libgstvideo-1.0.so.0 /usr/lib/x86_64-linux-gnu/libgstvideo-1.0.so.0.1602.0 /usr/lib/x86_64-linux-gnu/libgtk-3-0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0.2404.16 /usr/lib/x86_64-linux-gnu/libgudev-1.0.so.0 /usr/lib/x86_64-linux-gnu/libgudev-1.0.so.0.2.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.20600.4 /usr/lib/x86_64-linux-gnu/libiec61883.so.0 /usr/lib/x86_64-linux-gnu/libiec61883.so.0.1.1 /usr/lib/x86_64-linux-gnu/libjack.so.0 /usr/lib/x86_64-linux-gnu/libjack.so.0.1.0 /usr/lib/x86_64-linux-gnu/libjacknet.so.0 /usr/lib/x86_64-linux-gnu/libjacknet.so.0.1.0 /usr/lib/x86_64-linux-gnu/libjackserver.so.0 /usr/lib/x86_64-linux-gnu/libjackserver.so.0.1.0 /usr/lib/x86_64-linux-gnu/libjbig.so.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/libjson-glib-1.0.so.0 /usr/lib/x86_64-linux-gnu/libjson-glib-1.0.so.0.400.4 /usr/lib/x86_64-linux-gnu/libkeybinder-3.0.so.0 /usr/lib/x86_64-linux-gnu/libkeybinder-3.0.so.0.0.0 /usr/lib/x86_64-linux-gnu/liblcms2.so.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2.0.8 /usr/lib/x86_64-linux-gnu/liblilv-0.so.0 /usr/lib/x86_64-linux-gnu/liblilv-0.so.0.24.6 /usr/lib/x86_64-linux-gnu/libLLVM-11.so /usr/lib/x86_64-linux-gnu/libLLVM-11.so.1 /usr/lib/x86_64-linux-gnu/libmp3lame.so.0 /usr/lib/x86_64-linux-gnu/libmp3lame.so.0.0.0 /usr/lib/x86_64-linux-gnu/libmpg123.so.0 /usr/lib/x86_64-linux-gnu/libmpg123.so.0.44.10 /usr/lib/x86_64-linux-gnu/libmysofa.so.1 /usr/lib/x86_64-linux-gnu/libmysofa.so.1.0.0 /usr/lib/x86_64-linux-gnu/libnorm.so.1 /usr/lib/x86_64-linux-gnu/libnorm.so.1.5.8 /usr/lib/x86_64-linux-gnu/libnuma.so.1 /usr/lib/x86_64-linux-gnu/libnuma.so.1.0.0 /usr/lib/x86_64-linux-gnu/libogg.so.0 /usr/lib/x86_64-linux-gnu/libogg.so.0.8.4 /usr/lib/x86_64-linux-gnu/libopenal.so.1 /usr/lib/x86_64-linux-gnu/libopenal.so.1.19.1 /usr/lib/x86_64-linux-gnu/libOpenCL.so.1 /usr/lib/x86_64-linux-gnu/libOpenCL.so.1.0.0 /usr/lib/x86_64-linux-gnu/libopenjp2.so.2.3.1 /usr/lib/x86_64-linux-gnu/libopenjp2.so.7 /usr/lib/x86_64-linux-gnu/libopenmpt.so.0 /usr/lib/x86_64-linux-gnu/libopenmpt.so.0.1.1 /usr/lib/x86_64-linux-gnu/libopus.so.0 /usr/lib/x86_64-linux-gnu/libopus.so.0.8.0 /usr/lib/x86_64-linux-gnu/liborc-0.4.so.0 /usr/lib/x86_64-linux-gnu/liborc-0.4.so.0.31.0 /usr/lib/x86_64-linux-gnu/liborc-test-0.4.so.0 /usr/lib/x86_64-linux-gnu/liborc-test-0.4.so.0.31.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0.4400.7 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0.4400.7 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0.4400.7 /usr/lib/x86_64-linux-gnu/libpciaccess.so.0 /usr/lib/x86_64-linux-gnu/libpciaccess.so.0.11.1 /usr/lib/x86_64-linux-gnu/libpgm-5.2.so.0 /usr/lib/x86_64-linux-gnu/libpgm-5.2.so.0.0.122 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0.38.4 /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.37.0 /usr/lib/x86_64-linux-gnu/libpostproc.so.55 /usr/lib/x86_64-linux-gnu/libpostproc.so.55.5.100 /usr/lib/x86_64-linux-gnu/libpulse-simple.so.0 /usr/lib/x86_64-linux-gnu/libpulse-simple.so.0.1.1 /usr/lib/x86_64-linux-gnu/libpulse.so.0 /usr/lib/x86_64-linux-gnu/libpulse.so.0.21.2 /usr/lib/x86_64-linux-gnu/libraw1394.so.11 /usr/lib/x86_64-linux-gnu/libraw1394.so.11.1.0 /usr/lib/x86_64-linux-gnu/librest-0.7.so.0 /usr/lib/x86_64-linux-gnu/librest-0.7.so.0.0.0 /usr/lib/x86_64-linux-gnu/librom1394.so.0 /usr/lib/x86_64-linux-gnu/librom1394.so.0.3.0 /usr/lib/x86_64-linux-gnu/librsvg-2.so.2 /usr/lib/x86_64-linux-gnu/librsvg-2.so.2.47.0 /usr/lib/x86_64-linux-gnu/librubberband.so.2 /usr/lib/x86_64-linux-gnu/librubberband.so.2.1.1 /usr/lib/x86_64-linux-gnu/libsamplerate.so.0 /usr/lib/x86_64-linux-gnu/libsamplerate.so.0.1.8 /usr/lib/x86_64-linux-gnu/libSDL2-2.0.so.0 /usr/lib/x86_64-linux-gnu/libSDL2-2.0.so.0.10.0 /usr/lib/x86_64-linux-gnu/libsensors.so.5 /usr/lib/x86_64-linux-gnu/libsensors.so.5.0.0 /usr/lib/x86_64-linux-gnu/libserd-0.so.0 /usr/lib/x86_64-linux-gnu/libserd-0.so.0.30.2 /usr/lib/x86_64-linux-gnu/libshine.so.3 /usr/lib/x86_64-linux-gnu/libshine.so.3.0.1 /usr/lib/x86_64-linux-gnu/libshout.so.3 /usr/lib/x86_64-linux-gnu/libshout.so.3.2.0 /usr/lib/x86_64-linux-gnu/libslang.so.2 /usr/lib/x86_64-linux-gnu/libslang.so.2.3.2 /usr/lib/x86_64-linux-gnu/libsnappy.so.1 /usr/lib/x86_64-linux-gnu/libsnappy.so.1.1.8 /usr/lib/x86_64-linux-gnu/libsndfile.so.1 /usr/lib/x86_64-linux-gnu/libsndfile.so.1.0.28 /usr/lib/x86_64-linux-gnu/libsndio.so.7.0 /usr/lib/x86_64-linux-gnu/libsodium.so.23 /usr/lib/x86_64-linux-gnu/libsodium.so.23.3.0 /usr/lib/x86_64-linux-gnu/libsord-0.so.0 /usr/lib/x86_64-linux-gnu/libsord-0.so.0.16.4 /usr/lib/x86_64-linux-gnu/libsoup-gnome-2.4.so.1 /usr/lib/x86_64-linux-gnu/libsoup-gnome-2.4.so.1.9.0 /usr/lib/x86_64-linux-gnu/libsoxr.so.0 /usr/lib/x86_64-linux-gnu/libsoxr.so.0.1.2 /usr/lib/x86_64-linux-gnu/libspeex.so.1 /usr/lib/x86_64-linux-gnu/libspeex.so.1.5.0 /usr/lib/x86_64-linux-gnu/libsratom-0.so.0 /usr/lib/x86_64-linux-gnu/libsratom-0.so.0.6.4 /usr/lib/x86_64-linux-gnu/libssh-gcrypt.so.4 /usr/lib/x86_64-linux-gnu/libssh-gcrypt.so.4.8.4 /usr/lib/x86_64-linux-gnu/libswresample.so.3 /usr/lib/x86_64-linux-gnu/libswresample.so.3.5.100 /usr/lib/x86_64-linux-gnu/libswscale.so.5 /usr/lib/x86_64-linux-gnu/libswscale.so.5.5.100 /usr/lib/x86_64-linux-gnu/libtag.so.1 /usr/lib/x86_64-linux-gnu/libtag.so.1.17.0 /usr/lib/x86_64-linux-gnu/libthai.so.0 /usr/lib/x86_64-linux-gnu/libthai.so.0.3.1 /usr/lib/x86_64-linux-gnu/libtheora.so.0 /usr/lib/x86_64-linux-gnu/libtheora.so.0.3.10 /usr/lib/x86_64-linux-gnu/libtheoradec.so.1 /usr/lib/x86_64-linux-gnu/libtheoradec.so.1.1.4 /usr/lib/x86_64-linux-gnu/libtheoraenc.so.1 /usr/lib/x86_64-linux-gnu/libtheoraenc.so.1.1.2 /usr/lib/x86_64-linux-gnu/libtiff.so.5 /usr/lib/x86_64-linux-gnu/libtiff.so.5.5.0 /usr/lib/x86_64-linux-gnu/libtwolame.so.0 /usr/lib/x86_64-linux-gnu/libtwolame.so.0.0.0 /usr/lib/x86_64-linux-gnu/libusb-1.0.so.0 /usr/lib/x86_64-linux-gnu/libusb-1.0.so.0.2.0 /usr/lib/x86_64-linux-gnu/libv4l /usr/lib/x86_64-linux-gnu/libv4l1.so.0 /usr/lib/x86_64-linux-gnu/libv4l1.so.0.0.0 /usr/lib/x86_64-linux-gnu/libv4l2.so.0 /usr/lib/x86_64-linux-gnu/libv4l2.so.0.0.0 /usr/lib/x86_64-linux-gnu/libv4lconvert.so.0 /usr/lib/x86_64-linux-gnu/libv4lconvert.so.0.0.0 /usr/lib/x86_64-linux-gnu/libv4lconvert0 /usr/lib/x86_64-linux-gnu/libva-drm.so.2 /usr/lib/x86_64-linux-gnu/libva-drm.so.2.700.0 /usr/lib/x86_64-linux-gnu/libva-x11.so.2 /usr/lib/x86_64-linux-gnu/libva-x11.so.2.700.0 /usr/lib/x86_64-linux-gnu/libva.so.2 /usr/lib/x86_64-linux-gnu/libva.so.2.700.0 /usr/lib/x86_64-linux-gnu/libvdpau.so.1 /usr/lib/x86_64-linux-gnu/libvdpau.so.1.0.0 /usr/lib/x86_64-linux-gnu/libvidstab.so.1.1 /usr/lib/x86_64-linux-gnu/libvisual-0.4.so.0 /usr/lib/x86_64-linux-gnu/libvisual-0.4.so.0.0.0 /usr/lib/x86_64-linux-gnu/libvorbis.so.0 /usr/lib/x86_64-linux-gnu/libvorbis.so.0.4.8 /usr/lib/x86_64-linux-gnu/libvorbisenc.so.2 /usr/lib/x86_64-linux-gnu/libvorbisenc.so.2.0.11 /usr/lib/x86_64-linux-gnu/libvorbisfile.so.3 /usr/lib/x86_64-linux-gnu/libvorbisfile.so.3.3.7 /usr/lib/x86_64-linux-gnu/libvpx.so.6 /usr/lib/x86_64-linux-gnu/libvpx.so.6.2 /usr/lib/x86_64-linux-gnu/libvpx.so.6.2.0 /usr/lib/x86_64-linux-gnu/libvulkan.so.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1.2.131 /usr/lib/x86_64-linux-gnu/libwavpack.so.1 /usr/lib/x86_64-linux-gnu/libwavpack.so.1.2.1 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.3.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0.0.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.0.0 /usr/lib/x86_64-linux-gnu/libwebp.so.6 /usr/lib/x86_64-linux-gnu/libwebp.so.6.0.2 /usr/lib/x86_64-linux-gnu/libwebpmux.so.3 /usr/lib/x86_64-linux-gnu/libwebpmux.so.3.0.1 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1.0.0 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.3.0 /usr/lib/x86_64-linux-gnu/libx264.so.155 /usr/lib/x86_64-linux-gnu/libx265.so.179 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXcursor.so.1 /usr/lib/x86_64-linux-gnu/libXcursor.so.1.0.2 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libXi.so.6 /usr/lib/x86_64-linux-gnu/libXi.so.6.1.0 /usr/lib/x86_64-linux-gnu/libXinerama.so.1 /usr/lib/x86_64-linux-gnu/libXinerama.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrandr.so.2 /usr/lib/x86_64-linux-gnu/libXrandr.so.2.2.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXss.so.1 /usr/lib/x86_64-linux-gnu/libXss.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXv.so.1 /usr/lib/x86_64-linux-gnu/libXv.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxvidcore.so.4 /usr/lib/x86_64-linux-gnu/libxvidcore.so.4.3 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libzmq.so.5 /usr/lib/x86_64-linux-gnu/libzmq.so.5.2.2 /usr/lib/x86_64-linux-gnu/libzvbi-chains.so.0 /usr/lib/x86_64-linux-gnu/libzvbi-chains.so.0.0.0 /usr/lib/x86_64-linux-gnu/libzvbi.so.0 /usr/lib/x86_64-linux-gnu/libzvbi.so.0.13.2 /usr/lib/x86_64-linux-gnu/pulseaudio /usr/lib/x86_64-linux-gnu/vdpau /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgst1394.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstaasink.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstadder.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstalaw.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstalpha.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstalphacolor.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstapetag.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstapp.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstaudioconvert.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstaudiofx.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstaudiomixer.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstaudioparsers.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstaudiorate.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstaudioresample.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstaudiotestsrc.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstauparse.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstautodetect.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstavi.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstcacasink.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstcairo.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstcamerabin.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstcdparanoia.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstcompositor.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstcutter.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstdebug.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstdeinterlace.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstdtmf.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstdv.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgsteffectv.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstencoding.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstequalizer.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstflac.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstflv.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstflxdec.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstgdkpixbuf.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstgio.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstgoom.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstgoom2k1.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgsticydemux.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstid3demux.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstimagefreeze.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstinterleave.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstisomp4.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstjack.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstjpeg.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstjpegformat.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstlame.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstlevel.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstlibvisual.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstmatroska.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstmonoscope.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstmpg123.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstmulaw.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstmultifile.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstmultipart.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstnavigationtest.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstogg.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstopus.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstoss4.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstossaudio.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstoverlaycomposition.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstpbtypes.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstplayback.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstpng.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstrawparse.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstreplaygain.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstrtp.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstrtpmanager.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstrtsp.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstshapewipe.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstshout2.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstsmpte.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstsoup.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstspectrum.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstspeex.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstsubparse.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgsttaglib.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgsttcp.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgsttheora.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgsttwolame.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgsttypefindfunctions.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstudp.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstvideo4linux2.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstvideobox.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstvideoconvert.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstvideocrop.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstvideofilter.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstvideomixer.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstvideorate.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstvideoscale.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstvideotestsrc.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstvolume.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstvorbis.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstvpx.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstwavenc.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstwavpack.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstwavparse.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgstximagesrc.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/libgsty4menc.so /exports/usr/lib/x86_64-linux-gnu/gstreamer-1.0/ && \
  mv /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /exports/usr/local/bin/ && \
  mv /usr/local/share/fonts /exports/usr/local/share/ && \
  mv /usr/sbin/update-icon-caches /exports/usr/sbin/ && \
  mv /usr/share/alsa /usr/share/drirc.d /usr/share/ffmpeg /usr/share/fonts /usr/share/gst-plugins-base /usr/share/gstreamer-1.0 /usr/share/libdrm /usr/share/libthai /usr/share/metainfo /usr/share/mime /usr/share/openal /usr/share/themes /usr/share/thumbnailers /usr/share/X11 /exports/usr/share/ && \
  mv /usr/share/applications/com.uploadedlobster.peek.desktop /exports/usr/share/applications/ && \
  mv /usr/share/apport/package-hooks/source_fontconfig.py /exports/usr/share/apport/package-hooks/ && \
  mv /usr/share/bug/libgl1-mesa-dri /usr/share/bug/libgl1 /usr/share/bug/libglapi-mesa /usr/share/bug/libglvnd0 /usr/share/bug/libglx-mesa0 /usr/share/bug/libglx0 /usr/share/bug/libgtk-3-0 /usr/share/bug/libvdpau1 /exports/usr/share/bug/ && \
  mv /usr/share/dbus-1/services/com.uploadedlobster.peek.service /exports/usr/share/dbus-1/services/ && \
  mv /usr/share/doc-base/fontconfig-user /usr/share/doc-base/libpng16 /usr/share/doc-base/ocl-icd-libopencl1 /usr/share/doc-base/shared-mime-info /exports/usr/share/doc-base/ && \
  mv /usr/share/doc/adwaita-icon-theme /usr/share/doc/ffmpeg /usr/share/doc/fontconfig-config /usr/share/doc/fontconfig /usr/share/doc/fonts-dejavu-core /usr/share/doc/gstreamer1.0-plugins-base /usr/share/doc/gstreamer1.0-plugins-good /usr/share/doc/gtk-update-icon-cache /usr/share/doc/hicolor-icon-theme /usr/share/doc/humanity-icon-theme /usr/share/doc/libaa1 /usr/share/doc/libaom0 /usr/share/doc/libasound2-data /usr/share/doc/libasound2 /usr/share/doc/libass9 /usr/share/doc/libasyncns0 /usr/share/doc/libatk-bridge2.0-0 /usr/share/doc/libatk1.0-0 /usr/share/doc/libatk1.0-data /usr/share/doc/libatspi2.0-0 /usr/share/doc/libavahi-client3 /usr/share/doc/libavahi-common-data /usr/share/doc/libavahi-common3 /usr/share/doc/libavc1394-0 /usr/share/doc/libavcodec58 /usr/share/doc/libavdevice58 /usr/share/doc/libavfilter7 /usr/share/doc/libavformat58 /usr/share/doc/libavresample4 /usr/share/doc/libavutil56 /usr/share/doc/libbluray2 /usr/share/doc/libbs2b0 /usr/share/doc/libcaca0 /usr/share/doc/libcairo-gobject2 /usr/share/doc/libcairo2 /usr/share/doc/libcdio-cdda2 /usr/share/doc/libcdio-paranoia2 /usr/share/doc/libcdio18 /usr/share/doc/libcdparanoia0 /usr/share/doc/libchromaprint1 /usr/share/doc/libcodec2-0.9 /usr/share/doc/libcolord2 /usr/share/doc/libcups2 /usr/share/doc/libdatrie1 /usr/share/doc/libdc1394-22 /usr/share/doc/libdrm-amdgpu1 /usr/share/doc/libdrm-common /usr/share/doc/libdrm-intel1 /usr/share/doc/libdrm-nouveau2 /usr/share/doc/libdrm-radeon1 /usr/share/doc/libdrm2 /usr/share/doc/libdv4 /usr/share/doc/libepoxy0 /usr/share/doc/libfftw3-double3 /usr/share/doc/libflac8 /usr/share/doc/libflite1 /usr/share/doc/libfontconfig1 /usr/share/doc/libfreetype6 /usr/share/doc/libfribidi0 /usr/share/doc/libgdk-pixbuf2.0-0 /usr/share/doc/libgdk-pixbuf2.0-common /usr/share/doc/libgl1-mesa-dri /usr/share/doc/libgl1 /usr/share/doc/libglapi-mesa /usr/share/doc/libglvnd0 /usr/share/doc/libglx-mesa0 /usr/share/doc/libglx0 /usr/share/doc/libgme0 /usr/share/doc/libgomp1 /usr/share/doc/libgpm2 /usr/share/doc/libgraphite2-3 /usr/share/doc/libgsm1 /usr/share/doc/libgstreamer-plugins-base1.0-0 /usr/share/doc/libgstreamer-plugins-good1.0-0 /usr/share/doc/libgtk-3-0 /usr/share/doc/libgtk-3-common /usr/share/doc/libgudev-1.0-0 /usr/share/doc/libharfbuzz0b /usr/share/doc/libiec61883-0 /usr/share/doc/libjack-jackd2-0 /usr/share/doc/libjbig0 /usr/share/doc/libjpeg-turbo8 /usr/share/doc/libjpeg8 /usr/share/doc/libjson-glib-1.0-0 /usr/share/doc/libjson-glib-1.0-common /usr/share/doc/libkeybinder-3.0-0 /usr/share/doc/liblcms2-2 /usr/share/doc/liblilv-0-0 /usr/share/doc/libllvm11 /usr/share/doc/libmp3lame0 /usr/share/doc/libmpg123-0 /usr/share/doc/libmysofa1 /usr/share/doc/libnorm1 /usr/share/doc/libnuma1 /usr/share/doc/libogg0 /usr/share/doc/libopenal-data /usr/share/doc/libopenal1 /usr/share/doc/libopenjp2-7 /usr/share/doc/libopenmpt0 /usr/share/doc/libopus0 /usr/share/doc/liborc-0.4-0 /usr/share/doc/libpango-1.0-0 /usr/share/doc/libpangocairo-1.0-0 /usr/share/doc/libpangoft2-1.0-0 /usr/share/doc/libpciaccess0 /usr/share/doc/libpgm-5.2-0 /usr/share/doc/libpixman-1-0 /usr/share/doc/libpng16-16 /usr/share/doc/libpostproc55 /usr/share/doc/libpulse0 /usr/share/doc/libraw1394-11 /usr/share/doc/librest-0.7-0 /usr/share/doc/librsvg2-2 /usr/share/doc/librsvg2-common /usr/share/doc/librubberband2 /usr/share/doc/libsamplerate0 /usr/share/doc/libsdl2-2.0-0 /usr/share/doc/libsensors-config /usr/share/doc/libsensors5 /usr/share/doc/libserd-0-0 /usr/share/doc/libshine3 /usr/share/doc/libshout3 /usr/share/doc/libslang2 /usr/share/doc/libsnappy1v5 /usr/share/doc/libsndfile1 /usr/share/doc/libsndio7.0 /usr/share/doc/libsodium23 /usr/share/doc/libsord-0-0 /usr/share/doc/libsoup-gnome2.4-1 /usr/share/doc/libsoxr0 /usr/share/doc/libspeex1 /usr/share/doc/libsratom-0-0 /usr/share/doc/libssh-gcrypt-4 /usr/share/doc/libswresample3 /usr/share/doc/libswscale5 /usr/share/doc/libtag1v5-vanilla /usr/share/doc/libtag1v5 /usr/share/doc/libthai-data /usr/share/doc/libthai0 /usr/share/doc/libtheora0 /usr/share/doc/libtiff5 /usr/share/doc/libtwolame0 /usr/share/doc/libusb-1.0-0 /usr/share/doc/libv4l-0 /usr/share/doc/libv4lconvert0 /usr/share/doc/libva-drm2 /usr/share/doc/libva-x11-2 /usr/share/doc/libva2 /usr/share/doc/libvdpau1 /usr/share/doc/libvidstab1.1 /usr/share/doc/libvisual-0.4-0 /usr/share/doc/libvorbis0a /usr/share/doc/libvorbisenc2 /usr/share/doc/libvorbisfile3 /usr/share/doc/libvpx6 /usr/share/doc/libvulkan1 /usr/share/doc/libwavpack1 /usr/share/doc/libwayland-client0 /usr/share/doc/libwayland-cursor0 /usr/share/doc/libwayland-egl1 /usr/share/doc/libwebp6 /usr/share/doc/libwebpmux3 /usr/share/doc/libx11-6 /usr/share/doc/libx11-data /usr/share/doc/libx11-xcb1 /usr/share/doc/libx264-155 /usr/share/doc/libx265-179 /usr/share/doc/libxau6 /usr/share/doc/libxcb-dri2-0 /usr/share/doc/libxcb-dri3-0 /usr/share/doc/libxcb-glx0 /usr/share/doc/libxcb-present0 /usr/share/doc/libxcb-render0 /usr/share/doc/libxcb-shape0 /usr/share/doc/libxcb-shm0 /usr/share/doc/libxcb-sync1 /usr/share/doc/libxcb-xfixes0 /usr/share/doc/libxcb1 /usr/share/doc/libxcomposite1 /usr/share/doc/libxcursor1 /usr/share/doc/libxdamage1 /usr/share/doc/libxdmcp6 /usr/share/doc/libxext6 /usr/share/doc/libxfixes3 /usr/share/doc/libxi6 /usr/share/doc/libxinerama1 /usr/share/doc/libxkbcommon0 /usr/share/doc/libxrandr2 /usr/share/doc/libxrender1 /usr/share/doc/libxshmfence1 /usr/share/doc/libxss1 /usr/share/doc/libxv1 /usr/share/doc/libxvidcore4 /usr/share/doc/libxxf86vm1 /usr/share/doc/libzmq5 /usr/share/doc/libzvbi-common /usr/share/doc/libzvbi0 /usr/share/doc/ocl-icd-libopencl1 /usr/share/doc/peek /usr/share/doc/shared-mime-info /usr/share/doc/ubuntu-mono /usr/share/doc/x11-common /usr/share/doc/xkb-data /exports/usr/share/doc/ && \
  mv /usr/share/glib-2.0/schemas/com.uploadedlobster.peek.gschema.xml /usr/share/glib-2.0/schemas/gschemas.compiled /usr/share/glib-2.0/schemas/org.gtk.Settings.ColorChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.EmojiChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.FileChooser.gschema.xml /exports/usr/share/glib-2.0/schemas/ && \
  mv /usr/share/icons/Adwaita /usr/share/icons/default /usr/share/icons/Humanity-Dark /usr/share/icons/Humanity /usr/share/icons/LoginIcons /usr/share/icons/ubuntu-mono-dark /usr/share/icons/ubuntu-mono-light /exports/usr/share/icons/ && \
  mv /usr/share/icons/hicolor/128x128 /usr/share/icons/hicolor/16x16 /usr/share/icons/hicolor/192x192 /usr/share/icons/hicolor/22x22 /usr/share/icons/hicolor/24x24 /usr/share/icons/hicolor/256x256 /usr/share/icons/hicolor/32x32 /usr/share/icons/hicolor/36x36 /usr/share/icons/hicolor/512x512 /usr/share/icons/hicolor/64x64 /usr/share/icons/hicolor/72x72 /usr/share/icons/hicolor/96x96 /usr/share/icons/hicolor/icon-theme.cache /usr/share/icons/hicolor/index.theme /usr/share/icons/hicolor/symbolic /exports/usr/share/icons/hicolor/ && \
  mv /usr/share/icons/hicolor/48x48/actions /usr/share/icons/hicolor/48x48/animations /usr/share/icons/hicolor/48x48/categories /usr/share/icons/hicolor/48x48/devices /usr/share/icons/hicolor/48x48/emblems /usr/share/icons/hicolor/48x48/emotes /usr/share/icons/hicolor/48x48/filesystems /usr/share/icons/hicolor/48x48/intl /usr/share/icons/hicolor/48x48/mimetypes /usr/share/icons/hicolor/48x48/places /usr/share/icons/hicolor/48x48/status /usr/share/icons/hicolor/48x48/stock /exports/usr/share/icons/hicolor/48x48/ && \
  mv /usr/share/icons/hicolor/scalable/actions /usr/share/icons/hicolor/scalable/animations /usr/share/icons/hicolor/scalable/categories /usr/share/icons/hicolor/scalable/devices /usr/share/icons/hicolor/scalable/emblems /usr/share/icons/hicolor/scalable/emotes /usr/share/icons/hicolor/scalable/filesystems /usr/share/icons/hicolor/scalable/intl /usr/share/icons/hicolor/scalable/mimetypes /usr/share/icons/hicolor/scalable/places /usr/share/icons/hicolor/scalable/status /usr/share/icons/hicolor/scalable/stock /exports/usr/share/icons/hicolor/scalable/ && \
  mv /usr/share/icons/hicolor/scalable/apps/com.uploadedlobster.peek.svg /exports/usr/share/icons/hicolor/scalable/apps/ && \
  mv /usr/share/lintian/overrides/ffmpeg /usr/share/lintian/overrides/fontconfig /usr/share/lintian/overrides/hicolor-icon-theme /usr/share/lintian/overrides/libavcodec58 /usr/share/lintian/overrides/libavfilter7 /usr/share/lintian/overrides/libavformat58 /usr/share/lintian/overrides/libavresample4 /usr/share/lintian/overrides/libavutil56 /usr/share/lintian/overrides/libcdparanoia0 /usr/share/lintian/overrides/libdrm-nouveau2 /usr/share/lintian/overrides/libgdk-pixbuf2.0-0 /usr/share/lintian/overrides/libglapi-mesa /usr/share/lintian/overrides/libglvnd0 /usr/share/lintian/overrides/libjack-jackd2-0 /usr/share/lintian/overrides/libjpeg-turbo8 /usr/share/lintian/overrides/libllvm11 /usr/share/lintian/overrides/libmpg123-0 /usr/share/lintian/overrides/libpixman-1-0 /usr/share/lintian/overrides/libpostproc55 /usr/share/lintian/overrides/librsvg2-2 /usr/share/lintian/overrides/librsvg2-common /usr/share/lintian/overrides/libslang2 /usr/share/lintian/overrides/libsoup-gnome2.4-1 /usr/share/lintian/overrides/libssh-gcrypt-4 /usr/share/lintian/overrides/libswresample3 /usr/share/lintian/overrides/libswscale5 /usr/share/lintian/overrides/libtag1v5-vanilla /usr/share/lintian/overrides/libtiff5 /usr/share/lintian/overrides/libv4l-0 /usr/share/lintian/overrides/libvorbis0a /usr/share/lintian/overrides/libx11-6 /usr/share/lintian/overrides/ocl-icd-libopencl1 /usr/share/lintian/overrides/x11-common /exports/usr/share/lintian/overrides/ && \
  mv /usr/share/locale/ar/LC_MESSAGES/peek.mo /exports/usr/share/locale/ar/LC_MESSAGES/ && \
  mv /usr/share/locale/ca/LC_MESSAGES/peek.mo /exports/usr/share/locale/ca/LC_MESSAGES/ && \
  mv /usr/share/locale/cs/LC_MESSAGES/peek.mo /exports/usr/share/locale/cs/LC_MESSAGES/ && \
  mv /usr/share/locale/de/LC_MESSAGES/peek.mo /usr/share/locale/de/LC_MESSAGES/zvbi.mo /exports/usr/share/locale/de/LC_MESSAGES/ && \
  mv /usr/share/locale/el/LC_MESSAGES/peek.mo /exports/usr/share/locale/el/LC_MESSAGES/ && \
  mv /usr/share/locale/en@boldquot /usr/share/locale/en@quot /usr/share/locale/nap /usr/share/locale/pt_PT /usr/share/locale/uk_UA /exports/usr/share/locale/ && \
  mv /usr/share/locale/eo/LC_MESSAGES/peek.mo /exports/usr/share/locale/eo/LC_MESSAGES/ && \
  mv /usr/share/locale/es/LC_MESSAGES/peek.mo /usr/share/locale/es/LC_MESSAGES/zvbi.mo /exports/usr/share/locale/es/LC_MESSAGES/ && \
  mv /usr/share/locale/eu/LC_MESSAGES/peek.mo /exports/usr/share/locale/eu/LC_MESSAGES/ && \
  mv /usr/share/locale/fi/LC_MESSAGES/peek.mo /exports/usr/share/locale/fi/LC_MESSAGES/ && \
  mv /usr/share/locale/fr/LC_MESSAGES/peek.mo /usr/share/locale/fr/LC_MESSAGES/zvbi.mo /exports/usr/share/locale/fr/LC_MESSAGES/ && \
  mv /usr/share/locale/he/LC_MESSAGES/peek.mo /exports/usr/share/locale/he/LC_MESSAGES/ && \
  mv /usr/share/locale/hr/LC_MESSAGES/peek.mo /exports/usr/share/locale/hr/LC_MESSAGES/ && \
  mv /usr/share/locale/id/LC_MESSAGES/peek.mo /exports/usr/share/locale/id/LC_MESSAGES/ && \
  mv /usr/share/locale/it/LC_MESSAGES/peek.mo /usr/share/locale/it/LC_MESSAGES/zvbi.mo /exports/usr/share/locale/it/LC_MESSAGES/ && \
  mv /usr/share/locale/ja/LC_MESSAGES/peek.mo /exports/usr/share/locale/ja/LC_MESSAGES/ && \
  mv /usr/share/locale/kn/LC_MESSAGES/peek.mo /exports/usr/share/locale/kn/LC_MESSAGES/ && \
  mv /usr/share/locale/ko/LC_MESSAGES/peek.mo /exports/usr/share/locale/ko/LC_MESSAGES/ && \
  mv /usr/share/locale/lt/LC_MESSAGES/peek.mo /exports/usr/share/locale/lt/LC_MESSAGES/ && \
  mv /usr/share/locale/nb/LC_MESSAGES/peek.mo /exports/usr/share/locale/nb/LC_MESSAGES/ && \
  mv /usr/share/locale/nl/LC_MESSAGES/peek.mo /usr/share/locale/nl/LC_MESSAGES/zvbi.mo /exports/usr/share/locale/nl/LC_MESSAGES/ && \
  mv /usr/share/locale/pl/LC_MESSAGES/peek.mo /usr/share/locale/pl/LC_MESSAGES/zvbi.mo /exports/usr/share/locale/pl/LC_MESSAGES/ && \
  mv /usr/share/locale/pt_BR/LC_MESSAGES/peek.mo /exports/usr/share/locale/pt_BR/LC_MESSAGES/ && \
  mv /usr/share/locale/ru/LC_MESSAGES/peek.mo /exports/usr/share/locale/ru/LC_MESSAGES/ && \
  mv /usr/share/locale/sr/LC_MESSAGES/peek.mo /exports/usr/share/locale/sr/LC_MESSAGES/ && \
  mv /usr/share/locale/sv/LC_MESSAGES/peek.mo /exports/usr/share/locale/sv/LC_MESSAGES/ && \
  mv /usr/share/locale/tr/LC_MESSAGES/peek.mo /exports/usr/share/locale/tr/LC_MESSAGES/ && \
  mv /usr/share/locale/zh_CN/LC_MESSAGES/peek.mo /exports/usr/share/locale/zh_CN/LC_MESSAGES/ && \
  mv /usr/share/locale/zh_TW/LC_MESSAGES/peek.mo /exports/usr/share/locale/zh_TW/LC_MESSAGES/ && \
  mv /usr/share/man/man1/fc-cache.1.gz /usr/share/man/man1/fc-cat.1.gz /usr/share/man/man1/fc-conflist.1.gz /usr/share/man/man1/fc-list.1.gz /usr/share/man/man1/fc-match.1.gz /usr/share/man/man1/fc-pattern.1.gz /usr/share/man/man1/fc-query.1.gz /usr/share/man/man1/fc-scan.1.gz /usr/share/man/man1/fc-validate.1.gz /usr/share/man/man1/ffmpeg-all.1.gz /usr/share/man/man1/ffmpeg-bitstream-filters.1.gz /usr/share/man/man1/ffmpeg-codecs.1.gz /usr/share/man/man1/ffmpeg-devices.1.gz /usr/share/man/man1/ffmpeg-filters.1.gz /usr/share/man/man1/ffmpeg-formats.1.gz /usr/share/man/man1/ffmpeg-protocols.1.gz /usr/share/man/man1/ffmpeg-resampler.1.gz /usr/share/man/man1/ffmpeg-scaler.1.gz /usr/share/man/man1/ffmpeg-utils.1.gz /usr/share/man/man1/ffmpeg.1.gz /usr/share/man/man1/ffplay-all.1.gz /usr/share/man/man1/ffplay.1.gz /usr/share/man/man1/ffprobe-all.1.gz /usr/share/man/man1/ffprobe.1.gz /usr/share/man/man1/gtk-update-icon-cache.1.gz /usr/share/man/man1/peek.1.gz /usr/share/man/man1/qt-faststart.1.gz /usr/share/man/man1/update-mime-database.1.gz /exports/usr/share/man/man1/ && \
  mv /usr/share/man/man5/Compose.5.gz /usr/share/man/man5/fonts-conf.5.gz /usr/share/man/man5/XCompose.5.gz /usr/share/man/man5/Xsession.5.gz /usr/share/man/man5/Xsession.options.5.gz /exports/usr/share/man/man5/ && \
  mv /usr/share/man/man7/libOpenCL.7.gz /usr/share/man/man7/libOpenCL.so.7.gz /usr/share/man/man7/xkeyboard-config.7.gz /exports/usr/share/man/man7/ && \
  mv /usr/share/man/man8/update-icon-caches.8.gz /exports/usr/share/man/man8/ && \
  mv /usr/share/pkgconfig/adwaita-icon-theme.pc /usr/share/pkgconfig/shared-mime-info.pc /usr/share/pkgconfig/xkeyboard-config.pc /exports/usr/share/pkgconfig/ && \
  mv /usr/share/xml/fontconfig /exports/usr/share/xml/

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
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/share/man/man1/ && \
  mv /usr/local/bin/light /exports/usr/local/bin/ && \
  mv /usr/local/share/man/man1/light.1 /exports/usr/local/share/man/man1/

# FONTS
FROM base AS fonts
COPY --from=clone /exports/ /
COPY --from=apteryx /exports/ /
COPY --from=wget /exports/ /
RUN \
  apteryx fontconfig='2.13.1-*' fonts-noto fonts-noto-cjk fonts-noto-color-emoji ttf-ubuntu-font-family xfonts-utils && \
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
COPY --from=wget /exports/ /
COPY --from=apteryx /exports/ /
RUN \
  wget -O flameshot.deb https://github.com/flameshot-org/flameshot/releases/download/v0.9.0/flameshot-0.9.0-1.ubuntu-20.04.amd64.deb && \
  apteryx ./flameshot.deb && \
  rm flameshot.deb
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/applications/ /exports/usr/share/bash-completion/completions/ /exports/usr/share/dbus-1/interfaces/ /exports/usr/share/dbus-1/services/ /exports/usr/share/doc/ /exports/usr/share/ /exports/usr/share/icons/hicolor/48x48/apps/ /exports/usr/share/icons/hicolor/scalable/apps/ && \
  mv /usr/bin/flameshot /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu/dri /usr/lib/x86_64-linux-gnu/libdouble-conversion.so.3 /usr/lib/x86_64-linux-gnu/libdouble-conversion.so.3.1 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_intel.so.1 /usr/lib/x86_64-linux-gnu/libdrm_intel.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2.0.0 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1.0.1 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libEGL_mesa.so.0 /usr/lib/x86_64-linux-gnu/libEGL_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libEGL.so.1 /usr/lib/x86_64-linux-gnu/libEGL.so.1.1.0 /usr/lib/x86_64-linux-gnu/libevdev.so.2 /usr/lib/x86_64-linux-gnu/libevdev.so.2.3.0 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.0 /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.17.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libGL.so.1 /usr/lib/x86_64-linux-gnu/libGL.so.1.7.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX_indirect.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgudev-1.0.so.0 /usr/lib/x86_64-linux-gnu/libgudev-1.0.so.0.2.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.20600.4 /usr/lib/x86_64-linux-gnu/libICE.so.6 /usr/lib/x86_64-linux-gnu/libICE.so.6.3.0 /usr/lib/x86_64-linux-gnu/libinput.so.10 /usr/lib/x86_64-linux-gnu/libinput.so.10.13.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/libLLVM-11.so /usr/lib/x86_64-linux-gnu/libLLVM-11.so.1 /usr/lib/x86_64-linux-gnu/libmtdev.so.1 /usr/lib/x86_64-linux-gnu/libmtdev.so.1.0.0 /usr/lib/x86_64-linux-gnu/libpciaccess.so.0 /usr/lib/x86_64-linux-gnu/libpciaccess.so.0.11.1 /usr/lib/x86_64-linux-gnu/libpcre2-16.so.0 /usr/lib/x86_64-linux-gnu/libpcre2-16.so.0.9.0 /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.37.0 /usr/lib/x86_64-linux-gnu/libQt5Core.so.5 /usr/lib/x86_64-linux-gnu/libQt5Core.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5Core.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5DBus.so.5 /usr/lib/x86_64-linux-gnu/libQt5DBus.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5DBus.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5EglFSDeviceIntegration.so.5 /usr/lib/x86_64-linux-gnu/libQt5EglFSDeviceIntegration.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5EglFSDeviceIntegration.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5EglFsKmsSupport.so.5 /usr/lib/x86_64-linux-gnu/libQt5EglFsKmsSupport.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5EglFsKmsSupport.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5Gui.so.5 /usr/lib/x86_64-linux-gnu/libQt5Gui.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5Gui.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5Network.so.5 /usr/lib/x86_64-linux-gnu/libQt5Network.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5Network.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5Svg.so.5 /usr/lib/x86_64-linux-gnu/libQt5Svg.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5Svg.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5Widgets.so.5 /usr/lib/x86_64-linux-gnu/libQt5Widgets.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5Widgets.so.5.12.8 /usr/lib/x86_64-linux-gnu/libQt5XcbQpa.so.5 /usr/lib/x86_64-linux-gnu/libQt5XcbQpa.so.5.12 /usr/lib/x86_64-linux-gnu/libQt5XcbQpa.so.5.12.8 /usr/lib/x86_64-linux-gnu/libsensors.so.5 /usr/lib/x86_64-linux-gnu/libsensors.so.5.0.0 /usr/lib/x86_64-linux-gnu/libSM.so.6 /usr/lib/x86_64-linux-gnu/libSM.so.6.0.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1.2.131 /usr/lib/x86_64-linux-gnu/libwacom.so.2 /usr/lib/x86_64-linux-gnu/libwacom.so.2.6.1 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.3.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0.1.0 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1.0.0 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.3.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-icccm.so.4 /usr/lib/x86_64-linux-gnu/libxcb-icccm.so.4.0.0 /usr/lib/x86_64-linux-gnu/libxcb-image.so.0 /usr/lib/x86_64-linux-gnu/libxcb-image.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so.1 /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-render-util.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render-util.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-util.so.1 /usr/lib/x86_64-linux-gnu/libxcb-util.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xinput.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xinput.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-xkb.so.1 /usr/lib/x86_64-linux-gnu/libxcb-xkb.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libxkbcommon-x11.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon-x11.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1.0.0 /usr/lib/x86_64-linux-gnu/qt-default /usr/lib/x86_64-linux-gnu/qt5 /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/share/applications/org.flameshot.Flameshot.desktop /exports/usr/share/applications/ && \
  mv /usr/share/bash-completion/completions/flameshot /exports/usr/share/bash-completion/completions/ && \
  mv /usr/share/dbus-1/interfaces/org.flameshot.Flameshot.xml /exports/usr/share/dbus-1/interfaces/ && \
  mv /usr/share/dbus-1/services/org.flameshot.Flameshot.service /exports/usr/share/dbus-1/services/ && \
  mv /usr/share/doc/flameshot /exports/usr/share/doc/ && \
  mv /usr/share/flameshot /exports/usr/share/ && \
  mv /usr/share/icons/hicolor/48x48/apps/flameshot.png /usr/share/icons/hicolor/48x48/apps/org.flameshot.Flameshot.png /exports/usr/share/icons/hicolor/48x48/apps/ && \
  mv /usr/share/icons/hicolor/scalable/apps/flameshot.svg /usr/share/icons/hicolor/scalable/apps/org.flameshot.Flameshot.svg /exports/usr/share/icons/hicolor/scalable/apps/

# FEH
FROM base AS feh
COPY --from=apteryx /exports/ /
COPY --from=wget /exports/ /
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
  apteryx audacity='2.3.3-*'
RUN \
  mkdir -p /exports/etc/alternatives/ /exports/etc/ /exports/etc/init.d/ /exports/etc/rcS.d/ /exports/etc/X11/ /exports/etc/X11/Xsession.d/ /exports/usr/bin/ /exports/usr/include/ /exports/usr/lib/mime/packages/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/share/ /exports/usr/sbin/ /exports/usr/share/ /exports/usr/share/applications/ /exports/usr/share/apport/package-hooks/ /exports/usr/share/bug/ /exports/usr/share/doc-base/ /exports/usr/share/doc/ /exports/usr/share/glib-2.0/schemas/ /exports/usr/share/icons/ /exports/usr/share/icons/hicolor/ /exports/usr/share/icons/hicolor/48x48/ /exports/usr/share/icons/hicolor/48x48/apps/ /exports/usr/share/icons/hicolor/scalable/ /exports/usr/share/icons/hicolor/scalable/apps/ /exports/usr/share/lintian/overrides/ /exports/usr/share/locale/af/LC_MESSAGES/ /exports/usr/share/locale/ar/LC_MESSAGES/ /exports/usr/share/locale/be/LC_MESSAGES/ /exports/usr/share/locale/bg/LC_MESSAGES/ /exports/usr/share/locale/bn/LC_MESSAGES/ /exports/usr/share/locale/bs/LC_MESSAGES/ /exports/usr/share/locale/ /exports/usr/share/locale/ca/LC_MESSAGES/ /exports/usr/share/locale/cs/LC_MESSAGES/ /exports/usr/share/locale/cy/LC_MESSAGES/ /exports/usr/share/locale/da/LC_MESSAGES/ /exports/usr/share/locale/de/LC_MESSAGES/ /exports/usr/share/locale/el/LC_MESSAGES/ /exports/usr/share/locale/es/LC_MESSAGES/ /exports/usr/share/locale/eu/LC_MESSAGES/ /exports/usr/share/locale/fa/LC_MESSAGES/ /exports/usr/share/locale/fi/LC_MESSAGES/ /exports/usr/share/locale/fr/LC_MESSAGES/ /exports/usr/share/locale/ga/LC_MESSAGES/ /exports/usr/share/locale/gl/LC_MESSAGES/ /exports/usr/share/locale/he/LC_MESSAGES/ /exports/usr/share/locale/hi/LC_MESSAGES/ /exports/usr/share/locale/hr/LC_MESSAGES/ /exports/usr/share/locale/hu/LC_MESSAGES/ /exports/usr/share/locale/hy/LC_MESSAGES/ /exports/usr/share/locale/id/LC_MESSAGES/ /exports/usr/share/locale/it/LC_MESSAGES/ /exports/usr/share/locale/ja/LC_MESSAGES/ /exports/usr/share/locale/ka/LC_MESSAGES/ /exports/usr/share/locale/km/LC_MESSAGES/ /exports/usr/share/locale/ko/LC_MESSAGES/ /exports/usr/share/locale/lt/LC_MESSAGES/ /exports/usr/share/locale/mk/LC_MESSAGES/ /exports/usr/share/locale/my/LC_MESSAGES/ /exports/usr/share/locale/nb/LC_MESSAGES/ /exports/usr/share/locale/nl/LC_MESSAGES/ /exports/usr/share/locale/oc/LC_MESSAGES/ /exports/usr/share/locale/pl/LC_MESSAGES/ /exports/usr/share/locale/pt_BR/LC_MESSAGES/ /exports/usr/share/locale/ro/LC_MESSAGES/ /exports/usr/share/locale/ru/LC_MESSAGES/ /exports/usr/share/locale/sk/LC_MESSAGES/ /exports/usr/share/locale/sl/LC_MESSAGES/ /exports/usr/share/locale/sv/LC_MESSAGES/ /exports/usr/share/locale/ta/LC_MESSAGES/ /exports/usr/share/locale/tg/LC_MESSAGES/ /exports/usr/share/locale/tr/LC_MESSAGES/ /exports/usr/share/locale/uk/LC_MESSAGES/ /exports/usr/share/locale/vi/LC_MESSAGES/ /exports/usr/share/locale/zh_CN/LC_MESSAGES/ /exports/usr/share/locale/zh_TW/LC_MESSAGES/ /exports/usr/share/man/man1/ /exports/usr/share/man/man5/ /exports/usr/share/man/man7/ /exports/usr/share/man/man8/ /exports/usr/share/pixmaps/ /exports/usr/share/pkgconfig/ /exports/usr/share/xml/ && \
  mv /etc/alternatives/x-cursor-theme /exports/etc/alternatives/ && \
  mv /etc/gtk-3.0 /etc/ld.so.cache /etc/mailcap /etc/sensors.d /etc/sensors3.conf /etc/vdpau_wrapper.cfg /etc/vulkan /exports/etc/ && \
  mv /etc/init.d/x11-common /exports/etc/init.d/ && \
  mv /etc/rcS.d/S01x11-common /exports/etc/rcS.d/ && \
  mv /etc/X11/rgb.txt /etc/X11/xkb /etc/X11/Xreset /etc/X11/Xreset.d /etc/X11/Xresources /etc/X11/Xsession /etc/X11/Xsession.options /exports/etc/X11/ && \
  mv /etc/X11/Xsession.d/20x11-common_process-args /etc/X11/Xsession.d/30x11-common_xresources /etc/X11/Xsession.d/35x11-common_xhost-local /etc/X11/Xsession.d/40x11-common_xsessionrc /etc/X11/Xsession.d/50x11-common_determine-startup /etc/X11/Xsession.d/60x11-common_localhost /etc/X11/Xsession.d/60x11-common_xdg_path /etc/X11/Xsession.d/90x11-common_ssh-agent /etc/X11/Xsession.d/99x11-common_start /exports/etc/X11/Xsession.d/ && \
  mv /usr/bin/audacity /usr/bin/fc-cache /usr/bin/fc-cat /usr/bin/fc-conflist /usr/bin/fc-list /usr/bin/fc-match /usr/bin/fc-pattern /usr/bin/fc-query /usr/bin/fc-scan /usr/bin/fc-validate /usr/bin/gtk-update-icon-cache /usr/bin/update-mime-database /usr/bin/X11 /exports/usr/bin/ && \
  mv /usr/include/X11 /exports/usr/include/ && \
  mv /usr/lib/mime/packages/audacity /exports/usr/lib/mime/packages/ && \
  mv /usr/lib/X11 /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/avahi /usr/lib/x86_64-linux-gnu/dri /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0 /usr/lib/x86_64-linux-gnu/gtk-3.0 /usr/lib/x86_64-linux-gnu/libaom.so.0 /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libasound.so.2.0.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0.23510.1 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0.0.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0.0.1 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3.2.9 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3.5.3 /usr/lib/x86_64-linux-gnu/libavcodec.so.58 /usr/lib/x86_64-linux-gnu/libavcodec.so.58.54.100 /usr/lib/x86_64-linux-gnu/libavformat.so.58 /usr/lib/x86_64-linux-gnu/libavformat.so.58.29.100 /usr/lib/x86_64-linux-gnu/libavutil.so.56 /usr/lib/x86_64-linux-gnu/libavutil.so.56.31.100 /usr/lib/x86_64-linux-gnu/libbluray.so.2 /usr/lib/x86_64-linux-gnu/libbluray.so.2.2.0 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcairo.so.2 /usr/lib/x86_64-linux-gnu/libcairo.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libchromaprint.so.1 /usr/lib/x86_64-linux-gnu/libchromaprint.so.1.4.3 /usr/lib/x86_64-linux-gnu/libcodec2.so.0.9 /usr/lib/x86_64-linux-gnu/libcolord.so.2 /usr/lib/x86_64-linux-gnu/libcolord.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcups.so.2 /usr/lib/x86_64-linux-gnu/libdatrie.so.1 /usr/lib/x86_64-linux-gnu/libdatrie.so.1.3.5 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_intel.so.1 /usr/lib/x86_64-linux-gnu/libdrm_intel.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2.0.0 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1.0.1 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0.0.0 /usr/lib/x86_64-linux-gnu/libFLAC.so.8 /usr/lib/x86_64-linux-gnu/libFLAC.so.8.3.0 /usr/lib/x86_64-linux-gnu/libFLAC++.so.6 /usr/lib/x86_64-linux-gnu/libFLAC++.so.6.3.0 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.0 /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.17.1 /usr/lib/x86_64-linux-gnu/libfribidi.so.0 /usr/lib/x86_64-linux-gnu/libfribidi.so.0.4.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf_xlib-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf_xlib-2.0.so.0.4000.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0.4000.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0.2404.16 /usr/lib/x86_64-linux-gnu/libGL.so.1 /usr/lib/x86_64-linux-gnu/libGL.so.1.7.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX_indirect.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0.0.0 /usr/lib/x86_64-linux-gnu/libgme.so.0 /usr/lib/x86_64-linux-gnu/libgme.so.0.6.2 /usr/lib/x86_64-linux-gnu/libgomp.so.1 /usr/lib/x86_64-linux-gnu/libgomp.so.1.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgsm.so.1 /usr/lib/x86_64-linux-gnu/libgsm.so.1.0.18 /usr/lib/x86_64-linux-gnu/libgtk-3-0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0.2404.16 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.20600.4 /usr/lib/x86_64-linux-gnu/libICE.so.6 /usr/lib/x86_64-linux-gnu/libICE.so.6.3.0 /usr/lib/x86_64-linux-gnu/libid3tag.so.0 /usr/lib/x86_64-linux-gnu/libid3tag.so.0.3.0 /usr/lib/x86_64-linux-gnu/libjack.so.0 /usr/lib/x86_64-linux-gnu/libjack.so.0.1.0 /usr/lib/x86_64-linux-gnu/libjacknet.so.0 /usr/lib/x86_64-linux-gnu/libjacknet.so.0.1.0 /usr/lib/x86_64-linux-gnu/libjackserver.so.0 /usr/lib/x86_64-linux-gnu/libjackserver.so.0.1.0 /usr/lib/x86_64-linux-gnu/libjbig.so.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/libjson-glib-1.0.so.0 /usr/lib/x86_64-linux-gnu/libjson-glib-1.0.so.0.400.4 /usr/lib/x86_64-linux-gnu/liblcms2.so.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2.0.8 /usr/lib/x86_64-linux-gnu/liblilv-0.so.0 /usr/lib/x86_64-linux-gnu/liblilv-0.so.0.24.6 /usr/lib/x86_64-linux-gnu/libLLVM-11.so /usr/lib/x86_64-linux-gnu/libLLVM-11.so.1 /usr/lib/x86_64-linux-gnu/libmad.so.0 /usr/lib/x86_64-linux-gnu/libmad.so.0.2.1 /usr/lib/x86_64-linux-gnu/libmp3lame.so.0 /usr/lib/x86_64-linux-gnu/libmp3lame.so.0.0.0 /usr/lib/x86_64-linux-gnu/libmpg123.so.0 /usr/lib/x86_64-linux-gnu/libmpg123.so.0.44.10 /usr/lib/x86_64-linux-gnu/libnotify.so.4 /usr/lib/x86_64-linux-gnu/libnotify.so.4.0.0 /usr/lib/x86_64-linux-gnu/libnuma.so.1 /usr/lib/x86_64-linux-gnu/libnuma.so.1.0.0 /usr/lib/x86_64-linux-gnu/libogg.so.0 /usr/lib/x86_64-linux-gnu/libogg.so.0.8.4 /usr/lib/x86_64-linux-gnu/libOpenCL.so.1 /usr/lib/x86_64-linux-gnu/libOpenCL.so.1.0.0 /usr/lib/x86_64-linux-gnu/libopenjp2.so.2.3.1 /usr/lib/x86_64-linux-gnu/libopenjp2.so.7 /usr/lib/x86_64-linux-gnu/libopenmpt.so.0 /usr/lib/x86_64-linux-gnu/libopenmpt.so.0.1.1 /usr/lib/x86_64-linux-gnu/libopus.so.0 /usr/lib/x86_64-linux-gnu/libopus.so.0.8.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0.4400.7 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0.4400.7 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0.4400.7 /usr/lib/x86_64-linux-gnu/libpciaccess.so.0 /usr/lib/x86_64-linux-gnu/libpciaccess.so.0.11.1 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0.38.4 /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.37.0 /usr/lib/x86_64-linux-gnu/libportaudio.so.2 /usr/lib/x86_64-linux-gnu/libportaudio.so.2.0.0 /usr/lib/x86_64-linux-gnu/libportSMF.so.0 /usr/lib/x86_64-linux-gnu/libportSMF.so.0.0.0 /usr/lib/x86_64-linux-gnu/librest-0.7.so.0 /usr/lib/x86_64-linux-gnu/librest-0.7.so.0.0.0 /usr/lib/x86_64-linux-gnu/librsvg-2.so.2 /usr/lib/x86_64-linux-gnu/librsvg-2.so.2.47.0 /usr/lib/x86_64-linux-gnu/libsamplerate.so.0 /usr/lib/x86_64-linux-gnu/libsamplerate.so.0.1.8 /usr/lib/x86_64-linux-gnu/libsensors.so.5 /usr/lib/x86_64-linux-gnu/libsensors.so.5.0.0 /usr/lib/x86_64-linux-gnu/libserd-0.so.0 /usr/lib/x86_64-linux-gnu/libserd-0.so.0.30.2 /usr/lib/x86_64-linux-gnu/libshine.so.3 /usr/lib/x86_64-linux-gnu/libshine.so.3.0.1 /usr/lib/x86_64-linux-gnu/libSM.so.6 /usr/lib/x86_64-linux-gnu/libSM.so.6.0.1 /usr/lib/x86_64-linux-gnu/libsnappy.so.1 /usr/lib/x86_64-linux-gnu/libsnappy.so.1.1.8 /usr/lib/x86_64-linux-gnu/libsndfile.so.1 /usr/lib/x86_64-linux-gnu/libsndfile.so.1.0.28 /usr/lib/x86_64-linux-gnu/libsord-0.so.0 /usr/lib/x86_64-linux-gnu/libsord-0.so.0.16.4 /usr/lib/x86_64-linux-gnu/libSoundTouch.so.1 /usr/lib/x86_64-linux-gnu/libSoundTouch.so.1.0.0 /usr/lib/x86_64-linux-gnu/libsoup-gnome-2.4.so.1 /usr/lib/x86_64-linux-gnu/libsoup-gnome-2.4.so.1.9.0 /usr/lib/x86_64-linux-gnu/libsoxr.so.0 /usr/lib/x86_64-linux-gnu/libsoxr.so.0.1.2 /usr/lib/x86_64-linux-gnu/libspeex.so.1 /usr/lib/x86_64-linux-gnu/libspeex.so.1.5.0 /usr/lib/x86_64-linux-gnu/libsratom-0.so.0 /usr/lib/x86_64-linux-gnu/libsratom-0.so.0.6.4 /usr/lib/x86_64-linux-gnu/libssh-gcrypt.so.4 /usr/lib/x86_64-linux-gnu/libssh-gcrypt.so.4.8.4 /usr/lib/x86_64-linux-gnu/libsuil-0.so.0 /usr/lib/x86_64-linux-gnu/libsuil-0.so.0.10.6 /usr/lib/x86_64-linux-gnu/libswresample.so.3 /usr/lib/x86_64-linux-gnu/libswresample.so.3.5.100 /usr/lib/x86_64-linux-gnu/libthai.so.0 /usr/lib/x86_64-linux-gnu/libthai.so.0.3.1 /usr/lib/x86_64-linux-gnu/libtheora.so.0 /usr/lib/x86_64-linux-gnu/libtheora.so.0.3.10 /usr/lib/x86_64-linux-gnu/libtheoradec.so.1 /usr/lib/x86_64-linux-gnu/libtheoradec.so.1.1.4 /usr/lib/x86_64-linux-gnu/libtheoraenc.so.1 /usr/lib/x86_64-linux-gnu/libtheoraenc.so.1.1.2 /usr/lib/x86_64-linux-gnu/libtiff.so.5 /usr/lib/x86_64-linux-gnu/libtiff.so.5.5.0 /usr/lib/x86_64-linux-gnu/libtwolame.so.0 /usr/lib/x86_64-linux-gnu/libtwolame.so.0.0.0 /usr/lib/x86_64-linux-gnu/libva-drm.so.2 /usr/lib/x86_64-linux-gnu/libva-drm.so.2.700.0 /usr/lib/x86_64-linux-gnu/libva-x11.so.2 /usr/lib/x86_64-linux-gnu/libva-x11.so.2.700.0 /usr/lib/x86_64-linux-gnu/libva.so.2 /usr/lib/x86_64-linux-gnu/libva.so.2.700.0 /usr/lib/x86_64-linux-gnu/libvamp-hostsdk.so.3 /usr/lib/x86_64-linux-gnu/libvamp-hostsdk.so.3.9.0 /usr/lib/x86_64-linux-gnu/libvdpau.so.1 /usr/lib/x86_64-linux-gnu/libvdpau.so.1.0.0 /usr/lib/x86_64-linux-gnu/libvorbis.so.0 /usr/lib/x86_64-linux-gnu/libvorbis.so.0.4.8 /usr/lib/x86_64-linux-gnu/libvorbisenc.so.2 /usr/lib/x86_64-linux-gnu/libvorbisenc.so.2.0.11 /usr/lib/x86_64-linux-gnu/libvorbisfile.so.3 /usr/lib/x86_64-linux-gnu/libvorbisfile.so.3.3.7 /usr/lib/x86_64-linux-gnu/libvpx.so.6 /usr/lib/x86_64-linux-gnu/libvpx.so.6.2 /usr/lib/x86_64-linux-gnu/libvpx.so.6.2.0 /usr/lib/x86_64-linux-gnu/libvulkan.so.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1.2.131 /usr/lib/x86_64-linux-gnu/libwavpack.so.1 /usr/lib/x86_64-linux-gnu/libwavpack.so.1.2.1 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.3.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0.0.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.0.0 /usr/lib/x86_64-linux-gnu/libwebp.so.6 /usr/lib/x86_64-linux-gnu/libwebp.so.6.0.2 /usr/lib/x86_64-linux-gnu/libwebpmux.so.3 /usr/lib/x86_64-linux-gnu/libwebpmux.so.3.0.1 /usr/lib/x86_64-linux-gnu/libwx_baseu_net-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_baseu_net-3.0.so.0.4.0 /usr/lib/x86_64-linux-gnu/libwx_baseu_xml-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_baseu_xml-3.0.so.0.4.0 /usr/lib/x86_64-linux-gnu/libwx_baseu-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_baseu-3.0.so.0.4.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_adv-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_adv-3.0.so.0.4.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_aui-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_aui-3.0.so.0.4.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_core-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_core-3.0.so.0.4.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_gl-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_gl-3.0.so.0.4.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_html-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_html-3.0.so.0.4.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_propgrid-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_propgrid-3.0.so.0.4.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_qa-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_qa-3.0.so.0.4.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_ribbon-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_ribbon-3.0.so.0.4.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_richtext-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_richtext-3.0.so.0.4.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_stc-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_stc-3.0.so.0.4.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_xrc-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_xrc-3.0.so.0.4.0 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1.0.0 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.3.0 /usr/lib/x86_64-linux-gnu/libx264.so.155 /usr/lib/x86_64-linux-gnu/libx265.so.179 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXcursor.so.1 /usr/lib/x86_64-linux-gnu/libXcursor.so.1.0.2 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libXi.so.6 /usr/lib/x86_64-linux-gnu/libXi.so.6.1.0 /usr/lib/x86_64-linux-gnu/libXinerama.so.1 /usr/lib/x86_64-linux-gnu/libXinerama.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrandr.so.2 /usr/lib/x86_64-linux-gnu/libXrandr.so.2.2.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxvidcore.so.4 /usr/lib/x86_64-linux-gnu/libxvidcore.so.4.3 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libzvbi-chains.so.0 /usr/lib/x86_64-linux-gnu/libzvbi-chains.so.0.0.0 /usr/lib/x86_64-linux-gnu/libzvbi.so.0 /usr/lib/x86_64-linux-gnu/libzvbi.so.0.13.2 /usr/lib/x86_64-linux-gnu/suil-0 /usr/lib/x86_64-linux-gnu/vdpau /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/share/fonts /exports/usr/local/share/ && \
  mv /usr/sbin/update-icon-caches /exports/usr/sbin/ && \
  mv /usr/share/alsa /usr/share/audacity /usr/share/drirc.d /usr/share/fonts /usr/share/libdrm /usr/share/libthai /usr/share/mime /usr/share/themes /usr/share/thumbnailers /usr/share/X11 /exports/usr/share/ && \
  mv /usr/share/applications/audacity.desktop /exports/usr/share/applications/ && \
  mv /usr/share/apport/package-hooks/source_audacity.py /usr/share/apport/package-hooks/source_fontconfig.py /exports/usr/share/apport/package-hooks/ && \
  mv /usr/share/bug/audacity-data /usr/share/bug/audacity /usr/share/bug/libgl1-mesa-dri /usr/share/bug/libgl1 /usr/share/bug/libglapi-mesa /usr/share/bug/libglvnd0 /usr/share/bug/libglx-mesa0 /usr/share/bug/libglx0 /usr/share/bug/libgtk-3-0 /usr/share/bug/libvdpau1 /exports/usr/share/bug/ && \
  mv /usr/share/doc-base/fontconfig-user /usr/share/doc-base/libpng16 /usr/share/doc-base/ocl-icd-libopencl1 /usr/share/doc-base/shared-mime-info /exports/usr/share/doc-base/ && \
  mv /usr/share/doc/adwaita-icon-theme /usr/share/doc/audacity-data /usr/share/doc/audacity /usr/share/doc/fontconfig-config /usr/share/doc/fontconfig /usr/share/doc/fonts-dejavu-core /usr/share/doc/gtk-update-icon-cache /usr/share/doc/hicolor-icon-theme /usr/share/doc/humanity-icon-theme /usr/share/doc/libaom0 /usr/share/doc/libasound2-data /usr/share/doc/libasound2 /usr/share/doc/libatk-bridge2.0-0 /usr/share/doc/libatk1.0-0 /usr/share/doc/libatk1.0-data /usr/share/doc/libatspi2.0-0 /usr/share/doc/libavahi-client3 /usr/share/doc/libavahi-common-data /usr/share/doc/libavahi-common3 /usr/share/doc/libavcodec58 /usr/share/doc/libavformat58 /usr/share/doc/libavutil56 /usr/share/doc/libbluray2 /usr/share/doc/libcairo-gobject2 /usr/share/doc/libcairo2 /usr/share/doc/libchromaprint1 /usr/share/doc/libcodec2-0.9 /usr/share/doc/libcolord2 /usr/share/doc/libcups2 /usr/share/doc/libdatrie1 /usr/share/doc/libdrm-amdgpu1 /usr/share/doc/libdrm-common /usr/share/doc/libdrm-intel1 /usr/share/doc/libdrm-nouveau2 /usr/share/doc/libdrm-radeon1 /usr/share/doc/libdrm2 /usr/share/doc/libepoxy0 /usr/share/doc/libflac++6v5 /usr/share/doc/libflac8 /usr/share/doc/libfontconfig1 /usr/share/doc/libfreetype6 /usr/share/doc/libfribidi0 /usr/share/doc/libgdk-pixbuf2.0-0 /usr/share/doc/libgdk-pixbuf2.0-common /usr/share/doc/libgl1-mesa-dri /usr/share/doc/libgl1 /usr/share/doc/libglapi-mesa /usr/share/doc/libglvnd0 /usr/share/doc/libglx-mesa0 /usr/share/doc/libglx0 /usr/share/doc/libgme0 /usr/share/doc/libgomp1 /usr/share/doc/libgraphite2-3 /usr/share/doc/libgsm1 /usr/share/doc/libgtk-3-0 /usr/share/doc/libgtk-3-common /usr/share/doc/libharfbuzz0b /usr/share/doc/libice6 /usr/share/doc/libid3tag0 /usr/share/doc/libjack-jackd2-0 /usr/share/doc/libjbig0 /usr/share/doc/libjpeg-turbo8 /usr/share/doc/libjpeg8 /usr/share/doc/libjson-glib-1.0-0 /usr/share/doc/libjson-glib-1.0-common /usr/share/doc/liblcms2-2 /usr/share/doc/liblilv-0-0 /usr/share/doc/libllvm11 /usr/share/doc/libmad0 /usr/share/doc/libmp3lame0 /usr/share/doc/libmpg123-0 /usr/share/doc/libnotify4 /usr/share/doc/libnuma1 /usr/share/doc/libogg0 /usr/share/doc/libopenjp2-7 /usr/share/doc/libopenmpt0 /usr/share/doc/libopus0 /usr/share/doc/libpango-1.0-0 /usr/share/doc/libpangocairo-1.0-0 /usr/share/doc/libpangoft2-1.0-0 /usr/share/doc/libpciaccess0 /usr/share/doc/libpixman-1-0 /usr/share/doc/libpng16-16 /usr/share/doc/libportaudio2 /usr/share/doc/libportsmf0v5 /usr/share/doc/librest-0.7-0 /usr/share/doc/librsvg2-2 /usr/share/doc/librsvg2-common /usr/share/doc/libsamplerate0 /usr/share/doc/libsensors-config /usr/share/doc/libsensors5 /usr/share/doc/libserd-0-0 /usr/share/doc/libshine3 /usr/share/doc/libsm6 /usr/share/doc/libsnappy1v5 /usr/share/doc/libsndfile1 /usr/share/doc/libsord-0-0 /usr/share/doc/libsoundtouch1 /usr/share/doc/libsoup-gnome2.4-1 /usr/share/doc/libsoxr0 /usr/share/doc/libspeex1 /usr/share/doc/libsratom-0-0 /usr/share/doc/libssh-gcrypt-4 /usr/share/doc/libsuil-0-0 /usr/share/doc/libswresample3 /usr/share/doc/libthai-data /usr/share/doc/libthai0 /usr/share/doc/libtheora0 /usr/share/doc/libtiff5 /usr/share/doc/libtwolame0 /usr/share/doc/libva-drm2 /usr/share/doc/libva-x11-2 /usr/share/doc/libva2 /usr/share/doc/libvamp-hostsdk3v5 /usr/share/doc/libvdpau1 /usr/share/doc/libvorbis0a /usr/share/doc/libvorbisenc2 /usr/share/doc/libvorbisfile3 /usr/share/doc/libvpx6 /usr/share/doc/libvulkan1 /usr/share/doc/libwavpack1 /usr/share/doc/libwayland-client0 /usr/share/doc/libwayland-cursor0 /usr/share/doc/libwayland-egl1 /usr/share/doc/libwebp6 /usr/share/doc/libwebpmux3 /usr/share/doc/libwxbase3.0-0v5 /usr/share/doc/libwxgtk3.0-gtk3-0v5 /usr/share/doc/libx11-6 /usr/share/doc/libx11-data /usr/share/doc/libx11-xcb1 /usr/share/doc/libx264-155 /usr/share/doc/libx265-179 /usr/share/doc/libxau6 /usr/share/doc/libxcb-dri2-0 /usr/share/doc/libxcb-dri3-0 /usr/share/doc/libxcb-glx0 /usr/share/doc/libxcb-present0 /usr/share/doc/libxcb-render0 /usr/share/doc/libxcb-shm0 /usr/share/doc/libxcb-sync1 /usr/share/doc/libxcb-xfixes0 /usr/share/doc/libxcb1 /usr/share/doc/libxcomposite1 /usr/share/doc/libxcursor1 /usr/share/doc/libxdamage1 /usr/share/doc/libxdmcp6 /usr/share/doc/libxext6 /usr/share/doc/libxfixes3 /usr/share/doc/libxi6 /usr/share/doc/libxinerama1 /usr/share/doc/libxkbcommon0 /usr/share/doc/libxrandr2 /usr/share/doc/libxrender1 /usr/share/doc/libxshmfence1 /usr/share/doc/libxvidcore4 /usr/share/doc/libxxf86vm1 /usr/share/doc/libzvbi-common /usr/share/doc/libzvbi0 /usr/share/doc/ocl-icd-libopencl1 /usr/share/doc/shared-mime-info /usr/share/doc/ubuntu-mono /usr/share/doc/x11-common /usr/share/doc/xkb-data /exports/usr/share/doc/ && \
  mv /usr/share/glib-2.0/schemas/gschemas.compiled /usr/share/glib-2.0/schemas/org.gtk.Settings.ColorChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.EmojiChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.FileChooser.gschema.xml /exports/usr/share/glib-2.0/schemas/ && \
  mv /usr/share/icons/Adwaita /usr/share/icons/default /usr/share/icons/Humanity-Dark /usr/share/icons/Humanity /usr/share/icons/LoginIcons /usr/share/icons/ubuntu-mono-dark /usr/share/icons/ubuntu-mono-light /exports/usr/share/icons/ && \
  mv /usr/share/icons/hicolor/128x128 /usr/share/icons/hicolor/16x16 /usr/share/icons/hicolor/192x192 /usr/share/icons/hicolor/22x22 /usr/share/icons/hicolor/24x24 /usr/share/icons/hicolor/256x256 /usr/share/icons/hicolor/32x32 /usr/share/icons/hicolor/36x36 /usr/share/icons/hicolor/512x512 /usr/share/icons/hicolor/64x64 /usr/share/icons/hicolor/72x72 /usr/share/icons/hicolor/96x96 /usr/share/icons/hicolor/icon-theme.cache /usr/share/icons/hicolor/index.theme /usr/share/icons/hicolor/symbolic /exports/usr/share/icons/hicolor/ && \
  mv /usr/share/icons/hicolor/48x48/actions /usr/share/icons/hicolor/48x48/animations /usr/share/icons/hicolor/48x48/categories /usr/share/icons/hicolor/48x48/devices /usr/share/icons/hicolor/48x48/emblems /usr/share/icons/hicolor/48x48/emotes /usr/share/icons/hicolor/48x48/filesystems /usr/share/icons/hicolor/48x48/intl /usr/share/icons/hicolor/48x48/mimetypes /usr/share/icons/hicolor/48x48/places /usr/share/icons/hicolor/48x48/status /usr/share/icons/hicolor/48x48/stock /exports/usr/share/icons/hicolor/48x48/ && \
  mv /usr/share/icons/hicolor/48x48/apps/audacity.png /exports/usr/share/icons/hicolor/48x48/apps/ && \
  mv /usr/share/icons/hicolor/scalable/actions /usr/share/icons/hicolor/scalable/animations /usr/share/icons/hicolor/scalable/categories /usr/share/icons/hicolor/scalable/devices /usr/share/icons/hicolor/scalable/emblems /usr/share/icons/hicolor/scalable/emotes /usr/share/icons/hicolor/scalable/filesystems /usr/share/icons/hicolor/scalable/intl /usr/share/icons/hicolor/scalable/mimetypes /usr/share/icons/hicolor/scalable/places /usr/share/icons/hicolor/scalable/status /usr/share/icons/hicolor/scalable/stock /exports/usr/share/icons/hicolor/scalable/ && \
  mv /usr/share/icons/hicolor/scalable/apps/audacity.svg /exports/usr/share/icons/hicolor/scalable/apps/ && \
  mv /usr/share/lintian/overrides/audacity /usr/share/lintian/overrides/fontconfig /usr/share/lintian/overrides/hicolor-icon-theme /usr/share/lintian/overrides/libavcodec58 /usr/share/lintian/overrides/libavformat58 /usr/share/lintian/overrides/libavutil56 /usr/share/lintian/overrides/libdrm-nouveau2 /usr/share/lintian/overrides/libgdk-pixbuf2.0-0 /usr/share/lintian/overrides/libglapi-mesa /usr/share/lintian/overrides/libglvnd0 /usr/share/lintian/overrides/libjack-jackd2-0 /usr/share/lintian/overrides/libjpeg-turbo8 /usr/share/lintian/overrides/libllvm11 /usr/share/lintian/overrides/libmpg123-0 /usr/share/lintian/overrides/libpixman-1-0 /usr/share/lintian/overrides/libportsmf0v5 /usr/share/lintian/overrides/librsvg2-2 /usr/share/lintian/overrides/librsvg2-common /usr/share/lintian/overrides/libsoup-gnome2.4-1 /usr/share/lintian/overrides/libssh-gcrypt-4 /usr/share/lintian/overrides/libswresample3 /usr/share/lintian/overrides/libtiff5 /usr/share/lintian/overrides/libvorbis0a /usr/share/lintian/overrides/libwxbase3.0-0v5 /usr/share/lintian/overrides/libwxgtk3.0-gtk3-0v5 /usr/share/lintian/overrides/libx11-6 /usr/share/lintian/overrides/ocl-icd-libopencl1 /usr/share/lintian/overrides/x11-common /exports/usr/share/lintian/overrides/ && \
  mv /usr/share/locale/af/LC_MESSAGES/audacity.mo /exports/usr/share/locale/af/LC_MESSAGES/ && \
  mv /usr/share/locale/ar/LC_MESSAGES/audacity.mo /exports/usr/share/locale/ar/LC_MESSAGES/ && \
  mv /usr/share/locale/be/LC_MESSAGES/audacity.mo /exports/usr/share/locale/be/LC_MESSAGES/ && \
  mv /usr/share/locale/bg/LC_MESSAGES/audacity.mo /exports/usr/share/locale/bg/LC_MESSAGES/ && \
  mv /usr/share/locale/bn/LC_MESSAGES/audacity.mo /exports/usr/share/locale/bn/LC_MESSAGES/ && \
  mv /usr/share/locale/bs/LC_MESSAGES/audacity.mo /exports/usr/share/locale/bs/LC_MESSAGES/ && \
  mv /usr/share/locale/ca_ES@valencia /usr/share/locale/en@boldquot /usr/share/locale/en@quot /usr/share/locale/eu_ES /usr/share/locale/pt_PT /usr/share/locale/sr_RS@latin /usr/share/locale/sr_RS /exports/usr/share/locale/ && \
  mv /usr/share/locale/ca/LC_MESSAGES/audacity.mo /exports/usr/share/locale/ca/LC_MESSAGES/ && \
  mv /usr/share/locale/cs/LC_MESSAGES/audacity.mo /exports/usr/share/locale/cs/LC_MESSAGES/ && \
  mv /usr/share/locale/cy/LC_MESSAGES/audacity.mo /exports/usr/share/locale/cy/LC_MESSAGES/ && \
  mv /usr/share/locale/da/LC_MESSAGES/audacity.mo /exports/usr/share/locale/da/LC_MESSAGES/ && \
  mv /usr/share/locale/de/LC_MESSAGES/audacity.mo /usr/share/locale/de/LC_MESSAGES/zvbi.mo /exports/usr/share/locale/de/LC_MESSAGES/ && \
  mv /usr/share/locale/el/LC_MESSAGES/audacity.mo /exports/usr/share/locale/el/LC_MESSAGES/ && \
  mv /usr/share/locale/es/LC_MESSAGES/audacity.mo /usr/share/locale/es/LC_MESSAGES/zvbi.mo /exports/usr/share/locale/es/LC_MESSAGES/ && \
  mv /usr/share/locale/eu/LC_MESSAGES/audacity.mo /exports/usr/share/locale/eu/LC_MESSAGES/ && \
  mv /usr/share/locale/fa/LC_MESSAGES/audacity.mo /exports/usr/share/locale/fa/LC_MESSAGES/ && \
  mv /usr/share/locale/fi/LC_MESSAGES/audacity.mo /exports/usr/share/locale/fi/LC_MESSAGES/ && \
  mv /usr/share/locale/fr/LC_MESSAGES/audacity.mo /usr/share/locale/fr/LC_MESSAGES/zvbi.mo /exports/usr/share/locale/fr/LC_MESSAGES/ && \
  mv /usr/share/locale/ga/LC_MESSAGES/audacity.mo /exports/usr/share/locale/ga/LC_MESSAGES/ && \
  mv /usr/share/locale/gl/LC_MESSAGES/audacity.mo /exports/usr/share/locale/gl/LC_MESSAGES/ && \
  mv /usr/share/locale/he/LC_MESSAGES/audacity.mo /exports/usr/share/locale/he/LC_MESSAGES/ && \
  mv /usr/share/locale/hi/LC_MESSAGES/audacity.mo /exports/usr/share/locale/hi/LC_MESSAGES/ && \
  mv /usr/share/locale/hr/LC_MESSAGES/audacity.mo /exports/usr/share/locale/hr/LC_MESSAGES/ && \
  mv /usr/share/locale/hu/LC_MESSAGES/audacity.mo /exports/usr/share/locale/hu/LC_MESSAGES/ && \
  mv /usr/share/locale/hy/LC_MESSAGES/audacity.mo /exports/usr/share/locale/hy/LC_MESSAGES/ && \
  mv /usr/share/locale/id/LC_MESSAGES/audacity.mo /exports/usr/share/locale/id/LC_MESSAGES/ && \
  mv /usr/share/locale/it/LC_MESSAGES/audacity.mo /usr/share/locale/it/LC_MESSAGES/zvbi.mo /exports/usr/share/locale/it/LC_MESSAGES/ && \
  mv /usr/share/locale/ja/LC_MESSAGES/audacity.mo /exports/usr/share/locale/ja/LC_MESSAGES/ && \
  mv /usr/share/locale/ka/LC_MESSAGES/audacity.mo /exports/usr/share/locale/ka/LC_MESSAGES/ && \
  mv /usr/share/locale/km/LC_MESSAGES/audacity.mo /exports/usr/share/locale/km/LC_MESSAGES/ && \
  mv /usr/share/locale/ko/LC_MESSAGES/audacity.mo /exports/usr/share/locale/ko/LC_MESSAGES/ && \
  mv /usr/share/locale/lt/LC_MESSAGES/audacity.mo /exports/usr/share/locale/lt/LC_MESSAGES/ && \
  mv /usr/share/locale/mk/LC_MESSAGES/audacity.mo /exports/usr/share/locale/mk/LC_MESSAGES/ && \
  mv /usr/share/locale/my/LC_MESSAGES/audacity.mo /exports/usr/share/locale/my/LC_MESSAGES/ && \
  mv /usr/share/locale/nb/LC_MESSAGES/audacity.mo /exports/usr/share/locale/nb/LC_MESSAGES/ && \
  mv /usr/share/locale/nl/LC_MESSAGES/audacity.mo /usr/share/locale/nl/LC_MESSAGES/zvbi.mo /exports/usr/share/locale/nl/LC_MESSAGES/ && \
  mv /usr/share/locale/oc/LC_MESSAGES/audacity.mo /exports/usr/share/locale/oc/LC_MESSAGES/ && \
  mv /usr/share/locale/pl/LC_MESSAGES/audacity.mo /usr/share/locale/pl/LC_MESSAGES/zvbi.mo /exports/usr/share/locale/pl/LC_MESSAGES/ && \
  mv /usr/share/locale/pt_BR/LC_MESSAGES/audacity.mo /exports/usr/share/locale/pt_BR/LC_MESSAGES/ && \
  mv /usr/share/locale/ro/LC_MESSAGES/audacity.mo /exports/usr/share/locale/ro/LC_MESSAGES/ && \
  mv /usr/share/locale/ru/LC_MESSAGES/audacity.mo /exports/usr/share/locale/ru/LC_MESSAGES/ && \
  mv /usr/share/locale/sk/LC_MESSAGES/audacity.mo /exports/usr/share/locale/sk/LC_MESSAGES/ && \
  mv /usr/share/locale/sl/LC_MESSAGES/audacity.mo /exports/usr/share/locale/sl/LC_MESSAGES/ && \
  mv /usr/share/locale/sv/LC_MESSAGES/audacity.mo /exports/usr/share/locale/sv/LC_MESSAGES/ && \
  mv /usr/share/locale/ta/LC_MESSAGES/audacity.mo /exports/usr/share/locale/ta/LC_MESSAGES/ && \
  mv /usr/share/locale/tg/LC_MESSAGES/audacity.mo /exports/usr/share/locale/tg/LC_MESSAGES/ && \
  mv /usr/share/locale/tr/LC_MESSAGES/audacity.mo /exports/usr/share/locale/tr/LC_MESSAGES/ && \
  mv /usr/share/locale/uk/LC_MESSAGES/audacity.mo /exports/usr/share/locale/uk/LC_MESSAGES/ && \
  mv /usr/share/locale/vi/LC_MESSAGES/audacity.mo /exports/usr/share/locale/vi/LC_MESSAGES/ && \
  mv /usr/share/locale/zh_CN/LC_MESSAGES/audacity.mo /exports/usr/share/locale/zh_CN/LC_MESSAGES/ && \
  mv /usr/share/locale/zh_TW/LC_MESSAGES/audacity.mo /exports/usr/share/locale/zh_TW/LC_MESSAGES/ && \
  mv /usr/share/man/man1/audacity.1.gz /usr/share/man/man1/fc-cache.1.gz /usr/share/man/man1/fc-cat.1.gz /usr/share/man/man1/fc-conflist.1.gz /usr/share/man/man1/fc-list.1.gz /usr/share/man/man1/fc-match.1.gz /usr/share/man/man1/fc-pattern.1.gz /usr/share/man/man1/fc-query.1.gz /usr/share/man/man1/fc-scan.1.gz /usr/share/man/man1/fc-validate.1.gz /usr/share/man/man1/gtk-update-icon-cache.1.gz /usr/share/man/man1/update-mime-database.1.gz /exports/usr/share/man/man1/ && \
  mv /usr/share/man/man5/Compose.5.gz /usr/share/man/man5/fonts-conf.5.gz /usr/share/man/man5/XCompose.5.gz /usr/share/man/man5/Xsession.5.gz /usr/share/man/man5/Xsession.options.5.gz /exports/usr/share/man/man5/ && \
  mv /usr/share/man/man7/libOpenCL.7.gz /usr/share/man/man7/libOpenCL.so.7.gz /usr/share/man/man7/xkeyboard-config.7.gz /exports/usr/share/man/man7/ && \
  mv /usr/share/man/man8/update-icon-caches.8.gz /exports/usr/share/man/man8/ && \
  mv /usr/share/pixmaps/audacity16.xpm /usr/share/pixmaps/audacity32.xpm /usr/share/pixmaps/gnome-mime-application-x-audacity-project.xpm /exports/usr/share/pixmaps/ && \
  mv /usr/share/pkgconfig/adwaita-icon-theme.pc /usr/share/pkgconfig/shared-mime-info.pc /usr/share/pkgconfig/xkeyboard-config.pc /exports/usr/share/pkgconfig/ && \
  mv /usr/share/xml/fontconfig /exports/usr/share/xml/

# ALACRITTY
FROM base AS alacritty
COPY --from=apteryx /exports/ /
COPY --from=clone /exports/ /
COPY --from=rust /exports/ /
ENV \
  PATH=/root/.cargo/bin:$PATH
RUN \
  apteryx cmake gcc pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev python3 && \
  clone --https --shallow --tag 'v0.8.0' https://github.com/alacritty/alacritty && \
  cd /root/src/github.com/alacritty/alacritty && \
  cargo build --release && \
  mv target/release/alacritty /usr/local/bin/alacritty && \
  rm -r /root/src/
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/local/bin/alacritty /exports/usr/local/bin/ && \
  mv /usr/lib/bfd-plugins /usr/lib/compat-ld /usr/lib/cpp /usr/lib/emacsen-common /usr/lib/gcc /usr/lib/gold-ld /usr/lib/pkgconfig /usr/lib/pkg-config.multiarch /exports/usr/lib/ && \
  mv /usr/lib/x86_64-linux-gnu/crt1.o /usr/lib/x86_64-linux-gnu/crti.o /usr/lib/x86_64-linux-gnu/crtn.o /usr/lib/x86_64-linux-gnu/gcrt1.o /usr/lib/x86_64-linux-gnu/grcrt1.o /usr/lib/x86_64-linux-gnu/ldscripts /usr/lib/x86_64-linux-gnu/libanl.a /usr/lib/x86_64-linux-gnu/libanl.so /usr/lib/x86_64-linux-gnu/libarchive.so.13 /usr/lib/x86_64-linux-gnu/libarchive.so.13.4.0 /usr/lib/x86_64-linux-gnu/libasan.so.5 /usr/lib/x86_64-linux-gnu/libasan.so.5.0.0 /usr/lib/x86_64-linux-gnu/libatomic.so.1 /usr/lib/x86_64-linux-gnu/libatomic.so.1.2.0 /usr/lib/x86_64-linux-gnu/libbfd-2.34-system.so /usr/lib/x86_64-linux-gnu/libBrokenLocale.a /usr/lib/x86_64-linux-gnu/libBrokenLocale.so /usr/lib/x86_64-linux-gnu/libc.a /usr/lib/x86_64-linux-gnu/libcc1.so.0 /usr/lib/x86_64-linux-gnu/libcc1.so.0.0.0 /usr/lib/x86_64-linux-gnu/libc_nonshared.a /usr/lib/x86_64-linux-gnu/libcrypt.a /usr/lib/x86_64-linux-gnu/libcrypt.so /usr/lib/x86_64-linux-gnu/libc.so /usr/lib/x86_64-linux-gnu/libctf-nobfd.so.0 /usr/lib/x86_64-linux-gnu/libctf-nobfd.so.0.0.0 /usr/lib/x86_64-linux-gnu/libctf.so.0 /usr/lib/x86_64-linux-gnu/libctf.so.0.0.0 /usr/lib/x86_64-linux-gnu/libdl.a /usr/lib/x86_64-linux-gnu/libdl.so /usr/lib/x86_64-linux-gnu/libexpat.a /usr/lib/x86_64-linux-gnu/libexpat.so /usr/lib/x86_64-linux-gnu/libexpatw.a /usr/lib/x86_64-linux-gnu/libexpatw.so /usr/lib/x86_64-linux-gnu/libfontconfig.a /usr/lib/x86_64-linux-gnu/libfontconfig.so /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.0 /usr/lib/x86_64-linux-gnu/libfreetype.a /usr/lib/x86_64-linux-gnu/libfreetype.so /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.17.1 /usr/lib/x86_64-linux-gnu/libg.a /usr/lib/x86_64-linux-gnu/libgomp.so.1 /usr/lib/x86_64-linux-gnu/libgomp.so.1.0.0 /usr/lib/x86_64-linux-gnu/libisl.so.22 /usr/lib/x86_64-linux-gnu/libisl.so.22.0.1 /usr/lib/x86_64-linux-gnu/libitm.so.1 /usr/lib/x86_64-linux-gnu/libitm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libjsoncpp.so.1 /usr/lib/x86_64-linux-gnu/libjsoncpp.so.1.7.4 /usr/lib/x86_64-linux-gnu/liblsan.so.0 /usr/lib/x86_64-linux-gnu/liblsan.so.0.0.0 /usr/lib/x86_64-linux-gnu/libm-2.31.a /usr/lib/x86_64-linux-gnu/libm.a /usr/lib/x86_64-linux-gnu/libmcheck.a /usr/lib/x86_64-linux-gnu/libmpc.so.3 /usr/lib/x86_64-linux-gnu/libmpc.so.3.1.0 /usr/lib/x86_64-linux-gnu/libmpfr.so.6 /usr/lib/x86_64-linux-gnu/libmpfr.so.6.0.2 /usr/lib/x86_64-linux-gnu/libm.so /usr/lib/x86_64-linux-gnu/libmvec.a /usr/lib/x86_64-linux-gnu/libmvec.so /usr/lib/x86_64-linux-gnu/libnsl.a /usr/lib/x86_64-linux-gnu/libnsl.so /usr/lib/x86_64-linux-gnu/libnss_compat.so /usr/lib/x86_64-linux-gnu/libnss_dns.so /usr/lib/x86_64-linux-gnu/libnss_files.so /usr/lib/x86_64-linux-gnu/libnss_hesiod.so /usr/lib/x86_64-linux-gnu/libnss_nisplus.so /usr/lib/x86_64-linux-gnu/libnss_nis.so /usr/lib/x86_64-linux-gnu/libopcodes-2.34-system.so /usr/lib/x86_64-linux-gnu/libpng16.a /usr/lib/x86_64-linux-gnu/libpng16.so /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.37.0 /usr/lib/x86_64-linux-gnu/libpng.a /usr/lib/x86_64-linux-gnu/libpng.so /usr/lib/x86_64-linux-gnu/libpthread.a /usr/lib/x86_64-linux-gnu/libpthread.so /usr/lib/x86_64-linux-gnu/libquadmath.so.0 /usr/lib/x86_64-linux-gnu/libquadmath.so.0.0.0 /usr/lib/x86_64-linux-gnu/libresolv.a /usr/lib/x86_64-linux-gnu/libresolv.so /usr/lib/x86_64-linux-gnu/librhash.so.0 /usr/lib/x86_64-linux-gnu/librpcsvc.a /usr/lib/x86_64-linux-gnu/librt.a /usr/lib/x86_64-linux-gnu/librt.so /usr/lib/x86_64-linux-gnu/libthread_db.so /usr/lib/x86_64-linux-gnu/libtsan_preinit.o /usr/lib/x86_64-linux-gnu/libtsan.so.0 /usr/lib/x86_64-linux-gnu/libtsan.so.0.0.0 /usr/lib/x86_64-linux-gnu/libubsan.so.1 /usr/lib/x86_64-linux-gnu/libubsan.so.1.0.0 /usr/lib/x86_64-linux-gnu/libutil.a /usr/lib/x86_64-linux-gnu/libutil.so /usr/lib/x86_64-linux-gnu/libuuid.a /usr/lib/x86_64-linux-gnu/libuuid.so /usr/lib/x86_64-linux-gnu/libuv.so.1 /usr/lib/x86_64-linux-gnu/libuv.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXau.a /usr/lib/x86_64-linux-gnu/libXau.so /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb.a /usr/lib/x86_64-linux-gnu/libxcb-render.a /usr/lib/x86_64-linux-gnu/libxcb-render.so /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.a /usr/lib/x86_64-linux-gnu/libxcb-shape.so /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.a /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXdmcp.a /usr/lib/x86_64-linux-gnu/libXdmcp.so /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libz.a /usr/lib/x86_64-linux-gnu/libz.so /usr/lib/x86_64-linux-gnu/Mcrt1.o /usr/lib/x86_64-linux-gnu/pkgconfig /usr/lib/x86_64-linux-gnu/rcrt1.o /usr/lib/x86_64-linux-gnu/Scrt1.o /exports/usr/lib/x86_64-linux-gnu/

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

# WITHEXEDITORHOST
FROM base AS withexeditorhost
COPY --from=node /exports/ /
RUN \
  npm install -g 'withexeditorhost@6.1.0'
RUN \
  mkdir -p /exports/usr/local/lib/node_modules/ && \
  mv /usr/local/lib/node_modules/withexeditorhost /exports/usr/local/lib/node_modules/

# WATSON
FROM base AS watson
COPY --from=python3-pip /exports/ /
COPY --from=pipx /exports/ /
ENV \
  PIPX_HOME=/usr/local/pipx \
  PIPX_BIN_DIR=/usr/local/bin
RUN \
  pipx install td-watson==2.0.1 && \
  pipx inject td-watson click==7.1.2 && \
  rm -rf /root/.cache/pip
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

# SHOEBOX
FROM base AS shoebox
COPY --from=node /exports/ /
RUN \
  npm install -g '@stayradiated/shoebox@1.4.0'
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/@stayradiated/ && \
  mv /usr/local/bin/shoebox /exports/usr/local/bin/ && \
  mv /usr/local/lib/node_modules/@stayradiated/shoebox /exports/usr/local/lib/node_modules/@stayradiated/

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
  apteryx rsync='3.1.3-*'
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/rsync /exports/usr/bin/

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
  mkdir -p /exports/usr/bin/ /exports/usr/local/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man8/ && \
  mv /usr/bin/ping /usr/bin/ping4 /usr/bin/ping6 /exports/usr/bin/ && \
  mv /usr/local/bin/prettyping /exports/usr/local/bin/ && \
  mv /usr/share/doc/iputils-ping /exports/usr/share/doc/ && \
  mv /usr/share/man/man8/ping.8.gz /usr/share/man/man8/ping4.8.gz /usr/share/man/man8/ping6.8.gz /exports/usr/share/man/man8/

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
RUN \
  npm install -g 'np@7.4.0'
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/ && \
  mv /usr/local/bin/np /exports/usr/local/bin/ && \
  mv /usr/local/lib/node_modules/np /exports/usr/local/lib/node_modules/

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
RUN \
  npm install -g 'npm-check-updates@11.5.1'
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/ && \
  mv /usr/local/bin/ncu /exports/usr/local/bin/ && \
  mv /usr/local/lib/node_modules/npm-check-updates /exports/usr/local/lib/node_modules/

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

# MEDIAINFO
FROM base AS mediainfo
COPY --from=apteryx /exports/ /
RUN \
  apteryx mediainfo='19.09-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/man/man1/ && \
  mv /usr/bin/mediainfo /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.* /usr/lib/x86_64-linux-gnu/libmediainfo.so.* /usr/lib/x86_64-linux-gnu/libmms.so.* /usr/lib/x86_64-linux-gnu/libtinyxml2.so.* /usr/lib/x86_64-linux-gnu/libzen.so.* /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/share/man/man1/mediainfo.1.gz /exports/usr/share/man/man1/

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
  apteryx htop='2.2.0-*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man1/ && \
  mv /usr/bin/htop /exports/usr/bin/ && \
  mv /usr/share/doc/htop /exports/usr/share/doc/ && \
  mv /usr/share/man/man1/htop.1.gz /exports/usr/share/man/man1/

# HEROKU
FROM base AS heroku
COPY --from=node /exports/ /
RUN \
  npm install -g 'heroku@7.52.0'
RUN \
  mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/ && \
  mv /usr/local/bin/heroku /exports/usr/local/bin/ && \
  mv /usr/local/lib/node_modules/heroku /exports/usr/local/lib/node_modules/

# GIFSKI
FROM base AS gifski
COPY --from=apteryx /exports/ /
COPY --from=wget /exports/ /
COPY --from=xz /exports/ /
RUN \
  wget -O gifski.deb "https://github.com/ImageOptim/gifski/releases/download/1.4.0/gifski_1.4.0_amd64.deb" && \
  apteryx ./gifski.deb && \
  rm -rf debian
RUN \
  mkdir -p /exports/usr/bin/ && \
  mv /usr/bin/gifski /exports/usr/bin/

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

# DOCKER-COMPOSE
FROM base AS docker-compose
COPY --from=wget /exports/ /
RUN \
  wget -O /usr/local/bin/docker-compose 'https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64' && \
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
  apteryx docker-ce='5:20.10.6*'
RUN \
  mkdir -p /exports/usr/bin/ /exports/usr/share/zsh/vendor-completions/ && \
  mv /usr/bin/docker /exports/usr/bin/ && \
  mv /usr/share/zsh/vendor-completions/_docker /exports/usr/share/zsh/vendor-completions/

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
  wget -O container-diff 'https://storage.googleapis.com/container-diff/v0.16.0/container-diff-linux-amd64' && \
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
  apteryx x11-utils='7.7+*' x11-xkb-utils x11-xserver-utils xkb-data
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
  mkdir -p /exports/etc/ /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/bug/ /exports/usr/share/doc/ /exports/usr/share/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ /exports/usr/share/man/man5/ && \
  mv /etc/vulkan /exports/etc/ && \
  mv /usr/bin/eglinfo /usr/bin/es2_info /usr/bin/es2gears /usr/bin/es2gears_wayland /usr/bin/es2gears_x11 /usr/bin/es2tri /usr/bin/glxdemo /usr/bin/glxgears /usr/bin/glxheads /usr/bin/glxinfo /exports/usr/bin/ && \
  mv /usr/lib/x86_64-linux-gnu/dri /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_intel.so.1 /usr/lib/x86_64-linux-gnu/libdrm_intel.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2.0.0 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1.0.1 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libEGL_mesa.so.0 /usr/lib/x86_64-linux-gnu/libEGL_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libEGL.so.1 /usr/lib/x86_64-linux-gnu/libEGL.so.1.1.0 /usr/lib/x86_64-linux-gnu/libgbm.so.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libGL.so.1 /usr/lib/x86_64-linux-gnu/libGL.so.1.7.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLESv2.so.2 /usr/lib/x86_64-linux-gnu/libGLESv2.so.2.1.0 /usr/lib/x86_64-linux-gnu/libGLX_indirect.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0.0.0 /usr/lib/x86_64-linux-gnu/libLLVM-11.so /usr/lib/x86_64-linux-gnu/libLLVM-11.so.1 /usr/lib/x86_64-linux-gnu/libpciaccess.so.0 /usr/lib/x86_64-linux-gnu/libpciaccess.so.0.11.1 /usr/lib/x86_64-linux-gnu/libsensors.so.5 /usr/lib/x86_64-linux-gnu/libsensors.so.5.0.0 /usr/lib/x86_64-linux-gnu/libvulkan.so.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1.2.131 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.3.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.0.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0.1.0 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1.0.0 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.3.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1.0.0 /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/share/bug/libegl-mesa0 /usr/share/bug/libegl1 /usr/share/bug/libgbm1 /usr/share/bug/libgl1-mesa-dri /usr/share/bug/libgl1 /usr/share/bug/libglapi-mesa /usr/share/bug/libgles2 /usr/share/bug/libglvnd0 /usr/share/bug/libglx-mesa0 /usr/share/bug/libglx0 /exports/usr/share/bug/ && \
  mv /usr/share/doc/libdrm-amdgpu1 /usr/share/doc/libdrm-common /usr/share/doc/libdrm-intel1 /usr/share/doc/libdrm-nouveau2 /usr/share/doc/libdrm-radeon1 /usr/share/doc/libdrm2 /usr/share/doc/libegl-mesa0 /usr/share/doc/libegl1 /usr/share/doc/libgbm1 /usr/share/doc/libgl1-mesa-dri /usr/share/doc/libgl1 /usr/share/doc/libglapi-mesa /usr/share/doc/libgles2 /usr/share/doc/libglvnd0 /usr/share/doc/libglx-mesa0 /usr/share/doc/libglx0 /usr/share/doc/libllvm11 /usr/share/doc/libpciaccess0 /usr/share/doc/libsensors-config /usr/share/doc/libsensors5 /usr/share/doc/libvulkan1 /usr/share/doc/libwayland-client0 /usr/share/doc/libwayland-egl1 /usr/share/doc/libwayland-server0 /usr/share/doc/libx11-6 /usr/share/doc/libx11-data /usr/share/doc/libx11-xcb1 /usr/share/doc/libxau6 /usr/share/doc/libxcb-dri2-0 /usr/share/doc/libxcb-dri3-0 /usr/share/doc/libxcb-glx0 /usr/share/doc/libxcb-present0 /usr/share/doc/libxcb-sync1 /usr/share/doc/libxcb-xfixes0 /usr/share/doc/libxcb1 /usr/share/doc/libxdamage1 /usr/share/doc/libxdmcp6 /usr/share/doc/libxext6 /usr/share/doc/libxfixes3 /usr/share/doc/libxshmfence1 /usr/share/doc/libxxf86vm1 /usr/share/doc/mesa-utils-extra /usr/share/doc/mesa-utils /exports/usr/share/doc/ && \
  mv /usr/share/drirc.d /usr/share/glvnd /usr/share/libdrm /usr/share/X11 /exports/usr/share/ && \
  mv /usr/share/lintian/overrides/libdrm-nouveau2 /usr/share/lintian/overrides/libgbm1 /usr/share/lintian/overrides/libglapi-mesa /usr/share/lintian/overrides/libgles2 /usr/share/lintian/overrides/libglvnd0 /usr/share/lintian/overrides/libllvm11 /usr/share/lintian/overrides/libx11-6 /exports/usr/share/lintian/overrides/ && \
  mv /usr/share/man/man1/es2_info.1.gz /usr/share/man/man1/es2gears_wayland.1.gz /usr/share/man/man1/es2gears_x11.1.gz /usr/share/man/man1/es2gears.1.gz /usr/share/man/man1/es2tri.1.gz /usr/share/man/man1/glxdemo.1.gz /usr/share/man/man1/glxgears.1.gz /usr/share/man/man1/glxheads.1.gz /usr/share/man/man1/glxinfo.1.gz /exports/usr/share/man/man1/ && \
  mv /usr/share/man/man5/Compose.5.gz /usr/share/man/man5/XCompose.5.gz /exports/usr/share/man/man5/

# LIBXV1
FROM base AS libxv1
COPY --from=apteryx /exports/ /
RUN \
  apteryx libxv1='2:1.0.11-1'
RUN \
  mkdir -p /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/doc/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man5/ /exports/usr/share/ && \
  mv /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.3.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXv.so.1 /usr/lib/x86_64-linux-gnu/libXv.so.1.0.0 /exports/usr/lib/x86_64-linux-gnu/ && \
  mv /usr/share/doc/libx11-6 /usr/share/doc/libx11-data /usr/share/doc/libxau6 /usr/share/doc/libxcb1 /usr/share/doc/libxdmcp6 /usr/share/doc/libxext6 /usr/share/doc/libxv1 /exports/usr/share/doc/ && \
  mv /usr/share/lintian/overrides/libx11-6 /exports/usr/share/lintian/overrides/ && \
  mv /usr/share/man/man5/Compose.5.gz /usr/share/man/man5/XCompose.5.gz /exports/usr/share/man/man5/ && \
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
COPY --from=w3m /exports/ /
COPY --from=hyperfine /exports/ /
COPY --from=chs /exports/ /
COPY --from=youtube-dl /exports/ /
COPY --from=libglib /exports/ /
COPY --from=bandwhich /exports/ /
COPY --from=mycli /exports/ /
COPY --from=xdo /exports/ /
COPY --from=zx /exports/ /
COPY --from=mbsync /exports/ /
COPY --from=autotag /exports/ /
COPY --from=miller /exports/ /
COPY --from=electrum /exports/ /
ENV \
  PATH=/usr/local/go/bin:${PATH} \
  GOPATH=/root \
  GO111MODULE=auto
ENV \
  PATH=${PATH}:/home/admin/.cache/npm/bin
ENV \
  PATH=/home/admin/.yarn/bin:${PATH}
ENV \
  PATH=${PATH}:/opt/google/chrome
RUN \
  chmod 0600 /home/admin/.ssh/*
CMD /home/admin/.xinitrc
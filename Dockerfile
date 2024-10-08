

# BASE
FROM phusion/baseimage:jammy-1.0.1 AS base
RUN set -e \
  ; echo jammy-1.0.4 \
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

# WGET
FROM base AS wget
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx wget='1.21.2-2ubuntu1.1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man1/ \
  ; mv /usr/bin/wget /exports/usr/bin/ \
  ; mv /usr/share/doc/wget /exports/usr/share/doc/ \
  ; mv /usr/share/man/man1/wget.1.gz /exports/usr/share/man/man1/

# GIT
FROM base AS git
COPY --from=apteryx /exports/ /
RUN set -e \
  ; add-apt-repository ppa:git-core/ppa \
  ; apteryx git='1:2.47.0-0ppa1~ubuntu22.04.1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/ /exports/usr/share/perl5/ /exports/var/lib/ \
  ; mv /usr/bin/git /exports/usr/bin/ \
  ; mv /usr/lib/git-core /exports/usr/lib/ \
  ; mv /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.* /usr/lib/x86_64-linux-gnu/libgdbm.so.* /usr/lib/x86_64-linux-gnu/libgdbm_compat.so.* /usr/lib/x86_64-linux-gnu/libperl.so.* /usr/lib/x86_64-linux-gnu/perl /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/share/git-core /usr/share/perl /exports/usr/share/ \
  ; mv /usr/share/perl5/Error.pm /usr/share/perl5/Error /usr/share/perl5/Git.pm /usr/share/perl5/Git /exports/usr/share/perl5/ \
  ; mv /var/lib/git /exports/var/lib/

# GO
FROM base AS go
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/go.tgz "https://dl.google.com/go/go1.23.2.linux-amd64.tar.gz" \
  ; tar xzvf /tmp/go.tgz \
  ; mv go /usr/local/go \
  ; rm -rf /tmp/go.tgz
RUN set -e \
  ; mkdir -p /exports/usr/local/ \
  ; mv /usr/local/go /exports/usr/local/

# MAKE
FROM base AS make
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx make='4.3-4.1build1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/share/man/man1/ \
  ; mv /usr/bin/make /exports/usr/bin/ \
  ; mv /usr/share/man/man1/make.1.gz /exports/usr/share/man/man1/

# CLONE
FROM base AS clone
COPY --from=go /exports/ /
COPY --from=git /exports/ /
ENV \
  PATH=/usr/local/go/bin:${PATH} \
  GOPATH=/root \
  GO111MODULE=auto
RUN set -e \
  ; mkdir -p /root/src/github.com/stayradiated \
  ; cd /root/src/github.com/stayradiated \
  ; git clone --depth 1 https://github.com/stayradiated/clone \
  ; cd clone \
  ; git fetch --depth 1 origin tag 'v1.5.0' \
  ; git reset --hard 'v1.5.0' \
  ; go install \
  ; mv /root/bin/clone /usr/local/bin/clone \
  ; cd /root \
  ; rm -rf src bin
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ /exports/usr/share/ /exports/usr/share/perl5/ /exports/var/lib/ \
  ; mv /usr/bin/git /exports/usr/bin/ \
  ; mv /usr/lib/git-core /exports/usr/lib/ \
  ; mv /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.* /usr/lib/x86_64-linux-gnu/libgdbm_compat.so.* /usr/lib/x86_64-linux-gnu/libgdbm.so.* /usr/lib/x86_64-linux-gnu/libperl.so.* /usr/lib/x86_64-linux-gnu/perl /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/local/bin/clone /exports/usr/local/bin/ \
  ; mv /usr/share/git-core /usr/share/perl /exports/usr/share/ \
  ; mv /usr/share/perl5/Error.pm /usr/share/perl5/Error /usr/share/perl5/Git.pm /usr/share/perl5/Git /exports/usr/share/perl5/ \
  ; mv /var/lib/git /exports/var/lib/

# BUILD-ESSENTIAL
FROM base AS build-essential
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx build-essential='12.9ubuntu3'
RUN set -e \
  ; mkdir -p /exports/etc/alternatives/ /exports/etc/ /exports/usr/bin/ /exports/usr/include/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/bug/ /exports/usr/share/ /exports/usr/share/doc/ /exports/usr/share/doc/dpkg/ /exports/usr/share/doc/libcrypt1/ /exports/usr/share/doc/perl/ /exports/usr/share/dpkg/ /exports/usr/share/gdb/auto-load/ /exports/usr/share/gdb/auto-load/usr/lib/x86_64-linux-gnu/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ /exports/usr/share/man/man3/ /exports/usr/share/man/man5/ /exports/usr/share/man/man7/ /exports/usr/share/perl5/ /exports/usr/share/zsh/vendor-completions/ \
  ; mv /etc/alternatives/c++ /etc/alternatives/c++.1.gz /etc/alternatives/c89 /etc/alternatives/c89.1.gz /etc/alternatives/c99 /etc/alternatives/c99.1.gz /etc/alternatives/cc /etc/alternatives/cc.1.gz /etc/alternatives/cpp /etc/alternatives/lzcat /etc/alternatives/lzcat.1.gz /etc/alternatives/lzcmp /etc/alternatives/lzcmp.1.gz /etc/alternatives/lzdiff /etc/alternatives/lzdiff.1.gz /etc/alternatives/lzegrep /etc/alternatives/lzegrep.1.gz /etc/alternatives/lzfgrep /etc/alternatives/lzfgrep.1.gz /etc/alternatives/lzgrep /etc/alternatives/lzgrep.1.gz /etc/alternatives/lzless /etc/alternatives/lzless.1.gz /etc/alternatives/lzma /etc/alternatives/lzma.1.gz /etc/alternatives/lzmore /etc/alternatives/lzmore.1.gz /etc/alternatives/unlzma /etc/alternatives/unlzma.1.gz /exports/etc/alternatives/ \
  ; mv /etc/perl /exports/etc/ \
  ; mv /usr/bin/addr2line /usr/bin/ar /usr/bin/as /usr/bin/bunzip2 /usr/bin/bzcat /usr/bin/bzcmp /usr/bin/bzdiff /usr/bin/bzegrep /usr/bin/bzexe /usr/bin/bzfgrep /usr/bin/bzgrep /usr/bin/bzip2 /usr/bin/bzip2recover /usr/bin/bzless /usr/bin/bzmore /usr/bin/c++ /usr/bin/c++filt /usr/bin/c89 /usr/bin/c89-gcc /usr/bin/c99 /usr/bin/c99-gcc /usr/bin/cc /usr/bin/corelist /usr/bin/cpan /usr/bin/cpan5.34-x86_64-linux-gnu /usr/bin/cpp /usr/bin/cpp-11 /usr/bin/dpkg-architecture /usr/bin/dpkg-buildflags /usr/bin/dpkg-buildpackage /usr/bin/dpkg-checkbuilddeps /usr/bin/dpkg-distaddfile /usr/bin/dpkg-genbuildinfo /usr/bin/dpkg-genchanges /usr/bin/dpkg-gencontrol /usr/bin/dpkg-gensymbols /usr/bin/dpkg-mergechangelogs /usr/bin/dpkg-name /usr/bin/dpkg-parsechangelog /usr/bin/dpkg-scanpackages /usr/bin/dpkg-scansources /usr/bin/dpkg-shlibdeps /usr/bin/dpkg-source /usr/bin/dpkg-vendor /usr/bin/dwp /usr/bin/elfedit /usr/bin/enc2xs /usr/bin/encguess /usr/bin/g++ /usr/bin/g++-11 /usr/bin/gcc /usr/bin/gcc-11 /usr/bin/gcc-ar /usr/bin/gcc-ar-11 /usr/bin/gcc-nm /usr/bin/gcc-nm-11 /usr/bin/gcc-ranlib /usr/bin/gcc-ranlib-11 /usr/bin/gcov /usr/bin/gcov-11 /usr/bin/gcov-dump /usr/bin/gcov-dump-11 /usr/bin/gcov-tool /usr/bin/gcov-tool-11 /usr/bin/gencat /usr/bin/gmake /usr/bin/gold /usr/bin/gprof /usr/bin/h2ph /usr/bin/h2xs /usr/bin/instmodsh /usr/bin/json_pp /usr/bin/ld /usr/bin/ld.bfd /usr/bin/ld.gold /usr/bin/libnetcfg /usr/bin/lto-dump-11 /usr/bin/lzcat /usr/bin/lzcmp /usr/bin/lzdiff /usr/bin/lzegrep /usr/bin/lzfgrep /usr/bin/lzgrep /usr/bin/lzless /usr/bin/lzma /usr/bin/lzmainfo /usr/bin/lzmore /usr/bin/make /usr/bin/make-first-existing-target /usr/bin/nm /usr/bin/objcopy /usr/bin/objdump /usr/bin/patch /usr/bin/perl5.34-x86_64-linux-gnu /usr/bin/perlbug /usr/bin/perldoc /usr/bin/perlivp /usr/bin/perlthanks /usr/bin/piconv /usr/bin/pl2pm /usr/bin/pod2html /usr/bin/pod2man /usr/bin/pod2text /usr/bin/pod2usage /usr/bin/podchecker /usr/bin/prove /usr/bin/ptar /usr/bin/ptardiff /usr/bin/ptargrep /usr/bin/ranlib /usr/bin/readelf /usr/bin/rpcgen /usr/bin/shasum /usr/bin/size /usr/bin/splain /usr/bin/streamzip /usr/bin/strings /usr/bin/strip /usr/bin/unlzma /usr/bin/unxz /usr/bin/x86_64-linux-gnu-addr2line /usr/bin/x86_64-linux-gnu-ar /usr/bin/x86_64-linux-gnu-as /usr/bin/x86_64-linux-gnu-c++filt /usr/bin/x86_64-linux-gnu-cpp /usr/bin/x86_64-linux-gnu-cpp-11 /usr/bin/x86_64-linux-gnu-dwp /usr/bin/x86_64-linux-gnu-elfedit /usr/bin/x86_64-linux-gnu-g++ /usr/bin/x86_64-linux-gnu-g++-11 /usr/bin/x86_64-linux-gnu-gcc /usr/bin/x86_64-linux-gnu-gcc-11 /usr/bin/x86_64-linux-gnu-gcc-ar /usr/bin/x86_64-linux-gnu-gcc-ar-11 /usr/bin/x86_64-linux-gnu-gcc-nm /usr/bin/x86_64-linux-gnu-gcc-nm-11 /usr/bin/x86_64-linux-gnu-gcc-ranlib /usr/bin/x86_64-linux-gnu-gcc-ranlib-11 /usr/bin/x86_64-linux-gnu-gcov /usr/bin/x86_64-linux-gnu-gcov-11 /usr/bin/x86_64-linux-gnu-gcov-dump /usr/bin/x86_64-linux-gnu-gcov-dump-11 /usr/bin/x86_64-linux-gnu-gcov-tool /usr/bin/x86_64-linux-gnu-gcov-tool-11 /usr/bin/x86_64-linux-gnu-gold /usr/bin/x86_64-linux-gnu-gprof /usr/bin/x86_64-linux-gnu-ld /usr/bin/x86_64-linux-gnu-ld.bfd /usr/bin/x86_64-linux-gnu-ld.gold /usr/bin/x86_64-linux-gnu-lto-dump-11 /usr/bin/x86_64-linux-gnu-nm /usr/bin/x86_64-linux-gnu-objcopy /usr/bin/x86_64-linux-gnu-objdump /usr/bin/x86_64-linux-gnu-ranlib /usr/bin/x86_64-linux-gnu-readelf /usr/bin/x86_64-linux-gnu-size /usr/bin/x86_64-linux-gnu-strings /usr/bin/x86_64-linux-gnu-strip /usr/bin/xsubpp /usr/bin/xz /usr/bin/xzcat /usr/bin/xzcmp /usr/bin/xzdiff /usr/bin/xzegrep /usr/bin/xzfgrep /usr/bin/xzgrep /usr/bin/xzless /usr/bin/xzmore /usr/bin/zipdetails /exports/usr/bin/ \
  ; mv /usr/include/aio.h /usr/include/aliases.h /usr/include/alloca.h /usr/include/ar.h /usr/include/argp.h /usr/include/argz.h /usr/include/arpa /usr/include/asm-generic /usr/include/assert.h /usr/include/byteswap.h /usr/include/c++ /usr/include/complex.h /usr/include/cpio.h /usr/include/crypt.h /usr/include/ctype.h /usr/include/dirent.h /usr/include/dlfcn.h /usr/include/drm /usr/include/elf.h /usr/include/endian.h /usr/include/envz.h /usr/include/err.h /usr/include/errno.h /usr/include/error.h /usr/include/execinfo.h /usr/include/fcntl.h /usr/include/features-time64.h /usr/include/features.h /usr/include/fenv.h /usr/include/finclude /usr/include/fmtmsg.h /usr/include/fnmatch.h /usr/include/fstab.h /usr/include/fts.h /usr/include/ftw.h /usr/include/gconv.h /usr/include/getopt.h /usr/include/glob.h /usr/include/gnu-versions.h /usr/include/gnumake.h /usr/include/grp.h /usr/include/gshadow.h /usr/include/iconv.h /usr/include/ifaddrs.h /usr/include/inttypes.h /usr/include/langinfo.h /usr/include/lastlog.h /usr/include/libgen.h /usr/include/libintl.h /usr/include/limits.h /usr/include/link.h /usr/include/linux /usr/include/locale.h /usr/include/malloc.h /usr/include/math.h /usr/include/mcheck.h /usr/include/memory.h /usr/include/misc /usr/include/mntent.h /usr/include/monetary.h /usr/include/mqueue.h /usr/include/mtd /usr/include/net /usr/include/netash /usr/include/netatalk /usr/include/netax25 /usr/include/netdb.h /usr/include/neteconet /usr/include/netinet /usr/include/netipx /usr/include/netiucv /usr/include/netpacket /usr/include/netrom /usr/include/netrose /usr/include/nfs /usr/include/nl_types.h /usr/include/nss.h /usr/include/obstack.h /usr/include/paths.h /usr/include/poll.h /usr/include/printf.h /usr/include/proc_service.h /usr/include/protocols /usr/include/pthread.h /usr/include/pty.h /usr/include/pwd.h /usr/include/rdma /usr/include/re_comp.h /usr/include/regex.h /usr/include/regexp.h /usr/include/resolv.h /usr/include/rpc /usr/include/rpcsvc /usr/include/sched.h /usr/include/scsi /usr/include/search.h /usr/include/semaphore.h /usr/include/setjmp.h /usr/include/sgtty.h /usr/include/shadow.h /usr/include/signal.h /usr/include/sound /usr/include/spawn.h /usr/include/stab.h /usr/include/stdc-predef.h /usr/include/stdint.h /usr/include/stdio_ext.h /usr/include/stdio.h /usr/include/stdlib.h /usr/include/string.h /usr/include/strings.h /usr/include/syscall.h /usr/include/sysexits.h /usr/include/syslog.h /usr/include/tar.h /usr/include/termio.h /usr/include/termios.h /usr/include/tgmath.h /usr/include/thread_db.h /usr/include/threads.h /usr/include/time.h /usr/include/tirpc /usr/include/ttyent.h /usr/include/uchar.h /usr/include/ucontext.h /usr/include/ulimit.h /usr/include/unistd.h /usr/include/utime.h /usr/include/utmp.h /usr/include/utmpx.h /usr/include/values.h /usr/include/video /usr/include/wait.h /usr/include/wchar.h /usr/include/wctype.h /usr/include/wordexp.h /usr/include/x86_64-linux-gnu /usr/include/xen /exports/usr/include/ \
  ; mv /usr/lib/bfd-plugins /usr/lib/compat-ld /usr/lib/cpp /usr/lib/gcc /usr/lib/gold-ld /exports/usr/lib/ \
  ; mv /usr/lib/x86_64-linux-gnu/bfd-plugins /usr/lib/x86_64-linux-gnu/crt1.o /usr/lib/x86_64-linux-gnu/crti.o /usr/lib/x86_64-linux-gnu/crtn.o /usr/lib/x86_64-linux-gnu/gcrt1.o /usr/lib/x86_64-linux-gnu/grcrt1.o /usr/lib/x86_64-linux-gnu/ldscripts /usr/lib/x86_64-linux-gnu/libanl.a /usr/lib/x86_64-linux-gnu/libanl.so /usr/lib/x86_64-linux-gnu/libasan.so.6 /usr/lib/x86_64-linux-gnu/libasan.so.6.0.0 /usr/lib/x86_64-linux-gnu/libatomic.so.1 /usr/lib/x86_64-linux-gnu/libatomic.so.1.2.0 /usr/lib/x86_64-linux-gnu/libbfd-2.38-system.so /usr/lib/x86_64-linux-gnu/libBrokenLocale.a /usr/lib/x86_64-linux-gnu/libBrokenLocale.so /usr/lib/x86_64-linux-gnu/libc_malloc_debug.so /usr/lib/x86_64-linux-gnu/libc_nonshared.a /usr/lib/x86_64-linux-gnu/libc.a /usr/lib/x86_64-linux-gnu/libc.so /usr/lib/x86_64-linux-gnu/libcc1.so.0 /usr/lib/x86_64-linux-gnu/libcc1.so.0.0.0 /usr/lib/x86_64-linux-gnu/libcrypt.a /usr/lib/x86_64-linux-gnu/libcrypt.so /usr/lib/x86_64-linux-gnu/libctf-nobfd.so.0 /usr/lib/x86_64-linux-gnu/libctf-nobfd.so.0.0.0 /usr/lib/x86_64-linux-gnu/libctf.so.0 /usr/lib/x86_64-linux-gnu/libctf.so.0.0.0 /usr/lib/x86_64-linux-gnu/libdl.a /usr/lib/x86_64-linux-gnu/libg.a /usr/lib/x86_64-linux-gnu/libgdbm_compat.so.4 /usr/lib/x86_64-linux-gnu/libgdbm_compat.so.4.0.0 /usr/lib/x86_64-linux-gnu/libgdbm.so.6 /usr/lib/x86_64-linux-gnu/libgdbm.so.6.0.0 /usr/lib/x86_64-linux-gnu/libgomp.so.1 /usr/lib/x86_64-linux-gnu/libgomp.so.1.0.0 /usr/lib/x86_64-linux-gnu/libisl.so.23 /usr/lib/x86_64-linux-gnu/libisl.so.23.1.0 /usr/lib/x86_64-linux-gnu/libitm.so.1 /usr/lib/x86_64-linux-gnu/libitm.so.1.0.0 /usr/lib/x86_64-linux-gnu/liblsan.so.0 /usr/lib/x86_64-linux-gnu/liblsan.so.0.0.0 /usr/lib/x86_64-linux-gnu/libm-2.35.a /usr/lib/x86_64-linux-gnu/libm.a /usr/lib/x86_64-linux-gnu/libm.so /usr/lib/x86_64-linux-gnu/libmcheck.a /usr/lib/x86_64-linux-gnu/libmpc.so.3 /usr/lib/x86_64-linux-gnu/libmpc.so.3.2.1 /usr/lib/x86_64-linux-gnu/libmpfr.so.6 /usr/lib/x86_64-linux-gnu/libmpfr.so.6.1.0 /usr/lib/x86_64-linux-gnu/libmvec.a /usr/lib/x86_64-linux-gnu/libmvec.so /usr/lib/x86_64-linux-gnu/libnsl.a /usr/lib/x86_64-linux-gnu/libnsl.so /usr/lib/x86_64-linux-gnu/libnss_compat.so /usr/lib/x86_64-linux-gnu/libnss_hesiod.so /usr/lib/x86_64-linux-gnu/libopcodes-2.38-system.so /usr/lib/x86_64-linux-gnu/libperl.so.5.34 /usr/lib/x86_64-linux-gnu/libperl.so.5.34.0 /usr/lib/x86_64-linux-gnu/libpthread.a /usr/lib/x86_64-linux-gnu/libquadmath.so.0 /usr/lib/x86_64-linux-gnu/libquadmath.so.0.0.0 /usr/lib/x86_64-linux-gnu/libresolv.a /usr/lib/x86_64-linux-gnu/libresolv.so /usr/lib/x86_64-linux-gnu/librt.a /usr/lib/x86_64-linux-gnu/libthread_db.so /usr/lib/x86_64-linux-gnu/libtirpc.a /usr/lib/x86_64-linux-gnu/libtirpc.so /usr/lib/x86_64-linux-gnu/libtsan.so.0 /usr/lib/x86_64-linux-gnu/libtsan.so.0.0.0 /usr/lib/x86_64-linux-gnu/libubsan.so.1 /usr/lib/x86_64-linux-gnu/libubsan.so.1.0.0 /usr/lib/x86_64-linux-gnu/libutil.a /usr/lib/x86_64-linux-gnu/Mcrt1.o /usr/lib/x86_64-linux-gnu/perl /usr/lib/x86_64-linux-gnu/pkgconfig /usr/lib/x86_64-linux-gnu/rcrt1.o /usr/lib/x86_64-linux-gnu/Scrt1.o /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/share/bug/binutils /usr/share/bug/dpkg-dev /usr/share/bug/libdpkg-perl /exports/usr/share/bug/ \
  ; mv /usr/share/build-essential /usr/share/lto-disabled-list /usr/share/perl /exports/usr/share/ \
  ; mv /usr/share/doc/binutils-common /usr/share/doc/binutils-x86-64-linux-gnu /usr/share/doc/binutils /usr/share/doc/build-essential /usr/share/doc/bzip2 /usr/share/doc/cpp-11 /usr/share/doc/cpp /usr/share/doc/dpkg-dev /usr/share/doc/g++ /usr/share/doc/g++-11 /usr/share/doc/gcc /usr/share/doc/gcc-11 /usr/share/doc/gcc-11-base /usr/share/doc/libasan6 /usr/share/doc/libatomic1 /usr/share/doc/libbinutils /usr/share/doc/libc-dev-bin /usr/share/doc/libc6-dev /usr/share/doc/libcc1-0 /usr/share/doc/libcrypt-dev /usr/share/doc/libctf-nobfd0 /usr/share/doc/libctf0 /usr/share/doc/libdpkg-perl /usr/share/doc/libgcc-11-dev /usr/share/doc/libgdbm-compat4 /usr/share/doc/libgdbm6 /usr/share/doc/libgomp1 /usr/share/doc/libisl23 /usr/share/doc/libitm1 /usr/share/doc/liblsan0 /usr/share/doc/libmpc3 /usr/share/doc/libmpfr6 /usr/share/doc/libnsl-dev /usr/share/doc/libperl5.34 /usr/share/doc/libquadmath0 /usr/share/doc/libstdc++-11-dev /usr/share/doc/libtirpc-dev /usr/share/doc/libtsan0 /usr/share/doc/libubsan1 /usr/share/doc/linux-libc-dev /usr/share/doc/lto-disabled-list /usr/share/doc/make /usr/share/doc/patch /usr/share/doc/perl-modules-5.34 /usr/share/doc/rpcsvc-proto /usr/share/doc/xz-utils /exports/usr/share/doc/ \
  ; mv /usr/share/doc/dpkg/frontend.txt /usr/share/doc/dpkg/protected-field.txt /usr/share/doc/dpkg/rootless-builds.txt.gz /usr/share/doc/dpkg/triggers.txt.gz /exports/usr/share/doc/dpkg/ \
  ; mv /usr/share/doc/libcrypt1/README.md.gz /usr/share/doc/libcrypt1/TODO.md.gz /exports/usr/share/doc/libcrypt1/ \
  ; mv /usr/share/doc/perl/changelog.Debian.gz /usr/share/doc/perl/Changes.gz /usr/share/doc/perl/copyright /usr/share/doc/perl/README.Debian /exports/usr/share/doc/perl/ \
  ; mv /usr/share/dpkg/architecture.mk /usr/share/dpkg/buildflags.mk /usr/share/dpkg/buildopts.mk /usr/share/dpkg/buildtools.mk /usr/share/dpkg/default.mk /usr/share/dpkg/no-pie-compile.specs /usr/share/dpkg/no-pie-link.specs /usr/share/dpkg/pie-compile.specs /usr/share/dpkg/pie-link.specs /usr/share/dpkg/pkg-info.mk /usr/share/dpkg/vendor.mk /exports/usr/share/dpkg/ \
  ; mv /usr/share/gdb/auto-load/lib /exports/usr/share/gdb/auto-load/ \
  ; mv /usr/share/gdb/auto-load/usr/lib/x86_64-linux-gnu/libisl.so.23.1.0-gdb.py /exports/usr/share/gdb/auto-load/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/share/lintian/overrides/binutils /usr/share/lintian/overrides/binutils-common /usr/share/lintian/overrides/binutils-x86-64-linux-gnu /usr/share/lintian/overrides/cpp /usr/share/lintian/overrides/cpp-11 /usr/share/lintian/overrides/g++-11 /usr/share/lintian/overrides/gcc-11 /usr/share/lintian/overrides/libbinutils /usr/share/lintian/overrides/libc6-dev /usr/share/lintian/overrides/libperl5.34 /usr/share/lintian/overrides/perl /exports/usr/share/lintian/overrides/ \
  ; mv /usr/share/man/man1/addr2line.1.gz /usr/share/man/man1/ar.1.gz /usr/share/man/man1/as.1.gz /usr/share/man/man1/bunzip2.1.gz /usr/share/man/man1/bzcat.1.gz /usr/share/man/man1/bzcmp.1.gz /usr/share/man/man1/bzdiff.1.gz /usr/share/man/man1/bzegrep.1.gz /usr/share/man/man1/bzexe.1.gz /usr/share/man/man1/bzfgrep.1.gz /usr/share/man/man1/bzgrep.1.gz /usr/share/man/man1/bzip2.1.gz /usr/share/man/man1/bzip2recover.1.gz /usr/share/man/man1/bzless.1.gz /usr/share/man/man1/bzmore.1.gz /usr/share/man/man1/c++.1.gz /usr/share/man/man1/c++filt.1.gz /usr/share/man/man1/c89-gcc.1.gz /usr/share/man/man1/c89.1.gz /usr/share/man/man1/c99-gcc.1.gz /usr/share/man/man1/c99.1.gz /usr/share/man/man1/cc.1.gz /usr/share/man/man1/corelist.1.gz /usr/share/man/man1/cpan.1.gz /usr/share/man/man1/cpan5.34-x86_64-linux-gnu.1.gz /usr/share/man/man1/cpp-11.1.gz /usr/share/man/man1/cpp.1.gz /usr/share/man/man1/dpkg-architecture.1.gz /usr/share/man/man1/dpkg-buildflags.1.gz /usr/share/man/man1/dpkg-buildpackage.1.gz /usr/share/man/man1/dpkg-checkbuilddeps.1.gz /usr/share/man/man1/dpkg-distaddfile.1.gz /usr/share/man/man1/dpkg-genbuildinfo.1.gz /usr/share/man/man1/dpkg-genchanges.1.gz /usr/share/man/man1/dpkg-gencontrol.1.gz /usr/share/man/man1/dpkg-gensymbols.1.gz /usr/share/man/man1/dpkg-mergechangelogs.1.gz /usr/share/man/man1/dpkg-name.1.gz /usr/share/man/man1/dpkg-parsechangelog.1.gz /usr/share/man/man1/dpkg-scanpackages.1.gz /usr/share/man/man1/dpkg-scansources.1.gz /usr/share/man/man1/dpkg-shlibdeps.1.gz /usr/share/man/man1/dpkg-source.1.gz /usr/share/man/man1/dpkg-vendor.1.gz /usr/share/man/man1/dwp.1.gz /usr/share/man/man1/elfedit.1.gz /usr/share/man/man1/enc2xs.1.gz /usr/share/man/man1/encguess.1.gz /usr/share/man/man1/g++-11.1.gz /usr/share/man/man1/g++.1.gz /usr/share/man/man1/gcc-11.1.gz /usr/share/man/man1/gcc-ar-11.1.gz /usr/share/man/man1/gcc-ar.1.gz /usr/share/man/man1/gcc-nm-11.1.gz /usr/share/man/man1/gcc-nm.1.gz /usr/share/man/man1/gcc-ranlib-11.1.gz /usr/share/man/man1/gcc-ranlib.1.gz /usr/share/man/man1/gcc.1.gz /usr/share/man/man1/gcov-11.1.gz /usr/share/man/man1/gcov-dump-11.1.gz /usr/share/man/man1/gcov-dump.1.gz /usr/share/man/man1/gcov-tool-11.1.gz /usr/share/man/man1/gcov-tool.1.gz /usr/share/man/man1/gcov.1.gz /usr/share/man/man1/gencat.1.gz /usr/share/man/man1/gmake.1.gz /usr/share/man/man1/gold.1.gz /usr/share/man/man1/gprof.1.gz /usr/share/man/man1/h2ph.1.gz /usr/share/man/man1/h2xs.1.gz /usr/share/man/man1/instmodsh.1.gz /usr/share/man/man1/json_pp.1.gz /usr/share/man/man1/ld.1.gz /usr/share/man/man1/ld.bfd.1.gz /usr/share/man/man1/ld.gold.1.gz /usr/share/man/man1/libnetcfg.1.gz /usr/share/man/man1/lto-dump-11.1.gz /usr/share/man/man1/lzcat.1.gz /usr/share/man/man1/lzcmp.1.gz /usr/share/man/man1/lzdiff.1.gz /usr/share/man/man1/lzegrep.1.gz /usr/share/man/man1/lzfgrep.1.gz /usr/share/man/man1/lzgrep.1.gz /usr/share/man/man1/lzless.1.gz /usr/share/man/man1/lzma.1.gz /usr/share/man/man1/lzmainfo.1.gz /usr/share/man/man1/lzmore.1.gz /usr/share/man/man1/make-first-existing-target.1.gz /usr/share/man/man1/make.1.gz /usr/share/man/man1/nm.1.gz /usr/share/man/man1/objcopy.1.gz /usr/share/man/man1/objdump.1.gz /usr/share/man/man1/patch.1.gz /usr/share/man/man1/perl5.34-x86_64-linux-gnu.1.gz /usr/share/man/man1/perlbug.1.gz /usr/share/man/man1/perlivp.1.gz /usr/share/man/man1/perlthanks.1.gz /usr/share/man/man1/piconv.1.gz /usr/share/man/man1/pl2pm.1.gz /usr/share/man/man1/pod2html.1.gz /usr/share/man/man1/pod2man.1.gz /usr/share/man/man1/pod2text.1.gz /usr/share/man/man1/pod2usage.1.gz /usr/share/man/man1/podchecker.1.gz /usr/share/man/man1/prove.1.gz /usr/share/man/man1/ptar.1.gz /usr/share/man/man1/ptardiff.1.gz /usr/share/man/man1/ptargrep.1.gz /usr/share/man/man1/ranlib.1.gz /usr/share/man/man1/readelf.1.gz /usr/share/man/man1/rpcgen.1.gz /usr/share/man/man1/shasum.1.gz /usr/share/man/man1/size.1.gz /usr/share/man/man1/splain.1.gz /usr/share/man/man1/streamzip.1.gz /usr/share/man/man1/strings.1.gz /usr/share/man/man1/strip.1.gz /usr/share/man/man1/unlzma.1.gz /usr/share/man/man1/unxz.1.gz /usr/share/man/man1/x86_64-linux-gnu-addr2line.1.gz /usr/share/man/man1/x86_64-linux-gnu-ar.1.gz /usr/share/man/man1/x86_64-linux-gnu-as.1.gz /usr/share/man/man1/x86_64-linux-gnu-c++filt.1.gz /usr/share/man/man1/x86_64-linux-gnu-cpp-11.1.gz /usr/share/man/man1/x86_64-linux-gnu-cpp.1.gz /usr/share/man/man1/x86_64-linux-gnu-dwp.1.gz /usr/share/man/man1/x86_64-linux-gnu-elfedit.1.gz /usr/share/man/man1/x86_64-linux-gnu-g++-11.1.gz /usr/share/man/man1/x86_64-linux-gnu-g++.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcc-11.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcc-ar-11.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcc-ar.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcc-nm-11.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcc-nm.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcc-ranlib-11.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcc-ranlib.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcc.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcov-11.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcov-dump-11.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcov-dump.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcov-tool-11.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcov-tool.1.gz /usr/share/man/man1/x86_64-linux-gnu-gcov.1.gz /usr/share/man/man1/x86_64-linux-gnu-gold.1.gz /usr/share/man/man1/x86_64-linux-gnu-gprof.1.gz /usr/share/man/man1/x86_64-linux-gnu-ld.1.gz /usr/share/man/man1/x86_64-linux-gnu-ld.bfd.1.gz /usr/share/man/man1/x86_64-linux-gnu-ld.gold.1.gz /usr/share/man/man1/x86_64-linux-gnu-lto-dump-11.1.gz /usr/share/man/man1/x86_64-linux-gnu-nm.1.gz /usr/share/man/man1/x86_64-linux-gnu-objcopy.1.gz /usr/share/man/man1/x86_64-linux-gnu-objdump.1.gz /usr/share/man/man1/x86_64-linux-gnu-ranlib.1.gz /usr/share/man/man1/x86_64-linux-gnu-readelf.1.gz /usr/share/man/man1/x86_64-linux-gnu-size.1.gz /usr/share/man/man1/x86_64-linux-gnu-strings.1.gz /usr/share/man/man1/x86_64-linux-gnu-strip.1.gz /usr/share/man/man1/xsubpp.1.gz /usr/share/man/man1/xz.1.gz /usr/share/man/man1/xzcat.1.gz /usr/share/man/man1/xzcmp.1.gz /usr/share/man/man1/xzdiff.1.gz /usr/share/man/man1/xzegrep.1.gz /usr/share/man/man1/xzfgrep.1.gz /usr/share/man/man1/xzgrep.1.gz /usr/share/man/man1/xzless.1.gz /usr/share/man/man1/xzmore.1.gz /usr/share/man/man1/zipdetails.1.gz /exports/usr/share/man/man1/ \
  ; mv /usr/share/man/man3/bindresvport.3t.gz /usr/share/man/man3/crypt_checksalt.3.gz /usr/share/man/man3/crypt_gensalt_ra.3.gz /usr/share/man/man3/crypt_gensalt_rn.3.gz /usr/share/man/man3/crypt_gensalt.3.gz /usr/share/man/man3/crypt_preferred_method.3.gz /usr/share/man/man3/crypt_r.3.gz /usr/share/man/man3/crypt_ra.3.gz /usr/share/man/man3/crypt_rn.3.gz /usr/share/man/man3/crypt.3.gz /usr/share/man/man3/des_crypt.3t.gz /usr/share/man/man3/Dpkg::Arch.3perl.gz /usr/share/man/man3/Dpkg::Build::Env.3perl.gz /usr/share/man/man3/Dpkg::Build::Info.3perl.gz /usr/share/man/man3/Dpkg::Build::Types.3perl.gz /usr/share/man/man3/Dpkg::BuildFlags.3perl.gz /usr/share/man/man3/Dpkg::BuildOptions.3perl.gz /usr/share/man/man3/Dpkg::BuildProfiles.3perl.gz /usr/share/man/man3/Dpkg::Changelog::Debian.3perl.gz /usr/share/man/man3/Dpkg::Changelog::Entry::Debian.3perl.gz /usr/share/man/man3/Dpkg::Changelog::Entry.3perl.gz /usr/share/man/man3/Dpkg::Changelog::Parse.3perl.gz /usr/share/man/man3/Dpkg::Changelog.3perl.gz /usr/share/man/man3/Dpkg::Checksums.3perl.gz /usr/share/man/man3/Dpkg::Compression::FileHandle.3perl.gz /usr/share/man/man3/Dpkg::Compression::Process.3perl.gz /usr/share/man/man3/Dpkg::Compression.3perl.gz /usr/share/man/man3/Dpkg::Conf.3perl.gz /usr/share/man/man3/Dpkg::Control::Changelog.3perl.gz /usr/share/man/man3/Dpkg::Control::Fields.3perl.gz /usr/share/man/man3/Dpkg::Control::FieldsCore.3perl.gz /usr/share/man/man3/Dpkg::Control::Hash.3perl.gz /usr/share/man/man3/Dpkg::Control::HashCore.3perl.gz /usr/share/man/man3/Dpkg::Control::Info.3perl.gz /usr/share/man/man3/Dpkg::Control::Tests::Entry.3perl.gz /usr/share/man/man3/Dpkg::Control::Tests.3perl.gz /usr/share/man/man3/Dpkg::Control::Types.3perl.gz /usr/share/man/man3/Dpkg::Control.3perl.gz /usr/share/man/man3/Dpkg::Deps::AND.3perl.gz /usr/share/man/man3/Dpkg::Deps::KnownFacts.3perl.gz /usr/share/man/man3/Dpkg::Deps::Multiple.3perl.gz /usr/share/man/man3/Dpkg::Deps::OR.3perl.gz /usr/share/man/man3/Dpkg::Deps::Simple.3perl.gz /usr/share/man/man3/Dpkg::Deps::Union.3perl.gz /usr/share/man/man3/Dpkg::Deps.3perl.gz /usr/share/man/man3/Dpkg::Exit.3perl.gz /usr/share/man/man3/Dpkg::Gettext.3perl.gz /usr/share/man/man3/Dpkg::Index.3perl.gz /usr/share/man/man3/Dpkg::Interface::Storable.3perl.gz /usr/share/man/man3/Dpkg::IPC.3perl.gz /usr/share/man/man3/Dpkg::Path.3perl.gz /usr/share/man/man3/Dpkg::Source::Format.3perl.gz /usr/share/man/man3/Dpkg::Source::Package.3perl.gz /usr/share/man/man3/Dpkg::Substvars.3perl.gz /usr/share/man/man3/Dpkg::Vendor::Debian.3perl.gz /usr/share/man/man3/Dpkg::Vendor::Default.3perl.gz /usr/share/man/man3/Dpkg::Vendor::Ubuntu.3perl.gz /usr/share/man/man3/Dpkg::Vendor.3perl.gz /usr/share/man/man3/Dpkg::Version.3perl.gz /usr/share/man/man3/Dpkg.3perl.gz /usr/share/man/man3/getnetconfig.3t.gz /usr/share/man/man3/getnetpath.3t.gz /usr/share/man/man3/getrpcent.3t.gz /usr/share/man/man3/getrpcport.3t.gz /usr/share/man/man3/rpc_clnt_auth.3t.gz /usr/share/man/man3/rpc_clnt_calls.3t.gz /usr/share/man/man3/rpc_clnt_create.3t.gz /usr/share/man/man3/rpc_gss_get_error.3t.gz /usr/share/man/man3/rpc_gss_get_mech_info.3t.gz /usr/share/man/man3/rpc_gss_get_mechanisms.3t.gz /usr/share/man/man3/rpc_gss_get_principal_name.3t.gz /usr/share/man/man3/rpc_gss_get_versions.3t.gz /usr/share/man/man3/rpc_gss_getcred.3t.gz /usr/share/man/man3/rpc_gss_is_installed.3t.gz /usr/share/man/man3/rpc_gss_max_data_length.3t.gz /usr/share/man/man3/rpc_gss_mech_to_oid.3t.gz /usr/share/man/man3/rpc_gss_qop_to_num.3t.gz /usr/share/man/man3/rpc_gss_seccreate.3t.gz /usr/share/man/man3/rpc_gss_set_callback.3t.gz /usr/share/man/man3/rpc_gss_set_defaults.3t.gz /usr/share/man/man3/rpc_gss_set_svc_name.3t.gz /usr/share/man/man3/rpc_gss_svc_max_data_length.3t.gz /usr/share/man/man3/rpc_secure.3t.gz /usr/share/man/man3/rpc_soc.3t.gz /usr/share/man/man3/rpc_svc_calls.3t.gz /usr/share/man/man3/rpc_svc_create.3t.gz /usr/share/man/man3/rpc_svc_err.3t.gz /usr/share/man/man3/rpc_svc_reg.3t.gz /usr/share/man/man3/rpc_xdr.3t.gz /usr/share/man/man3/rpc.3t.gz /usr/share/man/man3/rpcbind.3t.gz /usr/share/man/man3/rpcsec_gss.3t.gz /usr/share/man/man3/rtime.3t.gz /exports/usr/share/man/man3/ \
  ; mv /usr/share/man/man5/crypt.5.gz /usr/share/man/man5/deb-buildinfo.5.gz /usr/share/man/man5/deb-changelog.5.gz /usr/share/man/man5/deb-changes.5.gz /usr/share/man/man5/deb-conffiles.5.gz /usr/share/man/man5/deb-control.5.gz /usr/share/man/man5/deb-extra-override.5.gz /usr/share/man/man5/deb-md5sums.5.gz /usr/share/man/man5/deb-old.5.gz /usr/share/man/man5/deb-origin.5.gz /usr/share/man/man5/deb-override.5.gz /usr/share/man/man5/deb-postinst.5.gz /usr/share/man/man5/deb-postrm.5.gz /usr/share/man/man5/deb-preinst.5.gz /usr/share/man/man5/deb-prerm.5.gz /usr/share/man/man5/deb-shlibs.5.gz /usr/share/man/man5/deb-split.5.gz /usr/share/man/man5/deb-src-control.5.gz /usr/share/man/man5/deb-src-files.5.gz /usr/share/man/man5/deb-src-rules.5.gz /usr/share/man/man5/deb-src-symbols.5.gz /usr/share/man/man5/deb-substvars.5.gz /usr/share/man/man5/deb-symbols.5.gz /usr/share/man/man5/deb-triggers.5.gz /usr/share/man/man5/deb.5.gz /usr/share/man/man5/deb822.5.gz /usr/share/man/man5/dsc.5.gz /exports/usr/share/man/man5/ \
  ; mv /usr/share/man/man7/deb-version.7.gz /usr/share/man/man7/fsf-funding.7gcc.gz /usr/share/man/man7/gfdl.7gcc.gz /usr/share/man/man7/gpl.7gcc.gz /exports/usr/share/man/man7/ \
  ; mv /usr/share/perl5/Dpkg.pm /usr/share/perl5/Dpkg /exports/usr/share/perl5/ \
  ; mv /usr/share/zsh/vendor-completions/_dpkg-parsechangelog /exports/usr/share/zsh/vendor-completions/

# GIT-CRYPT
FROM base AS git-crypt
COPY --from=build-essential /exports/ /
COPY --from=apteryx /exports/ /
COPY --from=clone /exports/ /
COPY --from=make /exports/ /
RUN set -e \
  ; apteryx libssl-dev \
  ; clone --https --tag='0.7.0' https://github.com/AGWA/git-crypt \
  ; cd /root/src/github.com/AGWA/git-crypt \
  ; CXXFLAGS='-static -DOPENSSL_API_COMPAT=0x30000000L' make \
  ; make install \
  ; mv git-crypt /usr/local/bin/git-crypt
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/git-crypt /exports/usr/local/bin/

# ZSH
FROM base AS zsh
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx zsh='5.8.1-1'
RUN set -e \
  ; mkdir -p /exports/etc/ /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/share/ /exports/usr/share/bug/ /exports/usr/share/doc/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ /exports/usr/share/menu/ /exports/usr/share/zsh/ \
  ; mv /etc/shells /etc/zsh /exports/etc/ \
  ; mv /usr/bin/rzsh /usr/bin/zsh /usr/bin/zsh5 /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu/zsh /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/local/share/zsh /exports/usr/local/share/ \
  ; mv /usr/share/bug/zsh /usr/share/bug/zsh-common /exports/usr/share/bug/ \
  ; mv /usr/share/doc/zsh-common /usr/share/doc/zsh /exports/usr/share/doc/ \
  ; mv /usr/share/lintian/overrides/zsh /usr/share/lintian/overrides/zsh-common /exports/usr/share/lintian/overrides/ \
  ; mv /usr/share/man/man1/rzsh.1.gz /usr/share/man/man1/zsh.1.gz /usr/share/man/man1/zshall.1.gz /usr/share/man/man1/zshbuiltins.1.gz /usr/share/man/man1/zshcalsys.1.gz /usr/share/man/man1/zshcompctl.1.gz /usr/share/man/man1/zshcompsys.1.gz /usr/share/man/man1/zshcompwid.1.gz /usr/share/man/man1/zshcontrib.1.gz /usr/share/man/man1/zshexpn.1.gz /usr/share/man/man1/zshmisc.1.gz /usr/share/man/man1/zshmodules.1.gz /usr/share/man/man1/zshoptions.1.gz /usr/share/man/man1/zshparam.1.gz /usr/share/man/man1/zshroadmap.1.gz /usr/share/man/man1/zshtcpsys.1.gz /usr/share/man/man1/zshzftpsys.1.gz /usr/share/man/man1/zshzle.1.gz /exports/usr/share/man/man1/ \
  ; mv /usr/share/menu/zsh-common /exports/usr/share/menu/ \
  ; mv /usr/share/zsh/5.* /usr/share/zsh/functions /usr/share/zsh/help /exports/usr/share/zsh/

# DOTFILES
FROM base AS dotfiles
COPY --from=clone /exports/ /
COPY --from=git-crypt /exports/ /
COPY ./secret/dotfiles-key /tmp/dotfiles-key
RUN set -e \
  ; clone --https --tag='v1.98.59' https://github.com/stayradiated/dotfiles \
  ; cd /root/src/github.com/stayradiated/dotfiles \
  ; git-crypt unlock /tmp/dotfiles-key \
  ; rm /tmp/dotfiles-key \
  ; mv /root/src/github.com/stayradiated/dotfiles /root/dotfiles \
  ; rm -rf src
RUN set -e \
  ; mkdir -p /exports/root/ \
  ; mv /root/dotfiles /exports/root/

# N
FROM base AS n
COPY --from=wget /exports/ /
RUN set -e \
  ; wget "https://raw.githubusercontent.com/tj/n/v10.0.0/bin/n" -O /usr/local/bin/n \
  ; chmod +x /usr/local/bin/n
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/n /exports/usr/local/bin/

# SHELL-ROOT
FROM base AS shell-root
COPY --from=apteryx /exports/ /
COPY --from=dotfiles /exports/ /
COPY --from=zsh /exports/ /
COPY ./secret/admin-passwd /tmp/admin-passwd
RUN set -e \
  ; echo "* - nofile 100000" >> /etc/security/limits.conf \
  ; echo "session required pam_limits.so" >> /etc/pam.d/common-session \
  ; useradd -s /bin/zsh --create-home admin \
  ; echo "admin:$(cat /tmp/admin-passwd)" | chpasswd --encrypted \
  ; adduser admin sudo \
  ; mv /root/dotfiles /home/admin/dotfiles \
  ; mkdir -p /home/admin/.cache /home/admin/.config /home/admin/.local/share \
  ; chown -R admin:admin /home/admin

# NODE
FROM base AS node
COPY --from=n /exports/ /
RUN set -e \
  ; n lts \
  ; n v22.9.0 \
  ; npm install -g npm
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/include/ /exports/usr/local/lib/ /exports/usr/local/ \
  ; mv /usr/local/bin/n /usr/local/bin/node /usr/local/bin/npm /usr/local/bin/npx /exports/usr/local/bin/ \
  ; mv /usr/local/include/node /exports/usr/local/include/ \
  ; mv /usr/local/lib/node_modules /exports/usr/local/lib/ \
  ; mv /usr/local/n /exports/usr/local/

# UV
FROM base AS uv
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/uv.tgz 'https://github.com/astral-sh/uv/releases/download/0.4.20/uv-x86_64-unknown-linux-gnu.tar.gz' \
  ; tar -xzvf /tmp/uv.tgz -C /tmp \
  ; rm /tmp/uv.tgz \
  ; mv /tmp/uv-x86_64-unknown-linux-gnu/uv /tmp/uv-x86_64-unknown-linux-gnu/uvx /usr/local/bin/ \
  ; rmdir /tmp/uv-x86_64-unknown-linux-gnu \
  ; mkdir -p /usr/local/uv/tools /usr/local/uv/bin /usr/local/uv/python
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/ \
  ; mv /usr/local/bin/uv /usr/local/bin/uvx /exports/usr/local/bin/ \
  ; mv /usr/local/uv /exports/usr/local/

# BZIP2
FROM base AS bzip2
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx bzip2='1.0.8-5build1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man1/ \
  ; mv /usr/bin/bunzip2 /usr/bin/bzcat /usr/bin/bzcmp /usr/bin/bzdiff /usr/bin/bzegrep /usr/bin/bzexe /usr/bin/bzfgrep /usr/bin/bzgrep /usr/bin/bzip2 /usr/bin/bzip2recover /usr/bin/bzless /usr/bin/bzmore /exports/usr/bin/ \
  ; mv /usr/share/doc/bzip2 /exports/usr/share/doc/ \
  ; mv /usr/share/man/man1/bunzip2.1.gz /usr/share/man/man1/bzcat.1.gz /usr/share/man/man1/bzcmp.1.gz /usr/share/man/man1/bzdiff.1.gz /usr/share/man/man1/bzegrep.1.gz /usr/share/man/man1/bzexe.1.gz /usr/share/man/man1/bzfgrep.1.gz /usr/share/man/man1/bzgrep.1.gz /usr/share/man/man1/bzip2.1.gz /usr/share/man/man1/bzip2recover.1.gz /usr/share/man/man1/bzless.1.gz /usr/share/man/man1/bzmore.1.gz /exports/usr/share/man/man1/

# XZ
FROM base AS xz
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx xz-utils='5.2.5-2ubuntu1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/share/man/man1/ \
  ; mv /usr/bin/xz /exports/usr/bin/ \
  ; mv /usr/share/man/man1/xz.1.gz /exports/usr/share/man/man1/

# UNZIP
FROM base AS unzip
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx unzip='6.0-26ubuntu3.2'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/share/man/man1/ \
  ; mv /usr/bin/unzip /exports/usr/bin/ \
  ; mv /usr/share/man/man1/unzip.1.gz /exports/usr/share/man/man1/

# RUST
FROM base AS rust
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O rust.sh 'https://sh.rustup.rs' \
  ; sh rust.sh -y --default-toolchain '1.81.0' \
  ; rm rust.sh
RUN set -e \
  ; mkdir -p /exports/root/ \
  ; mv /root/.cargo /root/.rustup /exports/root/

# AR
FROM base AS ar
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx binutils='2.38-4ubuntu2.6' \
  ; mv /usr/bin/x86_64-linux-gnu-ar /usr/bin/ar
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/bin/ar /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu/libbfd-2.*-system.so /exports/usr/lib/x86_64-linux-gnu/

# FZF
FROM base AS fzf
COPY --from=clone /exports/ /
RUN set -e \
  ; clone --https --tag='v0.55.0' https://github.com/junegunn/fzf \
  ; mv /root/src/github.com/junegunn/fzf /usr/local/share/fzf \
  ; rm -rf /root/src \
  ; /usr/local/share/fzf/install --bin
RUN set -e \
  ; mkdir -p /exports/usr/local/share/ \
  ; mv /usr/local/share/fzf /exports/usr/local/share/

# ANTIBODY
FROM base AS antibody
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/install-antibody.sh https://git.io/antibody \
  ; sh /tmp/install-antibody.sh -b /usr/local/bin \
  ; rm /tmp/install-antibody.sh
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/antibody /exports/usr/local/bin/

# SHELL-ADMIN
FROM shell-root AS shell-admin
USER admin
WORKDIR /home/admin
ENV \
  PATH=/home/admin/dotfiles/bin:${PATH}
RUN set -e \
  ; mkdir -p /home/admin/exports \
  ; mkdir -p /home/admin/.local/tmp

# YARN
FROM base AS yarn
COPY --from=node /exports/ /
RUN set -e \
  ; npm install -g 'yarn@1.22.22'
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/ \
  ; mv /usr/local/bin/yarn /exports/usr/local/bin/ \
  ; mv /usr/local/lib/node_modules/yarn /exports/usr/local/lib/node_modules/

# SXHKD
FROM base AS sxhkd
COPY --from=build-essential /exports/ /
COPY --from=apteryx /exports/ /
COPY --from=clone /exports/ /
COPY --from=make /exports/ /
RUN set -e \
  ; apteryx libxcb-util-dev libxcb-keysyms1-dev \
  ; clone --https --tag='0.6.2' https://github.com/baskerville/sxhkd \
  ; cd /root/src/github.com/baskerville/sxhkd \
  ; make all \
  ; make install \
  ; rm -rf /root/src
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/share/man/man1/ \
  ; mv /usr/local/bin/sxhkd /exports/usr/local/bin/ \
  ; mv /usr/local/share/man/man1/sxhkd.1 /exports/usr/local/share/man/man1/

# BSPWM
FROM base AS bspwm
COPY --from=apteryx /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=clone /exports/ /
COPY --from=make /exports/ /
RUN set -e \
  ; apteryx libxcb-ewmh-dev libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-randr0-dev libxcb-shape0-dev libxcb-util-dev libxcb-xinerama0-dev \
  ; clone --https --tag='0.9.10' https://github.com/baskerville/bspwm \
  ; cd /root/src/github.com/baskerville/bspwm \
  ; make all \
  ; make install \
  ; rm -rf /root/src
RUN set -e \
  ; mkdir -p /exports/usr/include/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ /exports/usr/local/bin/ \
  ; mv /usr/include/GL /usr/include/X11 /usr/include/xcb /exports/usr/include/ \
  ; mv /usr/lib/x86_64-linux-gnu/libXau.a /usr/lib/x86_64-linux-gnu/libXau.so /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-ewmh.a /usr/lib/x86_64-linux-gnu/libxcb-ewmh.so /usr/lib/x86_64-linux-gnu/libxcb-ewmh.so.2 /usr/lib/x86_64-linux-gnu/libxcb-ewmh.so.2.0.0 /usr/lib/x86_64-linux-gnu/libxcb-icccm.a /usr/lib/x86_64-linux-gnu/libxcb-icccm.so /usr/lib/x86_64-linux-gnu/libxcb-icccm.so.4 /usr/lib/x86_64-linux-gnu/libxcb-icccm.so.4.0.0 /usr/lib/x86_64-linux-gnu/libxcb-keysyms.a /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so.1 /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.a /usr/lib/x86_64-linux-gnu/libxcb-randr.so /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-render.a /usr/lib/x86_64-linux-gnu/libxcb-render.so /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.a /usr/lib/x86_64-linux-gnu/libxcb-shape.so /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-util.a /usr/lib/x86_64-linux-gnu/libxcb-util.so /usr/lib/x86_64-linux-gnu/libxcb-util.so.1 /usr/lib/x86_64-linux-gnu/libxcb-util.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xinerama.a /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.a /usr/lib/x86_64-linux-gnu/libxcb.so /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.a /usr/lib/x86_64-linux-gnu/libXdmcp.so /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/lib/x86_64-linux-gnu/pkgconfig/pthread-stubs.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xau.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-atom.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-aux.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-event.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-ewmh.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-icccm.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-keysyms.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-randr.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-render.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-shape.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-util.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-xinerama.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xdmcp.pc /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ \
  ; mv /usr/local/bin/bspc /usr/local/bin/bspwm /exports/usr/local/bin/

# NEOVIM
FROM base AS neovim
COPY --from=wget /exports/ /
COPY --from=uv /exports/ /
ENV \
  UV_LINK_MODE=copy \
  UV_COMPILE_BYTECODE=1 \
  UV_PYTHON_DOWNLOADS=manual \
  UV_TOOL_DIR=/usr/local/uv/tools \
  UV_TOOL_BIN_DIR=/usr/local/uv/bin \
  UV_PYTHON_INSTALL_DIR=/usr/local/uv/python
RUN set -e \
  ; wget -O /tmp/nvim.appimage 'https://github.com/neovim/neovim/releases/download/v0.10.2/nvim.appimage' \
  ; chmod +x /tmp/nvim.appimage \
  ; /tmp/nvim.appimage --appimage-extract \
  ; rm /tmp/nvim.appimage \
  ; mv squashfs-root/usr/bin/nvim /usr/local/bin/nvim \
  ; mv squashfs-root/usr/share/nvim /usr/local/share/nvim \
  ; rm -r squashfs-root \
  ; find /usr/local/share/nvim -type d -print0 | xargs -0 chmod 0775 \
  ; find /usr/local/share/nvim -type f -print0 | xargs -0 chmod 0664 \
  ; uv pip install --system neovim msgpack neovim-remote
RUN set -e \
  ; mkdir -p /exports/usr/include/ /exports/usr/local/bin/ /exports/usr/local/lib/python3.10/ /exports/usr/local/share/ \
  ; mv /usr/include/python3.10 /exports/usr/include/ \
  ; mv /usr/local/bin/nvim /usr/local/bin/nvr /exports/usr/local/bin/ \
  ; mv /usr/local/lib/python3.10/dist-packages /exports/usr/local/lib/python3.10/ \
  ; mv /usr/local/share/nvim /exports/usr/local/share/

# TMUX
FROM base AS tmux
COPY --from=apteryx /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=make /exports/ /
COPY --from=wget /exports/ /
RUN set -e \
  ; apteryx libncurses5-dev libevent-dev bison \
  ; cd /root \
  ; wget -O /tmp/tmux.tgz 'https://github.com/tmux/tmux/releases/download/3.5a/tmux-3.5a.tar.gz' \
  ; tar xzvf /tmp/tmux.tgz \
  ; rm /tmp/tmux.tgz \
  ; cd 'tmux-3.5a' \
  ; ./configure \
  ; make \
  ; make install \
  ; cd .. \
  ; rm -r 'tmux-3.5a'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/include/ /exports/usr/lib/valgrind/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ /exports/usr/local/bin/ /exports/usr/local/share/man/ /exports/usr/share/doc/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ \
  ; mv /usr/bin/ncurses5-config /usr/bin/ncurses6-config /usr/bin/ncursesw5-config /usr/bin/ncursesw6-config /exports/usr/bin/ \
  ; mv /usr/include/curses.h /usr/include/cursesapp.h /usr/include/cursesf.h /usr/include/cursesm.h /usr/include/cursesp.h /usr/include/cursesw.h /usr/include/cursslk.h /usr/include/eti.h /usr/include/etip.h /usr/include/evdns.h /usr/include/event.h /usr/include/event2 /usr/include/evhttp.h /usr/include/evrpc.h /usr/include/evutil.h /usr/include/form.h /usr/include/menu.h /usr/include/nc_tparm.h /usr/include/ncurses_dll.h /usr/include/ncurses.h /usr/include/ncursesw /usr/include/panel.h /usr/include/term_entry.h /usr/include/term.h /usr/include/termcap.h /usr/include/tic.h /usr/include/unctrl.h /exports/usr/include/ \
  ; mv /usr/lib/valgrind/ncurses.supp /exports/usr/lib/valgrind/ \
  ; mv /usr/lib/x86_64-linux-gnu/libcurses.a /usr/lib/x86_64-linux-gnu/libcurses.so /usr/lib/x86_64-linux-gnu/libevent_core-*.so.* /usr/lib/x86_64-linux-gnu/libevent_core.a /usr/lib/x86_64-linux-gnu/libevent_core.so /usr/lib/x86_64-linux-gnu/libevent_extra-*.so.* /usr/lib/x86_64-linux-gnu/libevent_extra.a /usr/lib/x86_64-linux-gnu/libevent_extra.so /usr/lib/x86_64-linux-gnu/libevent_openssl-*.so.* /usr/lib/x86_64-linux-gnu/libevent_openssl.a /usr/lib/x86_64-linux-gnu/libevent_openssl.so /usr/lib/x86_64-linux-gnu/libevent_pthreads-*.so.* /usr/lib/x86_64-linux-gnu/libevent_pthreads.a /usr/lib/x86_64-linux-gnu/libevent_pthreads.so /usr/lib/x86_64-linux-gnu/libevent-*.so.* /usr/lib/x86_64-linux-gnu/libevent.a /usr/lib/x86_64-linux-gnu/libevent.so /usr/lib/x86_64-linux-gnu/libform.a /usr/lib/x86_64-linux-gnu/libform.so /usr/lib/x86_64-linux-gnu/libformw.a /usr/lib/x86_64-linux-gnu/libformw.so /usr/lib/x86_64-linux-gnu/libmenu.a /usr/lib/x86_64-linux-gnu/libmenu.so /usr/lib/x86_64-linux-gnu/libmenuw.a /usr/lib/x86_64-linux-gnu/libmenuw.so /usr/lib/x86_64-linux-gnu/libncurses.a /usr/lib/x86_64-linux-gnu/libncurses.so /usr/lib/x86_64-linux-gnu/libncurses++.a /usr/lib/x86_64-linux-gnu/libncurses++w.a /usr/lib/x86_64-linux-gnu/libncursesw.a /usr/lib/x86_64-linux-gnu/libncursesw.so /usr/lib/x86_64-linux-gnu/libpanel.a /usr/lib/x86_64-linux-gnu/libpanel.so /usr/lib/x86_64-linux-gnu/libpanelw.a /usr/lib/x86_64-linux-gnu/libpanelw.so /usr/lib/x86_64-linux-gnu/libtermcap.a /usr/lib/x86_64-linux-gnu/libtermcap.so /usr/lib/x86_64-linux-gnu/libtic.a /usr/lib/x86_64-linux-gnu/libtic.so /usr/lib/x86_64-linux-gnu/libtinfo.a /usr/lib/x86_64-linux-gnu/libtinfo.so /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/lib/x86_64-linux-gnu/pkgconfig/form.pc /usr/lib/x86_64-linux-gnu/pkgconfig/formw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent_core.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent_extra.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent_openssl.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent_pthreads.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent.pc /usr/lib/x86_64-linux-gnu/pkgconfig/menu.pc /usr/lib/x86_64-linux-gnu/pkgconfig/menuw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncurses.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncurses++.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncurses++w.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncursesw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/panel.pc /usr/lib/x86_64-linux-gnu/pkgconfig/panelw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/tic.pc /usr/lib/x86_64-linux-gnu/pkgconfig/tinfo.pc /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ \
  ; mv /usr/local/bin/tmux /exports/usr/local/bin/ \
  ; mv /usr/local/share/man/man1 /exports/usr/local/share/man/ \
  ; mv /usr/share/doc/libevent-2.1-7 /usr/share/doc/libevent-core-2.1-7 /usr/share/doc/libevent-dev /usr/share/doc/libevent-extra-2.1-7 /usr/share/doc/libevent-openssl-2.1-7 /usr/share/doc/libevent-pthreads-2.1-7 /usr/share/doc/libncurses-dev /usr/share/doc/libncurses5-dev /exports/usr/share/doc/ \
  ; mv /usr/share/lintian/overrides/libevent-openssl-2.1-7 /exports/usr/share/lintian/overrides/ \
  ; mv /usr/share/man/man1/ncurses5-config.1.gz /usr/share/man/man1/ncurses6-config.1.gz /usr/share/man/man1/ncursesw5-config.1.gz /usr/share/man/man1/ncursesw6-config.1.gz /exports/usr/share/man/man1/

# RANGER
FROM base AS ranger
COPY --from=uv /exports/ /
ENV \
  UV_LINK_MODE=copy \
  UV_COMPILE_BYTECODE=1 \
  UV_PYTHON_DOWNLOADS=manual \
  UV_TOOL_DIR=/usr/local/uv/tools \
  UV_TOOL_BIN_DIR=/usr/local/uv/bin \
  UV_PYTHON_INSTALL_DIR=/usr/local/uv/python
RUN set -e \
  ; uv tool install ranger-fm=='1.9.3' \
  ; ln -s /usr/local/uv/bin/ranger /usr/local/bin/ranger
RUN set -e \
  ; mkdir -p /exports/usr/local/ /exports/usr/local/bin/ \
  ; mv /usr/local/uv /exports/usr/local/ \
  ; mv /usr/local/bin/ranger /exports/usr/local/bin/

# DIFF-SO-FANCY
FROM base AS diff-so-fancy
COPY --from=node /exports/ /
RUN set -e \
  ; npm install -g 'diff-so-fancy@1.4.3'
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/ \
  ; mv /usr/local/bin/diff-so-fancy /exports/usr/local/bin/ \
  ; mv /usr/local/lib/node_modules/diff-so-fancy /exports/usr/local/lib/node_modules/

# FIREFOX
FROM base AS firefox
COPY --from=apteryx /exports/ /
COPY --from=wget /exports/ /
COPY --from=bzip2 /exports/ /
RUN set -e \
  ; wget -O /tmp/firefox.tar.bz2 https://download-installer.cdn.mozilla.net/pub/firefox/releases/131.0.2/linux-x86_64/en-US/firefox-131.0.2.tar.bz2 \
  ; cd /opt \
  ; tar xjvf /tmp/firefox.tar.bz2 \
  ; rm /tmp/firefox.tar.bz2 \
  ; ln -s /opt/firefox/firefox /usr/local/bin/firefox \
  ; echo "[Desktop Entry]" >> /desktop \
  ; echo "Version=1.0" >> /desktop \
  ; echo "Name=Firefox Web Browser" >> /desktop \
  ; echo "Comment=Browse the World Wide Web" >> /desktop \
  ; echo "GenericName=Web Browser" >> /desktop \
  ; echo "Keywords=Internet;WWW;Browser;Web;Explorer" >> /desktop \
  ; echo "Exec=firefox %u" >> /desktop \
  ; echo "Terminal=false" >> /desktop \
  ; echo "X-MultipleArgs=false" >> /desktop \
  ; echo "Type=Application" >> /desktop \
  ; echo "Icon=firefox" >> /desktop \
  ; echo "Categories=GNOME;GTK;Network;WebBrowser;" >> /desktop \
  ; echo "MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;" >> /desktop \
  ; echo "StartupNotify=true" >> /desktop \
  ; mv /desktop /usr/share/applications/firefox.desktop \
  ; apteryx libdbus-glib-1-2
RUN set -e \
  ; mkdir -p /exports/opt/ /exports/usr/local/bin/ /exports/usr/share/applications/ /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /opt/firefox /exports/opt/ \
  ; mv /usr/local/bin/firefox /exports/usr/local/bin/ \
  ; mv /usr/share/applications/firefox.desktop /exports/usr/share/applications/ \
  ; mv /usr/lib/x86_64-linux-gnu/libdbus-glib-1.so.* /exports/usr/lib/x86_64-linux-gnu/

# GOOGLE-CHROME
FROM base AS google-chrome
COPY --from=wget /exports/ /
COPY --from=apteryx /exports/ /
RUN set -e \
  ; curl -s https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  ; sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
  ; apt-get update \
  ; apteryx google-chrome-beta='130.0.6723.31-*'
RUN set -e \
  ; mkdir -p /exports/etc/ /exports/etc/default/ /exports/etc/X11/ /exports/etc/X11/Xsession.d/ /exports/opt/ /exports/usr/bin/ /exports/usr/lib/systemd/user/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/gio/modules/ /exports/usr/libexec/ /exports/usr/local/share/ /exports/usr/sbin/ /exports/usr/share/ /exports/usr/share/applications/ /exports/usr/share/apport/package-hooks/ /exports/usr/share/bug/ /exports/usr/share/dbus-1/services/ /exports/usr/share/doc-base/ /exports/usr/share/doc/ /exports/usr/share/gettext/its/ /exports/usr/share/glib-2.0/schemas/ /exports/usr/share/icons/ /exports/usr/share/icons/hicolor/ /exports/usr/share/icons/hicolor/48x48/ /exports/usr/share/icons/hicolor/48x48/apps/ /exports/usr/share/icons/hicolor/scalable/ /exports/usr/share/info/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ /exports/usr/share/man/man5/ /exports/usr/share/man/man7/ /exports/usr/share/man/man8/ /exports/usr/share/menu/ /exports/usr/share/pkgconfig/ \
  ; mv /etc/dconf /etc/fonts /etc/gtk-3.0 /exports/etc/ \
  ; mv /etc/default/google-chrome-beta /exports/etc/default/ \
  ; mv /etc/X11/xkb /exports/etc/X11/ \
  ; mv /etc/X11/Xsession.d/20dbus_xdg-runtime /exports/etc/X11/Xsession.d/ \
  ; mv /opt/google /exports/opt/ \
  ; mv /usr/bin/google-chrome /usr/bin/google-chrome-beta /exports/usr/bin/ \
  ; mv /usr/lib/systemd/user/dbus.service /usr/lib/systemd/user/dbus.socket /usr/lib/systemd/user/dconf.service /usr/lib/systemd/user/sockets.target.wants /exports/usr/lib/systemd/user/ \
  ; mv /usr/lib/x86_64-linux-gnu/avahi /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0 /usr/lib/x86_64-linux-gnu/gtk-3.0 /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libasound.so.2.0.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0.23609.1 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0.0.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0.0.1 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3.2.9 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3.5.4 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcairo.so.2 /usr/lib/x86_64-linux-gnu/libcairo.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcolord.so.2 /usr/lib/x86_64-linux-gnu/libcolord.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcups.so.2 /usr/lib/x86_64-linux-gnu/libdatrie.so.1 /usr/lib/x86_64-linux-gnu/libdatrie.so.1.4.0 /usr/lib/x86_64-linux-gnu/libdconf.so.1 /usr/lib/x86_64-linux-gnu/libdconf.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdeflate.so.0 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0.0.0 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.0 /usr/lib/x86_64-linux-gnu/libfreebl3.chk /usr/lib/x86_64-linux-gnu/libfreebl3.so /usr/lib/x86_64-linux-gnu/libfreeblpriv3.chk /usr/lib/x86_64-linux-gnu/libfreeblpriv3.so /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.18.1 /usr/lib/x86_64-linux-gnu/libfribidi.so.0 /usr/lib/x86_64-linux-gnu/libfribidi.so.0.4.0 /usr/lib/x86_64-linux-gnu/libgbm.so.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0.4200.8 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0.2404.29 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgtk-3-0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0.2404.29 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.20704.0 /usr/lib/x86_64-linux-gnu/libjbig.so.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2.0.12 /usr/lib/x86_64-linux-gnu/libnspr4.so /usr/lib/x86_64-linux-gnu/libnss3.so /usr/lib/x86_64-linux-gnu/libnssutil3.so /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0.5000.6 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0.5000.6 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0.5000.6 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0.40.0 /usr/lib/x86_64-linux-gnu/libplc4.so /usr/lib/x86_64-linux-gnu/libplds4.so /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.37.0 /usr/lib/x86_64-linux-gnu/libsmime3.so /usr/lib/x86_64-linux-gnu/libssl3.so /usr/lib/x86_64-linux-gnu/libthai.so.0 /usr/lib/x86_64-linux-gnu/libthai.so.0.3.1 /usr/lib/x86_64-linux-gnu/libtiff.so.5 /usr/lib/x86_64-linux-gnu/libtiff.so.5.7.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.20.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0.20.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.20.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0.20.0 /usr/lib/x86_64-linux-gnu/libwebp.so.7 /usr/lib/x86_64-linux-gnu/libwebp.so.7.1.3 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXcursor.so.1 /usr/lib/x86_64-linux-gnu/libXcursor.so.1.0.2 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libXi.so.6 /usr/lib/x86_64-linux-gnu/libXi.so.6.1.0 /usr/lib/x86_64-linux-gnu/libXinerama.so.1 /usr/lib/x86_64-linux-gnu/libXinerama.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrandr.so.2 /usr/lib/x86_64-linux-gnu/libXrandr.so.2.2.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /usr/lib/x86_64-linux-gnu/nss /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/lib/x86_64-linux-gnu/gio/modules/giomodule.cache /usr/lib/x86_64-linux-gnu/gio/modules/libdconfsettings.so /exports/usr/lib/x86_64-linux-gnu/gio/modules/ \
  ; mv /usr/libexec/dconf-service /exports/usr/libexec/ \
  ; mv /usr/local/share/fonts /exports/usr/local/share/ \
  ; mv /usr/sbin/update-icon-caches /exports/usr/sbin/ \
  ; mv /usr/share/alsa /usr/share/appdata /usr/share/fonts /usr/share/gnome-control-center /usr/share/libdrm /usr/share/libthai /usr/share/mime /usr/share/themes /usr/share/X11 /exports/usr/share/ \
  ; mv /usr/share/applications/google-chrome-beta.desktop /exports/usr/share/applications/ \
  ; mv /usr/share/apport/package-hooks/source_fontconfig.py /exports/usr/share/apport/package-hooks/ \
  ; mv /usr/share/bug/fonts-liberation /usr/share/bug/libgbm1 /usr/share/bug/libgtk-3-0 /usr/share/bug/xdg-utils /exports/usr/share/bug/ \
  ; mv /usr/share/dbus-1/services/ca.desrt.dconf.service /exports/usr/share/dbus-1/services/ \
  ; mv /usr/share/doc-base/fontconfig.fontconfig-user /usr/share/doc-base/libpng16-16.libpng16 /usr/share/doc-base/shared-mime-info.shared-mime-info /exports/usr/share/doc-base/ \
  ; mv /usr/share/doc/adwaita-icon-theme /usr/share/doc/dbus-user-session /usr/share/doc/dconf-gsettings-backend /usr/share/doc/dconf-service /usr/share/doc/fontconfig-config /usr/share/doc/fontconfig /usr/share/doc/fonts-liberation /usr/share/doc/google-chrome-beta /usr/share/doc/gtk-update-icon-cache /usr/share/doc/hicolor-icon-theme /usr/share/doc/humanity-icon-theme /usr/share/doc/libasound2-data /usr/share/doc/libasound2 /usr/share/doc/libatk-bridge2.0-0 /usr/share/doc/libatk1.0-0 /usr/share/doc/libatk1.0-data /usr/share/doc/libatspi2.0-0 /usr/share/doc/libavahi-client3 /usr/share/doc/libavahi-common-data /usr/share/doc/libavahi-common3 /usr/share/doc/libcairo-gobject2 /usr/share/doc/libcairo2 /usr/share/doc/libcolord2 /usr/share/doc/libcups2 /usr/share/doc/libdatrie1 /usr/share/doc/libdconf1 /usr/share/doc/libdeflate0 /usr/share/doc/libdrm-common /usr/share/doc/libdrm2 /usr/share/doc/libepoxy0 /usr/share/doc/libfontconfig1 /usr/share/doc/libfreetype6 /usr/share/doc/libfribidi0 /usr/share/doc/libgbm1 /usr/share/doc/libgdk-pixbuf-2.0-0 /usr/share/doc/libgdk-pixbuf2.0-common /usr/share/doc/libgraphite2-3 /usr/share/doc/libgtk-3-0 /usr/share/doc/libgtk-3-common /usr/share/doc/libharfbuzz0b /usr/share/doc/libjbig0 /usr/share/doc/libjpeg-turbo8 /usr/share/doc/libjpeg8 /usr/share/doc/liblcms2-2 /usr/share/doc/libnspr4 /usr/share/doc/libnss3 /usr/share/doc/libpango-1.0-0 /usr/share/doc/libpangocairo-1.0-0 /usr/share/doc/libpangoft2-1.0-0 /usr/share/doc/libpixman-1-0 /usr/share/doc/libpng16-16 /usr/share/doc/libthai-data /usr/share/doc/libthai0 /usr/share/doc/libtiff5 /usr/share/doc/libwayland-client0 /usr/share/doc/libwayland-cursor0 /usr/share/doc/libwayland-egl1 /usr/share/doc/libwayland-server0 /usr/share/doc/libwebp7 /usr/share/doc/libx11-6 /usr/share/doc/libx11-data /usr/share/doc/libxau6 /usr/share/doc/libxcb-render0 /usr/share/doc/libxcb-shm0 /usr/share/doc/libxcb1 /usr/share/doc/libxcomposite1 /usr/share/doc/libxcursor1 /usr/share/doc/libxdamage1 /usr/share/doc/libxdmcp6 /usr/share/doc/libxext6 /usr/share/doc/libxfixes3 /usr/share/doc/libxi6 /usr/share/doc/libxinerama1 /usr/share/doc/libxkbcommon0 /usr/share/doc/libxrandr2 /usr/share/doc/libxrender1 /usr/share/doc/shared-mime-info /usr/share/doc/ubuntu-mono /usr/share/doc/wget /usr/share/doc/xdg-utils /usr/share/doc/xkb-data /exports/usr/share/doc/ \
  ; mv /usr/share/gettext/its/shared-mime-info.its /usr/share/gettext/its/shared-mime-info.loc /exports/usr/share/gettext/its/ \
  ; mv /usr/share/glib-2.0/schemas/gschemas.compiled /usr/share/glib-2.0/schemas/org.gtk.Settings.ColorChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.Debug.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.EmojiChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.FileChooser.gschema.xml /exports/usr/share/glib-2.0/schemas/ \
  ; mv /usr/share/icons/Adwaita /usr/share/icons/default /usr/share/icons/Humanity-Dark /usr/share/icons/Humanity /usr/share/icons/LoginIcons /usr/share/icons/ubuntu-mono-dark /usr/share/icons/ubuntu-mono-light /exports/usr/share/icons/ \
  ; mv /usr/share/icons/hicolor/128x128 /usr/share/icons/hicolor/16x16 /usr/share/icons/hicolor/192x192 /usr/share/icons/hicolor/22x22 /usr/share/icons/hicolor/24x24 /usr/share/icons/hicolor/256x256 /usr/share/icons/hicolor/32x32 /usr/share/icons/hicolor/36x36 /usr/share/icons/hicolor/512x512 /usr/share/icons/hicolor/64x64 /usr/share/icons/hicolor/72x72 /usr/share/icons/hicolor/96x96 /usr/share/icons/hicolor/icon-theme.cache /usr/share/icons/hicolor/index.theme /usr/share/icons/hicolor/symbolic /exports/usr/share/icons/hicolor/ \
  ; mv /usr/share/icons/hicolor/48x48/actions /usr/share/icons/hicolor/48x48/animations /usr/share/icons/hicolor/48x48/categories /usr/share/icons/hicolor/48x48/devices /usr/share/icons/hicolor/48x48/emblems /usr/share/icons/hicolor/48x48/emotes /usr/share/icons/hicolor/48x48/filesystems /usr/share/icons/hicolor/48x48/intl /usr/share/icons/hicolor/48x48/mimetypes /usr/share/icons/hicolor/48x48/places /usr/share/icons/hicolor/48x48/status /usr/share/icons/hicolor/48x48/stock /exports/usr/share/icons/hicolor/48x48/ \
  ; mv /usr/share/icons/hicolor/48x48/apps/google-chrome-beta.png /exports/usr/share/icons/hicolor/48x48/apps/ \
  ; mv /usr/share/icons/hicolor/scalable/actions /usr/share/icons/hicolor/scalable/animations /usr/share/icons/hicolor/scalable/categories /usr/share/icons/hicolor/scalable/devices /usr/share/icons/hicolor/scalable/emblems /usr/share/icons/hicolor/scalable/emotes /usr/share/icons/hicolor/scalable/filesystems /usr/share/icons/hicolor/scalable/intl /usr/share/icons/hicolor/scalable/mimetypes /usr/share/icons/hicolor/scalable/places /usr/share/icons/hicolor/scalable/status /usr/share/icons/hicolor/scalable/stock /exports/usr/share/icons/hicolor/scalable/ \
  ; mv /usr/share/info/wget.info.gz /exports/usr/share/info/ \
  ; mv /usr/share/lintian/overrides/dbus-user-session /usr/share/lintian/overrides/fontconfig /usr/share/lintian/overrides/hicolor-icon-theme /usr/share/lintian/overrides/libatk-bridge2.0-0 /usr/share/lintian/overrides/libatk1.0-0 /usr/share/lintian/overrides/libatspi2.0-0 /usr/share/lintian/overrides/libcairo-gobject2 /usr/share/lintian/overrides/libgbm1 /usr/share/lintian/overrides/libjpeg-turbo8 /usr/share/lintian/overrides/libnspr4 /usr/share/lintian/overrides/libnss3 /usr/share/lintian/overrides/libpixman-1-0 /usr/share/lintian/overrides/libx11-6 /exports/usr/share/lintian/overrides/ \
  ; mv /usr/share/man/man1/dconf-service.1.gz /usr/share/man/man1/fc-cache.1.gz /usr/share/man/man1/fc-cat.1.gz /usr/share/man/man1/fc-conflist.1.gz /usr/share/man/man1/fc-list.1.gz /usr/share/man/man1/fc-match.1.gz /usr/share/man/man1/fc-pattern.1.gz /usr/share/man/man1/fc-query.1.gz /usr/share/man/man1/fc-scan.1.gz /usr/share/man/man1/fc-validate.1.gz /usr/share/man/man1/google-chrome-beta.1.gz /usr/share/man/man1/gtk-update-icon-cache.1.gz /usr/share/man/man1/open.1.gz /usr/share/man/man1/update-mime-database.1.gz /usr/share/man/man1/wget.1.gz /usr/share/man/man1/xdg-desktop-icon.1.gz /usr/share/man/man1/xdg-desktop-menu.1.gz /usr/share/man/man1/xdg-email.1.gz /usr/share/man/man1/xdg-icon-resource.1.gz /usr/share/man/man1/xdg-mime.1.gz /usr/share/man/man1/xdg-open.1.gz /usr/share/man/man1/xdg-screensaver.1.gz /usr/share/man/man1/xdg-settings.1.gz /exports/usr/share/man/man1/ \
  ; mv /usr/share/man/man5/Compose.5.gz /usr/share/man/man5/fonts-conf.5.gz /usr/share/man/man5/XCompose.5.gz /exports/usr/share/man/man5/ \
  ; mv /usr/share/man/man7/xkeyboard-config.7.gz /exports/usr/share/man/man7/ \
  ; mv /usr/share/man/man8/update-icon-caches.8.gz /exports/usr/share/man/man8/ \
  ; mv /usr/share/menu/google-chrome-beta.menu /exports/usr/share/menu/ \
  ; mv /usr/share/pkgconfig/adwaita-icon-theme.pc /usr/share/pkgconfig/shared-mime-info.pc /usr/share/pkgconfig/xkeyboard-config.pc /exports/usr/share/pkgconfig/

# XDG-UTILS
FROM base AS xdg-utils
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx xdg-utils='1.1.3-4.1ubuntu3~22.04.1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ \
  ; mv /usr/bin/browse /usr/bin/xdg-desktop-icon /usr/bin/xdg-desktop-menu /usr/bin/xdg-email /usr/bin/xdg-icon-resource /usr/bin/xdg-mime /usr/bin/xdg-open /usr/bin/xdg-screensaver /usr/bin/xdg-settings /exports/usr/bin/

# PING
FROM base AS ping
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx iputils-ping='3:20211215-1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man8/ \
  ; mv /usr/bin/ping /usr/bin/ping4 /usr/bin/ping6 /exports/usr/bin/ \
  ; mv /usr/share/doc/iputils-ping /exports/usr/share/doc/ \
  ; mv /usr/share/man/man8/ping.8.gz /usr/share/man/man8/ping4.8.gz /usr/share/man/man8/ping6.8.gz /exports/usr/share/man/man8/

# CURLIE
FROM base AS curlie
COPY --from=wget /exports/ /
RUN set -e \
  ; wget --no-hsts -O /tmp/curlie.tgz 'https://github.com/rs/curlie/releases/download/v1.7.2/curlie_1.7.2_linux_amd64.tar.gz' \
  ; mkdir -p /tmp/curlie \
  ; tar xzvf /tmp/curlie.tgz -C /tmp/curlie/ \
  ; rm /tmp/curlie.tgz \
  ; mv /tmp/curlie/curlie /usr/local/bin/curlie \
  ; rm -r /tmp/curlie
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/curlie /exports/usr/local/bin/

# YT-DLP
FROM base AS yt-dlp
COPY --from=apteryx /exports/ /
RUN set -e \
  ; add-apt-repository ppa:tomtomtom/yt-dlp \
  ; apteryx yt-dlp='2024.08.06-*'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/python3/dist-packages/ \
  ; mv /usr/bin/yt-dlp /exports/usr/bin/ \
  ; mv /usr/lib/python3/dist-packages/_brotli.cpython-310-x86_64-linux-gnu.so /usr/lib/python3/dist-packages/brotli.py /usr/lib/python3/dist-packages/certifi /usr/lib/python3/dist-packages/chardet /usr/lib/python3/dist-packages/Cryptodome /usr/lib/python3/dist-packages/idna /usr/lib/python3/dist-packages/mutagen /usr/lib/python3/dist-packages/requests /usr/lib/python3/dist-packages/urllib3 /usr/lib/python3/dist-packages/websockets /usr/lib/python3/dist-packages/yt_dlp /exports/usr/lib/python3/dist-packages/

# FFMPEG
FROM base AS ffmpeg
COPY --from=wget /exports/ /
COPY --from=xz /exports/ /
RUN set -e \
  ; wget -O /tmp/release.txt 'https://johnvansickle.com/ffmpeg/release-readme.txt' \
  ; DL_VERSION=$(cat /tmp/release.txt | grep -oP 'version:\s[\d.]+' | cut -d ' ' -f 2) \
  ; ([ "7.0.2" != "$DL_VERSION" ] && echo "Version mismatch! The latest version of ffmpeg is ${DL_VERSION}." && exit 1 || true) \
  ; wget -O /tmp/ffmpeg.txz 'https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz' \
  ; tar -xvf /tmp/ffmpeg.txz \
  ; rm /tmp/ffmpeg.txz \
  ; mv 'ffmpeg-7.0.2-amd64-static' ffmpeg \
  ; mv ffmpeg/ffmpeg /usr/local/bin/ffmpeg \
  ; mv ffmpeg/ffprobe /usr/local/bin/ffprobe \
  ; rm -r ffmpeg
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /exports/usr/local/bin/

# HEY
FROM base AS hey
COPY --from=wget /exports/ /
RUN set -e \
  ; wget https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64 -O /usr/local/bin/hey
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/hey /exports/usr/local/bin/

# AST-GREP
FROM base AS ast-grep
COPY --from=wget /exports/ /
COPY --from=unzip /exports/ /
RUN set -e \
  ; wget -O /tmp/ast-grep.zip 'https://github.com/ast-grep/ast-grep/releases/download/0.28.0/app-x86_64-unknown-linux-gnu.zip' \
  ; unzip /tmp/ast-grep.zip \
  ; rm /tmp/ast-grep.zip \
  ; mv sg /usr/local/bin/sg \
  ; rm ast-grep
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/sg /exports/usr/local/bin/

# GIFSKI
FROM base AS gifski
COPY --from=apteryx /exports/ /
COPY --from=wget /exports/ /
COPY --from=xz /exports/ /
RUN set -e \
  ; wget -O gifski.deb "https://github.com/ImageOptim/gifski/releases/download/1.32.0/gifski_1.32.0-1_amd64.deb" \
  ; apteryx ./gifski.deb \
  ; rm -rf debian
RUN set -e \
  ; mkdir -p /exports/usr/bin/ \
  ; mv /usr/bin/gifski /exports/usr/bin/

# LAZYGIT
FROM base AS lazygit
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/lazygit.tgz 'https://github.com/jesseduffield/lazygit/releases/download/v0.44.1/lazygit_0.44.1_Linux_x86_64.tar.gz' \
  ; mkdir -p /tmp/lazygit \
  ; tar xzvf /tmp/lazygit.tgz -C /tmp/lazygit \
  ; mv /tmp/lazygit/lazygit /usr/local/bin \
  ; rm -r /tmp/lazygit /tmp/lazygit.tgz
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/lazygit /exports/usr/local/bin/

# OHA
FROM base AS oha
COPY --from=wget /exports/ /
RUN set -e \
  ; wget "https://github.com/hatoo/oha/releases/download/v1.4.6/oha-linux-amd64" -O /tmp/oha \
  ; chmod +x /tmp/oha \
  ; mv /tmp/oha /usr/local/bin/oha
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/oha /exports/usr/local/bin/

# SLEEK
FROM base AS sleek
COPY --from=build-essential /exports/ /
COPY --from=rust /exports/ /
ENV \
  PATH=/root/.cargo/bin:$PATH
RUN set -e \
  ; cargo install --version 0.3.0 sleek \
  ; mv /root/.cargo/bin/sleek /usr/local/bin/sleek
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/sleek /exports/usr/local/bin/

# XCOLOR
FROM base AS xcolor
COPY --from=apteryx /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=rust /exports/ /
ENV \
  PATH=/root/.cargo/bin:$PATH
RUN set -e \
  ; PKG_LIST="pkg-config libx11-dev libx11-xcb-dev libxcursor-dev" \
  ; apteryx $PKG_LIST \
  ; cargo install --version 0.5.1 xcolor \
  ; apt-get remove --purge -y $PKG_LIST \
  ; mv /root/.cargo/bin/xcolor /usr/local/bin/xcolor
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/xcolor /exports/usr/local/bin/

# FONTS
FROM base AS fonts
COPY --from=clone /exports/ /
COPY --from=apteryx /exports/ /
COPY --from=wget /exports/ /
RUN set -e \
  ; apteryx fontconfig='2.13.1-4.2ubuntu5' fonts-noto fonts-noto-cjk fonts-noto-color-emoji xfonts-utils \
  ; mkdir -p /usr/share/fonts/X11/bitmap \
  ; wget -O /usr/share/fonts/X11/bitmap/gomme.bdf 'http://raw.githubusercontent.com/Tecate/bitmap-fonts/master/bitmap/gomme/Gomme10x20n.bdf' \
  ; wget -O /usr/share/fonts/X11/bitmap/terminal.bdf 'http://raw.githubusercontent.com/Tecate/bitmap-fonts/master/bitmap/dylex/7x13.bdf' \
  ; clone --shallow --https https://github.com/blaisck/sfwin \
  ; cd /root/src/github.com/blaisck/sfwin \
  ; mv SFCompact/TrueType /usr/share/fonts/SFCompact \
  ; mv SFMono/TrueType /usr/share/fonts/SFMono \
  ; mv SFPro/TrueType /usr/share/fonts/SFPro \
  ; cd /etc/fonts/conf.d \
  ; rm 10* 70-no-bitmaps.conf \
  ; ln -s ../conf.avail/70-yes-bitmaps.conf . \
  ; dpkg-reconfigure fontconfig \
  ; fc-cache -fv
RUN set -e \
  ; mkdir -p /exports/etc/ /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/share/ /exports/usr/sbin/ /exports/usr/share/aclocal/ /exports/usr/share/apport/package-hooks/ /exports/usr/share/ /exports/usr/share/pkgconfig/ /exports/usr/share/xml/ /exports/var/cache/ /exports/var/lib/ \
  ; mv /etc/fonts /exports/etc/ \
  ; mv /usr/bin/bdftopcf /usr/bin/bdftruncate /usr/bin/fc-cache /usr/bin/fc-cat /usr/bin/fc-list /usr/bin/fc-match /usr/bin/fc-pattern /usr/bin/fc-query /usr/bin/fc-scan /usr/bin/fc-validate /usr/bin/fonttosfnt /usr/bin/mkfontdir /usr/bin/mkfontscale /usr/bin/ucs2any /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu/libfontconfig.so.* /usr/lib/x86_64-linux-gnu/libfontenc.so.* /usr/lib/x86_64-linux-gnu/libfreetype.so.* /usr/lib/x86_64-linux-gnu/libpng16.so.* /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/local/share/fonts /exports/usr/local/share/ \
  ; mv /usr/sbin/update-fonts-alias /usr/sbin/update-fonts-dir /usr/sbin/update-fonts-scale /exports/usr/sbin/ \
  ; mv /usr/share/aclocal/fontutil.m4 /exports/usr/share/aclocal/ \
  ; mv /usr/share/apport/package-hooks/source_fontconfig.py /exports/usr/share/apport/package-hooks/ \
  ; mv /usr/share/fonts /exports/usr/share/ \
  ; mv /usr/share/pkgconfig/fontutil.pc /exports/usr/share/pkgconfig/ \
  ; mv /usr/share/xml/fontconfig /exports/usr/share/xml/ \
  ; mv /var/cache/fontconfig /exports/var/cache/ \
  ; mv /var/lib/xfonts /exports/var/lib/

# GOSEE
FROM base AS gosee
COPY --from=clone /exports/ /
COPY --from=go /exports/ /
ENV \
  PATH=/usr/local/go/bin:${PATH} \
  GOPATH=/root \
  GO111MODULE=auto
RUN set -e \
  ; clone --https --shallow --ref=75d8486059a13c88072ea129546f98b8cb1fe434 https://github.com/jmbaur/gosee \
  ; cd /root/src/github.com/jmbaur/gosee \
  ; go build -o /usr/local/bin/gosee \
  ; rm -r /root/src
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/gosee /exports/usr/local/bin/

# RIP
FROM base AS rip
COPY --from=build-essential /exports/ /
COPY --from=rust /exports/ /
ENV \
  PATH=/root/.cargo/bin:$PATH
RUN set -e \
  ; cargo install --version 0.13.1 rm-improved \
  ; mv /root/.cargo/bin/rip /usr/local/bin/rip
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/rip /exports/usr/local/bin/

# BUN
FROM base AS bun
COPY --from=wget /exports/ /
COPY --from=unzip /exports/ /
RUN set -e \
  ; wget -O /tmp/bun.zip https://github.com/oven-sh/bun/releases/download/bun-v1.1.30/bun-linux-x64.zip \
  ; mkdir /tmp/bun \
  ; cd /tmp/bun \
  ; unzip /tmp/bun.zip \
  ; mv /tmp/bun/bun-linux-x64/bun /usr/local/bin/ \
  ; rm -r /tmp/bun /tmp/bun.zip
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/bun /exports/usr/local/bin/

# ZOXIDE
FROM base AS zoxide
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/zoxide.tar.gz "https://github.com/ajeetdsouza/zoxide/releases/download/v0.9.6/zoxide-0.9.6-x86_64-unknown-linux-musl.tar.gz" \
  ; mkdir -p /tmp/zoxide \
  ; tar -xvf /tmp/zoxide.tar.gz -C /tmp/zoxide --no-same-owner \
  ; mv /tmp/zoxide/zoxide /usr/local/bin/ \
  ; mv /tmp/zoxide/completions/_zoxide /usr/share/zsh/vendor-completions/ \
  ; mv /tmp/zoxide/man/man1/zoxide* usr/share/man/man1/ \
  ; rm -r /tmp/zoxide.tar.gz /tmp/zoxide
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/share/man/man1/ /exports/usr/share/zsh/vendor-completions/ \
  ; mv /usr/local/bin/zoxide /exports/usr/local/bin/ \
  ; mv /usr/share/man/man1/zoxide-add.1 /usr/share/man/man1/zoxide-import.1 /usr/share/man/man1/zoxide-init.1 /usr/share/man/man1/zoxide-query.1 /usr/share/man/man1/zoxide-remove.1 /usr/share/man/man1/zoxide.1 /exports/usr/share/man/man1/ \
  ; mv /usr/share/zsh/vendor-completions/_zoxide /exports/usr/share/zsh/vendor-completions/

# EXA
FROM base AS exa
COPY --from=wget /exports/ /
COPY --from=unzip /exports/ /
RUN set -e \
  ; wget -O /tmp/exa.tar.gz "https://github.com/ogham/exa/releases/download/v0.10.1/exa-linux-x86_64-v0.10.1.zip" \
  ; mkdir -p /tmp/exa \
  ; cd /tmp/exa \
  ; unzip /tmp/exa.tar.gz \
  ; mv /tmp/exa/bin/exa /usr/local/bin/ \
  ; mv /tmp/exa/completions/exa.zsh /usr/share/zsh/vendor-completions/ \
  ; mv /tmp/exa/man/exa* /usr/share/man/man1/ \
  ; rm -r /tmp/exa.tar.gz /tmp/exa
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/share/man/man1/ /exports/usr/share/zsh/vendor-completions/ \
  ; mv /usr/local/bin/exa /exports/usr/local/bin/ \
  ; mv /usr/share/man/man1/exa_colors.5 /usr/share/man/man1/exa.1 /exports/usr/share/man/man1/ \
  ; mv /usr/share/zsh/vendor-completions/exa.zsh /exports/usr/share/zsh/vendor-completions/

# ROFI
FROM base AS rofi
COPY --from=apteryx /exports/ /
COPY --from=clone /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/rofi.tgz "https://github.com/davatorium/rofi/releases/download/1.7.5/rofi-1.7.5.tar.gz" \
  ; tar xzvf /tmp/rofi.tgz \
  ; rm /tmp/rofi.tgz \
  ; PKG_LIST="autoconf automake bison check flex libcairo2-dev libgdk-pixbuf2.0-dev libglib2.0-dev libpango1.0-dev libpangocairo-1.0-0 libstartup-notification0-dev libtool libxcb-cursor-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-randr0-dev libxcb-util-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev pkg-config qalc " \
  ; apteryx $PKG_LIST \
  ; cd "/rofi-1.7.5" \
  ; mkdir build \
  ; cd build \
  ; ../configure \
  ; make \
  ; make install
RUN set -e \
  ; clone --https --shallow https://github.com/svenstaro/rofi-calc \
  ; cd /root/src/github.com/svenstaro/rofi-calc \
  ; autoreconf -i \
  ; mkdir build \
  ; cd build/ \
  ; ../configure \
  ; make \
  ; make install
RUN set -e \
  ; clone --ref 78a98f28c69c69ec3bfc08392290e96b9d19e03c --https --shallow https://github.com/Mange/rofi-emoji \
  ; cd /root/src/github.com/Mange/rofi-emoji \
  ; autoreconf -i \
  ; mkdir build \
  ; cd build/ \
  ; ../configure \
  ; make \
  ; make install \
  ; apt-get remove --purge -y $PKG_LIST \
  ; rm -r /root/src "/rofi-1.7.5"
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ /exports/usr/local/include/ /exports/usr/local/lib/ /exports/usr/local/share/ /exports/usr/share/doc/ /exports/usr/share/man/man1/ /exports/usr/share/ \
  ; mv /usr/bin/qalc /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu/libqalculate.so.* /usr/lib/x86_64-linux-gnu/libxcb-cursor.so.* /usr/lib/x86_64-linux-gnu/libstartup-notification-1.so.* /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/local/bin/rofi /usr/local/bin/rofi-sensible-terminal /usr/local/bin/rofi-theme-selector /exports/usr/local/bin/ \
  ; mv /usr/local/include/rofi /exports/usr/local/include/ \
  ; mv /usr/local/lib/rofi /exports/usr/local/lib/ \
  ; mv /usr/local/share/rofi /usr/local/share/rofi-emoji /exports/usr/local/share/ \
  ; mv /usr/share/doc/libqalculate* /usr/share/doc/qalc /exports/usr/share/doc/ \
  ; mv /usr/share/man/man1/qalc.1.gz /exports/usr/share/man/man1/ \
  ; mv /usr/share/qalculate /exports/usr/share/

# FASTGRON
FROM base AS fastgron
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /usr/local/bin/fastgron "https://github.com/adamritter/fastgron/releases/download/v0.7.7/fastgron-ubuntu" \
  ; chmod +x /usr/local/bin/fastgron
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/fastgron /exports/usr/local/bin/

# BRAVE
FROM base AS brave
COPY --from=apteryx /exports/ /
RUN set -e \
  ; curl -fsSLo /usr/share/keyrings/brave-browser-beta-archive-keyring.gpg https://brave-browser-apt-beta.s3.brave.com/brave-browser-beta-archive-keyring.gpg \
  ; echo "deb [signed-by=/usr/share/keyrings/brave-browser-beta-archive-keyring.gpg] https://brave-browser-apt-beta.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-beta.list \
  ; apt update \
  ; apteryx brave-browser-beta='1.72.77*'
RUN set -e \
  ; mkdir -p /exports/opt/ /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/gio/modules/ /exports/usr/share/applications/ /exports/usr/share/dbus-1/services/ /exports/usr/share/doc-base/ \
  ; mv /opt/brave.com /exports/opt/ \
  ; mv /usr/bin/brave-browser /usr/bin/brave-browser-beta /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu/avahi /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0 /usr/lib/x86_64-linux-gnu/gtk-3.0 /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libasound.so.2.0.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0.23609.1 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0.0.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0.0.1 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3.2.9 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3.5.4 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcairo.so.2 /usr/lib/x86_64-linux-gnu/libcairo.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcolord.so.2 /usr/lib/x86_64-linux-gnu/libcolord.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcups.so.2 /usr/lib/x86_64-linux-gnu/libdatrie.so.1 /usr/lib/x86_64-linux-gnu/libdatrie.so.1.4.0 /usr/lib/x86_64-linux-gnu/libdconf.so.1 /usr/lib/x86_64-linux-gnu/libdconf.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdeflate.so.0 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0.0.0 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.0 /usr/lib/x86_64-linux-gnu/libfreebl3.chk /usr/lib/x86_64-linux-gnu/libfreebl3.so /usr/lib/x86_64-linux-gnu/libfreeblpriv3.chk /usr/lib/x86_64-linux-gnu/libfreeblpriv3.so /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.18.1 /usr/lib/x86_64-linux-gnu/libfribidi.so.0 /usr/lib/x86_64-linux-gnu/libfribidi.so.0.4.0 /usr/lib/x86_64-linux-gnu/libgbm.so.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0.4200.8 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0.2404.29 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgtk-3-0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0.2404.29 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.20704.0 /usr/lib/x86_64-linux-gnu/libjbig.so.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2.0.12 /usr/lib/x86_64-linux-gnu/libnspr4.so /usr/lib/x86_64-linux-gnu/libnss3.so /usr/lib/x86_64-linux-gnu/libnssutil3.so /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0.5000.6 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0.5000.6 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0.5000.6 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0.40.0 /usr/lib/x86_64-linux-gnu/libplc4.so /usr/lib/x86_64-linux-gnu/libplds4.so /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.37.0 /usr/lib/x86_64-linux-gnu/libsmime3.so /usr/lib/x86_64-linux-gnu/libssl3.so /usr/lib/x86_64-linux-gnu/libthai.so.0 /usr/lib/x86_64-linux-gnu/libthai.so.0.3.1 /usr/lib/x86_64-linux-gnu/libtiff.so.5 /usr/lib/x86_64-linux-gnu/libtiff.so.5.7.0 /usr/lib/x86_64-linux-gnu/libvulkan.so.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1.3.204 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.20.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0.20.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.20.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0.20.0 /usr/lib/x86_64-linux-gnu/libwebp.so.7 /usr/lib/x86_64-linux-gnu/libwebp.so.7.1.3 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXcursor.so.1 /usr/lib/x86_64-linux-gnu/libXcursor.so.1.0.2 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libXi.so.6 /usr/lib/x86_64-linux-gnu/libXi.so.6.1.0 /usr/lib/x86_64-linux-gnu/libXinerama.so.1 /usr/lib/x86_64-linux-gnu/libXinerama.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrandr.so.2 /usr/lib/x86_64-linux-gnu/libXrandr.so.2.2.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /usr/lib/x86_64-linux-gnu/nss /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/lib/x86_64-linux-gnu/gio/modules/giomodule.cache /usr/lib/x86_64-linux-gnu/gio/modules/libdconfsettings.so /exports/usr/lib/x86_64-linux-gnu/gio/modules/ \
  ; mv /usr/share/applications/brave-browser-beta.desktop /exports/usr/share/applications/ \
  ; mv /usr/share/dbus-1/services/ca.desrt.dconf.service /exports/usr/share/dbus-1/services/ \
  ; mv /usr/share/doc-base/fontconfig.fontconfig-user /usr/share/doc-base/libpng16-16.libpng16 /usr/share/doc-base/shared-mime-info.shared-mime-info /exports/usr/share/doc-base/

# HEROKU
FROM base AS heroku
COPY --from=node /exports/ /
RUN set -e \
  ; npm install -g 'heroku@9.3.0'
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/ \
  ; mv /usr/local/bin/heroku /exports/usr/local/bin/ \
  ; mv /usr/local/lib/node_modules/heroku /exports/usr/local/lib/node_modules/

# KOLIDE
FROM base AS kolide
COPY --from=ar /exports/ /
COPY --from=wget /exports/ /
COPY --from=unzip /exports/ /
COPY ./secret/kolide-secret /etc/kolide-k2/secret
RUN set -e \
  ; mkdir -p /usr/local/kolide-k2/bin \
  ; wget -O /tmp/osquery.deb https://github.com/osquery/osquery/releases/download/5.5.1/osquery_5.5.1-1.linux_amd64.deb \
  ; cd /tmp \
  ; ar xv ./osquery.deb data.tar.gz \
  ; tar xzvf ./data.tar.gz ./opt/osquery/bin/osqueryd \
  ; mv opt/osquery/bin/osqueryd /usr/local/kolide-k2/bin/osqueryd \
  ; rm -r ./opt ./osquery.deb ./data.tar.gz \
  ; wget -O /tmp/launcher.zip https://github.com/kolide/launcher/releases/download/v0.12.1/linux-binaries.zip \
  ; unzip /tmp/launcher.zip \
  ; rm /tmp/launcher.zip \
  ; mv ./linux.amd64/launcher /usr/local/kolide-k2/bin/launcher \
  ; rm -r ./linux.amd64 \
  ; mkdir -p /var/kolide-k2/k2device.kolide.com/ \
  ; cd /etc/kolide-k2/ \
  ; touch launcher.flags \
  ; echo 'with_initial_runner' >> launcher.flags \
  ; echo 'control' >> launcher.flags \
  ; echo 'autoupdate' >> launcher.flags \
  ; echo 'root_directory /var/kolide-k2/k2device.kolide.com' >> launcher.flags \
  ; echo 'osqueryd_path /usr/local/kolide-k2/bin/osqueryd' >> launcher.flags \
  ; echo 'enroll_secret_path /etc/kolide-k2/secret' >> launcher.flags \
  ; echo 'control_hostname k2control.kolide.com' >> launcher.flags \
  ; echo 'update_channel stable' >> launcher.flags \
  ; echo 'transport jsonrpc' >> launcher.flags \
  ; echo 'hostname k2device.kolide.com' >> launcher.flags
RUN set -e \
  ; mkdir -p /exports/etc/ /exports/usr/local/ /exports/var/kolide-k2/ \
  ; mv /etc/kolide-k2 /exports/etc/ \
  ; mv /usr/local/kolide-k2 /exports/usr/local/ \
  ; mv /var/kolide-k2/k2device.kolide.com /exports/var/kolide-k2/

# SQLITE-UTILS
FROM base AS sqlite-utils
COPY --from=uv /exports/ /
ENV \
  UV_LINK_MODE=copy \
  UV_COMPILE_BYTECODE=1 \
  UV_PYTHON_DOWNLOADS=manual \
  UV_TOOL_DIR=/usr/local/uv/tools \
  UV_TOOL_BIN_DIR=/usr/local/uv/bin \
  UV_PYTHON_INSTALL_DIR=/usr/local/uv/python
RUN set -e \
  ; uv tool install sqlite-utils=='3.37' \
  ; ln -s /usr/local/uv/bin/sqlite-utils /usr/local/bin/sqlite-utils
RUN set -e \
  ; mkdir -p /exports/usr/local/ /exports/usr/local/bin/ \
  ; mv /usr/local/uv /exports/usr/local/ \
  ; mv /usr/local/bin/sqlite-utils /exports/usr/local/bin/

# TTOK
FROM base AS ttok
COPY --from=uv /exports/ /
ENV \
  UV_LINK_MODE=copy \
  UV_COMPILE_BYTECODE=1 \
  UV_PYTHON_DOWNLOADS=manual \
  UV_TOOL_DIR=/usr/local/uv/tools \
  UV_TOOL_BIN_DIR=/usr/local/uv/bin \
  UV_PYTHON_INSTALL_DIR=/usr/local/uv/python
RUN set -e \
  ; uv tool install ttok=='0.3' \
  ; ln -s /usr/local/uv/bin/ttok /usr/local/bin/ttok
RUN set -e \
  ; mkdir -p /exports/usr/local/ /exports/usr/local/bin/ \
  ; mv /usr/local/uv /exports/usr/local/ \
  ; mv /usr/local/bin/ttok /exports/usr/local/bin/

# STRIP-TAGS
FROM base AS strip-tags
COPY --from=uv /exports/ /
ENV \
  UV_LINK_MODE=copy \
  UV_COMPILE_BYTECODE=1 \
  UV_PYTHON_DOWNLOADS=manual \
  UV_TOOL_DIR=/usr/local/uv/tools \
  UV_TOOL_BIN_DIR=/usr/local/uv/bin \
  UV_PYTHON_INSTALL_DIR=/usr/local/uv/python
RUN set -e \
  ; uv tool install strip-tags=='0.5.1' \
  ; ln -s /usr/local/uv/bin/strip-tags /usr/local/bin/strip-tags
RUN set -e \
  ; mkdir -p /exports/usr/local/ /exports/usr/local/bin/ \
  ; mv /usr/local/uv /exports/usr/local/ \
  ; mv /usr/local/bin/strip-tags /exports/usr/local/bin/

# LLM
FROM base AS llm
COPY --from=uv /exports/ /
ENV \
  UV_LINK_MODE=copy \
  UV_COMPILE_BYTECODE=1 \
  UV_PYTHON_DOWNLOADS=manual \
  UV_TOOL_DIR=/usr/local/uv/tools \
  UV_TOOL_BIN_DIR=/usr/local/uv/bin \
  UV_PYTHON_INSTALL_DIR=/usr/local/uv/python
RUN set -e \
  ; uv tool install llm=='0.16' \
  ; ln -s /usr/local/uv/bin/llm /usr/local/bin/llm \
  ; llm install llm-claude-3
RUN set -e \
  ; mkdir -p /exports/usr/local/ /exports/usr/local/bin/ \
  ; mv /usr/local/uv /exports/usr/local/ \
  ; mv /usr/local/bin/llm /exports/usr/local/bin/

# OBSIDIAN
FROM base AS obsidian
COPY --from=wget /exports/ /
COPY --from=apteryx /exports/ /
RUN set -e \
  ; wget -O /tmp/obsidian.deb "https://github.com/obsidianmd/obsidian-releases/releases/download/v1.6.7/obsidian_1.6.7_amd64.deb" \
  ; apteryx /tmp/obsidian.deb
RUN set -e \
  ; mkdir -p /exports/opt/ /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/gio/modules/ \
  ; mv /opt/Obsidian /exports/opt/ \
  ; mv /usr/bin/obsidian /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu/avahi /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0 /usr/lib/x86_64-linux-gnu/gtk-3.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0.23609.1 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0.0.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0.0.1 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3.2.9 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3.5.4 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcairo.so.2 /usr/lib/x86_64-linux-gnu/libcairo.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcolord.so.2 /usr/lib/x86_64-linux-gnu/libcolord.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcups.so.2 /usr/lib/x86_64-linux-gnu/libdatrie.so.1 /usr/lib/x86_64-linux-gnu/libdatrie.so.1.4.0 /usr/lib/x86_64-linux-gnu/libdbus-1.so.3.19.13 /usr/lib/x86_64-linux-gnu/libdconf.so.1 /usr/lib/x86_64-linux-gnu/libdconf.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdeflate.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0.0.0 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.0 /usr/lib/x86_64-linux-gnu/libfreebl3.chk /usr/lib/x86_64-linux-gnu/libfreebl3.so /usr/lib/x86_64-linux-gnu/libfreeblpriv3.chk /usr/lib/x86_64-linux-gnu/libfreeblpriv3.so /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.18.1 /usr/lib/x86_64-linux-gnu/libfribidi.so.0 /usr/lib/x86_64-linux-gnu/libfribidi.so.0.4.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0.4200.8 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0.2404.29 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgtk-3-0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0.2404.29 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.20704.0 /usr/lib/x86_64-linux-gnu/libjbig.so.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2.0.12 /usr/lib/x86_64-linux-gnu/libnotify.so.4 /usr/lib/x86_64-linux-gnu/libnotify.so.4.0.0 /usr/lib/x86_64-linux-gnu/libnspr4.so /usr/lib/x86_64-linux-gnu/libnss3.so /usr/lib/x86_64-linux-gnu/libnssutil3.so /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0.5000.6 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0.5000.6 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0.5000.6 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0.40.0 /usr/lib/x86_64-linux-gnu/libplc4.so /usr/lib/x86_64-linux-gnu/libplds4.so /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.37.0 /usr/lib/x86_64-linux-gnu/libsecret-1.so.0 /usr/lib/x86_64-linux-gnu/libsecret-1.so.0.0.0 /usr/lib/x86_64-linux-gnu/libsmime3.so /usr/lib/x86_64-linux-gnu/libssl3.so /usr/lib/x86_64-linux-gnu/libthai.so.0 /usr/lib/x86_64-linux-gnu/libthai.so.0.3.1 /usr/lib/x86_64-linux-gnu/libtiff.so.5 /usr/lib/x86_64-linux-gnu/libtiff.so.5.7.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.20.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0.20.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.20.0 /usr/lib/x86_64-linux-gnu/libwebp.so.7 /usr/lib/x86_64-linux-gnu/libwebp.so.7.1.3 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXcursor.so.1 /usr/lib/x86_64-linux-gnu/libXcursor.so.1.0.2 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libXi.so.6 /usr/lib/x86_64-linux-gnu/libXi.so.6.1.0 /usr/lib/x86_64-linux-gnu/libXinerama.so.1 /usr/lib/x86_64-linux-gnu/libXinerama.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrandr.so.2 /usr/lib/x86_64-linux-gnu/libXrandr.so.2.2.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /usr/lib/x86_64-linux-gnu/libXss.so.1 /usr/lib/x86_64-linux-gnu/libXss.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXtst.so.6 /usr/lib/x86_64-linux-gnu/libXtst.so.6.1.0 /usr/lib/x86_64-linux-gnu/nss /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/lib/x86_64-linux-gnu/gio/modules/giomodule.cache /usr/lib/x86_64-linux-gnu/gio/modules/libdconfsettings.so /exports/usr/lib/x86_64-linux-gnu/gio/modules/

# CADDY
FROM base AS caddy
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/caddy.tgz 'https://github.com/caddyserver/caddy/releases/download/v2.8.4/caddy_2.8.4_linux_amd64.tar.gz' \
  ; tar xzvf /tmp/caddy.tgz \
  ; mv caddy /usr/local/bin/caddy \
  ; rm /tmp/caddy.tgz
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/caddy /exports/usr/local/bin/

# BANDWHICH
FROM base AS bandwhich
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/bandwhich.tgz 'https://github.com/imsnif/bandwhich/releases/download/v0.23.1/bandwhich-v0.23.1-x86_64-unknown-linux-musl.tar.gz' \
  ; tar -xvf /tmp/bandwhich.tgz \
  ; rm /tmp/bandwhich.tgz \
  ; mv bandwhich /usr/local/bin/bandwhich
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/bandwhich /exports/usr/local/bin/

# IMGP
FROM base AS imgp
COPY --from=wget /exports/ /
COPY --from=apteryx /exports/ /
RUN set -e \
  ; wget -O /tmp/imgp.deb https://github.com/jarun/imgp/releases/download/v2.8/imgp_2.8-1_ubuntu20.04.amd64.deb \
  ; apteryx /tmp/imgp.deb
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/include/ /exports/usr/lib/python3/dist-packages/ /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/bin/imgp /exports/usr/bin/ \
  ; mv /usr/include/python3.10 /exports/usr/include/ \
  ; mv /usr/lib/python3/dist-packages/PIL /usr/lib/python3/dist-packages/Pillow-9.0.1.egg-info /exports/usr/lib/python3/dist-packages/ \
  ; mv /usr/lib/x86_64-linux-gnu/libdeflate.so.0 /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.18.1 /usr/lib/x86_64-linux-gnu/libfribidi.so.0 /usr/lib/x86_64-linux-gnu/libfribidi.so.0.4.0 /usr/lib/x86_64-linux-gnu/libgdbm_compat.so.4 /usr/lib/x86_64-linux-gnu/libgdbm_compat.so.4.0.0 /usr/lib/x86_64-linux-gnu/libgdbm.so.6 /usr/lib/x86_64-linux-gnu/libgdbm.so.6.0.0 /usr/lib/x86_64-linux-gnu/libgomp.so.1 /usr/lib/x86_64-linux-gnu/libgomp.so.1.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.20704.0 /usr/lib/x86_64-linux-gnu/libimagequant.so.0 /usr/lib/x86_64-linux-gnu/libjbig.so.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2.0.12 /usr/lib/x86_64-linux-gnu/libopenjp2.so.2.4.0 /usr/lib/x86_64-linux-gnu/libopenjp2.so.7 /usr/lib/x86_64-linux-gnu/libperl.so.5.34 /usr/lib/x86_64-linux-gnu/libperl.so.5.34.0 /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.37.0 /usr/lib/x86_64-linux-gnu/libraqm.so.0 /usr/lib/x86_64-linux-gnu/libraqm.so.0.700.0 /usr/lib/x86_64-linux-gnu/libtiff.so.5 /usr/lib/x86_64-linux-gnu/libtiff.so.5.7.0 /usr/lib/x86_64-linux-gnu/libwebp.so.7 /usr/lib/x86_64-linux-gnu/libwebp.so.7.1.3 /usr/lib/x86_64-linux-gnu/libwebpdemux.so.2 /usr/lib/x86_64-linux-gnu/libwebpdemux.so.2.0.9 /usr/lib/x86_64-linux-gnu/libwebpmux.so.3 /usr/lib/x86_64-linux-gnu/libwebpmux.so.3.0.8 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/perl /exports/usr/lib/x86_64-linux-gnu/

# WIFI
FROM base AS wifi
COPY --from=clone /exports/ /
COPY --from=go /exports/ /
ENV \
  PATH=/usr/local/go/bin:${PATH} \
  GOPATH=/root \
  GO111MODULE=auto
RUN set -e \
  ; clone --https --tag=v1.5.0 https://github.com/stayradiated/wifi \
  ; cd /root/src/github.com/stayradiated/wifi \
  ; go build \
  ; mv wifi /usr/local/bin/wifi
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/wifi /exports/usr/local/bin/

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
  ; version=$(echo "8.10.48-17" | sed 's/-/~/') \
  ; apteryx 1password="${version}.BETA"
RUN set -e \
  ; mkdir -p /exports/etc/ /exports/etc/X11/ /exports/etc/X11/Xsession.d/ /exports/opt/ /exports/usr/bin/ /exports/usr/lib/gnupg/ /exports/usr/lib/systemd/user/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/gio/modules/ /exports/usr/libexec/ /exports/usr/local/bin/ /exports/usr/sbin/ /exports/usr/share/ /exports/usr/share/apport/package-hooks/ /exports/usr/share/bug/ /exports/usr/share/dbus-1/services/ /exports/usr/share/doc/ /exports/usr/share/gettext/its/ /exports/usr/share/glib-2.0/schemas/ /exports/usr/share/icons/ /exports/usr/share/icons/hicolor/ /exports/usr/share/icons/hicolor/48x48/ /exports/usr/share/icons/hicolor/scalable/ /exports/usr/share/info/ /exports/usr/share/keyrings/ /exports/usr/share/polkit-1/actions/ /exports/usr/share/xml/ /exports/var/cache/ \
  ; mv /etc/gtk-3.0 /exports/etc/ \
  ; mv /etc/X11/xkb /exports/etc/X11/ \
  ; mv /etc/X11/Xsession.d/20dbus_xdg-runtime /exports/etc/X11/Xsession.d/ \
  ; mv /opt/1Password /exports/opt/ \
  ; mv /usr/bin/1password /usr/bin/gpg-wks-server /usr/bin/gpg-zip /usr/bin/gpg2 /usr/bin/gpgcompose /usr/bin/gpgparsemail /usr/bin/gpgsm /usr/bin/gpgsplit /usr/bin/gpgtar /usr/bin/gtk-update-icon-cache /usr/bin/kbxutil /usr/bin/lspgpot /usr/bin/migrate-pubring-from-classic-gpg /usr/bin/update-mime-database /usr/bin/watchgnupg /exports/usr/bin/ \
  ; mv /usr/lib/gnupg/gpg-wks-client /exports/usr/lib/gnupg/ \
  ; mv /usr/lib/systemd/user/dbus.service /usr/lib/systemd/user/dbus.socket /usr/lib/systemd/user/dconf.service /usr/lib/systemd/user/sockets.target.wants /exports/usr/lib/systemd/user/ \
  ; mv /usr/lib/x86_64-linux-gnu/avahi /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0 /usr/lib/x86_64-linux-gnu/gtk-3.0 /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libasound.so.2.0.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0.23609.1 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0.0.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0.0.1 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3.2.9 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3.5.4 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcairo.so.2 /usr/lib/x86_64-linux-gnu/libcairo.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcolord.so.2 /usr/lib/x86_64-linux-gnu/libcolord.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcups.so.2 /usr/lib/x86_64-linux-gnu/libdatrie.so.1 /usr/lib/x86_64-linux-gnu/libdatrie.so.1.4.0 /usr/lib/x86_64-linux-gnu/libdconf.so.1 /usr/lib/x86_64-linux-gnu/libdconf.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdeflate.so.0 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0.0.0 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.0 /usr/lib/x86_64-linux-gnu/libfreebl3.chk /usr/lib/x86_64-linux-gnu/libfreebl3.so /usr/lib/x86_64-linux-gnu/libfreeblpriv3.chk /usr/lib/x86_64-linux-gnu/libfreeblpriv3.so /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.18.1 /usr/lib/x86_64-linux-gnu/libfribidi.so.0 /usr/lib/x86_64-linux-gnu/libfribidi.so.0.4.0 /usr/lib/x86_64-linux-gnu/libgbm.so.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0.4200.8 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0.2404.29 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgtk-3-0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0.2404.29 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.20704.0 /usr/lib/x86_64-linux-gnu/libjbig.so.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2.0.12 /usr/lib/x86_64-linux-gnu/libnotify.so.4 /usr/lib/x86_64-linux-gnu/libnotify.so.4.0.0 /usr/lib/x86_64-linux-gnu/libnspr4.so /usr/lib/x86_64-linux-gnu/libnss3.so /usr/lib/x86_64-linux-gnu/libnssutil3.so /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0.5000.6 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0.5000.6 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0.5000.6 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0.40.0 /usr/lib/x86_64-linux-gnu/libplc4.so /usr/lib/x86_64-linux-gnu/libplds4.so /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.37.0 /usr/lib/x86_64-linux-gnu/libsmime3.so /usr/lib/x86_64-linux-gnu/libssl3.so /usr/lib/x86_64-linux-gnu/libthai.so.0 /usr/lib/x86_64-linux-gnu/libthai.so.0.3.1 /usr/lib/x86_64-linux-gnu/libtiff.so.5 /usr/lib/x86_64-linux-gnu/libtiff.so.5.7.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.20.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0.20.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.20.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0.20.0 /usr/lib/x86_64-linux-gnu/libwebp.so.7 /usr/lib/x86_64-linux-gnu/libwebp.so.7.1.3 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXcursor.so.1 /usr/lib/x86_64-linux-gnu/libXcursor.so.1.0.2 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libXi.so.6 /usr/lib/x86_64-linux-gnu/libXi.so.6.1.0 /usr/lib/x86_64-linux-gnu/libXinerama.so.1 /usr/lib/x86_64-linux-gnu/libXinerama.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrandr.so.2 /usr/lib/x86_64-linux-gnu/libXrandr.so.2.2.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1.0.0 /usr/lib/x86_64-linux-gnu/nss /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/lib/x86_64-linux-gnu/gio/modules/giomodule.cache /usr/lib/x86_64-linux-gnu/gio/modules/libdconfsettings.so /exports/usr/lib/x86_64-linux-gnu/gio/modules/ \
  ; mv /usr/libexec/dconf-service /exports/usr/libexec/ \
  ; mv /usr/local/bin/apteryx /exports/usr/local/bin/ \
  ; mv /usr/sbin/addgnupghome /usr/sbin/applygnupgdefaults /usr/sbin/update-icon-caches /exports/usr/sbin/ \
  ; mv /usr/share/alsa /usr/share/libdrm /usr/share/libthai /usr/share/mime /usr/share/themes /usr/share/X11 /exports/usr/share/ \
  ; mv /usr/share/apport/package-hooks/source_fontconfig.py /exports/usr/share/apport/package-hooks/ \
  ; mv /usr/share/bug/libgbm1 /usr/share/bug/libgtk-3-0 /exports/usr/share/bug/ \
  ; mv /usr/share/dbus-1/services/ca.desrt.dconf.service /exports/usr/share/dbus-1/services/ \
  ; mv /usr/share/doc/1password /exports/usr/share/doc/ \
  ; mv /usr/share/gettext/its/shared-mime-info.its /usr/share/gettext/its/shared-mime-info.loc /exports/usr/share/gettext/its/ \
  ; mv /usr/share/glib-2.0/schemas/gschemas.compiled /usr/share/glib-2.0/schemas/org.gtk.Settings.ColorChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.Debug.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.EmojiChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.FileChooser.gschema.xml /exports/usr/share/glib-2.0/schemas/ \
  ; mv /usr/share/icons/Adwaita /usr/share/icons/default /usr/share/icons/Humanity-Dark /usr/share/icons/Humanity /usr/share/icons/LoginIcons /usr/share/icons/ubuntu-mono-dark /usr/share/icons/ubuntu-mono-light /exports/usr/share/icons/ \
  ; mv /usr/share/icons/hicolor/128x128 /usr/share/icons/hicolor/16x16 /usr/share/icons/hicolor/192x192 /usr/share/icons/hicolor/22x22 /usr/share/icons/hicolor/24x24 /usr/share/icons/hicolor/256x256 /usr/share/icons/hicolor/32x32 /usr/share/icons/hicolor/36x36 /usr/share/icons/hicolor/512x512 /usr/share/icons/hicolor/64x64 /usr/share/icons/hicolor/72x72 /usr/share/icons/hicolor/96x96 /usr/share/icons/hicolor/icon-theme.cache /usr/share/icons/hicolor/index.theme /usr/share/icons/hicolor/symbolic /exports/usr/share/icons/hicolor/ \
  ; mv /usr/share/icons/hicolor/48x48/actions /usr/share/icons/hicolor/48x48/animations /usr/share/icons/hicolor/48x48/categories /usr/share/icons/hicolor/48x48/devices /usr/share/icons/hicolor/48x48/emblems /usr/share/icons/hicolor/48x48/emotes /usr/share/icons/hicolor/48x48/filesystems /usr/share/icons/hicolor/48x48/intl /usr/share/icons/hicolor/48x48/mimetypes /usr/share/icons/hicolor/48x48/places /usr/share/icons/hicolor/48x48/status /usr/share/icons/hicolor/48x48/stock /exports/usr/share/icons/hicolor/48x48/ \
  ; mv /usr/share/icons/hicolor/scalable/actions /usr/share/icons/hicolor/scalable/animations /usr/share/icons/hicolor/scalable/categories /usr/share/icons/hicolor/scalable/devices /usr/share/icons/hicolor/scalable/emblems /usr/share/icons/hicolor/scalable/emotes /usr/share/icons/hicolor/scalable/filesystems /usr/share/icons/hicolor/scalable/intl /usr/share/icons/hicolor/scalable/mimetypes /usr/share/icons/hicolor/scalable/places /usr/share/icons/hicolor/scalable/status /usr/share/icons/hicolor/scalable/stock /exports/usr/share/icons/hicolor/scalable/ \
  ; mv /usr/share/info/gnupg-card-architecture.png /usr/share/info/gnupg-module-overview.png /usr/share/info/gnupg.info-1.gz /usr/share/info/gnupg.info-2.gz /usr/share/info/gnupg.info.gz /exports/usr/share/info/ \
  ; mv /usr/share/keyrings/1password-archive-keyring.gpg /exports/usr/share/keyrings/ \
  ; mv /usr/share/polkit-1/actions/com.1password.1Password.policy /exports/usr/share/polkit-1/actions/ \
  ; mv /usr/share/xml/fontconfig /exports/usr/share/xml/ \
  ; mv /var/cache/fontconfig /exports/var/cache/

# GREENCLIP
FROM base AS greenclip
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /usr/local/bin/greenclip https://github.com/erebe/greenclip/releases/download/v4.2/greenclip \
  ; chmod +x /usr/local/bin/greenclip
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/greenclip /exports/usr/local/bin/

# NET-TOOLS
FROM base AS net-tools
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx net-tools='1.60+git20181103.0eebece-1ubuntu5'
RUN set -e \
  ; mkdir -p /exports/usr/sbin/ /exports/usr/share/man/man8/ \
  ; mv /usr/sbin/ifconfig /exports/usr/sbin/ \
  ; mv /usr/share/man/man8/ifconfig.8.gz /exports/usr/share/man/man8/

# PNPM
FROM base AS pnpm
COPY --from=node /exports/ /
RUN set -e \
  ; npm install -g 'pnpm@9.12.1'
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/ \
  ; mv /usr/local/bin/pnpm /usr/local/bin/pnpx /exports/usr/local/bin/ \
  ; mv /usr/local/lib/node_modules/pnpm /exports/usr/local/lib/node_modules/

# SHELL-ZSH
FROM shell-admin AS shell-zsh
COPY --from=antibody /exports/ /
COPY --from=git /exports/ /
COPY --from=make /exports/ /
COPY --from=fzf /exports/ /
COPY --from=zsh /exports/ /
RUN set -e \
  ; cd dotfiles \
  ; make zsh \
  ; antibody bundle < /home/admin/dotfiles/apps/zsh/bundles.txt > /home/admin/.antibody.sh \
  ; XDG_CONFIG_HOME=/home/admin/.config \
  ; /usr/local/share/fzf/install --xdg --key-bindings --completion --no-bash \
  ; mkdir -p ~/src
RUN set -e \
  ; mkdir -p /home/admin/exports/home/admin/ /home/admin/exports/home/admin/.cache/ /home/admin/exports/home/admin/.config/ \
  ; mv /home/admin/.antibody.sh /home/admin/.zshrc /home/admin/src /home/admin/exports/home/admin/ \
  ; mv /home/admin/.cache/antibody /home/admin/exports/home/admin/.cache/ \
  ; mv /home/admin/.config/fzf /home/admin/exports/home/admin/.config/
USER root
RUN set -e \
  ; mkdir -p /exports/etc/ /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/share/ /exports/usr/share/bug/ /exports/usr/share/doc/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ /exports/usr/share/menu/ /exports/usr/share/zsh/ \
  ; mv /etc/shells /etc/zsh /exports/etc/ \
  ; mv /usr/bin/rzsh /usr/bin/zsh /usr/bin/zsh5 /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu/zsh /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/local/share/fzf /usr/local/share/zsh /exports/usr/local/share/ \
  ; mv /usr/share/bug/zsh /usr/share/bug/zsh-common /exports/usr/share/bug/ \
  ; mv /usr/share/doc/zsh-common /usr/share/doc/zsh /exports/usr/share/doc/ \
  ; mv /usr/share/lintian/overrides/zsh /usr/share/lintian/overrides/zsh-common /exports/usr/share/lintian/overrides/ \
  ; mv /usr/share/man/man1/rzsh.1.gz /usr/share/man/man1/zsh.1.gz /usr/share/man/man1/zshall.1.gz /usr/share/man/man1/zshbuiltins.1.gz /usr/share/man/man1/zshcalsys.1.gz /usr/share/man/man1/zshcompctl.1.gz /usr/share/man/man1/zshcompsys.1.gz /usr/share/man/man1/zshcompwid.1.gz /usr/share/man/man1/zshcontrib.1.gz /usr/share/man/man1/zshexpn.1.gz /usr/share/man/man1/zshmisc.1.gz /usr/share/man/man1/zshmodules.1.gz /usr/share/man/man1/zshoptions.1.gz /usr/share/man/man1/zshparam.1.gz /usr/share/man/man1/zshroadmap.1.gz /usr/share/man/man1/zshtcpsys.1.gz /usr/share/man/man1/zshzftpsys.1.gz /usr/share/man/man1/zshzle.1.gz /exports/usr/share/man/man1/ \
  ; mv /usr/share/menu/zsh-common /exports/usr/share/menu/ \
  ; mv /usr/share/zsh/5.* /usr/share/zsh/functions /usr/share/zsh/help /exports/usr/share/zsh/

# SHELL-YARN
FROM shell-admin AS shell-yarn
COPY --from=yarn /exports/ /
USER root
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/ \
  ; mv /usr/local/bin/yarn /exports/usr/local/bin/ \
  ; mv /usr/local/lib/node_modules/yarn /exports/usr/local/lib/node_modules/

# SHELL-WM
FROM shell-admin AS shell-wm
COPY --from=make /exports/ /
COPY --from=git /exports/ /
COPY --from=bspwm /exports/ /
COPY --from=sxhkd /exports/ /
RUN set -e \
  ; cd dotfiles \
  ; make bspwm sxhkd x11
RUN set -e \
  ; mkdir -p /home/admin/exports/home/admin/.config/ /home/admin/exports/home/admin/ \
  ; mv /home/admin/.config/bspwm /home/admin/.config/sxhkd /home/admin/exports/home/admin/.config/ \
  ; mv /home/admin/.xinitrc /home/admin/exports/home/admin/
USER root
RUN set -e \
  ; mkdir -p /exports/usr/include/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ /exports/usr/local/bin/ /exports/usr/local/share/man/man1/ \
  ; mv /usr/include/GL /usr/include/X11 /usr/include/xcb /exports/usr/include/ \
  ; mv /usr/lib/x86_64-linux-gnu/libXau.a /usr/lib/x86_64-linux-gnu/libXau.so /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-ewmh.a /usr/lib/x86_64-linux-gnu/libxcb-ewmh.so /usr/lib/x86_64-linux-gnu/libxcb-ewmh.so.2 /usr/lib/x86_64-linux-gnu/libxcb-ewmh.so.2.0.0 /usr/lib/x86_64-linux-gnu/libxcb-icccm.a /usr/lib/x86_64-linux-gnu/libxcb-icccm.so /usr/lib/x86_64-linux-gnu/libxcb-icccm.so.4 /usr/lib/x86_64-linux-gnu/libxcb-icccm.so.4.0.0 /usr/lib/x86_64-linux-gnu/libxcb-keysyms.a /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so.1 /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.a /usr/lib/x86_64-linux-gnu/libxcb-randr.so /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-render.a /usr/lib/x86_64-linux-gnu/libxcb-render.so /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.a /usr/lib/x86_64-linux-gnu/libxcb-shape.so /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-util.a /usr/lib/x86_64-linux-gnu/libxcb-util.so /usr/lib/x86_64-linux-gnu/libxcb-util.so.1 /usr/lib/x86_64-linux-gnu/libxcb-util.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xinerama.a /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.a /usr/lib/x86_64-linux-gnu/libxcb.so /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.a /usr/lib/x86_64-linux-gnu/libXdmcp.so /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/lib/x86_64-linux-gnu/pkgconfig/pthread-stubs.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xau.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-atom.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-aux.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-event.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-ewmh.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-icccm.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-keysyms.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-randr.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-render.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-shape.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-util.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb-xinerama.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xcb.pc /usr/lib/x86_64-linux-gnu/pkgconfig/xdmcp.pc /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ \
  ; mv /usr/local/bin/bspc /usr/local/bin/bspwm /usr/local/bin/sxhkd /exports/usr/local/bin/ \
  ; mv /usr/local/share/man/man1/sxhkd.1 /exports/usr/local/share/man/man1/

# SHELL-VIM
FROM shell-admin AS shell-vim
COPY --from=make /exports/ /
COPY --from=git /exports/ /
COPY --from=neovim /exports/ /
COPY --from=node /exports/ /
RUN set -e \
  ; cd dotfiles \
  ; make vim \
  ; nvim +'set display=lastline' +'call dein#install()' +qall || true \
  ; nvim +UpdateRemotePlugins +qall
RUN set -e \
  ; mkdir -p /home/admin/exports/home/admin/.config/ /home/admin/exports/home/admin/.local/share/ /home/admin/exports/home/admin/dotfiles/apps/ \
  ; mv /home/admin/.config/nvim /home/admin/exports/home/admin/.config/ \
  ; mv /home/admin/.local/share/nvim /home/admin/exports/home/admin/.local/share/ \
  ; mv /home/admin/dotfiles/apps/vim /home/admin/exports/home/admin/dotfiles/apps/
USER root
RUN set -e \
  ; mkdir -p /exports/usr/include/ /exports/usr/local/bin/ /exports/usr/local/include/ /exports/usr/local/lib/ /exports/usr/local/lib/python3.10/ /exports/usr/local/ /exports/usr/local/share/ \
  ; mv /usr/include/python3.10 /exports/usr/include/ \
  ; mv /usr/local/bin/n /usr/local/bin/node /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/nvim /usr/local/bin/nvr /exports/usr/local/bin/ \
  ; mv /usr/local/include/node /exports/usr/local/include/ \
  ; mv /usr/local/lib/node_modules /exports/usr/local/lib/ \
  ; mv /usr/local/lib/python3.10/dist-packages /exports/usr/local/lib/python3.10/ \
  ; mv /usr/local/n /exports/usr/local/ \
  ; mv /usr/local/share/nvim /exports/usr/local/share/

# SHELL-TMUX
FROM shell-admin AS shell-tmux
COPY --from=make /exports/ /
COPY --from=git /exports/ /
COPY --from=tmux /exports/ /
RUN set -e \
  ; cd dotfiles \
  ; make tmux
RUN set -e \
  ; mkdir -p /home/admin/exports/home/admin/ \
  ; mv /home/admin/.tmux.conf /home/admin/.tmux /home/admin/exports/home/admin/
USER root
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/include/ /exports/usr/lib/valgrind/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ /exports/usr/local/bin/ /exports/usr/local/share/man/ /exports/usr/share/doc/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ \
  ; mv /usr/bin/ncurses5-config /usr/bin/ncurses6-config /usr/bin/ncursesw5-config /usr/bin/ncursesw6-config /exports/usr/bin/ \
  ; mv /usr/include/curses.h /usr/include/cursesapp.h /usr/include/cursesf.h /usr/include/cursesm.h /usr/include/cursesp.h /usr/include/cursesw.h /usr/include/cursslk.h /usr/include/eti.h /usr/include/etip.h /usr/include/evdns.h /usr/include/event.h /usr/include/event2 /usr/include/evhttp.h /usr/include/evrpc.h /usr/include/evutil.h /usr/include/form.h /usr/include/menu.h /usr/include/nc_tparm.h /usr/include/ncurses_dll.h /usr/include/ncurses.h /usr/include/ncursesw /usr/include/panel.h /usr/include/term_entry.h /usr/include/term.h /usr/include/termcap.h /usr/include/tic.h /usr/include/unctrl.h /exports/usr/include/ \
  ; mv /usr/lib/valgrind/ncurses.supp /exports/usr/lib/valgrind/ \
  ; mv /usr/lib/x86_64-linux-gnu/libcurses.a /usr/lib/x86_64-linux-gnu/libcurses.so /usr/lib/x86_64-linux-gnu/libevent_core-*.so.* /usr/lib/x86_64-linux-gnu/libevent_core.a /usr/lib/x86_64-linux-gnu/libevent_core.so /usr/lib/x86_64-linux-gnu/libevent_extra-*.so.* /usr/lib/x86_64-linux-gnu/libevent_extra.a /usr/lib/x86_64-linux-gnu/libevent_extra.so /usr/lib/x86_64-linux-gnu/libevent_openssl-*.so.* /usr/lib/x86_64-linux-gnu/libevent_openssl.a /usr/lib/x86_64-linux-gnu/libevent_openssl.so /usr/lib/x86_64-linux-gnu/libevent_pthreads-*.so.* /usr/lib/x86_64-linux-gnu/libevent_pthreads.a /usr/lib/x86_64-linux-gnu/libevent_pthreads.so /usr/lib/x86_64-linux-gnu/libevent-*.so.* /usr/lib/x86_64-linux-gnu/libevent.a /usr/lib/x86_64-linux-gnu/libevent.so /usr/lib/x86_64-linux-gnu/libform.a /usr/lib/x86_64-linux-gnu/libform.so /usr/lib/x86_64-linux-gnu/libformw.a /usr/lib/x86_64-linux-gnu/libformw.so /usr/lib/x86_64-linux-gnu/libmenu.a /usr/lib/x86_64-linux-gnu/libmenu.so /usr/lib/x86_64-linux-gnu/libmenuw.a /usr/lib/x86_64-linux-gnu/libmenuw.so /usr/lib/x86_64-linux-gnu/libncurses.a /usr/lib/x86_64-linux-gnu/libncurses.so /usr/lib/x86_64-linux-gnu/libncurses++.a /usr/lib/x86_64-linux-gnu/libncurses++w.a /usr/lib/x86_64-linux-gnu/libncursesw.a /usr/lib/x86_64-linux-gnu/libncursesw.so /usr/lib/x86_64-linux-gnu/libpanel.a /usr/lib/x86_64-linux-gnu/libpanel.so /usr/lib/x86_64-linux-gnu/libpanelw.a /usr/lib/x86_64-linux-gnu/libpanelw.so /usr/lib/x86_64-linux-gnu/libtermcap.a /usr/lib/x86_64-linux-gnu/libtermcap.so /usr/lib/x86_64-linux-gnu/libtic.a /usr/lib/x86_64-linux-gnu/libtic.so /usr/lib/x86_64-linux-gnu/libtinfo.a /usr/lib/x86_64-linux-gnu/libtinfo.so /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/lib/x86_64-linux-gnu/pkgconfig/form.pc /usr/lib/x86_64-linux-gnu/pkgconfig/formw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent_core.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent_extra.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent_openssl.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent_pthreads.pc /usr/lib/x86_64-linux-gnu/pkgconfig/libevent.pc /usr/lib/x86_64-linux-gnu/pkgconfig/menu.pc /usr/lib/x86_64-linux-gnu/pkgconfig/menuw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncurses.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncurses++.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncurses++w.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncursesw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/panel.pc /usr/lib/x86_64-linux-gnu/pkgconfig/panelw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/tic.pc /usr/lib/x86_64-linux-gnu/pkgconfig/tinfo.pc /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ \
  ; mv /usr/local/bin/tmux /exports/usr/local/bin/ \
  ; mv /usr/local/share/man/man1 /exports/usr/local/share/man/ \
  ; mv /usr/share/doc/libevent-2.1-7 /usr/share/doc/libevent-core-2.1-7 /usr/share/doc/libevent-dev /usr/share/doc/libevent-extra-2.1-7 /usr/share/doc/libevent-openssl-2.1-7 /usr/share/doc/libevent-pthreads-2.1-7 /usr/share/doc/libncurses-dev /usr/share/doc/libncurses5-dev /exports/usr/share/doc/ \
  ; mv /usr/share/lintian/overrides/libevent-openssl-2.1-7 /exports/usr/share/lintian/overrides/ \
  ; mv /usr/share/man/man1/ncurses5-config.1.gz /usr/share/man/man1/ncurses6-config.1.gz /usr/share/man/man1/ncursesw5-config.1.gz /usr/share/man/man1/ncursesw6-config.1.gz /exports/usr/share/man/man1/

# SHELL-SSH
FROM shell-admin AS shell-ssh
COPY --from=make /exports/ /
RUN set -e \
  ; cd dotfiles \
  ; make ssh
RUN set -e \
  ; mkdir -p /home/admin/exports/home/admin/ \
  ; mv /home/admin/.ssh /home/admin/exports/home/admin/

# SHELL-RANGER
FROM shell-admin AS shell-ranger
COPY --from=make /exports/ /
COPY --from=ranger /exports/ /
RUN set -e \
  ; cd dotfiles \
  ; make ranger
RUN set -e \
  ; mkdir -p /home/admin/exports/home/admin/.config/ \
  ; mv /home/admin/.config/ranger /home/admin/exports/home/admin/.config/
USER root
RUN set -e \
  ; mkdir -p /exports/usr/local/ /exports/usr/local/bin/ \
  ; mv /usr/local/uv /exports/usr/local/ \
  ; mv /usr/local/bin/ranger /exports/usr/local/bin/

# SHELL-PASSWORDS
FROM shell-admin AS shell-passwords
COPY --from=make /exports/ /
RUN set -e \
  ; cd dotfiles \
  ; make 1password
RUN set -e \
  ; mkdir -p /home/admin/exports/home/admin/.config/1Password/settings/ /home/admin/exports/home/admin/.config/1Password/ \
  ; mv /home/admin/.config/1Password/settings/settings.json /home/admin/exports/home/admin/.config/1Password/settings/ \
  ; mv /home/admin/.config/1Password/1password.sqlite /home/admin/exports/home/admin/.config/1Password/

# SHELL-NPM
FROM shell-admin AS shell-npm
COPY --from=make /exports/ /
COPY --from=node /exports/ /
RUN set -e \
  ; cd dotfiles \
  ; make npm \
  ; mkdir -p /home/admin/.cache/npm \
  ; npm config set prefix /home/admin/.cache/npm
RUN set -e \
  ; mkdir -p /home/admin/exports/home/admin/ \
  ; mv /home/admin/.npmrc /home/admin/exports/home/admin/
USER root
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/include/ /exports/usr/local/lib/ /exports/usr/local/ \
  ; mv /usr/local/bin/n /usr/local/bin/node /usr/local/bin/npm /usr/local/bin/npx /exports/usr/local/bin/ \
  ; mv /usr/local/include/node /exports/usr/local/include/ \
  ; mv /usr/local/lib/node_modules /exports/usr/local/lib/ \
  ; mv /usr/local/n /exports/usr/local/

# SHELL-GIT
FROM shell-admin AS shell-git
COPY --from=make /exports/ /
COPY --from=git /exports/ /
COPY --from=git-crypt /exports/ /
COPY --from=diff-so-fancy /exports/ /
RUN set -e \
  ; cd dotfiles \
  ; make git
RUN set -e \
  ; mkdir -p /home/admin/exports/home/admin/ \
  ; mv /home/admin/.gitconfig /home/admin/exports/home/admin/
USER root
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/ /exports/usr/share/ /exports/usr/share/perl5/ /exports/var/lib/ \
  ; mv /usr/bin/git /exports/usr/bin/ \
  ; mv /usr/lib/git-core /exports/usr/lib/ \
  ; mv /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.* /usr/lib/x86_64-linux-gnu/libgdbm_compat.so.* /usr/lib/x86_64-linux-gnu/libgdbm.so.* /usr/lib/x86_64-linux-gnu/libperl.so.* /usr/lib/x86_64-linux-gnu/perl /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/local/bin/diff-so-fancy /usr/local/bin/git-crypt /exports/usr/local/bin/ \
  ; mv /usr/local/lib/node_modules/diff-so-fancy /exports/usr/local/lib/node_modules/ \
  ; mv /usr/share/git-core /usr/share/perl /exports/usr/share/ \
  ; mv /usr/share/perl5/Error.pm /usr/share/perl5/Error /usr/share/perl5/Git.pm /usr/share/perl5/Git /exports/usr/share/perl5/ \
  ; mv /var/lib/git /exports/var/lib/

# SHELL-CRON
FROM base AS shell-cron
RUN set -e \
  ; echo '*/5 * * * * admin chronic mbsync --config ~/src/mail/czabania.com.config primary' >> /etc/crontab \
  ; echo '*/5 * * * * admin chronic mbsync --config ~/src/mail/stayradiated.com.config primary' >> /etc/crontab \
  ; echo 'service cron start' >> /etc/rc.local
RUN set -e \
  ; mkdir -p /exports/etc/ \
  ; mv /etc/crontab /etc/rc.local /exports/etc/

# SHELL-BROWSER
FROM shell-admin AS shell-browser
COPY --from=make /exports/ /
COPY --from=xdg-utils /exports/ /
COPY --from=google-chrome /exports/ /
COPY --from=firefox /exports/ /
ENV \
  PATH=${PATH}:/opt/google/chrome
RUN set -e \
  ; cd dotfiles \
  ; make firefox
RUN set -e \
  ; mkdir -p /home/admin/exports/home/admin/.config/ \
  ; mv /home/admin/.config/mimeapps.list /home/admin/exports/home/admin/.config/
USER root
RUN set -e \
  ; mkdir -p /exports/etc/ /exports/etc/default/ /exports/etc/X11/ /exports/etc/X11/Xsession.d/ /exports/opt/ /exports/usr/bin/ /exports/usr/lib/systemd/user/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/gio/modules/ /exports/usr/libexec/ /exports/usr/local/bin/ /exports/usr/local/share/ /exports/usr/sbin/ /exports/usr/share/ /exports/usr/share/applications/ /exports/usr/share/apport/package-hooks/ /exports/usr/share/bug/ /exports/usr/share/dbus-1/services/ /exports/usr/share/doc-base/ /exports/usr/share/doc/ /exports/usr/share/gettext/its/ /exports/usr/share/glib-2.0/schemas/ /exports/usr/share/icons/ /exports/usr/share/icons/hicolor/ /exports/usr/share/icons/hicolor/48x48/ /exports/usr/share/icons/hicolor/48x48/apps/ /exports/usr/share/icons/hicolor/scalable/ /exports/usr/share/info/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ /exports/usr/share/man/man5/ /exports/usr/share/man/man7/ /exports/usr/share/man/man8/ /exports/usr/share/menu/ /exports/usr/share/pkgconfig/ \
  ; mv /etc/dconf /etc/fonts /etc/gtk-3.0 /exports/etc/ \
  ; mv /etc/default/google-chrome-beta /exports/etc/default/ \
  ; mv /etc/X11/xkb /exports/etc/X11/ \
  ; mv /etc/X11/Xsession.d/20dbus_xdg-runtime /exports/etc/X11/Xsession.d/ \
  ; mv /opt/firefox /opt/google /exports/opt/ \
  ; mv /usr/bin/google-chrome /usr/bin/google-chrome-beta /exports/usr/bin/ \
  ; mv /usr/lib/systemd/user/dbus.service /usr/lib/systemd/user/dbus.socket /usr/lib/systemd/user/dconf.service /usr/lib/systemd/user/sockets.target.wants /exports/usr/lib/systemd/user/ \
  ; mv /usr/lib/x86_64-linux-gnu/avahi /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0 /usr/lib/x86_64-linux-gnu/gtk-3.0 /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libasound.so.2.0.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0.23609.1 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0.0.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0.0.1 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3.2.9 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3.5.4 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcairo.so.2 /usr/lib/x86_64-linux-gnu/libcairo.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcolord.so.2 /usr/lib/x86_64-linux-gnu/libcolord.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcups.so.2 /usr/lib/x86_64-linux-gnu/libdatrie.so.1 /usr/lib/x86_64-linux-gnu/libdatrie.so.1.4.0 /usr/lib/x86_64-linux-gnu/libdbus-glib-1.so.* /usr/lib/x86_64-linux-gnu/libdconf.so.1 /usr/lib/x86_64-linux-gnu/libdconf.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdeflate.so.0 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0.0.0 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.0 /usr/lib/x86_64-linux-gnu/libfreebl3.chk /usr/lib/x86_64-linux-gnu/libfreebl3.so /usr/lib/x86_64-linux-gnu/libfreeblpriv3.chk /usr/lib/x86_64-linux-gnu/libfreeblpriv3.so /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.18.1 /usr/lib/x86_64-linux-gnu/libfribidi.so.0 /usr/lib/x86_64-linux-gnu/libfribidi.so.0.4.0 /usr/lib/x86_64-linux-gnu/libgbm.so.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0.4200.8 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0.2404.29 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgtk-3-0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0.2404.29 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.20704.0 /usr/lib/x86_64-linux-gnu/libjbig.so.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2.0.12 /usr/lib/x86_64-linux-gnu/libnspr4.so /usr/lib/x86_64-linux-gnu/libnss3.so /usr/lib/x86_64-linux-gnu/libnssutil3.so /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0.5000.6 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0.5000.6 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0.5000.6 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0.40.0 /usr/lib/x86_64-linux-gnu/libplc4.so /usr/lib/x86_64-linux-gnu/libplds4.so /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.37.0 /usr/lib/x86_64-linux-gnu/libsmime3.so /usr/lib/x86_64-linux-gnu/libssl3.so /usr/lib/x86_64-linux-gnu/libthai.so.0 /usr/lib/x86_64-linux-gnu/libthai.so.0.3.1 /usr/lib/x86_64-linux-gnu/libtiff.so.5 /usr/lib/x86_64-linux-gnu/libtiff.so.5.7.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.20.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0.20.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.20.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0.20.0 /usr/lib/x86_64-linux-gnu/libwebp.so.7 /usr/lib/x86_64-linux-gnu/libwebp.so.7.1.3 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXcursor.so.1 /usr/lib/x86_64-linux-gnu/libXcursor.so.1.0.2 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libXi.so.6 /usr/lib/x86_64-linux-gnu/libXi.so.6.1.0 /usr/lib/x86_64-linux-gnu/libXinerama.so.1 /usr/lib/x86_64-linux-gnu/libXinerama.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrandr.so.2 /usr/lib/x86_64-linux-gnu/libXrandr.so.2.2.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /usr/lib/x86_64-linux-gnu/nss /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/lib/x86_64-linux-gnu/gio/modules/giomodule.cache /usr/lib/x86_64-linux-gnu/gio/modules/libdconfsettings.so /exports/usr/lib/x86_64-linux-gnu/gio/modules/ \
  ; mv /usr/libexec/dconf-service /exports/usr/libexec/ \
  ; mv /usr/local/bin/firefox /exports/usr/local/bin/ \
  ; mv /usr/local/share/fonts /exports/usr/local/share/ \
  ; mv /usr/sbin/update-icon-caches /exports/usr/sbin/ \
  ; mv /usr/share/alsa /usr/share/appdata /usr/share/fonts /usr/share/gnome-control-center /usr/share/libdrm /usr/share/libthai /usr/share/mime /usr/share/themes /usr/share/X11 /exports/usr/share/ \
  ; mv /usr/share/applications/firefox.desktop /usr/share/applications/google-chrome-beta.desktop /exports/usr/share/applications/ \
  ; mv /usr/share/apport/package-hooks/source_fontconfig.py /exports/usr/share/apport/package-hooks/ \
  ; mv /usr/share/bug/fonts-liberation /usr/share/bug/libgbm1 /usr/share/bug/libgtk-3-0 /usr/share/bug/xdg-utils /exports/usr/share/bug/ \
  ; mv /usr/share/dbus-1/services/ca.desrt.dconf.service /exports/usr/share/dbus-1/services/ \
  ; mv /usr/share/doc-base/fontconfig.fontconfig-user /usr/share/doc-base/libpng16-16.libpng16 /usr/share/doc-base/shared-mime-info.shared-mime-info /exports/usr/share/doc-base/ \
  ; mv /usr/share/doc/adwaita-icon-theme /usr/share/doc/dbus-user-session /usr/share/doc/dconf-gsettings-backend /usr/share/doc/dconf-service /usr/share/doc/fontconfig-config /usr/share/doc/fontconfig /usr/share/doc/fonts-liberation /usr/share/doc/google-chrome-beta /usr/share/doc/gtk-update-icon-cache /usr/share/doc/hicolor-icon-theme /usr/share/doc/humanity-icon-theme /usr/share/doc/libasound2-data /usr/share/doc/libasound2 /usr/share/doc/libatk-bridge2.0-0 /usr/share/doc/libatk1.0-0 /usr/share/doc/libatk1.0-data /usr/share/doc/libatspi2.0-0 /usr/share/doc/libavahi-client3 /usr/share/doc/libavahi-common-data /usr/share/doc/libavahi-common3 /usr/share/doc/libcairo-gobject2 /usr/share/doc/libcairo2 /usr/share/doc/libcolord2 /usr/share/doc/libcups2 /usr/share/doc/libdatrie1 /usr/share/doc/libdconf1 /usr/share/doc/libdeflate0 /usr/share/doc/libdrm-common /usr/share/doc/libdrm2 /usr/share/doc/libepoxy0 /usr/share/doc/libfontconfig1 /usr/share/doc/libfreetype6 /usr/share/doc/libfribidi0 /usr/share/doc/libgbm1 /usr/share/doc/libgdk-pixbuf-2.0-0 /usr/share/doc/libgdk-pixbuf2.0-common /usr/share/doc/libgraphite2-3 /usr/share/doc/libgtk-3-0 /usr/share/doc/libgtk-3-common /usr/share/doc/libharfbuzz0b /usr/share/doc/libjbig0 /usr/share/doc/libjpeg-turbo8 /usr/share/doc/libjpeg8 /usr/share/doc/liblcms2-2 /usr/share/doc/libnspr4 /usr/share/doc/libnss3 /usr/share/doc/libpango-1.0-0 /usr/share/doc/libpangocairo-1.0-0 /usr/share/doc/libpangoft2-1.0-0 /usr/share/doc/libpixman-1-0 /usr/share/doc/libpng16-16 /usr/share/doc/libthai-data /usr/share/doc/libthai0 /usr/share/doc/libtiff5 /usr/share/doc/libwayland-client0 /usr/share/doc/libwayland-cursor0 /usr/share/doc/libwayland-egl1 /usr/share/doc/libwayland-server0 /usr/share/doc/libwebp7 /usr/share/doc/libx11-6 /usr/share/doc/libx11-data /usr/share/doc/libxau6 /usr/share/doc/libxcb-render0 /usr/share/doc/libxcb-shm0 /usr/share/doc/libxcb1 /usr/share/doc/libxcomposite1 /usr/share/doc/libxcursor1 /usr/share/doc/libxdamage1 /usr/share/doc/libxdmcp6 /usr/share/doc/libxext6 /usr/share/doc/libxfixes3 /usr/share/doc/libxi6 /usr/share/doc/libxinerama1 /usr/share/doc/libxkbcommon0 /usr/share/doc/libxrandr2 /usr/share/doc/libxrender1 /usr/share/doc/shared-mime-info /usr/share/doc/ubuntu-mono /usr/share/doc/wget /usr/share/doc/xdg-utils /usr/share/doc/xkb-data /exports/usr/share/doc/ \
  ; mv /usr/share/gettext/its/shared-mime-info.its /usr/share/gettext/its/shared-mime-info.loc /exports/usr/share/gettext/its/ \
  ; mv /usr/share/glib-2.0/schemas/gschemas.compiled /usr/share/glib-2.0/schemas/org.gtk.Settings.ColorChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.Debug.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.EmojiChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.FileChooser.gschema.xml /exports/usr/share/glib-2.0/schemas/ \
  ; mv /usr/share/icons/Adwaita /usr/share/icons/default /usr/share/icons/Humanity-Dark /usr/share/icons/Humanity /usr/share/icons/LoginIcons /usr/share/icons/ubuntu-mono-dark /usr/share/icons/ubuntu-mono-light /exports/usr/share/icons/ \
  ; mv /usr/share/icons/hicolor/128x128 /usr/share/icons/hicolor/16x16 /usr/share/icons/hicolor/192x192 /usr/share/icons/hicolor/22x22 /usr/share/icons/hicolor/24x24 /usr/share/icons/hicolor/256x256 /usr/share/icons/hicolor/32x32 /usr/share/icons/hicolor/36x36 /usr/share/icons/hicolor/512x512 /usr/share/icons/hicolor/64x64 /usr/share/icons/hicolor/72x72 /usr/share/icons/hicolor/96x96 /usr/share/icons/hicolor/icon-theme.cache /usr/share/icons/hicolor/index.theme /usr/share/icons/hicolor/symbolic /exports/usr/share/icons/hicolor/ \
  ; mv /usr/share/icons/hicolor/48x48/actions /usr/share/icons/hicolor/48x48/animations /usr/share/icons/hicolor/48x48/categories /usr/share/icons/hicolor/48x48/devices /usr/share/icons/hicolor/48x48/emblems /usr/share/icons/hicolor/48x48/emotes /usr/share/icons/hicolor/48x48/filesystems /usr/share/icons/hicolor/48x48/intl /usr/share/icons/hicolor/48x48/mimetypes /usr/share/icons/hicolor/48x48/places /usr/share/icons/hicolor/48x48/status /usr/share/icons/hicolor/48x48/stock /exports/usr/share/icons/hicolor/48x48/ \
  ; mv /usr/share/icons/hicolor/48x48/apps/google-chrome-beta.png /exports/usr/share/icons/hicolor/48x48/apps/ \
  ; mv /usr/share/icons/hicolor/scalable/actions /usr/share/icons/hicolor/scalable/animations /usr/share/icons/hicolor/scalable/categories /usr/share/icons/hicolor/scalable/devices /usr/share/icons/hicolor/scalable/emblems /usr/share/icons/hicolor/scalable/emotes /usr/share/icons/hicolor/scalable/filesystems /usr/share/icons/hicolor/scalable/intl /usr/share/icons/hicolor/scalable/mimetypes /usr/share/icons/hicolor/scalable/places /usr/share/icons/hicolor/scalable/status /usr/share/icons/hicolor/scalable/stock /exports/usr/share/icons/hicolor/scalable/ \
  ; mv /usr/share/info/wget.info.gz /exports/usr/share/info/ \
  ; mv /usr/share/lintian/overrides/dbus-user-session /usr/share/lintian/overrides/fontconfig /usr/share/lintian/overrides/hicolor-icon-theme /usr/share/lintian/overrides/libatk-bridge2.0-0 /usr/share/lintian/overrides/libatk1.0-0 /usr/share/lintian/overrides/libatspi2.0-0 /usr/share/lintian/overrides/libcairo-gobject2 /usr/share/lintian/overrides/libgbm1 /usr/share/lintian/overrides/libjpeg-turbo8 /usr/share/lintian/overrides/libnspr4 /usr/share/lintian/overrides/libnss3 /usr/share/lintian/overrides/libpixman-1-0 /usr/share/lintian/overrides/libx11-6 /exports/usr/share/lintian/overrides/ \
  ; mv /usr/share/man/man1/dconf-service.1.gz /usr/share/man/man1/fc-cache.1.gz /usr/share/man/man1/fc-cat.1.gz /usr/share/man/man1/fc-conflist.1.gz /usr/share/man/man1/fc-list.1.gz /usr/share/man/man1/fc-match.1.gz /usr/share/man/man1/fc-pattern.1.gz /usr/share/man/man1/fc-query.1.gz /usr/share/man/man1/fc-scan.1.gz /usr/share/man/man1/fc-validate.1.gz /usr/share/man/man1/google-chrome-beta.1.gz /usr/share/man/man1/gtk-update-icon-cache.1.gz /usr/share/man/man1/open.1.gz /usr/share/man/man1/update-mime-database.1.gz /usr/share/man/man1/wget.1.gz /usr/share/man/man1/xdg-desktop-icon.1.gz /usr/share/man/man1/xdg-desktop-menu.1.gz /usr/share/man/man1/xdg-email.1.gz /usr/share/man/man1/xdg-icon-resource.1.gz /usr/share/man/man1/xdg-mime.1.gz /usr/share/man/man1/xdg-open.1.gz /usr/share/man/man1/xdg-screensaver.1.gz /usr/share/man/man1/xdg-settings.1.gz /exports/usr/share/man/man1/ \
  ; mv /usr/share/man/man5/Compose.5.gz /usr/share/man/man5/fonts-conf.5.gz /usr/share/man/man5/XCompose.5.gz /exports/usr/share/man/man5/ \
  ; mv /usr/share/man/man7/xkeyboard-config.7.gz /exports/usr/share/man/man7/ \
  ; mv /usr/share/man/man8/update-icon-caches.8.gz /exports/usr/share/man/man8/ \
  ; mv /usr/share/menu/google-chrome-beta.menu /exports/usr/share/menu/ \
  ; mv /usr/share/pkgconfig/adwaita-icon-theme.pc /usr/share/pkgconfig/shared-mime-info.pc /usr/share/pkgconfig/xkeyboard-config.pc /exports/usr/share/pkgconfig/

# XSECURELOCK
FROM base AS xsecurelock
COPY --from=apteryx /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=clone /exports/ /
RUN set -e \
  ; apteryx apache2-utils autoconf autotools-dev automake binutils gcc libc6-dev libpam-dev libx11-dev libxcomposite-dev libxext-dev libxfixes-dev libxft-dev libxmuu-dev libxrandr-dev libxss-dev make mplayer mpv pamtester pkg-config x11proto-core-dev xscreensaver \
  ; clone --https --tag='v1.9.0' https://github.com/google/xsecurelock \
  ; cd ~/src/github.com/google/xsecurelock \
  ; sh autogen.sh \
  ; ./configure --with-pam-service-name=xscreensaver \
  ; make \
  ; make install
RUN set -e \
  ; mkdir -p /exports/etc/pam.d/ /exports/usr/bin/ /exports/usr/libexec/ /exports/usr/share/ /exports/usr/lib/systemd/user/ /exports/usr/local/bin/ /exports/usr/local/libexec/ \
  ; mv /etc/pam.d/xscreensaver /exports/etc/pam.d/ \
  ; mv /usr/bin/xscreensaver /usr/bin/xscreensaver-* /exports/usr/bin/ \
  ; mv /usr/libexec/xscreensaver /exports/usr/libexec/ \
  ; mv /usr/share/xscreensaver /exports/usr/share/ \
  ; mv /usr/lib/systemd/user/xscreensaver.service /exports/usr/lib/systemd/user/ \
  ; mv /usr/local/bin/xsecurelock /exports/usr/local/bin/ \
  ; mv /usr/local/libexec/xsecurelock /exports/usr/local/libexec/

# XCLIP
FROM base AS xclip
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx xclip='0.13-2'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/bin/xclip /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu/libICE.so.* /usr/lib/x86_64-linux-gnu/libSM.so.* /usr/lib/x86_64-linux-gnu/libX11.so.* /usr/lib/x86_64-linux-gnu/libXau.so.* /usr/lib/x86_64-linux-gnu/libxcb.so.* /usr/lib/x86_64-linux-gnu/libXdmcp.so.* /usr/lib/x86_64-linux-gnu/libXext.so.* /usr/lib/x86_64-linux-gnu/libXmu.so.* /usr/lib/x86_64-linux-gnu/libXt.so.* /exports/usr/lib/x86_64-linux-gnu/

# REDSHIFT
FROM base AS redshift
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx redshift='1.12-4.2ubuntu1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/ \
  ; mv /usr/bin/redshift /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# QPDFVIEW
FROM base AS qpdfview
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx qpdfview='0.4.18-6'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/ \
  ; mv /usr/bin/qpdfview /exports/usr/bin/ \
  ; mv /usr/lib/qpdfview /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# LIGHT
FROM base AS light
COPY --from=clone /exports/ /
RUN set -e \
  ; clone --https --ref='85022325043182eb26e42a13b2e080ad991bdf6a' https://github.com/stayradiated/light \
  ; cd /root/src/github.com/stayradiated/light \
  ; mv light /usr/local/bin/light
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/light /exports/usr/local/bin/

# FLAMESHOT
FROM base AS flameshot
COPY --from=wget /exports/ /
COPY --from=apteryx /exports/ /
RUN set -e \
  ; wget -O flameshot.deb https://github.com/flameshot-org/flameshot/releases/download/v12.1.0/flameshot-12.1.0-1.ubuntu-22.04.amd64.deb \
  ; apteryx ./flameshot.deb \
  ; rm flameshot.deb
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/share/ /exports/usr/share/applications/ /exports/usr/share/apport/package-hooks/ /exports/usr/share/bash-completion/completions/ /exports/usr/share/dbus-1/interfaces/ /exports/usr/share/dbus-1/services/ /exports/usr/share/ \
  ; mv /usr/bin/flameshot /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu/dri /usr/lib/x86_64-linux-gnu/libdouble-conversion.so.3 /usr/lib/x86_64-linux-gnu/libdouble-conversion.so.3.1 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2.0.0 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1.0.1 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libEGL_mesa.so.0 /usr/lib/x86_64-linux-gnu/libEGL_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libEGL.so.1 /usr/lib/x86_64-linux-gnu/libEGL.so.1.1.0 /usr/lib/x86_64-linux-gnu/libevdev.so.2 /usr/lib/x86_64-linux-gnu/libevdev.so.2.3.0 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.0 /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.18.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libGL.so.1 /usr/lib/x86_64-linux-gnu/libGL.so.1.7.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX_indirect.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgudev-1.0.so.0 /usr/lib/x86_64-linux-gnu/libgudev-1.0.so.0.3.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.20704.0 /usr/lib/x86_64-linux-gnu/libICE.so.6 /usr/lib/x86_64-linux-gnu/libICE.so.6.3.0 /usr/lib/x86_64-linux-gnu/libinput.so.10 /usr/lib/x86_64-linux-gnu/libinput.so.10.13.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/libLLVM-15.so /usr/lib/x86_64-linux-gnu/libLLVM-15.so.1 /usr/lib/x86_64-linux-gnu/libmd4c.so.0 /usr/lib/x86_64-linux-gnu/libmd4c.so.0.4.8 /usr/lib/x86_64-linux-gnu/libmtdev.so.1 /usr/lib/x86_64-linux-gnu/libmtdev.so.1.0.0 /usr/lib/x86_64-linux-gnu/libpcre2-16.so.0 /usr/lib/x86_64-linux-gnu/libpcre2-16.so.0.10.4 /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.37.0 /usr/lib/x86_64-linux-gnu/libQt5Core.so.5 /usr/lib/x86_64-linux-gnu/libQt5Core.so.5.15 /usr/lib/x86_64-linux-gnu/libQt5Core.so.5.15.3 /usr/lib/x86_64-linux-gnu/libQt5DBus.so.5 /usr/lib/x86_64-linux-gnu/libQt5DBus.so.5.15 /usr/lib/x86_64-linux-gnu/libQt5DBus.so.5.15.3 /usr/lib/x86_64-linux-gnu/libQt5EglFSDeviceIntegration.so.5 /usr/lib/x86_64-linux-gnu/libQt5EglFSDeviceIntegration.so.5.15 /usr/lib/x86_64-linux-gnu/libQt5EglFSDeviceIntegration.so.5.15.3 /usr/lib/x86_64-linux-gnu/libQt5EglFsKmsSupport.so.5 /usr/lib/x86_64-linux-gnu/libQt5EglFsKmsSupport.so.5.15 /usr/lib/x86_64-linux-gnu/libQt5EglFsKmsSupport.so.5.15.3 /usr/lib/x86_64-linux-gnu/libQt5Gui.so.5 /usr/lib/x86_64-linux-gnu/libQt5Gui.so.5.15 /usr/lib/x86_64-linux-gnu/libQt5Gui.so.5.15.3 /usr/lib/x86_64-linux-gnu/libQt5Network.so.5 /usr/lib/x86_64-linux-gnu/libQt5Network.so.5.15 /usr/lib/x86_64-linux-gnu/libQt5Network.so.5.15.3 /usr/lib/x86_64-linux-gnu/libQt5Svg.so.5 /usr/lib/x86_64-linux-gnu/libQt5Svg.so.5.15 /usr/lib/x86_64-linux-gnu/libQt5Svg.so.5.15.3 /usr/lib/x86_64-linux-gnu/libQt5Widgets.so.5 /usr/lib/x86_64-linux-gnu/libQt5Widgets.so.5.15 /usr/lib/x86_64-linux-gnu/libQt5Widgets.so.5.15.3 /usr/lib/x86_64-linux-gnu/libQt5XcbQpa.so.5 /usr/lib/x86_64-linux-gnu/libQt5XcbQpa.so.5.15 /usr/lib/x86_64-linux-gnu/libQt5XcbQpa.so.5.15.3 /usr/lib/x86_64-linux-gnu/libsensors.so.5 /usr/lib/x86_64-linux-gnu/libsensors.so.5.0.0 /usr/lib/x86_64-linux-gnu/libSM.so.6 /usr/lib/x86_64-linux-gnu/libSM.so.6.0.1 /usr/lib/x86_64-linux-gnu/libwacom.so.9 /usr/lib/x86_64-linux-gnu/libwacom.so.9.0.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.20.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0.20.0 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1.0.0 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-icccm.so.4 /usr/lib/x86_64-linux-gnu/libxcb-icccm.so.4.0.0 /usr/lib/x86_64-linux-gnu/libxcb-image.so.0 /usr/lib/x86_64-linux-gnu/libxcb-image.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so.1 /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-render-util.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render-util.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-util.so.1 /usr/lib/x86_64-linux-gnu/libxcb-util.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xinput.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xinput.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-xkb.so.1 /usr/lib/x86_64-linux-gnu/libxcb-xkb.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libxkbcommon-x11.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon-x11.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1.0.0 /usr/lib/x86_64-linux-gnu/qt-default /usr/lib/x86_64-linux-gnu/qt5 /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/local/share/fonts /exports/usr/local/share/ \
  ; mv /usr/share/applications/org.flameshot.Flameshot.desktop /exports/usr/share/applications/ \
  ; mv /usr/share/apport/package-hooks/source_fontconfig.py /usr/share/apport/package-hooks/source_mtdev.py /exports/usr/share/apport/package-hooks/ \
  ; mv /usr/share/bash-completion/completions/flameshot /exports/usr/share/bash-completion/completions/ \
  ; mv /usr/share/dbus-1/interfaces/org.flameshot.Flameshot.xml /exports/usr/share/dbus-1/interfaces/ \
  ; mv /usr/share/dbus-1/services/org.flameshot.Flameshot.service /exports/usr/share/dbus-1/services/ \
  ; mv /usr/share/flameshot /exports/usr/share/

# FEH
FROM base AS feh
COPY --from=apteryx /exports/ /
COPY --from=wget /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=make /exports/ /
RUN set -e \
  ; apteryx libimlib2-dev libpng-dev libx11-dev libxt-dev \
  ; wget -O /tmp/feh.tar.bz2 https://feh.finalrewind.org/feh-3.10.3.tar.bz2 \
  ; tar xjvf /tmp/feh.tar.bz2 -C /tmp \
  ; cd /tmp/feh-3.10.3 \
  ; make curl=0 xinerama=0 \
  ; make install app=1 \
  ; rm -rf /tmp/feh*
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/share/ /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/local/bin/feh /exports/usr/local/bin/ \
  ; mv /usr/local/share/feh /exports/usr/local/share/ \
  ; mv /usr/lib/x86_64-linux-gnu/imlib2 /usr/lib/x86_64-linux-gnu/libImlib2* /usr/lib/x86_64-linux-gnu/libpng* /usr/lib/x86_64-linux-gnu/libX11* /usr/lib/x86_64-linux-gnu/libXt* /exports/usr/lib/x86_64-linux-gnu/

# AUDACITY
FROM base AS audacity
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx audacity='2.4.2~dfsg0-5'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/mime/packages/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/gio/modules/ /exports/usr/libexec/ /exports/usr/local/share/ /exports/usr/sbin/ /exports/usr/share/ /exports/usr/share/applications/ /exports/usr/share/apport/package-hooks/ /exports/usr/share/dbus-1/services/ /exports/usr/share/doc-base/ /exports/usr/share/glib-2.0/schemas/ /exports/usr/share/man/man1/ /exports/usr/share/man/man8/ /exports/usr/share/pixmaps/ \
  ; mv /usr/bin/audacity /exports/usr/bin/ \
  ; mv /usr/lib/audacity /exports/usr/lib/ \
  ; mv /usr/lib/mime/packages/audacity /exports/usr/lib/mime/packages/ \
  ; mv /usr/lib/x86_64-linux-gnu/avahi /usr/lib/x86_64-linux-gnu/dri /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0 /usr/lib/x86_64-linux-gnu/gtk-3.0 /usr/lib/x86_64-linux-gnu/libaom.so.3 /usr/lib/x86_64-linux-gnu/libaom.so.3.3.0 /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libasound.so.2.0.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0.23609.1 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0.0.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0.0.1 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3.2.9 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3.5.4 /usr/lib/x86_64-linux-gnu/libavcodec.so.58 /usr/lib/x86_64-linux-gnu/libavcodec.so.58.134.100 /usr/lib/x86_64-linux-gnu/libavformat.so.58 /usr/lib/x86_64-linux-gnu/libavformat.so.58.76.100 /usr/lib/x86_64-linux-gnu/libavutil.so.56 /usr/lib/x86_64-linux-gnu/libavutil.so.56.70.100 /usr/lib/x86_64-linux-gnu/libbluray.so.2 /usr/lib/x86_64-linux-gnu/libbluray.so.2.4.1 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libcairo.so.2 /usr/lib/x86_64-linux-gnu/libcairo.so.2.11600.0 /usr/lib/x86_64-linux-gnu/libchromaprint.so.1 /usr/lib/x86_64-linux-gnu/libchromaprint.so.1.5.1 /usr/lib/x86_64-linux-gnu/libcodec2.so.1.0 /usr/lib/x86_64-linux-gnu/libcolord.so.2 /usr/lib/x86_64-linux-gnu/libcolord.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcups.so.2 /usr/lib/x86_64-linux-gnu/libdatrie.so.1 /usr/lib/x86_64-linux-gnu/libdatrie.so.1.4.0 /usr/lib/x86_64-linux-gnu/libdav1d.so.5 /usr/lib/x86_64-linux-gnu/libdav1d.so.5.1.1 /usr/lib/x86_64-linux-gnu/libdconf.so.1 /usr/lib/x86_64-linux-gnu/libdconf.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdeflate.so.0 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2.0.0 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1.0.1 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0.0.0 /usr/lib/x86_64-linux-gnu/libFLAC.so.8 /usr/lib/x86_64-linux-gnu/libFLAC.so.8.3.0 /usr/lib/x86_64-linux-gnu/libFLAC++.so.6 /usr/lib/x86_64-linux-gnu/libFLAC++.so.6.3.0 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.0 /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.18.1 /usr/lib/x86_64-linux-gnu/libfribidi.so.0 /usr/lib/x86_64-linux-gnu/libfribidi.so.0.4.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0.4200.8 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0.2404.29 /usr/lib/x86_64-linux-gnu/libGL.so.1 /usr/lib/x86_64-linux-gnu/libGL.so.1.7.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX_indirect.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0.0.0 /usr/lib/x86_64-linux-gnu/libgme.so.0 /usr/lib/x86_64-linux-gnu/libgme.so.0.6.3 /usr/lib/x86_64-linux-gnu/libgomp.so.1 /usr/lib/x86_64-linux-gnu/libgomp.so.1.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgsm.so.1 /usr/lib/x86_64-linux-gnu/libgsm.so.1.0.19 /usr/lib/x86_64-linux-gnu/libgtk-3-0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0.2404.29 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.20704.0 /usr/lib/x86_64-linux-gnu/libICE.so.6 /usr/lib/x86_64-linux-gnu/libICE.so.6.3.0 /usr/lib/x86_64-linux-gnu/libid3tag.so.0 /usr/lib/x86_64-linux-gnu/libid3tag.so.0.3.0 /usr/lib/x86_64-linux-gnu/libjack.so.0 /usr/lib/x86_64-linux-gnu/libjack.so.0.1.0 /usr/lib/x86_64-linux-gnu/libjacknet.so.0 /usr/lib/x86_64-linux-gnu/libjacknet.so.0.1.0 /usr/lib/x86_64-linux-gnu/libjackserver.so.0 /usr/lib/x86_64-linux-gnu/libjackserver.so.0.1.0 /usr/lib/x86_64-linux-gnu/libjbig.so.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2.0.12 /usr/lib/x86_64-linux-gnu/liblilv-0.so.0 /usr/lib/x86_64-linux-gnu/liblilv-0.so.0.24.12 /usr/lib/x86_64-linux-gnu/libLLVM-15.so /usr/lib/x86_64-linux-gnu/libLLVM-15.so.1 /usr/lib/x86_64-linux-gnu/libmad.so.0 /usr/lib/x86_64-linux-gnu/libmad.so.0.2.1 /usr/lib/x86_64-linux-gnu/libmfx-tracer.so.1 /usr/lib/x86_64-linux-gnu/libmfx-tracer.so.1.35 /usr/lib/x86_64-linux-gnu/libmfx.so.1 /usr/lib/x86_64-linux-gnu/libmfx.so.1.35 /usr/lib/x86_64-linux-gnu/libmfxhw64.so.1 /usr/lib/x86_64-linux-gnu/libmfxhw64.so.1.35 /usr/lib/x86_64-linux-gnu/libmp3lame.so.0 /usr/lib/x86_64-linux-gnu/libmp3lame.so.0.0.0 /usr/lib/x86_64-linux-gnu/libmpg123.so.0 /usr/lib/x86_64-linux-gnu/libmpg123.so.0.46.7 /usr/lib/x86_64-linux-gnu/libnorm.so.1 /usr/lib/x86_64-linux-gnu/libnotify.so.4 /usr/lib/x86_64-linux-gnu/libnotify.so.4.0.0 /usr/lib/x86_64-linux-gnu/libnuma.so.1 /usr/lib/x86_64-linux-gnu/libnuma.so.1.0.0 /usr/lib/x86_64-linux-gnu/libogg.so.0 /usr/lib/x86_64-linux-gnu/libogg.so.0.8.5 /usr/lib/x86_64-linux-gnu/libOpenCL.so.1 /usr/lib/x86_64-linux-gnu/libOpenCL.so.1.0.0 /usr/lib/x86_64-linux-gnu/libopenjp2.so.2.4.0 /usr/lib/x86_64-linux-gnu/libopenjp2.so.7 /usr/lib/x86_64-linux-gnu/libopenmpt.so.0 /usr/lib/x86_64-linux-gnu/libopenmpt.so.0.3.3 /usr/lib/x86_64-linux-gnu/libopus.so.0 /usr/lib/x86_64-linux-gnu/libopus.so.0.8.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0.5000.6 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0.5000.6 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0.5000.6 /usr/lib/x86_64-linux-gnu/libpgm-5.3.so.0 /usr/lib/x86_64-linux-gnu/libpgm-5.3.so.0.0.128 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0.40.0 /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.37.0 /usr/lib/x86_64-linux-gnu/libportaudio.so.2 /usr/lib/x86_64-linux-gnu/libportaudio.so.2.0.0 /usr/lib/x86_64-linux-gnu/libportSMF.so.0 /usr/lib/x86_64-linux-gnu/libportSMF.so.0.0.0 /usr/lib/x86_64-linux-gnu/librabbitmq.so.4 /usr/lib/x86_64-linux-gnu/librabbitmq.so.4.4.0 /usr/lib/x86_64-linux-gnu/librsvg-2.so.2 /usr/lib/x86_64-linux-gnu/librsvg-2.so.2.48.0 /usr/lib/x86_64-linux-gnu/libsamplerate.so.0 /usr/lib/x86_64-linux-gnu/libsamplerate.so.0.2.2 /usr/lib/x86_64-linux-gnu/libsensors.so.5 /usr/lib/x86_64-linux-gnu/libsensors.so.5.0.0 /usr/lib/x86_64-linux-gnu/libserd-0.so.0 /usr/lib/x86_64-linux-gnu/libserd-0.so.0.30.10 /usr/lib/x86_64-linux-gnu/libshine.so.3 /usr/lib/x86_64-linux-gnu/libshine.so.3.0.1 /usr/lib/x86_64-linux-gnu/libSM.so.6 /usr/lib/x86_64-linux-gnu/libSM.so.6.0.1 /usr/lib/x86_64-linux-gnu/libsnappy.so.1 /usr/lib/x86_64-linux-gnu/libsnappy.so.1.1.8 /usr/lib/x86_64-linux-gnu/libsndfile.so.1 /usr/lib/x86_64-linux-gnu/libsndfile.so.1.0.31 /usr/lib/x86_64-linux-gnu/libsodium.so.23 /usr/lib/x86_64-linux-gnu/libsodium.so.23.3.0 /usr/lib/x86_64-linux-gnu/libsord-0.so.0 /usr/lib/x86_64-linux-gnu/libsord-0.so.0.16.8 /usr/lib/x86_64-linux-gnu/libSoundTouch.so.1 /usr/lib/x86_64-linux-gnu/libSoundTouch.so.1.0.0 /usr/lib/x86_64-linux-gnu/libsoxr.so.0 /usr/lib/x86_64-linux-gnu/libsoxr.so.0.1.2 /usr/lib/x86_64-linux-gnu/libspeex.so.1 /usr/lib/x86_64-linux-gnu/libspeex.so.1.5.0 /usr/lib/x86_64-linux-gnu/libsratom-0.so.0 /usr/lib/x86_64-linux-gnu/libsratom-0.so.0.6.8 /usr/lib/x86_64-linux-gnu/libsrt-gnutls.so.1.4 /usr/lib/x86_64-linux-gnu/libsrt-gnutls.so.1.4.4 /usr/lib/x86_64-linux-gnu/libssh-gcrypt.so.4 /usr/lib/x86_64-linux-gnu/libssh-gcrypt.so.4.8.7 /usr/lib/x86_64-linux-gnu/libsuil-0.so.0 /usr/lib/x86_64-linux-gnu/libsuil-0.so.0.10.10 /usr/lib/x86_64-linux-gnu/libswresample.so.3 /usr/lib/x86_64-linux-gnu/libswresample.so.3.9.100 /usr/lib/x86_64-linux-gnu/libthai.so.0 /usr/lib/x86_64-linux-gnu/libthai.so.0.3.1 /usr/lib/x86_64-linux-gnu/libtheora.so.0 /usr/lib/x86_64-linux-gnu/libtheora.so.0.3.10 /usr/lib/x86_64-linux-gnu/libtheoradec.so.1 /usr/lib/x86_64-linux-gnu/libtheoradec.so.1.1.4 /usr/lib/x86_64-linux-gnu/libtheoraenc.so.1 /usr/lib/x86_64-linux-gnu/libtheoraenc.so.1.1.2 /usr/lib/x86_64-linux-gnu/libtiff.so.5 /usr/lib/x86_64-linux-gnu/libtiff.so.5.7.0 /usr/lib/x86_64-linux-gnu/libtwolame.so.0 /usr/lib/x86_64-linux-gnu/libtwolame.so.0.0.0 /usr/lib/x86_64-linux-gnu/libudfread.so.0 /usr/lib/x86_64-linux-gnu/libudfread.so.0.1.0 /usr/lib/x86_64-linux-gnu/libva-drm.so.2 /usr/lib/x86_64-linux-gnu/libva-drm.so.2.1400.0 /usr/lib/x86_64-linux-gnu/libva-x11.so.2 /usr/lib/x86_64-linux-gnu/libva-x11.so.2.1400.0 /usr/lib/x86_64-linux-gnu/libva.so.2 /usr/lib/x86_64-linux-gnu/libva.so.2.1400.0 /usr/lib/x86_64-linux-gnu/libvamp-hostsdk.so.3 /usr/lib/x86_64-linux-gnu/libvamp-hostsdk.so.3.10.0 /usr/lib/x86_64-linux-gnu/libvdpau.so.1 /usr/lib/x86_64-linux-gnu/libvdpau.so.1.0.0 /usr/lib/x86_64-linux-gnu/libvorbis.so.0 /usr/lib/x86_64-linux-gnu/libvorbis.so.0.4.9 /usr/lib/x86_64-linux-gnu/libvorbisenc.so.2 /usr/lib/x86_64-linux-gnu/libvorbisenc.so.2.0.12 /usr/lib/x86_64-linux-gnu/libvorbisfile.so.3 /usr/lib/x86_64-linux-gnu/libvorbisfile.so.3.3.8 /usr/lib/x86_64-linux-gnu/libvpx.so.7 /usr/lib/x86_64-linux-gnu/libvpx.so.7.0 /usr/lib/x86_64-linux-gnu/libvpx.so.7.0.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.20.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0.20.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.20.0 /usr/lib/x86_64-linux-gnu/libwebp.so.7 /usr/lib/x86_64-linux-gnu/libwebp.so.7.1.3 /usr/lib/x86_64-linux-gnu/libwebpmux.so.3 /usr/lib/x86_64-linux-gnu/libwebpmux.so.3.0.8 /usr/lib/x86_64-linux-gnu/libwx_baseu_net-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_baseu_net-3.0.so.0.5.0 /usr/lib/x86_64-linux-gnu/libwx_baseu_xml-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_baseu_xml-3.0.so.0.5.0 /usr/lib/x86_64-linux-gnu/libwx_baseu-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_baseu-3.0.so.0.5.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_adv-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_adv-3.0.so.0.5.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_aui-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_aui-3.0.so.0.5.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_core-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_core-3.0.so.0.5.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_gl-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_gl-3.0.so.0.5.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_html-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_html-3.0.so.0.5.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_propgrid-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_propgrid-3.0.so.0.5.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_qa-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_qa-3.0.so.0.5.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_ribbon-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_ribbon-3.0.so.0.5.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_richtext-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_richtext-3.0.so.0.5.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_stc-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_stc-3.0.so.0.5.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_xrc-3.0.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_xrc-3.0.so.0.5.0 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1.0.0 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.4.0 /usr/lib/x86_64-linux-gnu/libx264.so.163 /usr/lib/x86_64-linux-gnu/libx265.so.199 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXcursor.so.1 /usr/lib/x86_64-linux-gnu/libXcursor.so.1.0.2 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libXi.so.6 /usr/lib/x86_64-linux-gnu/libXi.so.6.1.0 /usr/lib/x86_64-linux-gnu/libXinerama.so.1 /usr/lib/x86_64-linux-gnu/libXinerama.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrandr.so.2 /usr/lib/x86_64-linux-gnu/libXrandr.so.2.2.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxvidcore.so.4 /usr/lib/x86_64-linux-gnu/libxvidcore.so.4.3 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libzmq.so.5 /usr/lib/x86_64-linux-gnu/libzmq.so.5.2.4 /usr/lib/x86_64-linux-gnu/libzvbi-chains.so.0 /usr/lib/x86_64-linux-gnu/libzvbi-chains.so.0.0.0 /usr/lib/x86_64-linux-gnu/libzvbi.so.0 /usr/lib/x86_64-linux-gnu/libzvbi.so.0.13.2 /usr/lib/x86_64-linux-gnu/mfx /usr/lib/x86_64-linux-gnu/suil-0 /usr/lib/x86_64-linux-gnu/vdpau /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/lib/x86_64-linux-gnu/gio/modules/giomodule.cache /usr/lib/x86_64-linux-gnu/gio/modules/libdconfsettings.so /exports/usr/lib/x86_64-linux-gnu/gio/modules/ \
  ; mv /usr/libexec/dconf-service /exports/usr/libexec/ \
  ; mv /usr/local/share/fonts /exports/usr/local/share/ \
  ; mv /usr/sbin/update-icon-caches /exports/usr/sbin/ \
  ; mv /usr/share/alsa /usr/share/audacity /usr/share/libthai /usr/share/mfx /usr/share/themes /exports/usr/share/ \
  ; mv /usr/share/applications/audacity.desktop /exports/usr/share/applications/ \
  ; mv /usr/share/apport/package-hooks/source_audacity.py /usr/share/apport/package-hooks/source_fontconfig.py /exports/usr/share/apport/package-hooks/ \
  ; mv /usr/share/dbus-1/services/ca.desrt.dconf.service /exports/usr/share/dbus-1/services/ \
  ; mv /usr/share/doc-base/ocl-icd-libopencl1 /exports/usr/share/doc-base/ \
  ; mv /usr/share/glib-2.0/schemas/gschemas.compiled /usr/share/glib-2.0/schemas/org.gtk.Settings.ColorChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.Debug.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.EmojiChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.FileChooser.gschema.xml /exports/usr/share/glib-2.0/schemas/ \
  ; mv /usr/share/man/man1/audacity.1.gz /usr/share/man/man1/dconf-service.1.gz /usr/share/man/man1/gtk-update-icon-cache.1.gz /exports/usr/share/man/man1/ \
  ; mv /usr/share/man/man8/update-icon-caches.8.gz /exports/usr/share/man/man8/ \
  ; mv /usr/share/pixmaps/audacity16.xpm /usr/share/pixmaps/audacity32.xpm /usr/share/pixmaps/gnome-mime-application-x-audacity-project.xpm /exports/usr/share/pixmaps/

# ALACRITTY
FROM base AS alacritty
COPY --from=clone /exports/ /
COPY --from=rust /exports/ /
ENV \
  PATH=/root/.cargo/bin:$PATH
RUN set -e \
  ; packages="cmake gcc pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev python3" \
  ; apt-get -q update \
  ; apt-get install -y --no-install-recommends --auto-remove $packages \
  ; clone --https --tag='v0.13.2' https://github.com/alacritty/alacritty \
  ; cd /root/src/github.com/alacritty/alacritty \
  ; cargo build --release --no-default-features --features=x11 \
  ; mv target/release/alacritty /usr/local/bin/alacritty \
  ; rm -r /root/src/ \
  ; apt-get remove --purge -y $packages \
  ; apt-get -q clean
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/local/bin/ \
  ; mv /usr/bin/x86_64-linux-gnu-addr2line /usr/bin/x86_64-linux-gnu-ar /usr/bin/x86_64-linux-gnu-as /usr/bin/x86_64-linux-gnu-c++filt /usr/bin/x86_64-linux-gnu-cpp /usr/bin/x86_64-linux-gnu-cpp-11 /usr/bin/x86_64-linux-gnu-dwp /usr/bin/x86_64-linux-gnu-elfedit /usr/bin/x86_64-linux-gnu-gcc-11 /usr/bin/x86_64-linux-gnu-gcc-ar-11 /usr/bin/x86_64-linux-gnu-gcc-nm-11 /usr/bin/x86_64-linux-gnu-gcc-ranlib-11 /usr/bin/x86_64-linux-gnu-gcov-11 /usr/bin/x86_64-linux-gnu-gcov-dump-11 /usr/bin/x86_64-linux-gnu-gcov-tool-11 /usr/bin/x86_64-linux-gnu-gold /usr/bin/x86_64-linux-gnu-gprof /usr/bin/x86_64-linux-gnu-ld /usr/bin/x86_64-linux-gnu-ld.bfd /usr/bin/x86_64-linux-gnu-ld.gold /usr/bin/x86_64-linux-gnu-lto-dump-11 /usr/bin/x86_64-linux-gnu-nm /usr/bin/x86_64-linux-gnu-objcopy /usr/bin/x86_64-linux-gnu-objdump /usr/bin/x86_64-linux-gnu-ranlib /usr/bin/x86_64-linux-gnu-readelf /usr/bin/x86_64-linux-gnu-size /usr/bin/x86_64-linux-gnu-strings /usr/bin/x86_64-linux-gnu-strip /exports/usr/bin/ \
  ; mv /usr/local/bin/alacritty /exports/usr/local/bin/

# URLVIEW
FROM base AS urlview
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx urlview='0.9-22'
RUN set -e \
  ; mkdir -p /exports/etc/ /exports/usr/bin/ \
  ; mv /etc/urlview /exports/etc/ \
  ; mv /usr/bin/urlview /exports/usr/bin/

# XSV
FROM base AS xsv
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/xsv.tgz https://github.com/BurntSushi/xsv/releases/download/0.13.0/xsv-0.13.0-i686-unknown-linux-musl.tar.gz \
  ; tar xzvf /tmp/xsv.tgz -C /tmp \
  ; mv /tmp/xsv /usr/local/bin \
  ; rm -r /tmp/xsv*
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/xsv /exports/usr/local/bin/

# XINPUT
FROM base AS xinput
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx xinput='1.6.3-1build2'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ \
  ; mv /usr/bin/xinput /exports/usr/bin/

# TREE
FROM base AS tree
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx tree='2.0.2-1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man1/ \
  ; mv /usr/bin/tree /exports/usr/bin/ \
  ; mv /usr/share/doc/tree /exports/usr/share/doc/ \
  ; mv /usr/share/man/man1/tree.1.gz /exports/usr/share/man/man1/

# SUDO
FROM base AS sudo
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx sudo='1.9.9-1ubuntu2.4'
RUN set -e \
  ; mkdir -p /exports/etc/pam.d/ /exports/etc/ /exports/etc/systemd/system/ /exports/usr/bin/ /exports/usr/include/ /exports/usr/lib/tmpfiles.d/ /exports/usr/libexec/ /exports/usr/sbin/ /exports/usr/share/apport/package-hooks/ /exports/usr/share/man/man1/ /exports/usr/share/man/man5/ /exports/usr/share/man/man8/ \
  ; mv /etc/pam.d/sudo /etc/pam.d/sudo-i /exports/etc/pam.d/ \
  ; mv /etc/sudo_logsrvd.conf /etc/sudo.conf /etc/sudoers /etc/sudoers.d /exports/etc/ \
  ; mv /etc/systemd/system/sudo.service /exports/etc/systemd/system/ \
  ; mv /usr/bin/cvtsudoers /usr/bin/sudo /usr/bin/sudoedit /usr/bin/sudoreplay /exports/usr/bin/ \
  ; mv /usr/include/sudo_plugin.h /exports/usr/include/ \
  ; mv /usr/lib/tmpfiles.d/sudo.conf /exports/usr/lib/tmpfiles.d/ \
  ; mv /usr/libexec/sudo /exports/usr/libexec/ \
  ; mv /usr/sbin/sudo_logsrvd /usr/sbin/sudo_sendlog /usr/sbin/visudo /exports/usr/sbin/ \
  ; mv /usr/share/apport/package-hooks/source_sudo.py /exports/usr/share/apport/package-hooks/ \
  ; mv /usr/share/man/man1/cvtsudoers.1.gz /exports/usr/share/man/man1/ \
  ; mv /usr/share/man/man5/sudo_logsrv.proto.5.gz /usr/share/man/man5/sudo_logsrvd.conf.5.gz /usr/share/man/man5/sudo.conf.5.gz /usr/share/man/man5/sudoers_timestamp.5.gz /usr/share/man/man5/sudoers.5.gz /exports/usr/share/man/man5/ \
  ; mv /usr/share/man/man8/sudo_logsrvd.8.gz /usr/share/man/man8/sudo_plugin.8.gz /usr/share/man/man8/sudo_root.8.gz /usr/share/man/man8/sudo_sendlog.8.gz /usr/share/man/man8/sudo.8.gz /usr/share/man/man8/sudoedit.8.gz /usr/share/man/man8/sudoreplay.8.gz /usr/share/man/man8/visudo.8.gz /exports/usr/share/man/man8/

# SHOEBOX
FROM base AS shoebox
COPY --from=node /exports/ /
RUN set -e \
  ; npm install -g '@stayradiated/shoebox@2.8.0'
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/@stayradiated/ \
  ; mv /usr/local/bin/shoebox /exports/usr/local/bin/ \
  ; mv /usr/local/lib/node_modules/@stayradiated/shoebox /exports/usr/local/lib/node_modules/@stayradiated/

# SD
FROM base AS sd
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/sd.tar.gz 'https://github.com/chmln/sd/releases/download/v1.0.0/sd-v1.0.0-x86_64-unknown-linux-gnu.tar.gz' \
  ; mkdir -p /tmp/sd \
  ; tar -xzvf /tmp/sd.tar.gz -C /tmp \
  ; mv /tmp/sd-*/sd /usr/local/bin/sd \
  ; chmod +x /usr/local/bin/sd \
  ; rm -rf /tmp/sd-* /tmp/sd.tar.gz
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/sd /exports/usr/local/bin/

# RSYNC
FROM base AS rsync
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx rsync='3.2.7-0ubuntu0.22.04.2'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ \
  ; mv /usr/bin/rsync /exports/usr/bin/

# RIPGREP
FROM base AS ripgrep
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/ripgrep.tgz 'https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-x86_64-unknown-linux-musl.tar.gz' \
  ; tar -xzvf /tmp/ripgrep.tgz \
  ; rm /tmp/ripgrep.tgz \
  ; mv ripgrep-14.1.1-x86_64-unknown-linux-musl ripgrep \
  ; mv ripgrep/rg /usr/local/bin/rg \
  ; mkdir -p /usr/local/share/man/man1 \
  ; mv ripgrep/doc/rg.1 /usr/local/share/man/man1/rg.1 \
  ; rm -r ripgrep
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/share/man/man1/ \
  ; mv /usr/local/bin/rg /exports/usr/local/bin/ \
  ; mv /usr/local/share/man/man1/rg.1 /exports/usr/local/share/man/man1/

# PRETTYPING
FROM base AS prettyping
COPY --from=wget /exports/ /
COPY --from=ping /exports/ /
RUN set -e \
  ; wget -O /usr/local/bin/prettyping 'https://raw.githubusercontent.com/denilsonsa/prettyping/v1.0.1/prettyping' \
  ; chmod +x /usr/local/bin/prettyping
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/local/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man8/ \
  ; mv /usr/bin/ping /usr/bin/ping4 /usr/bin/ping6 /exports/usr/bin/ \
  ; mv /usr/local/bin/prettyping /exports/usr/local/bin/ \
  ; mv /usr/share/doc/iputils-ping /exports/usr/share/doc/ \
  ; mv /usr/share/man/man8/ping.8.gz /usr/share/man/man8/ping4.8.gz /usr/share/man/man8/ping6.8.gz /exports/usr/share/man/man8/

# PGCLI
FROM base AS pgcli
COPY --from=apteryx /exports/ /
COPY --from=uv /exports/ /
ENV \
  UV_LINK_MODE=copy \
  UV_COMPILE_BYTECODE=1 \
  UV_PYTHON_DOWNLOADS=manual \
  UV_TOOL_DIR=/usr/local/uv/tools \
  UV_TOOL_BIN_DIR=/usr/local/uv/bin \
  UV_PYTHON_INSTALL_DIR=/usr/local/uv/python
RUN set -e \
  ; apteryx libpq-dev \
  ; uv tool install pgcli=='4.1.0' \
  ; ln -s /usr/local/uv/bin/pgcli /usr/local/bin/pgcli
RUN set -e \
  ; mkdir -p /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/bin/ /exports/usr/local/ \
  ; mv /usr/lib/x86_64-linux-gnu/libpq.* /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/local/bin/apteryx /usr/local/bin/pgcli /usr/local/bin/uv /usr/local/bin/uvx /exports/usr/local/bin/ \
  ; mv /usr/local/uv /exports/usr/local/

# NCU
FROM base AS ncu
COPY --from=node /exports/ /
RUN set -e \
  ; npm install -g 'npm-check-updates@17.1.3'
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/ \
  ; mv /usr/local/bin/ncu /exports/usr/local/bin/ \
  ; mv /usr/local/lib/node_modules/npm-check-updates /exports/usr/local/lib/node_modules/

# MOREUTILS
FROM base AS moreutils
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx moreutils='0.66-1'
RUN set -e \
  ; mkdir -p /exports/usr/share/ /exports/usr/share/perl5/ /exports/usr/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man1/ \
  ; mv /usr/share/perl /exports/usr/share/ \
  ; mv /usr/share/perl5/IPC /exports/usr/share/perl5/ \
  ; mv /usr/bin/chronic /usr/bin/combine /usr/bin/errno /usr/bin/ifdata /usr/bin/ifne /usr/bin/isutf8 /usr/bin/lckdo /usr/bin/mispipe /usr/bin/parallel /usr/bin/pee /usr/bin/sponge /usr/bin/ts /usr/bin/vidir /usr/bin/vipe /usr/bin/zrun /exports/usr/bin/ \
  ; mv /usr/share/doc/moreutils /exports/usr/share/doc/ \
  ; mv /usr/share/man/man1/chronic.1.gz /usr/share/man/man1/combine.1.gz /usr/share/man/man1/errno.1.gz /usr/share/man/man1/ifdata.1.gz /usr/share/man/man1/ifne.1.gz /usr/share/man/man1/isutf8.1.gz /usr/share/man/man1/lckdo.1.gz /usr/share/man/man1/mispipe.1.gz /usr/share/man/man1/parallel.1.gz /usr/share/man/man1/pee.1.gz /usr/share/man/man1/sponge.1.gz /usr/share/man/man1/ts.1.gz /usr/share/man/man1/vidir.1.gz /usr/share/man/man1/vipe.1.gz /usr/share/man/man1/zrun.1.gz /exports/usr/share/man/man1/

# MEDIAINFO
FROM base AS mediainfo
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx mediainfo='22.03-1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/man/man1/ \
  ; mv /usr/bin/mediainfo /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.* /usr/lib/x86_64-linux-gnu/libmediainfo.so.* /usr/lib/x86_64-linux-gnu/libmms.so.* /usr/lib/x86_64-linux-gnu/libtinyxml2.so.* /usr/lib/x86_64-linux-gnu/libzen.so.* /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/share/man/man1/mediainfo.1.gz /exports/usr/share/man/man1/

# MBSYNC
FROM base AS mbsync
COPY --from=wget /exports/ /
COPY --from=apteryx /exports/ /
COPY --from=build-essential /exports/ /
RUN set -e \
  ; apteryx libssl-dev \
  ; wget -O /tmp/isync.tgz "https://sourceforge.net/projects/isync/files/isync/1.4.4/isync-1.4.4.tar.gz/download" \
  ; tar xzvf /tmp/isync.tgz -C /tmp \
  ; rm /tmp/isync.tgz \
  ; cd "/tmp/isync-1.4.4" \
  ; ls -alh \
  ; ./configure \
  ; make \
  ; mv src/mbsync /usr/local/bin/mbsync \
  ; rm -r "/tmp/isync-1.4.4"
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/mbsync /exports/usr/local/bin/

# MAN
FROM base AS man
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx man-db='2.10.2-1'
RUN set -e \
  ; mkdir -p /exports/etc/cron.daily/ /exports/etc/cron.weekly/ /exports/etc/ /exports/etc/systemd/system/timers.target.wants/ /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/mime/packages/ /exports/usr/lib/systemd/system/ /exports/usr/lib/tmpfiles.d/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/libexec/ /exports/usr/sbin/ /exports/usr/share/bash-completion/completions/ /exports/usr/share/bug/ /exports/usr/share/doc-base/ /exports/usr/share/doc/ /exports/usr/share/ /exports/usr/share/man/man1/ /exports/usr/share/man/man5/ /exports/usr/share/man/man8/ \
  ; mv /etc/cron.daily/man-db /exports/etc/cron.daily/ \
  ; mv /etc/cron.weekly/man-db /exports/etc/cron.weekly/ \
  ; mv /etc/groff /etc/manpath.config /exports/etc/ \
  ; mv /etc/systemd/system/timers.target.wants/man-db.timer /exports/etc/systemd/system/timers.target.wants/ \
  ; mv /usr/bin/apropos /usr/bin/catman /usr/bin/col /usr/bin/colcrt /usr/bin/colrm /usr/bin/column /usr/bin/eqn /usr/bin/geqn /usr/bin/gpic /usr/bin/groff /usr/bin/grog /usr/bin/grops /usr/bin/grotty /usr/bin/gtbl /usr/bin/hd /usr/bin/hexdump /usr/bin/lexgrog /usr/bin/look /usr/bin/man /usr/bin/man-recode /usr/bin/mandb /usr/bin/manpath /usr/bin/neqn /usr/bin/nroff /usr/bin/pic /usr/bin/preconv /usr/bin/soelim /usr/bin/tbl /usr/bin/troff /usr/bin/ul /usr/bin/whatis /usr/bin/write /usr/bin/write.ul /exports/usr/bin/ \
  ; mv /usr/lib/groff /usr/lib/man-db /exports/usr/lib/ \
  ; mv /usr/lib/mime/packages/groff-base /usr/lib/mime/packages/man-db /exports/usr/lib/mime/packages/ \
  ; mv /usr/lib/systemd/system/man-db.service /usr/lib/systemd/system/man-db.timer /exports/usr/lib/systemd/system/ \
  ; mv /usr/lib/tmpfiles.d/man-db.conf /exports/usr/lib/tmpfiles.d/ \
  ; mv /usr/lib/x86_64-linux-gnu/libgdbm.so.6 /usr/lib/x86_64-linux-gnu/libgdbm.so.6.0.0 /usr/lib/x86_64-linux-gnu/libpipeline.so.1 /usr/lib/x86_64-linux-gnu/libpipeline.so.1.5.5 /usr/lib/x86_64-linux-gnu/libuchardet.so.0 /usr/lib/x86_64-linux-gnu/libuchardet.so.0.0.7 /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/libexec/man-db /exports/usr/libexec/ \
  ; mv /usr/sbin/accessdb /exports/usr/sbin/ \
  ; mv /usr/share/bash-completion/completions/col /usr/share/bash-completion/completions/colcrt /usr/share/bash-completion/completions/colrm /usr/share/bash-completion/completions/column /usr/share/bash-completion/completions/hexdump /usr/share/bash-completion/completions/look /usr/share/bash-completion/completions/ul /exports/usr/share/bash-completion/completions/ \
  ; mv /usr/share/bug/man-db /exports/usr/share/bug/ \
  ; mv /usr/share/doc-base/man-db.man-db /exports/usr/share/doc-base/ \
  ; mv /usr/share/doc/groff-base /usr/share/doc/man-db /exports/usr/share/doc/ \
  ; mv /usr/share/groff /usr/share/man-db /exports/usr/share/ \
  ; mv /usr/share/man/man1/apropos.1.gz /usr/share/man/man1/col.1.gz /usr/share/man/man1/colcrt.1.gz /usr/share/man/man1/colrm.1.gz /usr/share/man/man1/column.1.gz /usr/share/man/man1/eqn.1.gz /usr/share/man/man1/geqn.1.gz /usr/share/man/man1/gpic.1.gz /usr/share/man/man1/groff.1.gz /usr/share/man/man1/grog.1.gz /usr/share/man/man1/grops.1.gz /usr/share/man/man1/grotty.1.gz /usr/share/man/man1/gtbl.1.gz /usr/share/man/man1/hd.1.gz /usr/share/man/man1/hexdump.1.gz /usr/share/man/man1/lexgrog.1.gz /usr/share/man/man1/look.1.gz /usr/share/man/man1/man-recode.1.gz /usr/share/man/man1/man.1.gz /usr/share/man/man1/manconv.1.gz /usr/share/man/man1/manpath.1.gz /usr/share/man/man1/neqn.1.gz /usr/share/man/man1/nroff.1.gz /usr/share/man/man1/pic.1.gz /usr/share/man/man1/preconv.1.gz /usr/share/man/man1/soelim.1.gz /usr/share/man/man1/tbl.1.gz /usr/share/man/man1/troff.1.gz /usr/share/man/man1/ul.1.gz /usr/share/man/man1/whatis.1.gz /usr/share/man/man1/write.1.gz /usr/share/man/man1/write.ul.1.gz /usr/share/man/man1/zsoelim.1.gz /exports/usr/share/man/man1/ \
  ; mv /usr/share/man/man5/manpath.5.gz /exports/usr/share/man/man5/ \
  ; mv /usr/share/man/man8/accessdb.8.gz /usr/share/man/man8/catman.8.gz /usr/share/man/man8/mandb.8.gz /exports/usr/share/man/man8/

# LIBGLIB
FROM base AS libglib
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx libglib2.0-bin='2.72.4-0ubuntu2.3'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/bin/gapplication /usr/bin/gdbus /usr/bin/gio /usr/bin/gio-querymodules /usr/bin/glib-compile-schemas /usr/bin/gresource /usr/bin/gsettings /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu/libelf-*.so /usr/lib/x86_64-linux-gnu/libelf.so.1 /exports/usr/lib/x86_64-linux-gnu/

# JQ
FROM base AS jq
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /usr/local/bin/jq 'https://github.com/stedolan/jq/releases/download/jq-1.7.1/jq-linux64' \
  ; chmod +x /usr/local/bin/jq
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/jq /exports/usr/local/bin/

# HTTPIE
FROM base AS httpie
COPY --from=uv /exports/ /
ENV \
  UV_LINK_MODE=copy \
  UV_COMPILE_BYTECODE=1 \
  UV_PYTHON_DOWNLOADS=manual \
  UV_TOOL_DIR=/usr/local/uv/tools \
  UV_TOOL_BIN_DIR=/usr/local/uv/bin \
  UV_PYTHON_INSTALL_DIR=/usr/local/uv/python
RUN set -e \
  ; uv tool install httpie=='3.2.3' \
  ; ln -s /usr/local/uv/bin/http /usr/local/bin/http
RUN set -e \
  ; mkdir -p /exports/usr/local/ /exports/usr/local/bin/ \
  ; mv /usr/local/uv /exports/usr/local/ \
  ; mv /usr/local/bin/http /exports/usr/local/bin/

# HTOP
FROM base AS htop
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx htop='3.0.5-7build2'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/doc/ /exports/usr/share/man/man1/ \
  ; mv /usr/bin/htop /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu/libnl-3.so.200 /usr/lib/x86_64-linux-gnu/libnl-3.so.200.26.0 /usr/lib/x86_64-linux-gnu/libnl-genl-3.so.200 /usr/lib/x86_64-linux-gnu/libnl-genl-3.so.200.26.0 /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/share/doc/htop /exports/usr/share/doc/ \
  ; mv /usr/share/man/man1/htop.1.gz /exports/usr/share/man/man1/

# GH
FROM base AS gh
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/gh.tgz 'https://github.com/cli/cli/releases/download/v2.58.0/gh_2.58.0_linux_amd64.tar.gz' \
  ; tar xzvf /tmp/gh.tgz \
  ; rm /tmp/gh.tgz \
  ; mv 'gh_2.58.0_linux_amd64/bin/gh' /usr/local/bin/gh \
  ; rm -r 'gh_2.58.0_linux_amd64'
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/gh /exports/usr/local/bin/

# FILE
FROM base AS file
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx file='1:5.41-3ubuntu0.1'
RUN set -e \
  ; mkdir -p /exports/etc/ /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/misc/ \
  ; mv /etc/magic /etc/magic.mime /exports/etc/ \
  ; mv /usr/bin/file /exports/usr/bin/ \
  ; mv /usr/lib/file /exports/usr/lib/ \
  ; mv /usr/lib/x86_64-linux-gnu/libmagic.so.* /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/share/misc/magic /usr/share/misc/magic.mgc /exports/usr/share/misc/

# FD
FROM base AS fd
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/fd.tgz 'https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-x86_64-unknown-linux-musl.tar.gz' \
  ; tar -xzvf /tmp/fd.tgz \
  ; rm /tmp/fd.tgz \
  ; mv 'fd-v10.2.0-x86_64-unknown-linux-musl' fd \
  ; mv fd/fd /usr/local/bin/fd \
  ; mkdir -p /usr/local/share/man/man1 \
  ; mv fd/fd.1 /usr/local/share/man/man1/fd.1 \
  ; rm -r fd
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/share/man/man1/ \
  ; mv /usr/local/bin/fd /exports/usr/local/bin/ \
  ; mv /usr/local/share/man/man1/fd.1 /exports/usr/local/share/man/man1/

# DOCKER-COMPOSE
FROM base AS docker-compose
COPY --from=wget /exports/ /
RUN set -e \
  ; mkdir -p /usr/local/lib/docker/cli-plugins \
  ; wget -O /usr/local/lib/docker/cli-plugins/docker-compose 'https://github.com/docker/compose/releases/download/v2.29.7/docker-compose-linux-x86_64' \
  ; chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
RUN set -e \
  ; mkdir -p /exports/usr/local/lib/docker/cli-plugins/ \
  ; mv /usr/local/lib/docker/cli-plugins/docker-compose /exports/usr/local/lib/docker/cli-plugins/

# DOCKER
FROM base AS docker
COPY --from=apteryx /exports/ /
COPY --from=wget /exports/ /
RUN set -e \
  ; install -m 0755 -d /etc/apt/keyrings \
  ; curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
  ; chmod a+r /etc/apt/keyrings/docker.gpg \
  ; echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
  ; apt-get update \
  ; apteryx docker-ce-cli='5:23.0.6*'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/share/zsh/vendor-completions/ \
  ; mv /usr/bin/docker /exports/usr/bin/ \
  ; mv /usr/share/zsh/vendor-completions/_docker /exports/usr/share/zsh/vendor-completions/

# CONTAINER-DIFF
FROM base AS container-diff
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O container-diff 'https://storage.googleapis.com/container-diff/v0.17.0/container-diff-linux-amd64' \
  ; chmod +x container-diff \
  ; mv container-diff /usr/local/bin/container-diff
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/container-diff /exports/usr/local/bin/

# BSDMAINUTILS
FROM base AS bsdmainutils
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx bsdmainutils='12.1.7+nmu3ubuntu2'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ \
  ; mv /usr/bin/column /exports/usr/bin/

# BAT
FROM base AS bat
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O bat.tgz 'https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-x86_64-unknown-linux-gnu.tar.gz' \
  ; tar -xzvf bat.tgz \
  ; rm bat.tgz \
  ; mv 'bat-v0.24.0-x86_64-unknown-linux-gnu/bat' /usr/local/bin/bat \
  ; rm -rf 'bat-v0.24.0-x86_64-unknown-linux-gnu'
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/bat /exports/usr/local/bin/

# AUTOTAG
FROM base AS autotag
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/autotag.tgz "https://github.com/pantheon-systems/autotag/releases/download/v1.3.30/autotag_linux_amd64.tar.gz" \
  ; tar xzvf /tmp/autotag.tgz autotag \
  ; mv autotag /usr/local/bin/autotag \
  ; rm /tmp/autotag.tgz
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/autotag /exports/usr/local/bin/

# APULSE
FROM base AS apulse
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx apulse='0.1.13-2'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/ /exports/usr/share/doc/ /exports/usr/share/man/man1/ \
  ; mv /usr/bin/apulse /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu/apulse /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libasound.so.2.0.0 /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/share/alsa /exports/usr/share/ \
  ; mv /usr/share/doc/apulse /usr/share/doc/libasound2-data /usr/share/doc/libasound2 /exports/usr/share/doc/ \
  ; mv /usr/share/man/man1/apulse.1.gz /exports/usr/share/man/man1/

# ALSA-UTILS
FROM base AS alsa-utils
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx alsa-utils='1.2.6-1ubuntu1'
RUN set -e \
  ; mkdir -p /exports/etc/ /exports/etc/init.d/ /exports/etc/rc0.d/ /exports/etc/rc1.d/ /exports/etc/rc6.d/ /exports/etc/rcS.d/ /exports/usr/bin/ /exports/usr/lib/modprobe.d/ /exports/usr/lib/systemd/system/ /exports/usr/lib/udev/rules.d/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/sbin/ /exports/usr/share/ /exports/usr/share/bash-completion/completions/ /exports/usr/share/doc/ /exports/usr/share/doc/libkmod2/ /exports/usr/share/man/fr/man5/ /exports/usr/share/man/man1/ /exports/usr/share/man/man5/ /exports/usr/share/man/man7/ /exports/usr/share/man/man8/ /exports/var/cache/ldconfig/ /exports/var/lib/ \
  ; mv /etc/depmod.d /etc/modprobe.d /etc/modules /exports/etc/ \
  ; mv /etc/init.d/alsa-utils /etc/init.d/kmod /exports/etc/init.d/ \
  ; mv /etc/rc0.d/K01alsa-utils /exports/etc/rc0.d/ \
  ; mv /etc/rc1.d/K01alsa-utils /exports/etc/rc1.d/ \
  ; mv /etc/rc6.d/K01alsa-utils /exports/etc/rc6.d/ \
  ; mv /etc/rcS.d/S01alsa-utils /etc/rcS.d/S01kmod /exports/etc/rcS.d/ \
  ; mv /usr/bin/aconnect /usr/bin/alsabat /usr/bin/alsaloop /usr/bin/alsamixer /usr/bin/alsatplg /usr/bin/alsaucm /usr/bin/amidi /usr/bin/amixer /usr/bin/aplay /usr/bin/aplaymidi /usr/bin/arecord /usr/bin/arecordmidi /usr/bin/aseqdump /usr/bin/aseqnet /usr/bin/axfer /usr/bin/iecset /usr/bin/kmod /usr/bin/lsmod /usr/bin/speaker-test /exports/usr/bin/ \
  ; mv /usr/lib/modprobe.d/aliases.conf /exports/usr/lib/modprobe.d/ \
  ; mv /usr/lib/systemd/system/alsa-restore.service /usr/lib/systemd/system/alsa-state.service /usr/lib/systemd/system/alsa-utils.service /usr/lib/systemd/system/sound.target.wants /exports/usr/lib/systemd/system/ \
  ; mv /usr/lib/udev/rules.d/90-alsa-restore.rules /exports/usr/lib/udev/rules.d/ \
  ; mv /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libasound.so.2.0.0 /usr/lib/x86_64-linux-gnu/libatopology.so.2 /usr/lib/x86_64-linux-gnu/libatopology.so.2.0.0 /usr/lib/x86_64-linux-gnu/libfftw3f_omp.so.3 /usr/lib/x86_64-linux-gnu/libfftw3f_omp.so.3.5.8 /usr/lib/x86_64-linux-gnu/libfftw3f_threads.so.3 /usr/lib/x86_64-linux-gnu/libfftw3f_threads.so.3.5.8 /usr/lib/x86_64-linux-gnu/libfftw3f.so.3 /usr/lib/x86_64-linux-gnu/libfftw3f.so.3.5.8 /usr/lib/x86_64-linux-gnu/libgomp.so.1 /usr/lib/x86_64-linux-gnu/libgomp.so.1.0.0 /usr/lib/x86_64-linux-gnu/libsamplerate.so.0 /usr/lib/x86_64-linux-gnu/libsamplerate.so.0.2.2 /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/sbin/alsa-info /usr/sbin/alsabat-test /usr/sbin/alsactl /usr/sbin/depmod /usr/sbin/insmod /usr/sbin/lsmod /usr/sbin/modinfo /usr/sbin/modprobe /usr/sbin/rmmod /exports/usr/sbin/ \
  ; mv /usr/share/alsa /usr/share/initramfs-tools /usr/share/sounds /exports/usr/share/ \
  ; mv /usr/share/bash-completion/completions/kmod /exports/usr/share/bash-completion/completions/ \
  ; mv /usr/share/doc/alsa-utils /usr/share/doc/kmod /usr/share/doc/libasound2-data /usr/share/doc/libasound2 /usr/share/doc/libatopology2 /usr/share/doc/libfftw3-single3 /usr/share/doc/libgomp1 /usr/share/doc/libsamplerate0 /exports/usr/share/doc/ \
  ; mv /usr/share/doc/libkmod2/README /usr/share/doc/libkmod2/TODO /exports/usr/share/doc/libkmod2/ \
  ; mv /usr/share/man/fr/man5/modules.5.gz /exports/usr/share/man/fr/man5/ \
  ; mv /usr/share/man/man1/aconnect.1.gz /usr/share/man/man1/alsabat.1.gz /usr/share/man/man1/alsactl.1.gz /usr/share/man/man1/alsaloop.1.gz /usr/share/man/man1/alsamixer.1.gz /usr/share/man/man1/alsatplg.1.gz /usr/share/man/man1/alsaucm.1.gz /usr/share/man/man1/amidi.1.gz /usr/share/man/man1/amixer.1.gz /usr/share/man/man1/aplay.1.gz /usr/share/man/man1/aplaymidi.1.gz /usr/share/man/man1/arecord.1.gz /usr/share/man/man1/arecordmidi.1.gz /usr/share/man/man1/aseqdump.1.gz /usr/share/man/man1/aseqnet.1.gz /usr/share/man/man1/axfer-list.1.gz /usr/share/man/man1/axfer-transfer.1.gz /usr/share/man/man1/axfer.1.gz /usr/share/man/man1/iecset.1.gz /usr/share/man/man1/speaker-test.1.gz /exports/usr/share/man/man1/ \
  ; mv /usr/share/man/man5/depmod.d.5.gz /usr/share/man/man5/modprobe.d.5.gz /usr/share/man/man5/modules.5.gz /usr/share/man/man5/modules.dep.5.gz /usr/share/man/man5/modules.dep.bin.5.gz /exports/usr/share/man/man5/ \
  ; mv /usr/share/man/man7/alsactl_init.7.gz /exports/usr/share/man/man7/ \
  ; mv /usr/share/man/man8/alsa-info.8.gz /usr/share/man/man8/depmod.8.gz /usr/share/man/man8/insmod.8.gz /usr/share/man/man8/kmod.8.gz /usr/share/man/man8/lsmod.8.gz /usr/share/man/man8/modinfo.8.gz /usr/share/man/man8/modprobe.8.gz /usr/share/man/man8/rmmod.8.gz /exports/usr/share/man/man8/ \
  ; mv /var/cache/ldconfig/aux-cache /exports/var/cache/ldconfig/ \
  ; mv /var/lib/alsa /exports/var/lib/

# ACPI
FROM base AS acpi
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx acpi='1.7-1.1ubuntu1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ \
  ; mv /usr/bin/acpi /exports/usr/bin/

# X11-UTILS
FROM base AS x11-utils
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx x11-utils='7.7+5build2' x11-xkb-utils x11-xserver-utils xkb-data
RUN set -e \
  ; mkdir -p /exports/etc/ /exports/etc/init.d/ /exports/etc/rcS.d/ /exports/usr/ \
  ; mv /etc/X11 /etc/sensors.d /etc/sensors3.conf /exports/etc/ \
  ; mv /etc/init.d/x11-common /exports/etc/init.d/ \
  ; mv /etc/rcS.d/S01x11-common /exports/etc/rcS.d/ \
  ; mv /usr/bin /usr/lib /usr/share /exports/usr/

# MESA
FROM base AS mesa
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx mesa-utils='8.4.0-1ubuntu1' mesa-utils-extra
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/ \
  ; mv /usr/bin/eglinfo /usr/bin/eglinfo.x86_64-linux-gnu /usr/bin/es2_info /usr/bin/es2_info.x86_64-linux-gnu /usr/bin/es2gears_wayland /usr/bin/es2gears_wayland.x86_64-linux-gnu /usr/bin/es2gears_x11 /usr/bin/es2gears_x11.x86_64-linux-gnu /usr/bin/es2tri /usr/bin/es2tri.x86_64-linux-gnu /usr/bin/glxdemo /usr/bin/glxdemo.x86_64-linux-gnu /usr/bin/glxgears /usr/bin/glxgears.x86_64-linux-gnu /usr/bin/glxheads /usr/bin/glxheads.x86_64-linux-gnu /usr/bin/glxinfo /usr/bin/glxinfo.x86_64-linux-gnu /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu/dri /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_intel.so.1 /usr/lib/x86_64-linux-gnu/libdrm_intel.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2.0.0 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1.0.1 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libEGL_mesa.so.0 /usr/lib/x86_64-linux-gnu/libEGL_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libEGL.so.1 /usr/lib/x86_64-linux-gnu/libEGL.so.1.1.0 /usr/lib/x86_64-linux-gnu/libgbm.so.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libGL.so.1 /usr/lib/x86_64-linux-gnu/libGL.so.1.7.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLESv2.so.2 /usr/lib/x86_64-linux-gnu/libGLESv2.so.2.1.0 /usr/lib/x86_64-linux-gnu/libGLX_indirect.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0.0.0 /usr/lib/x86_64-linux-gnu/libLLVM-15.so /usr/lib/x86_64-linux-gnu/libLLVM-15.so.1 /usr/lib/x86_64-linux-gnu/libpciaccess.so.0 /usr/lib/x86_64-linux-gnu/libpciaccess.so.0.11.1 /usr/lib/x86_64-linux-gnu/libsensors.so.5 /usr/lib/x86_64-linux-gnu/libsensors.so.5.0.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.20.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.20.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0.20.0 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1.0.0 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1.0.0 /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/share/drirc.d /usr/share/glvnd /usr/share/libdrm /usr/share/mesa-demos /usr/share/X11 /exports/usr/share/

# LIBXV1
FROM base AS libxv1
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx libxv1='2:1.0.11-1build2'
RUN set -e \
  ; mkdir -p /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/ \
  ; mv /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXv.so.1 /usr/lib/x86_64-linux-gnu/libXv.so.1.0.0 /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/share/X11 /exports/usr/share/

# MY-DESKTOP
FROM shell-admin AS my-desktop
COPY --from=libxv1 /exports/ /
COPY --from=mesa /exports/ /
COPY --from=x11-utils /exports/ /
COPY --from=acpi /exports/ /
COPY --from=alsa-utils /exports/ /
COPY --from=apulse /exports/ /
COPY --from=autotag /exports/ /
COPY --from=bat /exports/ /
COPY --from=bsdmainutils /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=clone /exports/ /
COPY --from=container-diff /exports/ /
COPY --from=docker /exports/ /
COPY --from=docker-compose /exports/ /
COPY --from=fd /exports/ /
COPY --from=file /exports/ /
COPY --from=fzf /exports/ /
COPY --from=gh /exports/ /
COPY --from=go /exports/ /
COPY --from=htop /exports/ /
COPY --from=httpie /exports/ /
COPY --from=jq /exports/ /
COPY --from=libglib /exports/ /
COPY --from=make /exports/ /
COPY --from=man /exports/ /
COPY --from=mbsync /exports/ /
COPY --from=mediainfo /exports/ /
COPY --from=moreutils /exports/ /
COPY --from=ncu /exports/ /
COPY --from=node /exports/ /
COPY --from=pgcli /exports/ /
COPY --from=prettyping /exports/ /
COPY --from=ripgrep /exports/ /
COPY --from=rsync /exports/ /
COPY --from=sd /exports/ /
COPY --from=shoebox /exports/ /
COPY --from=sudo /exports/ /
COPY --from=tree /exports/ /
COPY --from=unzip /exports/ /
COPY --from=wget /exports/ /
COPY --from=xinput /exports/ /
COPY --from=xsv /exports/ /
COPY --from=urlview /exports/ /
COPY --from=alacritty /exports/ /
COPY --from=audacity /exports/ /
COPY --from=feh /exports/ /
COPY --from=flameshot /exports/ /
COPY --from=light /exports/ /
COPY --from=qpdfview /exports/ /
COPY --from=redshift /exports/ /
COPY --from=xclip /exports/ /
COPY --from=xdg-utils /exports/ /
COPY --from=xsecurelock /exports/ /
COPY --from=shell-browser --chown=admin /home/admin/exports/ /
COPY --from=shell-browser /exports/ /
COPY --from=shell-cron /exports/ /
COPY --from=shell-git --chown=admin /home/admin/exports/ /
COPY --from=shell-git /exports/ /
COPY --from=shell-npm --chown=admin /home/admin/exports/ /
COPY --from=shell-npm /exports/ /
COPY --from=shell-passwords --chown=admin /home/admin/exports/ /
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
COPY --from=pnpm /exports/ /
COPY --from=net-tools /exports/ /
COPY --from=greenclip /exports/ /
COPY --from=one-password /exports/ /
COPY --from=wifi /exports/ /
COPY --from=imgp /exports/ /
COPY --from=bandwhich /exports/ /
COPY --from=caddy /exports/ /
COPY --from=obsidian /exports/ /
COPY --from=llm /exports/ /
COPY --from=strip-tags /exports/ /
COPY --from=ttok /exports/ /
COPY --from=sqlite-utils /exports/ /
COPY --from=kolide /exports/ /
COPY --from=heroku /exports/ /
COPY --from=brave /exports/ /
COPY --from=fastgron /exports/ /
COPY --from=rofi /exports/ /
COPY --from=exa /exports/ /
COPY --from=zoxide /exports/ /
COPY --from=bun /exports/ /
COPY --from=rip /exports/ /
COPY --from=gosee /exports/ /
COPY --from=fonts /exports/ /
COPY --from=xcolor /exports/ /
COPY --from=sleek /exports/ /
COPY --from=oha /exports/ /
COPY --from=lazygit /exports/ /
COPY --from=gifski /exports/ /
COPY --from=ast-grep /exports/ /
COPY --from=hey /exports/ /
COPY --from=ffmpeg /exports/ /
COPY --from=yt-dlp /exports/ /
COPY --from=curlie /exports/ /
ENV \
  PATH=/usr/local/go/bin:${PATH} \
  GOPATH=/root \
  GO111MODULE=auto
ENV \
  PATH=${PATH}:/opt/google/chrome
ENV \
  PATH=${PATH}:/home/admin/.cache/npm/bin
ENV \
  PATH=/home/admin/.yarn/bin:${PATH}
ENV \
  PATH=${PATH}:/opt/brave.com/brave
RUN set -e \
  ; chmod 0600 /home/admin/.ssh/* \
  ; chmod +x /home/admin/.ssh/sockets
CMD /home/admin/.xinitrc
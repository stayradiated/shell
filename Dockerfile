

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

# GIT
FROM base AS git
COPY --from=apteryx /exports/ /
RUN set -e \
  ; add-apt-repository ppa:git-core/ppa \
  ; apteryx git='1:2.47.1-*'
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
  ; wget -O /tmp/go.tgz "https://dl.google.com/go/go1.23.4.linux-amd64.tar.gz" \
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
  ; apteryx make='4.3-4.1build2'
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
  ; apteryx build-essential='12.10ubuntu1'
RUN set -e \
  ; mkdir -p /exports/etc/alternatives/ /exports/etc/ /exports/usr/bin/ /exports/usr/include/ /exports/usr/lib/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/libexec/ /exports/usr/share/bug/ /exports/usr/share/ /exports/usr/share/doc/ /exports/usr/share/dpkg/ /exports/usr/share/gdb/auto-load/ /exports/usr/share/gdb/auto-load/usr/lib/x86_64-linux-gnu/ /exports/usr/share/perl5/ \
  ; mv /etc/alternatives/c++ /etc/alternatives/c++.1.gz /etc/alternatives/c89 /etc/alternatives/c89.1.gz /etc/alternatives/c99 /etc/alternatives/c99.1.gz /etc/alternatives/cc /etc/alternatives/cc.1.gz /etc/alternatives/cpp /etc/alternatives/lzcat /etc/alternatives/lzcat.1.gz /etc/alternatives/lzcmp /etc/alternatives/lzcmp.1.gz /etc/alternatives/lzdiff /etc/alternatives/lzdiff.1.gz /etc/alternatives/lzegrep /etc/alternatives/lzegrep.1.gz /etc/alternatives/lzfgrep /etc/alternatives/lzfgrep.1.gz /etc/alternatives/lzgrep /etc/alternatives/lzgrep.1.gz /etc/alternatives/lzless /etc/alternatives/lzless.1.gz /etc/alternatives/lzma /etc/alternatives/lzma.1.gz /etc/alternatives/lzmore /etc/alternatives/lzmore.1.gz /etc/alternatives/unlzma /etc/alternatives/unlzma.1.gz /exports/etc/alternatives/ \
  ; mv /etc/gprofng.rc /etc/perl /exports/etc/ \
  ; mv /usr/bin/addr2line /usr/bin/ar /usr/bin/as /usr/bin/bunzip2 /usr/bin/bzcat /usr/bin/bzcmp /usr/bin/bzdiff /usr/bin/bzegrep /usr/bin/bzexe /usr/bin/bzfgrep /usr/bin/bzgrep /usr/bin/bzip2 /usr/bin/bzip2recover /usr/bin/bzless /usr/bin/bzmore /usr/bin/c++ /usr/bin/c++filt /usr/bin/c89 /usr/bin/c89-gcc /usr/bin/c99 /usr/bin/c99-gcc /usr/bin/cc /usr/bin/corelist /usr/bin/cpan /usr/bin/cpan5.38-x86_64-linux-gnu /usr/bin/cpp /usr/bin/cpp-13 /usr/bin/dpkg-architecture /usr/bin/dpkg-buildapi /usr/bin/dpkg-buildflags /usr/bin/dpkg-buildpackage /usr/bin/dpkg-buildtree /usr/bin/dpkg-checkbuilddeps /usr/bin/dpkg-distaddfile /usr/bin/dpkg-genbuildinfo /usr/bin/dpkg-genchanges /usr/bin/dpkg-gencontrol /usr/bin/dpkg-gensymbols /usr/bin/dpkg-mergechangelogs /usr/bin/dpkg-name /usr/bin/dpkg-parsechangelog /usr/bin/dpkg-scanpackages /usr/bin/dpkg-scansources /usr/bin/dpkg-shlibdeps /usr/bin/dpkg-source /usr/bin/dpkg-vendor /usr/bin/dwp /usr/bin/elfedit /usr/bin/enc2xs /usr/bin/encguess /usr/bin/g++ /usr/bin/g++-13 /usr/bin/gcc /usr/bin/gcc-13 /usr/bin/gcc-ar /usr/bin/gcc-ar-13 /usr/bin/gcc-nm /usr/bin/gcc-nm-13 /usr/bin/gcc-ranlib /usr/bin/gcc-ranlib-13 /usr/bin/gcov /usr/bin/gcov-13 /usr/bin/gcov-dump /usr/bin/gcov-dump-13 /usr/bin/gcov-tool /usr/bin/gcov-tool-13 /usr/bin/gencat /usr/bin/gmake /usr/bin/gold /usr/bin/gp-archive /usr/bin/gp-collect-app /usr/bin/gp-display-html /usr/bin/gp-display-src /usr/bin/gp-display-text /usr/bin/gprof /usr/bin/gprofng /usr/bin/h2ph /usr/bin/h2xs /usr/bin/instmodsh /usr/bin/json_pp /usr/bin/ld /usr/bin/ld.bfd /usr/bin/ld.gold /usr/bin/libnetcfg /usr/bin/lto-dump /usr/bin/lto-dump-13 /usr/bin/lzcat /usr/bin/lzcmp /usr/bin/lzdiff /usr/bin/lzegrep /usr/bin/lzfgrep /usr/bin/lzgrep /usr/bin/lzless /usr/bin/lzma /usr/bin/lzmainfo /usr/bin/lzmore /usr/bin/make /usr/bin/make-first-existing-target /usr/bin/nm /usr/bin/objcopy /usr/bin/objdump /usr/bin/patch /usr/bin/perl5.38-x86_64-linux-gnu /usr/bin/perlbug /usr/bin/perldoc /usr/bin/perlivp /usr/bin/perlthanks /usr/bin/piconv /usr/bin/pl2pm /usr/bin/pod2html /usr/bin/pod2man /usr/bin/pod2text /usr/bin/pod2usage /usr/bin/podchecker /usr/bin/prove /usr/bin/ptar /usr/bin/ptardiff /usr/bin/ptargrep /usr/bin/ranlib /usr/bin/readelf /usr/bin/rpcgen /usr/bin/shasum /usr/bin/size /usr/bin/splain /usr/bin/streamzip /usr/bin/strings /usr/bin/strip /usr/bin/unlzma /usr/bin/unxz /usr/bin/x86_64-linux-gnu-addr2line /usr/bin/x86_64-linux-gnu-ar /usr/bin/x86_64-linux-gnu-as /usr/bin/x86_64-linux-gnu-c++filt /usr/bin/x86_64-linux-gnu-cpp /usr/bin/x86_64-linux-gnu-cpp-13 /usr/bin/x86_64-linux-gnu-dwp /usr/bin/x86_64-linux-gnu-elfedit /usr/bin/x86_64-linux-gnu-g++ /usr/bin/x86_64-linux-gnu-g++-13 /usr/bin/x86_64-linux-gnu-gcc /usr/bin/x86_64-linux-gnu-gcc-13 /usr/bin/x86_64-linux-gnu-gcc-ar /usr/bin/x86_64-linux-gnu-gcc-ar-13 /usr/bin/x86_64-linux-gnu-gcc-nm /usr/bin/x86_64-linux-gnu-gcc-nm-13 /usr/bin/x86_64-linux-gnu-gcc-ranlib /usr/bin/x86_64-linux-gnu-gcc-ranlib-13 /usr/bin/x86_64-linux-gnu-gcov /usr/bin/x86_64-linux-gnu-gcov-13 /usr/bin/x86_64-linux-gnu-gcov-dump /usr/bin/x86_64-linux-gnu-gcov-dump-13 /usr/bin/x86_64-linux-gnu-gcov-tool /usr/bin/x86_64-linux-gnu-gcov-tool-13 /usr/bin/x86_64-linux-gnu-gold /usr/bin/x86_64-linux-gnu-gp-archive /usr/bin/x86_64-linux-gnu-gp-collect-app /usr/bin/x86_64-linux-gnu-gp-display-html /usr/bin/x86_64-linux-gnu-gp-display-src /usr/bin/x86_64-linux-gnu-gp-display-text /usr/bin/x86_64-linux-gnu-gprof /usr/bin/x86_64-linux-gnu-gprofng /usr/bin/x86_64-linux-gnu-ld /usr/bin/x86_64-linux-gnu-ld.bfd /usr/bin/x86_64-linux-gnu-ld.gold /usr/bin/x86_64-linux-gnu-lto-dump /usr/bin/x86_64-linux-gnu-lto-dump-13 /usr/bin/x86_64-linux-gnu-nm /usr/bin/x86_64-linux-gnu-objcopy /usr/bin/x86_64-linux-gnu-objdump /usr/bin/x86_64-linux-gnu-ranlib /usr/bin/x86_64-linux-gnu-readelf /usr/bin/x86_64-linux-gnu-size /usr/bin/x86_64-linux-gnu-strings /usr/bin/x86_64-linux-gnu-strip /usr/bin/xsubpp /usr/bin/xz /usr/bin/xzcat /usr/bin/xzcmp /usr/bin/xzdiff /usr/bin/xzegrep /usr/bin/xzfgrep /usr/bin/xzgrep /usr/bin/xzless /usr/bin/xzmore /usr/bin/zipdetails /exports/usr/bin/ \
  ; mv /usr/include/aio.h /usr/include/aliases.h /usr/include/alloca.h /usr/include/ar.h /usr/include/argp.h /usr/include/argz.h /usr/include/arpa /usr/include/asm-generic /usr/include/assert.h /usr/include/byteswap.h /usr/include/c++ /usr/include/complex.h /usr/include/cpio.h /usr/include/crypt.h /usr/include/ctype.h /usr/include/dirent.h /usr/include/dlfcn.h /usr/include/drm /usr/include/elf.h /usr/include/endian.h /usr/include/envz.h /usr/include/err.h /usr/include/errno.h /usr/include/error.h /usr/include/execinfo.h /usr/include/fcntl.h /usr/include/features-time64.h /usr/include/features.h /usr/include/fenv.h /usr/include/finclude /usr/include/fmtmsg.h /usr/include/fnmatch.h /usr/include/fstab.h /usr/include/fts.h /usr/include/ftw.h /usr/include/gconv.h /usr/include/getopt.h /usr/include/glob.h /usr/include/gnu-versions.h /usr/include/gnumake.h /usr/include/grp.h /usr/include/gshadow.h /usr/include/iconv.h /usr/include/ifaddrs.h /usr/include/inttypes.h /usr/include/langinfo.h /usr/include/lastlog.h /usr/include/libgen.h /usr/include/libintl.h /usr/include/limits.h /usr/include/link.h /usr/include/linux /usr/include/locale.h /usr/include/malloc.h /usr/include/math.h /usr/include/mcheck.h /usr/include/memory.h /usr/include/misc /usr/include/mntent.h /usr/include/monetary.h /usr/include/mqueue.h /usr/include/mtd /usr/include/net /usr/include/netash /usr/include/netatalk /usr/include/netax25 /usr/include/netdb.h /usr/include/neteconet /usr/include/netinet /usr/include/netipx /usr/include/netiucv /usr/include/netpacket /usr/include/netrom /usr/include/netrose /usr/include/nfs /usr/include/nl_types.h /usr/include/nss.h /usr/include/obstack.h /usr/include/paths.h /usr/include/poll.h /usr/include/printf.h /usr/include/proc_service.h /usr/include/protocols /usr/include/pthread.h /usr/include/pty.h /usr/include/pwd.h /usr/include/rdma /usr/include/re_comp.h /usr/include/regex.h /usr/include/regexp.h /usr/include/regulator /usr/include/resolv.h /usr/include/rpc /usr/include/rpcsvc /usr/include/sched.h /usr/include/scsi /usr/include/search.h /usr/include/semaphore.h /usr/include/setjmp.h /usr/include/sgtty.h /usr/include/shadow.h /usr/include/signal.h /usr/include/sound /usr/include/spawn.h /usr/include/stab.h /usr/include/stdbit.h /usr/include/stdc-predef.h /usr/include/stdint.h /usr/include/stdio_ext.h /usr/include/stdio.h /usr/include/stdlib.h /usr/include/string.h /usr/include/strings.h /usr/include/syscall.h /usr/include/sysexits.h /usr/include/syslog.h /usr/include/tar.h /usr/include/termio.h /usr/include/termios.h /usr/include/tgmath.h /usr/include/thread_db.h /usr/include/threads.h /usr/include/time.h /usr/include/ttyent.h /usr/include/uchar.h /usr/include/ucontext.h /usr/include/ulimit.h /usr/include/unistd.h /usr/include/utime.h /usr/include/utmp.h /usr/include/utmpx.h /usr/include/values.h /usr/include/video /usr/include/wait.h /usr/include/wchar.h /usr/include/wctype.h /usr/include/wordexp.h /usr/include/x86_64-linux-gnu /usr/include/xen /exports/usr/include/ \
  ; mv /usr/lib/bfd-plugins /usr/lib/compat-ld /usr/lib/cpp /usr/lib/gcc /usr/lib/gold-ld /exports/usr/lib/ \
  ; mv /usr/lib/x86_64-linux-gnu/audit /usr/lib/x86_64-linux-gnu/bfd-plugins /usr/lib/x86_64-linux-gnu/crt1.o /usr/lib/x86_64-linux-gnu/crti.o /usr/lib/x86_64-linux-gnu/crtn.o /usr/lib/x86_64-linux-gnu/gcrt1.o /usr/lib/x86_64-linux-gnu/gprofng /usr/lib/x86_64-linux-gnu/grcrt1.o /usr/lib/x86_64-linux-gnu/ldscripts /usr/lib/x86_64-linux-gnu/libanl.a /usr/lib/x86_64-linux-gnu/libanl.so /usr/lib/x86_64-linux-gnu/libasan.so.8 /usr/lib/x86_64-linux-gnu/libasan.so.8.0.0 /usr/lib/x86_64-linux-gnu/libatomic.so.1 /usr/lib/x86_64-linux-gnu/libatomic.so.1.2.0 /usr/lib/x86_64-linux-gnu/libbfd-2.42-system.so /usr/lib/x86_64-linux-gnu/libBrokenLocale.a /usr/lib/x86_64-linux-gnu/libBrokenLocale.so /usr/lib/x86_64-linux-gnu/libc_malloc_debug.so /usr/lib/x86_64-linux-gnu/libc_nonshared.a /usr/lib/x86_64-linux-gnu/libc.a /usr/lib/x86_64-linux-gnu/libc.so /usr/lib/x86_64-linux-gnu/libcc1.so.0 /usr/lib/x86_64-linux-gnu/libcc1.so.0.0.0 /usr/lib/x86_64-linux-gnu/libcrypt.a /usr/lib/x86_64-linux-gnu/libcrypt.so /usr/lib/x86_64-linux-gnu/libctf-nobfd.so.0 /usr/lib/x86_64-linux-gnu/libctf-nobfd.so.0.0.0 /usr/lib/x86_64-linux-gnu/libctf.so.0 /usr/lib/x86_64-linux-gnu/libctf.so.0.0.0 /usr/lib/x86_64-linux-gnu/libdl.a /usr/lib/x86_64-linux-gnu/libg.a /usr/lib/x86_64-linux-gnu/libgdbm_compat.so.4 /usr/lib/x86_64-linux-gnu/libgdbm_compat.so.4.0.0 /usr/lib/x86_64-linux-gnu/libgdbm.so.6 /usr/lib/x86_64-linux-gnu/libgdbm.so.6.0.0 /usr/lib/x86_64-linux-gnu/libgomp.so.1 /usr/lib/x86_64-linux-gnu/libgomp.so.1.0.0 /usr/lib/x86_64-linux-gnu/libgprofng.so.0 /usr/lib/x86_64-linux-gnu/libgprofng.so.0.0.0 /usr/lib/x86_64-linux-gnu/libhwasan.so.0 /usr/lib/x86_64-linux-gnu/libhwasan.so.0.0.0 /usr/lib/x86_64-linux-gnu/libisl.so.23 /usr/lib/x86_64-linux-gnu/libisl.so.23.3.0 /usr/lib/x86_64-linux-gnu/libitm.so.1 /usr/lib/x86_64-linux-gnu/libitm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libjansson.so.4 /usr/lib/x86_64-linux-gnu/libjansson.so.4.14.0 /usr/lib/x86_64-linux-gnu/liblsan.so.0 /usr/lib/x86_64-linux-gnu/liblsan.so.0.0.0 /usr/lib/x86_64-linux-gnu/libm-2.39.a /usr/lib/x86_64-linux-gnu/libm.a /usr/lib/x86_64-linux-gnu/libm.so /usr/lib/x86_64-linux-gnu/libmcheck.a /usr/lib/x86_64-linux-gnu/libmpc.so.3 /usr/lib/x86_64-linux-gnu/libmpc.so.3.3.1 /usr/lib/x86_64-linux-gnu/libmpfr.so.6 /usr/lib/x86_64-linux-gnu/libmpfr.so.6.2.1 /usr/lib/x86_64-linux-gnu/libmvec.a /usr/lib/x86_64-linux-gnu/libmvec.so /usr/lib/x86_64-linux-gnu/libnss_compat.so /usr/lib/x86_64-linux-gnu/libnss_hesiod.so /usr/lib/x86_64-linux-gnu/libopcodes-2.42-system.so /usr/lib/x86_64-linux-gnu/libperl.so.5.38 /usr/lib/x86_64-linux-gnu/libperl.so.5.38.2 /usr/lib/x86_64-linux-gnu/libpthread_nonshared.a /usr/lib/x86_64-linux-gnu/libpthread.a /usr/lib/x86_64-linux-gnu/libquadmath.so.0 /usr/lib/x86_64-linux-gnu/libquadmath.so.0.0.0 /usr/lib/x86_64-linux-gnu/libresolv.a /usr/lib/x86_64-linux-gnu/libresolv.so /usr/lib/x86_64-linux-gnu/librt.a /usr/lib/x86_64-linux-gnu/libsframe.so.1 /usr/lib/x86_64-linux-gnu/libsframe.so.1.0.0 /usr/lib/x86_64-linux-gnu/libthread_db.so /usr/lib/x86_64-linux-gnu/libtsan.so.2 /usr/lib/x86_64-linux-gnu/libtsan.so.2.0.0 /usr/lib/x86_64-linux-gnu/libubsan.so.1 /usr/lib/x86_64-linux-gnu/libubsan.so.1.0.0 /usr/lib/x86_64-linux-gnu/libutil.a /usr/lib/x86_64-linux-gnu/Mcrt1.o /usr/lib/x86_64-linux-gnu/perl /usr/lib/x86_64-linux-gnu/pkgconfig /usr/lib/x86_64-linux-gnu/rcrt1.o /usr/lib/x86_64-linux-gnu/Scrt1.o /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/libexec/gcc /exports/usr/libexec/ \
  ; mv /usr/share/bug/binutils /usr/share/bug/dpkg-dev /usr/share/bug/libdpkg-perl /exports/usr/share/bug/ \
  ; mv /usr/share/build-essential /usr/share/lto-disabled-list /usr/share/perl /exports/usr/share/ \
  ; mv /usr/share/doc/xz-utils /exports/usr/share/doc/ \
  ; mv /usr/share/dpkg/architecture.mk /usr/share/dpkg/buildapi.mk /usr/share/dpkg/buildflags.mk /usr/share/dpkg/buildopts.mk /usr/share/dpkg/buildtools.mk /usr/share/dpkg/default.mk /usr/share/dpkg/no-pie-compile.specs /usr/share/dpkg/no-pie-link.specs /usr/share/dpkg/pie-compile.specs /usr/share/dpkg/pie-link.specs /usr/share/dpkg/pkg-info.mk /usr/share/dpkg/vendor.mk /exports/usr/share/dpkg/ \
  ; mv /usr/share/gdb/auto-load/lib /exports/usr/share/gdb/auto-load/ \
  ; mv /usr/share/gdb/auto-load/usr/lib/x86_64-linux-gnu/libisl.so.23.3.0-gdb.py /exports/usr/share/gdb/auto-load/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/share/perl5/Dpkg.pm /usr/share/perl5/Dpkg /exports/usr/share/perl5/

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
  ; apteryx zsh='5.9-6ubuntu2'
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
  ; clone --https --tag='v1.99.11' https://github.com/stayradiated/dotfiles \
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
  ; wget "https://raw.githubusercontent.com/tj/n/v10.1.0/bin/n" -O /usr/local/bin/n \
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
  ; userdel ubuntu \
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
  ; n v23.5.0 \
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
  ; wget -O /tmp/uv.tgz 'https://github.com/astral-sh/uv/releases/download/0.5.10/uv-x86_64-unknown-linux-gnu.tar.gz' \
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
  ; apteryx bzip2='1.0.8-5.1build0.1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man1/ \
  ; mv /usr/bin/bunzip2 /usr/bin/bzcat /usr/bin/bzcmp /usr/bin/bzdiff /usr/bin/bzegrep /usr/bin/bzexe /usr/bin/bzfgrep /usr/bin/bzgrep /usr/bin/bzip2 /usr/bin/bzip2recover /usr/bin/bzless /usr/bin/bzmore /exports/usr/bin/ \
  ; mv /usr/share/doc/bzip2 /exports/usr/share/doc/ \
  ; mv /usr/share/man/man1/bunzip2.1.gz /usr/share/man/man1/bzcat.1.gz /usr/share/man/man1/bzcmp.1.gz /usr/share/man/man1/bzdiff.1.gz /usr/share/man/man1/bzegrep.1.gz /usr/share/man/man1/bzexe.1.gz /usr/share/man/man1/bzfgrep.1.gz /usr/share/man/man1/bzgrep.1.gz /usr/share/man/man1/bzip2.1.gz /usr/share/man/man1/bzip2recover.1.gz /usr/share/man/man1/bzless.1.gz /usr/share/man/man1/bzmore.1.gz /exports/usr/share/man/man1/

# XZ
FROM base AS xz
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx xz-utils='5.6.1+really5.4.5-1build0.1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/share/man/man1/ \
  ; mv /usr/bin/xz /exports/usr/bin/ \
  ; mv /usr/share/man/man1/xz.1.gz /exports/usr/share/man/man1/

# UNZIP
FROM base AS unzip
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx unzip='6.0-28ubuntu4.1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/share/man/man1/ \
  ; mv /usr/bin/unzip /exports/usr/bin/ \
  ; mv /usr/share/man/man1/unzip.1.gz /exports/usr/share/man/man1/

# RUST
FROM base AS rust
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O rust.sh 'https://sh.rustup.rs' \
  ; sh rust.sh -y --default-toolchain '1.83.0' \
  ; rm rust.sh
RUN set -e \
  ; mkdir -p /exports/root/ \
  ; mv /root/.cargo /root/.rustup /exports/root/

# FZF
FROM base AS fzf
COPY --from=clone /exports/ /
RUN set -e \
  ; clone --https --tag='v0.57.0' https://github.com/junegunn/fzf \
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
  ; uv pip install --system --break-system-packages neovim msgpack neovim-remote
RUN set -e \
  ; mkdir -p /exports/usr/include/ /exports/usr/local/bin/ /exports/usr/local/lib/python3.12/ /exports/usr/local/share/ \
  ; mv /usr/include/python3.12 /exports/usr/include/ \
  ; mv /usr/local/bin/nvim /usr/local/bin/nvr /exports/usr/local/bin/ \
  ; mv /usr/local/lib/python3.12/dist-packages /exports/usr/local/lib/python3.12/ \
  ; mv /usr/local/share/nvim /exports/usr/local/share/

# TMUX
FROM base AS tmux
COPY --from=apteryx /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=make /exports/ /
COPY --from=wget /exports/ /
RUN set -e \
  ; packages="libncurses5-dev libevent-dev bison" \
  ; apteryx $packages \
  ; wget --no-hsts -O /tmp/tmux.tgz 'https://github.com/tmux/tmux/releases/download/3.5a/tmux-3.5a.tar.gz' \
  ; mkdir -p /tmp/tmux \
  ; tar -xz --strip-components=1 -C /tmp/tmux -f /tmp/tmux.tgz \
  ; rm /tmp/tmux.tgz \
  ; cd /tmp/tmux \
  ; ./configure \
  ; make \
  ; make install \
  ; cd / \
  ; rm -r /tmp/tmux \
  ; apt-get remove --purge -y $packages
RUN set -e \
  ; mkdir -p /exports/usr/include/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ /exports/usr/local/bin/ \
  ; mv /usr/include/curses.h /usr/include/cursesapp.h /usr/include/cursesf.h /usr/include/cursesm.h /usr/include/cursesp.h /usr/include/cursesw.h /usr/include/cursslk.h /usr/include/eti.h /usr/include/etip.h /usr/include/form.h /usr/include/menu.h /usr/include/ncurses_dll.h /usr/include/ncurses.h /usr/include/ncursesw /usr/include/panel.h /usr/include/term_entry.h /usr/include/term.h /usr/include/termcap.h /usr/include/unctrl.h /exports/usr/include/ \
  ; mv /usr/lib/x86_64-linux-gnu/libcurses.a /usr/lib/x86_64-linux-gnu/libcurses.so /usr/lib/x86_64-linux-gnu/libevent_core-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent_core-2.1.so.7.0.1 /usr/lib/x86_64-linux-gnu/libevent_extra-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent_extra-2.1.so.7.0.1 /usr/lib/x86_64-linux-gnu/libevent_openssl-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent_openssl-2.1.so.7.0.1 /usr/lib/x86_64-linux-gnu/libevent_pthreads-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent_pthreads-2.1.so.7.0.1 /usr/lib/x86_64-linux-gnu/libevent-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent-2.1.so.7.0.1 /usr/lib/x86_64-linux-gnu/libform.a /usr/lib/x86_64-linux-gnu/libform.so /usr/lib/x86_64-linux-gnu/libform.so.6 /usr/lib/x86_64-linux-gnu/libform.so.6.4 /usr/lib/x86_64-linux-gnu/libformw.a /usr/lib/x86_64-linux-gnu/libformw.so /usr/lib/x86_64-linux-gnu/libmenu.a /usr/lib/x86_64-linux-gnu/libmenu.so /usr/lib/x86_64-linux-gnu/libmenu.so.6 /usr/lib/x86_64-linux-gnu/libmenu.so.6.4 /usr/lib/x86_64-linux-gnu/libmenuw.a /usr/lib/x86_64-linux-gnu/libmenuw.so /usr/lib/x86_64-linux-gnu/libncurses.a /usr/lib/x86_64-linux-gnu/libncurses.so /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.6.4 /usr/lib/x86_64-linux-gnu/libncurses++.a /usr/lib/x86_64-linux-gnu/libncurses++w.a /usr/lib/x86_64-linux-gnu/libncursesw.a /usr/lib/x86_64-linux-gnu/libncursesw.so /usr/lib/x86_64-linux-gnu/libpanel.a /usr/lib/x86_64-linux-gnu/libpanel.so /usr/lib/x86_64-linux-gnu/libpanel.so.6 /usr/lib/x86_64-linux-gnu/libpanel.so.6.4 /usr/lib/x86_64-linux-gnu/libpanelw.a /usr/lib/x86_64-linux-gnu/libpanelw.so /usr/lib/x86_64-linux-gnu/libtermcap.a /usr/lib/x86_64-linux-gnu/libtermcap.so /usr/lib/x86_64-linux-gnu/libtic.a /usr/lib/x86_64-linux-gnu/libtic.so /usr/lib/x86_64-linux-gnu/libtinfo.a /usr/lib/x86_64-linux-gnu/libtinfo.so /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/lib/x86_64-linux-gnu/pkgconfig/form.pc /usr/lib/x86_64-linux-gnu/pkgconfig/formw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/menu.pc /usr/lib/x86_64-linux-gnu/pkgconfig/menuw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncurses.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncurses++.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncurses++w.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncursesw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/panel.pc /usr/lib/x86_64-linux-gnu/pkgconfig/panelw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/tic.pc /usr/lib/x86_64-linux-gnu/pkgconfig/tinfo.pc /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ \
  ; mv /usr/local/bin/tmux /exports/usr/local/bin/

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
  ; uv tool install ranger-fm=='1.9.4' \
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
  ; wget -O /tmp/firefox.tar.bz2 https://download-installer.cdn.mozilla.net/pub/firefox/releases/133.0.3/linux-x86_64/en-US/firefox-133.0.3.tar.bz2 \
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
  ; apteryx google-chrome-beta='132.0.6834.57-*'
RUN set -e \
  ; mkdir -p /exports/etc/ /exports/etc/default/ /exports/etc/X11/ /exports/etc/X11/Xsession.d/ /exports/opt/ /exports/usr/bin/ /exports/usr/lib/systemd/user/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/gio/modules/ /exports/usr/libexec/ /exports/usr/local/share/ /exports/usr/sbin/ /exports/usr/share/ /exports/usr/share/applications/ /exports/usr/share/apport/package-hooks/ /exports/usr/share/bug/ /exports/usr/share/dbus-1/services/ /exports/usr/share/doc-base/ /exports/usr/share/doc/ /exports/usr/share/glib-2.0/schemas/ /exports/usr/share/icons/ /exports/usr/share/icons/hicolor/ /exports/usr/share/icons/hicolor/48x48/ /exports/usr/share/icons/hicolor/48x48/apps/ /exports/usr/share/icons/hicolor/scalable/ /exports/usr/share/info/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ /exports/usr/share/man/man5/ /exports/usr/share/man/man7/ /exports/usr/share/menu/ /exports/usr/share/pkgconfig/ \
  ; mv /etc/dconf /etc/fonts /etc/gtk-3.0 /etc/vulkan /exports/etc/ \
  ; mv /etc/default/google-chrome-beta /exports/etc/default/ \
  ; mv /etc/X11/xkb /exports/etc/X11/ \
  ; mv /etc/X11/Xsession.d/20dbus_xdg-runtime /exports/etc/X11/Xsession.d/ \
  ; mv /opt/google /exports/opt/ \
  ; mv /usr/bin/google-chrome /usr/bin/google-chrome-beta /exports/usr/bin/ \
  ; mv /usr/lib/systemd/user/dbus.service /usr/lib/systemd/user/dbus.socket /usr/lib/systemd/user/dconf.service /usr/lib/systemd/user/sockets.target.wants /exports/usr/lib/systemd/user/ \
  ; mv /usr/lib/x86_64-linux-gnu/avahi /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0 /usr/lib/x86_64-linux-gnu/gtk-3.0 /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libasound.so.2.0.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0.25209.1 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0.0.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0.0.1 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3.2.9 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3.5.4 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2.11800.0 /usr/lib/x86_64-linux-gnu/libcairo.so.2 /usr/lib/x86_64-linux-gnu/libcairo.so.2.11800.0 /usr/lib/x86_64-linux-gnu/libcolord.so.2 /usr/lib/x86_64-linux-gnu/libcolord.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcups.so.2 /usr/lib/x86_64-linux-gnu/libdatrie.so.1 /usr/lib/x86_64-linux-gnu/libdatrie.so.1.4.0 /usr/lib/x86_64-linux-gnu/libdconf.so.1 /usr/lib/x86_64-linux-gnu/libdconf.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdeflate.so.0 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0.0.0 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.1 /usr/lib/x86_64-linux-gnu/libfreebl3.chk /usr/lib/x86_64-linux-gnu/libfreebl3.so /usr/lib/x86_64-linux-gnu/libfreeblpriv3.chk /usr/lib/x86_64-linux-gnu/libfreeblpriv3.so /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.20.1 /usr/lib/x86_64-linux-gnu/libfribidi.so.0 /usr/lib/x86_64-linux-gnu/libfribidi.so.0.4.0 /usr/lib/x86_64-linux-gnu/libgbm.so.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0.4200.10 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0.2409.32 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgtk-3-0t64 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0.2409.32 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.60830.0 /usr/lib/x86_64-linux-gnu/libjbig.so.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2.0.14 /usr/lib/x86_64-linux-gnu/libLerc.so.4 /usr/lib/x86_64-linux-gnu/libnspr4.so /usr/lib/x86_64-linux-gnu/libnss3.so /usr/lib/x86_64-linux-gnu/libnssckbi.so /usr/lib/x86_64-linux-gnu/libnssdbm3.chk /usr/lib/x86_64-linux-gnu/libnssdbm3.so /usr/lib/x86_64-linux-gnu/libnssutil3.so /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0.5200.1 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0.5200.1 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0.5200.1 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0.42.2 /usr/lib/x86_64-linux-gnu/libplc4.so /usr/lib/x86_64-linux-gnu/libplds4.so /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.43.0 /usr/lib/x86_64-linux-gnu/libsharpyuv.so.0 /usr/lib/x86_64-linux-gnu/libsharpyuv.so.0.0.1 /usr/lib/x86_64-linux-gnu/libsmime3.so /usr/lib/x86_64-linux-gnu/libsoftokn3.chk /usr/lib/x86_64-linux-gnu/libsoftokn3.so /usr/lib/x86_64-linux-gnu/libssl3.so /usr/lib/x86_64-linux-gnu/libthai.so.0 /usr/lib/x86_64-linux-gnu/libthai.so.0.3.1 /usr/lib/x86_64-linux-gnu/libtiff.so.6 /usr/lib/x86_64-linux-gnu/libtiff.so.6.0.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1.3.275 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.22.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0.22.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.22.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0.22.0 /usr/lib/x86_64-linux-gnu/libwebp.so.7 /usr/lib/x86_64-linux-gnu/libwebp.so.7.1.8 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXcursor.so.1 /usr/lib/x86_64-linux-gnu/libXcursor.so.1.0.2 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libXi.so.6 /usr/lib/x86_64-linux-gnu/libXi.so.6.1.0 /usr/lib/x86_64-linux-gnu/libXinerama.so.1 /usr/lib/x86_64-linux-gnu/libXinerama.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrandr.so.2 /usr/lib/x86_64-linux-gnu/libXrandr.so.2.2.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/lib/x86_64-linux-gnu/gio/modules/giomodule.cache /usr/lib/x86_64-linux-gnu/gio/modules/libdconfsettings.so /exports/usr/lib/x86_64-linux-gnu/gio/modules/ \
  ; mv /usr/libexec/dconf-service /exports/usr/libexec/ \
  ; mv /usr/local/share/fonts /exports/usr/local/share/ \
  ; mv /usr/sbin/update-icon-caches /exports/usr/sbin/ \
  ; mv /usr/share/alsa /usr/share/appdata /usr/share/fontconfig /usr/share/fonts /usr/share/gettext /usr/share/gnome-control-center /usr/share/gtk-3.0 /usr/share/libdrm /usr/share/libthai /usr/share/mime /usr/share/themes /usr/share/X11 /exports/usr/share/ \
  ; mv /usr/share/applications/google-chrome-beta.desktop /exports/usr/share/applications/ \
  ; mv /usr/share/apport/package-hooks/source_fontconfig.py /exports/usr/share/apport/package-hooks/ \
  ; mv /usr/share/bug/fonts-liberation /usr/share/bug/libgbm1 /usr/share/bug/libgtk-3-0t64 /usr/share/bug/xdg-utils /exports/usr/share/bug/ \
  ; mv /usr/share/dbus-1/services/ca.desrt.dconf.service /exports/usr/share/dbus-1/services/ \
  ; mv /usr/share/doc-base/fontconfig.fontconfig-user /usr/share/doc-base/libpng16-16t64.libpng16 /usr/share/doc-base/shared-mime-info.shared-mime-info /exports/usr/share/doc-base/ \
  ; mv /usr/share/doc/adwaita-icon-theme /usr/share/doc/at-spi2-common /usr/share/doc/dbus-user-session /usr/share/doc/dconf-gsettings-backend /usr/share/doc/dconf-service /usr/share/doc/fontconfig-config /usr/share/doc/fontconfig /usr/share/doc/fonts-liberation /usr/share/doc/google-chrome-beta /usr/share/doc/gtk-update-icon-cache /usr/share/doc/hicolor-icon-theme /usr/share/doc/humanity-icon-theme /usr/share/doc/libasound2-data /usr/share/doc/libasound2t64 /usr/share/doc/libatk-bridge2.0-0t64 /usr/share/doc/libatk1.0-0t64 /usr/share/doc/libatspi2.0-0t64 /usr/share/doc/libavahi-client3 /usr/share/doc/libavahi-common-data /usr/share/doc/libavahi-common3 /usr/share/doc/libcairo-gobject2 /usr/share/doc/libcairo2 /usr/share/doc/libcolord2 /usr/share/doc/libcups2t64 /usr/share/doc/libdatrie1 /usr/share/doc/libdconf1 /usr/share/doc/libdeflate0 /usr/share/doc/libdrm-common /usr/share/doc/libdrm2 /usr/share/doc/libepoxy0 /usr/share/doc/libfontconfig1 /usr/share/doc/libfreetype6 /usr/share/doc/libfribidi0 /usr/share/doc/libgbm1 /usr/share/doc/libgdk-pixbuf-2.0-0 /usr/share/doc/libgdk-pixbuf2.0-common /usr/share/doc/libgraphite2-3 /usr/share/doc/libgtk-3-0t64 /usr/share/doc/libgtk-3-common /usr/share/doc/libharfbuzz0b /usr/share/doc/libjbig0 /usr/share/doc/libjpeg-turbo8 /usr/share/doc/libjpeg8 /usr/share/doc/liblcms2-2 /usr/share/doc/liblerc4 /usr/share/doc/libnspr4 /usr/share/doc/libnss3 /usr/share/doc/libpango-1.0-0 /usr/share/doc/libpangocairo-1.0-0 /usr/share/doc/libpangoft2-1.0-0 /usr/share/doc/libpixman-1-0 /usr/share/doc/libpng16-16t64 /usr/share/doc/libsharpyuv0 /usr/share/doc/libthai-data /usr/share/doc/libthai0 /usr/share/doc/libtiff6 /usr/share/doc/libvulkan1 /usr/share/doc/libwayland-client0 /usr/share/doc/libwayland-cursor0 /usr/share/doc/libwayland-egl1 /usr/share/doc/libwayland-server0 /usr/share/doc/libwebp7 /usr/share/doc/libx11-6 /usr/share/doc/libx11-data /usr/share/doc/libxau6 /usr/share/doc/libxcb-randr0 /usr/share/doc/libxcb-render0 /usr/share/doc/libxcb-shm0 /usr/share/doc/libxcb1 /usr/share/doc/libxcomposite1 /usr/share/doc/libxcursor1 /usr/share/doc/libxdamage1 /usr/share/doc/libxdmcp6 /usr/share/doc/libxext6 /usr/share/doc/libxfixes3 /usr/share/doc/libxi6 /usr/share/doc/libxinerama1 /usr/share/doc/libxkbcommon0 /usr/share/doc/libxrandr2 /usr/share/doc/libxrender1 /usr/share/doc/shared-mime-info /usr/share/doc/ubuntu-mono /usr/share/doc/xdg-utils /usr/share/doc/xkb-data /exports/usr/share/doc/ \
  ; mv /usr/share/glib-2.0/schemas/gschemas.compiled /usr/share/glib-2.0/schemas/org.gtk.Settings.ColorChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.Debug.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.EmojiChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.FileChooser.gschema.xml /exports/usr/share/glib-2.0/schemas/ \
  ; mv /usr/share/icons/Adwaita /usr/share/icons/default /usr/share/icons/Humanity-Dark /usr/share/icons/Humanity /usr/share/icons/LoginIcons /usr/share/icons/ubuntu-mono-dark /usr/share/icons/ubuntu-mono-light /exports/usr/share/icons/ \
  ; mv /usr/share/icons/hicolor/128x128 /usr/share/icons/hicolor/16x16 /usr/share/icons/hicolor/192x192 /usr/share/icons/hicolor/22x22 /usr/share/icons/hicolor/24x24 /usr/share/icons/hicolor/256x256 /usr/share/icons/hicolor/32x32 /usr/share/icons/hicolor/36x36 /usr/share/icons/hicolor/512x512 /usr/share/icons/hicolor/64x64 /usr/share/icons/hicolor/72x72 /usr/share/icons/hicolor/96x96 /usr/share/icons/hicolor/icon-theme.cache /usr/share/icons/hicolor/index.theme /usr/share/icons/hicolor/symbolic /exports/usr/share/icons/hicolor/ \
  ; mv /usr/share/icons/hicolor/48x48/actions /usr/share/icons/hicolor/48x48/animations /usr/share/icons/hicolor/48x48/categories /usr/share/icons/hicolor/48x48/devices /usr/share/icons/hicolor/48x48/emblems /usr/share/icons/hicolor/48x48/emotes /usr/share/icons/hicolor/48x48/filesystems /usr/share/icons/hicolor/48x48/intl /usr/share/icons/hicolor/48x48/mimetypes /usr/share/icons/hicolor/48x48/places /usr/share/icons/hicolor/48x48/status /usr/share/icons/hicolor/48x48/stock /exports/usr/share/icons/hicolor/48x48/ \
  ; mv /usr/share/icons/hicolor/48x48/apps/google-chrome-beta.png /exports/usr/share/icons/hicolor/48x48/apps/ \
  ; mv /usr/share/icons/hicolor/scalable/actions /usr/share/icons/hicolor/scalable/animations /usr/share/icons/hicolor/scalable/categories /usr/share/icons/hicolor/scalable/devices /usr/share/icons/hicolor/scalable/emblems /usr/share/icons/hicolor/scalable/emotes /usr/share/icons/hicolor/scalable/filesystems /usr/share/icons/hicolor/scalable/intl /usr/share/icons/hicolor/scalable/mimetypes /usr/share/icons/hicolor/scalable/places /usr/share/icons/hicolor/scalable/status /usr/share/icons/hicolor/scalable/stock /exports/usr/share/icons/hicolor/scalable/ \
  ; mv /usr/share/info/wget.info.gz /exports/usr/share/info/ \
  ; mv /usr/share/lintian/overrides/adwaita-icon-theme /usr/share/lintian/overrides/dbus-user-session /usr/share/lintian/overrides/hicolor-icon-theme /usr/share/lintian/overrides/libasound2t64 /usr/share/lintian/overrides/libatk-bridge2.0-0t64 /usr/share/lintian/overrides/libatk1.0-0t64 /usr/share/lintian/overrides/libatspi2.0-0t64 /usr/share/lintian/overrides/libcairo-gobject2 /usr/share/lintian/overrides/libcups2t64 /usr/share/lintian/overrides/libgbm1 /usr/share/lintian/overrides/libgtk-3-0t64 /usr/share/lintian/overrides/libjpeg-turbo8 /usr/share/lintian/overrides/libnspr4 /usr/share/lintian/overrides/libnss3 /usr/share/lintian/overrides/libpixman-1-0 /usr/share/lintian/overrides/libpng16-16t64 /usr/share/lintian/overrides/libx11-6 /exports/usr/share/lintian/overrides/ \
  ; mv /usr/share/man/man1/dconf-service.1.gz /usr/share/man/man1/fc-cache.1.gz /usr/share/man/man1/fc-cat.1.gz /usr/share/man/man1/fc-conflist.1.gz /usr/share/man/man1/fc-list.1.gz /usr/share/man/man1/fc-match.1.gz /usr/share/man/man1/fc-pattern.1.gz /usr/share/man/man1/fc-query.1.gz /usr/share/man/man1/fc-scan.1.gz /usr/share/man/man1/fc-validate.1.gz /usr/share/man/man1/google-chrome-beta.1.gz /usr/share/man/man1/gtk-update-icon-cache.1.gz /usr/share/man/man1/open.1.gz /usr/share/man/man1/update-mime-database.1.gz /usr/share/man/man1/xdg-desktop-icon.1.gz /usr/share/man/man1/xdg-desktop-menu.1.gz /usr/share/man/man1/xdg-email.1.gz /usr/share/man/man1/xdg-icon-resource.1.gz /usr/share/man/man1/xdg-mime.1.gz /usr/share/man/man1/xdg-open.1.gz /usr/share/man/man1/xdg-screensaver.1.gz /usr/share/man/man1/xdg-settings.1.gz /exports/usr/share/man/man1/ \
  ; mv /usr/share/man/man5/Compose.5.gz /usr/share/man/man5/fonts-conf.5.gz /usr/share/man/man5/XCompose.5.gz /exports/usr/share/man/man5/ \
  ; mv /usr/share/man/man7/xkeyboard-config.7.gz /exports/usr/share/man/man7/ \
  ; mv /usr/share/menu/google-chrome-beta.menu /exports/usr/share/menu/ \
  ; mv /usr/share/pkgconfig/adwaita-icon-theme.pc /usr/share/pkgconfig/shared-mime-info.pc /usr/share/pkgconfig/xkeyboard-config.pc /exports/usr/share/pkgconfig/

# XDG-UTILS
FROM base AS xdg-utils
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx xdg-utils='1.1.3-4.1ubuntu3'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ \
  ; mv /usr/bin/browse /usr/bin/xdg-desktop-icon /usr/bin/xdg-desktop-menu /usr/bin/xdg-email /usr/bin/xdg-icon-resource /usr/bin/xdg-mime /usr/bin/xdg-open /usr/bin/xdg-screensaver /usr/bin/xdg-settings /exports/usr/bin/

# PING
FROM base AS ping
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx iputils-ping='3:20240117-1build1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man8/ \
  ; mv /usr/bin/ping /usr/bin/ping4 /usr/bin/ping6 /exports/usr/bin/ \
  ; mv /usr/share/doc/iputils-ping /exports/usr/share/doc/ \
  ; mv /usr/share/man/man8/ping.8.gz /usr/share/man/man8/ping4.8.gz /usr/share/man/man8/ping6.8.gz /exports/usr/share/man/man8/

# MILLER
FROM base AS miller
COPY --from=wget /exports/ /
RUN set -e \
  ; wget --no-hsts -O /tmp/miller.tar.gz https://github.com/johnkerl/miller/releases/download/v6.13.0/miller-6.13.0-linux-amd64.tar.gz \
  ; tar -xz --strip-components=1 -C /usr/bin -f /tmp/miller.tar.gz miller-6.13.0-linux-amd64/mlr \
  ; rm /tmp/miller.tar.gz
RUN set -e \
  ; mkdir -p /exports/usr/bin/ \
  ; mv /usr/bin/mlr /exports/usr/bin/

# FILES-TO-PROMPT
FROM base AS files-to-prompt
COPY --from=uv /exports/ /
ENV \
  UV_LINK_MODE=copy \
  UV_COMPILE_BYTECODE=1 \
  UV_PYTHON_DOWNLOADS=manual \
  UV_TOOL_DIR=/usr/local/uv/tools \
  UV_TOOL_BIN_DIR=/usr/local/uv/bin \
  UV_PYTHON_INSTALL_DIR=/usr/local/uv/python
RUN set -e \
  ; uv tool install files-to-prompt=='0.4' \
  ; ln -s /usr/local/uv/bin/files-to-prompt /usr/local/bin/files-to-prompt
RUN set -e \
  ; mkdir -p /exports/usr/local/ /exports/usr/local/bin/ \
  ; mv /usr/local/uv /exports/usr/local/ \
  ; mv /usr/local/bin/files-to-prompt /exports/usr/local/bin/

# CLOUDFLARED
FROM base AS cloudflared
COPY --from=wget /exports/ /
RUN set -e \
  ; wget --no-hsts -O /usr/local/bin/cloudflared 'https://github.com/cloudflare/cloudflared/releases/download/2024.12.2/cloudflared-linux-amd64' \
  ; chmod +x /usr/local/bin/cloudflared
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/cloudflared /exports/usr/local/bin/

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
COPY --from=uv /exports/ /
ENV \
  UV_LINK_MODE=copy \
  UV_COMPILE_BYTECODE=1 \
  UV_PYTHON_DOWNLOADS=manual \
  UV_TOOL_DIR=/usr/local/uv/tools \
  UV_TOOL_BIN_DIR=/usr/local/uv/bin \
  UV_PYTHON_INSTALL_DIR=/usr/local/uv/python
RUN set -e \
  ; uv tool install yt-dlp=='2024.11.18' \
  ; ln -s /usr/local/uv/bin/yt-dlp /usr/local/bin/yt-dlp
RUN set -e \
  ; mkdir -p /exports/usr/local/ /exports/usr/local/bin/ \
  ; mv /usr/local/uv /exports/usr/local/ \
  ; mv /usr/local/bin/yt-dlp /exports/usr/local/bin/

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

# JUJUTSU
FROM base AS jujutsu
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/jj.tgz 'https://github.com/martinvonz/jj/releases/download/v0.24.0/jj-v0.24.0-x86_64-unknown-linux-musl.tar.gz' \
  ; tar xzvf /tmp/jj.tgz \
  ; rm /tmp/jj.tgz \
  ; mv 'jj' /usr/local/bin/jj
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/jj /exports/usr/local/bin/

# AST-GREP
FROM base AS ast-grep
COPY --from=wget /exports/ /
COPY --from=unzip /exports/ /
RUN set -e \
  ; wget -O /tmp/ast-grep.zip 'https://github.com/ast-grep/ast-grep/releases/download/0.32.2/app-x86_64-unknown-linux-gnu.zip' \
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
  ; wget "https://github.com/hatoo/oha/releases/download/v1.5.0/oha-linux-amd64" -O /tmp/oha \
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

# JO
FROM base AS jo
COPY --from=clone /exports/ /
COPY --from=apteryx /exports/ /
COPY --from=build-essential /exports/ /
RUN set -e \
  ; PKG_LIST="autoconf automake pkgconf" \
  ; apteryx $PKG_LIST \
  ; clone --https --ref='0ae09bc6d46369bd137b8a30e697007e3393ba0f' --shallow 'https://github.com/jpmens/jo' \
  ; cd /root/src/github.com/jpmens/jo \
  ; autoreconf -i \
  ; ./configure \
  ; make install \
  ; apt-get remove --purge -y $PKG_LIST \
  ; rm -r /root/src
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/jo /exports/usr/local/bin/

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

# YQ
FROM base AS yq
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /usr/local/bin/yq 'https://github.com/mikefarah/yq/releases/download/v4.44.6/yq_linux_amd64' \
  ; chmod +x /usr/local/bin/yq
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/yq /exports/usr/local/bin/

# FONTS
FROM base AS fonts
COPY --from=clone /exports/ /
COPY --from=apteryx /exports/ /
COPY --from=wget /exports/ /
RUN set -e \
  ; apteryx fontconfig='2.15.0-1.1ubuntu2' fonts-noto fonts-noto-cjk fonts-noto-color-emoji xfonts-utils \
  ; mkdir -p /usr/share/fonts/X11/bitmap \
  ; wget -O /usr/share/fonts/X11/bitmap/gomme.bdf 'http://raw.githubusercontent.com/Tecate/bitmap-fonts/master/bitmap/gomme/Gomme10x20n.bdf' \
  ; wget -O /usr/share/fonts/X11/bitmap/terminal.bdf 'http://raw.githubusercontent.com/Tecate/bitmap-fonts/master/bitmap/dylex/7x13.bdf' \
  ; clone --shallow --https https://github.com/blaisck/sfwin \
  ; cd /root/src/github.com/blaisck/sfwin \
  ; mv SFCompact/TrueType /usr/share/fonts/SFCompact \
  ; mv SFMono/TrueType /usr/share/fonts/SFMono \
  ; mv SFPro/TrueType /usr/share/fonts/SFPro \
  ; cd /etc/fonts/conf.d \
  ; ls -alh \
  ; rm 10* 70-no-bitmaps-except-emoji.conf \
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
  ; clone --https --shallow --ref=91af896b8632572f9b2b9f6a83aa1971d9262f1d https://github.com/jmbaur/gosee \
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
  ; wget -O /tmp/bun.zip https://github.com/oven-sh/bun/releases/download/bun-v1.1.40/bun-linux-x64.zip \
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

# BRAVE
FROM base AS brave
COPY --from=apteryx /exports/ /
RUN set -e \
  ; curl -fsSLo /usr/share/keyrings/brave-browser-beta-archive-keyring.gpg https://brave-browser-apt-beta.s3.brave.com/brave-browser-beta-archive-keyring.gpg \
  ; echo "deb [signed-by=/usr/share/keyrings/brave-browser-beta-archive-keyring.gpg] https://brave-browser-apt-beta.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-beta.list \
  ; apt update \
  ; apteryx brave-browser-beta='1.74.31*'
RUN set -e \
  ; mkdir -p /exports/opt/ /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/gio/modules/ /exports/usr/local/share/ /exports/usr/share/applications/ /exports/usr/share/dbus-1/services/ /exports/usr/share/doc-base/ /exports/usr/share/ \
  ; mv /opt/brave.com /exports/opt/ \
  ; mv /usr/bin/brave-browser /usr/bin/brave-browser-beta /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu/avahi /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0 /usr/lib/x86_64-linux-gnu/gtk-3.0 /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libasound.so.2.0.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0.25209.1 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0.0.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0.0.1 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3.2.9 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3.5.4 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2.11800.0 /usr/lib/x86_64-linux-gnu/libcairo.so.2 /usr/lib/x86_64-linux-gnu/libcairo.so.2.11800.0 /usr/lib/x86_64-linux-gnu/libcolord.so.2 /usr/lib/x86_64-linux-gnu/libcolord.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcups.so.2 /usr/lib/x86_64-linux-gnu/libdatrie.so.1 /usr/lib/x86_64-linux-gnu/libdatrie.so.1.4.0 /usr/lib/x86_64-linux-gnu/libdconf.so.1 /usr/lib/x86_64-linux-gnu/libdconf.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdeflate.so.0 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0.0.0 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.1 /usr/lib/x86_64-linux-gnu/libfreebl3.chk /usr/lib/x86_64-linux-gnu/libfreebl3.so /usr/lib/x86_64-linux-gnu/libfreeblpriv3.chk /usr/lib/x86_64-linux-gnu/libfreeblpriv3.so /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.20.1 /usr/lib/x86_64-linux-gnu/libfribidi.so.0 /usr/lib/x86_64-linux-gnu/libfribidi.so.0.4.0 /usr/lib/x86_64-linux-gnu/libgbm.so.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0.4200.10 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0.2409.32 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgtk-3-0t64 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0.2409.32 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.60830.0 /usr/lib/x86_64-linux-gnu/libjbig.so.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2.0.14 /usr/lib/x86_64-linux-gnu/libLerc.so.4 /usr/lib/x86_64-linux-gnu/libnspr4.so /usr/lib/x86_64-linux-gnu/libnss3.so /usr/lib/x86_64-linux-gnu/libnssckbi.so /usr/lib/x86_64-linux-gnu/libnssdbm3.chk /usr/lib/x86_64-linux-gnu/libnssdbm3.so /usr/lib/x86_64-linux-gnu/libnssutil3.so /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0.5200.1 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0.5200.1 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0.5200.1 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0.42.2 /usr/lib/x86_64-linux-gnu/libplc4.so /usr/lib/x86_64-linux-gnu/libplds4.so /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.43.0 /usr/lib/x86_64-linux-gnu/libsharpyuv.so.0 /usr/lib/x86_64-linux-gnu/libsharpyuv.so.0.0.1 /usr/lib/x86_64-linux-gnu/libsmime3.so /usr/lib/x86_64-linux-gnu/libsoftokn3.chk /usr/lib/x86_64-linux-gnu/libsoftokn3.so /usr/lib/x86_64-linux-gnu/libssl3.so /usr/lib/x86_64-linux-gnu/libthai.so.0 /usr/lib/x86_64-linux-gnu/libthai.so.0.3.1 /usr/lib/x86_64-linux-gnu/libtiff.so.6 /usr/lib/x86_64-linux-gnu/libtiff.so.6.0.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1.3.275 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.22.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0.22.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.22.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0.22.0 /usr/lib/x86_64-linux-gnu/libwebp.so.7 /usr/lib/x86_64-linux-gnu/libwebp.so.7.1.8 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXcursor.so.1 /usr/lib/x86_64-linux-gnu/libXcursor.so.1.0.2 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libXi.so.6 /usr/lib/x86_64-linux-gnu/libXi.so.6.1.0 /usr/lib/x86_64-linux-gnu/libXinerama.so.1 /usr/lib/x86_64-linux-gnu/libXinerama.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrandr.so.2 /usr/lib/x86_64-linux-gnu/libXrandr.so.2.2.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/lib/x86_64-linux-gnu/gio/modules/giomodule.cache /usr/lib/x86_64-linux-gnu/gio/modules/libdconfsettings.so /exports/usr/lib/x86_64-linux-gnu/gio/modules/ \
  ; mv /usr/local/share/fonts /exports/usr/local/share/ \
  ; mv /usr/share/applications/brave-browser-beta.desktop /exports/usr/share/applications/ \
  ; mv /usr/share/dbus-1/services/ca.desrt.dconf.service /exports/usr/share/dbus-1/services/ \
  ; mv /usr/share/doc-base/fontconfig.fontconfig-user /usr/share/doc-base/libpng16-16t64.libpng16 /usr/share/doc-base/shared-mime-info.shared-mime-info /exports/usr/share/doc-base/ \
  ; mv /usr/share/fontconfig /usr/share/gettext /usr/share/gtk-3.0 /exports/usr/share/

# HEROKU
FROM base AS heroku
COPY --from=node /exports/ /
RUN set -e \
  ; npm install -g 'heroku@10.0.0'
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/ \
  ; mv /usr/local/bin/heroku /exports/usr/local/bin/ \
  ; mv /usr/local/lib/node_modules/heroku /exports/usr/local/lib/node_modules/

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
  ; uv tool install sqlite-utils=='3.38' \
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
  ; uv tool install llm=='0.19.1' \
  ; ln -s /usr/local/uv/bin/llm /usr/local/bin/llm \
  ; llm install llm-claude-3
RUN set -e \
  ; mkdir -p /exports/usr/local/ /exports/usr/local/bin/ \
  ; mv /usr/local/uv /exports/usr/local/ \
  ; mv /usr/local/bin/llm /exports/usr/local/bin/

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
  ; version=$(echo "8.10.56-22" | sed 's/-/~/') \
  ; apteryx 1password="${version}.BETA"
RUN set -e \
  ; mkdir -p /exports/etc/alternatives/ /exports/etc/ /exports/etc/systemd/user/sockets.target.wants/ /exports/etc/X11/ /exports/etc/X11/Xsession.d/ /exports/opt/ /exports/usr/bin/ /exports/usr/lib/gnupg/ /exports/usr/lib/systemd/user/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/gio/modules/ /exports/usr/libexec/ /exports/usr/local/share/ /exports/usr/sbin/ /exports/usr/share/apport/package-hooks/ /exports/usr/share/bug/ /exports/usr/share/dbus-1/services/ /exports/usr/share/doc-base/ /exports/usr/share/ /exports/usr/share/glib-2.0/schemas/ /exports/usr/share/icons/ /exports/usr/share/icons/hicolor/ /exports/usr/share/icons/hicolor/48x48/ /exports/usr/share/icons/hicolor/48x48/apps/ /exports/usr/share/icons/hicolor/scalable/ /exports/usr/share/info/ /exports/usr/share/keyrings/ /exports/usr/share/polkit-1/actions/ /exports/usr/share/xml/ /exports/var/cache/ /exports/var/lib/systemd/deb-systemd-user-helper-enabled/ /exports/var/lib/systemd/deb-systemd-user-helper-enabled/sockets.target.wants/ \
  ; mv /etc/alternatives/open /etc/alternatives/open.1.gz /exports/etc/alternatives/ \
  ; mv /etc/gtk-3.0 /exports/etc/ \
  ; mv /etc/systemd/user/sockets.target.wants/keyboxd.socket /exports/etc/systemd/user/sockets.target.wants/ \
  ; mv /etc/X11/xkb /exports/etc/X11/ \
  ; mv /etc/X11/Xsession.d/20dbus_xdg-runtime /exports/etc/X11/Xsession.d/ \
  ; mv /opt/1Password /exports/opt/ \
  ; mv /usr/bin/1password /usr/bin/browse /usr/bin/gpg2 /usr/bin/gpgparsemail /usr/bin/gpgsm /usr/bin/gpgsplit /usr/bin/gpgtar /usr/bin/gtk-update-icon-cache /usr/bin/kbxutil /usr/bin/lspgpot /usr/bin/migrate-pubring-from-classic-gpg /usr/bin/open /usr/bin/update-mime-database /usr/bin/watchgnupg /usr/bin/xdg-desktop-icon /usr/bin/xdg-desktop-menu /usr/bin/xdg-email /usr/bin/xdg-icon-resource /usr/bin/xdg-mime /usr/bin/xdg-open /usr/bin/xdg-screensaver /usr/bin/xdg-settings /exports/usr/bin/ \
  ; mv /usr/lib/gnupg/gpg-pair-tool /usr/lib/gnupg/keyboxd /exports/usr/lib/gnupg/ \
  ; mv /usr/lib/systemd/user/dbus.service /usr/lib/systemd/user/dbus.socket /usr/lib/systemd/user/dconf.service /usr/lib/systemd/user/keyboxd.service /usr/lib/systemd/user/keyboxd.socket /usr/lib/systemd/user/sockets.target.wants /exports/usr/lib/systemd/user/ \
  ; mv /usr/lib/x86_64-linux-gnu/avahi /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0 /usr/lib/x86_64-linux-gnu/gtk-3.0 /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0.25209.1 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0.0.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0.0.1 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3.2.9 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3.5.4 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2.11800.0 /usr/lib/x86_64-linux-gnu/libcairo.so.2 /usr/lib/x86_64-linux-gnu/libcairo.so.2.11800.0 /usr/lib/x86_64-linux-gnu/libcolord.so.2 /usr/lib/x86_64-linux-gnu/libcolord.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcups.so.2 /usr/lib/x86_64-linux-gnu/libdatrie.so.1 /usr/lib/x86_64-linux-gnu/libdatrie.so.1.4.0 /usr/lib/x86_64-linux-gnu/libdconf.so.1 /usr/lib/x86_64-linux-gnu/libdconf.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdeflate.so.0 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0.0.0 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.1 /usr/lib/x86_64-linux-gnu/libfreebl3.chk /usr/lib/x86_64-linux-gnu/libfreebl3.so /usr/lib/x86_64-linux-gnu/libfreeblpriv3.chk /usr/lib/x86_64-linux-gnu/libfreeblpriv3.so /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.20.1 /usr/lib/x86_64-linux-gnu/libfribidi.so.0 /usr/lib/x86_64-linux-gnu/libfribidi.so.0.4.0 /usr/lib/x86_64-linux-gnu/libgbm.so.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0.4200.10 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0.2409.32 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgtk-3-0t64 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0.2409.32 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.60830.0 /usr/lib/x86_64-linux-gnu/libjbig.so.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2.0.14 /usr/lib/x86_64-linux-gnu/libLerc.so.4 /usr/lib/x86_64-linux-gnu/libnotify.so.4 /usr/lib/x86_64-linux-gnu/libnotify.so.4.0.0 /usr/lib/x86_64-linux-gnu/libnspr4.so /usr/lib/x86_64-linux-gnu/libnss3.so /usr/lib/x86_64-linux-gnu/libnssckbi.so /usr/lib/x86_64-linux-gnu/libnssdbm3.chk /usr/lib/x86_64-linux-gnu/libnssdbm3.so /usr/lib/x86_64-linux-gnu/libnssutil3.so /usr/lib/x86_64-linux-gnu/liboss4-salsa.so.2 /usr/lib/x86_64-linux-gnu/liboss4-salsa.so.2.0.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0.5200.1 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0.5200.1 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0.5200.1 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0.42.2 /usr/lib/x86_64-linux-gnu/libplc4.so /usr/lib/x86_64-linux-gnu/libplds4.so /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.43.0 /usr/lib/x86_64-linux-gnu/libsharpyuv.so.0 /usr/lib/x86_64-linux-gnu/libsharpyuv.so.0.0.1 /usr/lib/x86_64-linux-gnu/libsmime3.so /usr/lib/x86_64-linux-gnu/libsoftokn3.chk /usr/lib/x86_64-linux-gnu/libsoftokn3.so /usr/lib/x86_64-linux-gnu/libssl3.so /usr/lib/x86_64-linux-gnu/libthai.so.0 /usr/lib/x86_64-linux-gnu/libthai.so.0.3.1 /usr/lib/x86_64-linux-gnu/libtiff.so.6 /usr/lib/x86_64-linux-gnu/libtiff.so.6.0.1 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.22.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0.22.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.22.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0.22.0 /usr/lib/x86_64-linux-gnu/libwebp.so.7 /usr/lib/x86_64-linux-gnu/libwebp.so.7.1.8 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXcursor.so.1 /usr/lib/x86_64-linux-gnu/libXcursor.so.1.0.2 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libXi.so.6 /usr/lib/x86_64-linux-gnu/libXi.so.6.1.0 /usr/lib/x86_64-linux-gnu/libXinerama.so.1 /usr/lib/x86_64-linux-gnu/libXinerama.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrandr.so.2 /usr/lib/x86_64-linux-gnu/libXrandr.so.2.2.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1.0.0 /usr/lib/x86_64-linux-gnu/oss4-libsalsa /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/lib/x86_64-linux-gnu/gio/modules/giomodule.cache /usr/lib/x86_64-linux-gnu/gio/modules/libdconfsettings.so /exports/usr/lib/x86_64-linux-gnu/gio/modules/ \
  ; mv /usr/libexec/dconf-service /exports/usr/libexec/ \
  ; mv /usr/local/share/fonts /exports/usr/local/share/ \
  ; mv /usr/sbin/addgnupghome /usr/sbin/applygnupgdefaults /usr/sbin/update-icon-caches /exports/usr/sbin/ \
  ; mv /usr/share/apport/package-hooks/source_fontconfig.py /exports/usr/share/apport/package-hooks/ \
  ; mv /usr/share/bug/libgbm1 /usr/share/bug/libgtk-3-0t64 /usr/share/bug/xdg-utils /exports/usr/share/bug/ \
  ; mv /usr/share/dbus-1/services/ca.desrt.dconf.service /exports/usr/share/dbus-1/services/ \
  ; mv /usr/share/doc-base/fontconfig.fontconfig-user /usr/share/doc-base/libpng16-16t64.libpng16 /usr/share/doc-base/shared-mime-info.shared-mime-info /exports/usr/share/doc-base/ \
  ; mv /usr/share/fontconfig /usr/share/gettext /usr/share/gtk-3.0 /usr/share/libdrm /usr/share/libthai /usr/share/mime /usr/share/themes /usr/share/X11 /exports/usr/share/ \
  ; mv /usr/share/glib-2.0/schemas/gschemas.compiled /usr/share/glib-2.0/schemas/org.gtk.Settings.ColorChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.Debug.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.EmojiChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.FileChooser.gschema.xml /exports/usr/share/glib-2.0/schemas/ \
  ; mv /usr/share/icons/Adwaita /usr/share/icons/default /usr/share/icons/Humanity-Dark /usr/share/icons/Humanity /usr/share/icons/LoginIcons /usr/share/icons/ubuntu-mono-dark /usr/share/icons/ubuntu-mono-light /exports/usr/share/icons/ \
  ; mv /usr/share/icons/hicolor/128x128 /usr/share/icons/hicolor/16x16 /usr/share/icons/hicolor/192x192 /usr/share/icons/hicolor/22x22 /usr/share/icons/hicolor/24x24 /usr/share/icons/hicolor/256x256 /usr/share/icons/hicolor/32x32 /usr/share/icons/hicolor/36x36 /usr/share/icons/hicolor/512x512 /usr/share/icons/hicolor/64x64 /usr/share/icons/hicolor/72x72 /usr/share/icons/hicolor/96x96 /usr/share/icons/hicolor/icon-theme.cache /usr/share/icons/hicolor/index.theme /usr/share/icons/hicolor/symbolic /exports/usr/share/icons/hicolor/ \
  ; mv /usr/share/icons/hicolor/48x48/actions /usr/share/icons/hicolor/48x48/animations /usr/share/icons/hicolor/48x48/categories /usr/share/icons/hicolor/48x48/devices /usr/share/icons/hicolor/48x48/emblems /usr/share/icons/hicolor/48x48/emotes /usr/share/icons/hicolor/48x48/filesystems /usr/share/icons/hicolor/48x48/intl /usr/share/icons/hicolor/48x48/mimetypes /usr/share/icons/hicolor/48x48/places /usr/share/icons/hicolor/48x48/status /usr/share/icons/hicolor/48x48/stock /exports/usr/share/icons/hicolor/48x48/ \
  ; mv /usr/share/icons/hicolor/48x48/apps/1password.png /exports/usr/share/icons/hicolor/48x48/apps/ \
  ; mv /usr/share/icons/hicolor/scalable/actions /usr/share/icons/hicolor/scalable/animations /usr/share/icons/hicolor/scalable/categories /usr/share/icons/hicolor/scalable/devices /usr/share/icons/hicolor/scalable/emblems /usr/share/icons/hicolor/scalable/emotes /usr/share/icons/hicolor/scalable/filesystems /usr/share/icons/hicolor/scalable/intl /usr/share/icons/hicolor/scalable/mimetypes /usr/share/icons/hicolor/scalable/places /usr/share/icons/hicolor/scalable/status /usr/share/icons/hicolor/scalable/stock /exports/usr/share/icons/hicolor/scalable/ \
  ; mv /usr/share/info/gnupg-card-architecture.png /usr/share/info/gnupg-module-overview.png /usr/share/info/gnupg.info-1.gz /usr/share/info/gnupg.info-2.gz /usr/share/info/gnupg.info-3.gz /usr/share/info/gnupg.info.gz /exports/usr/share/info/ \
  ; mv /usr/share/keyrings/1password-archive-keyring.gpg /exports/usr/share/keyrings/ \
  ; mv /usr/share/polkit-1/actions/com.1password.1Password.policy /exports/usr/share/polkit-1/actions/ \
  ; mv /usr/share/xml/fontconfig /exports/usr/share/xml/ \
  ; mv /var/cache/fontconfig /exports/var/cache/ \
  ; mv /var/lib/systemd/deb-systemd-user-helper-enabled/keyboxd.socket.dsh-also /exports/var/lib/systemd/deb-systemd-user-helper-enabled/ \
  ; mv /var/lib/systemd/deb-systemd-user-helper-enabled/sockets.target.wants/keyboxd.socket /exports/var/lib/systemd/deb-systemd-user-helper-enabled/sockets.target.wants/

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
  ; apteryx net-tools='2.10-0.1ubuntu4'
RUN set -e \
  ; mkdir -p /exports/usr/sbin/ /exports/usr/share/man/man8/ \
  ; mv /usr/sbin/ifconfig /exports/usr/sbin/ \
  ; mv /usr/share/man/man8/ifconfig.8.gz /exports/usr/share/man/man8/

# PNPM
FROM base AS pnpm
COPY --from=node /exports/ /
RUN set -e \
  ; npm install -g 'pnpm@9.15.0'
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
  ; mkdir -p /exports/usr/include/ /exports/usr/local/bin/ /exports/usr/local/include/ /exports/usr/local/lib/ /exports/usr/local/lib/python3.12/ /exports/usr/local/ /exports/usr/local/share/ \
  ; mv /usr/include/python3.12 /exports/usr/include/ \
  ; mv /usr/local/bin/n /usr/local/bin/node /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/nvim /usr/local/bin/nvr /exports/usr/local/bin/ \
  ; mv /usr/local/include/node /exports/usr/local/include/ \
  ; mv /usr/local/lib/node_modules /exports/usr/local/lib/ \
  ; mv /usr/local/lib/python3.12/dist-packages /exports/usr/local/lib/python3.12/ \
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
  ; mkdir -p /exports/usr/include/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ /exports/usr/local/bin/ \
  ; mv /usr/include/curses.h /usr/include/cursesapp.h /usr/include/cursesf.h /usr/include/cursesm.h /usr/include/cursesp.h /usr/include/cursesw.h /usr/include/cursslk.h /usr/include/eti.h /usr/include/etip.h /usr/include/form.h /usr/include/menu.h /usr/include/ncurses_dll.h /usr/include/ncurses.h /usr/include/ncursesw /usr/include/panel.h /usr/include/term_entry.h /usr/include/term.h /usr/include/termcap.h /usr/include/unctrl.h /exports/usr/include/ \
  ; mv /usr/lib/x86_64-linux-gnu/libcurses.a /usr/lib/x86_64-linux-gnu/libcurses.so /usr/lib/x86_64-linux-gnu/libevent_core-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent_core-2.1.so.7.0.1 /usr/lib/x86_64-linux-gnu/libevent_extra-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent_extra-2.1.so.7.0.1 /usr/lib/x86_64-linux-gnu/libevent_openssl-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent_openssl-2.1.so.7.0.1 /usr/lib/x86_64-linux-gnu/libevent_pthreads-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent_pthreads-2.1.so.7.0.1 /usr/lib/x86_64-linux-gnu/libevent-2.1.so.7 /usr/lib/x86_64-linux-gnu/libevent-2.1.so.7.0.1 /usr/lib/x86_64-linux-gnu/libform.a /usr/lib/x86_64-linux-gnu/libform.so /usr/lib/x86_64-linux-gnu/libform.so.6 /usr/lib/x86_64-linux-gnu/libform.so.6.4 /usr/lib/x86_64-linux-gnu/libformw.a /usr/lib/x86_64-linux-gnu/libformw.so /usr/lib/x86_64-linux-gnu/libmenu.a /usr/lib/x86_64-linux-gnu/libmenu.so /usr/lib/x86_64-linux-gnu/libmenu.so.6 /usr/lib/x86_64-linux-gnu/libmenu.so.6.4 /usr/lib/x86_64-linux-gnu/libmenuw.a /usr/lib/x86_64-linux-gnu/libmenuw.so /usr/lib/x86_64-linux-gnu/libncurses.a /usr/lib/x86_64-linux-gnu/libncurses.so /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.6.4 /usr/lib/x86_64-linux-gnu/libncurses++.a /usr/lib/x86_64-linux-gnu/libncurses++w.a /usr/lib/x86_64-linux-gnu/libncursesw.a /usr/lib/x86_64-linux-gnu/libncursesw.so /usr/lib/x86_64-linux-gnu/libpanel.a /usr/lib/x86_64-linux-gnu/libpanel.so /usr/lib/x86_64-linux-gnu/libpanel.so.6 /usr/lib/x86_64-linux-gnu/libpanel.so.6.4 /usr/lib/x86_64-linux-gnu/libpanelw.a /usr/lib/x86_64-linux-gnu/libpanelw.so /usr/lib/x86_64-linux-gnu/libtermcap.a /usr/lib/x86_64-linux-gnu/libtermcap.so /usr/lib/x86_64-linux-gnu/libtic.a /usr/lib/x86_64-linux-gnu/libtic.so /usr/lib/x86_64-linux-gnu/libtinfo.a /usr/lib/x86_64-linux-gnu/libtinfo.so /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/lib/x86_64-linux-gnu/pkgconfig/form.pc /usr/lib/x86_64-linux-gnu/pkgconfig/formw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/menu.pc /usr/lib/x86_64-linux-gnu/pkgconfig/menuw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncurses.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncurses++.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncurses++w.pc /usr/lib/x86_64-linux-gnu/pkgconfig/ncursesw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/panel.pc /usr/lib/x86_64-linux-gnu/pkgconfig/panelw.pc /usr/lib/x86_64-linux-gnu/pkgconfig/tic.pc /usr/lib/x86_64-linux-gnu/pkgconfig/tinfo.pc /exports/usr/lib/x86_64-linux-gnu/pkgconfig/ \
  ; mv /usr/local/bin/tmux /exports/usr/local/bin/

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
  ; mkdir -p /exports/etc/ /exports/etc/default/ /exports/etc/X11/ /exports/etc/X11/Xsession.d/ /exports/opt/ /exports/usr/bin/ /exports/usr/lib/systemd/user/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/gio/modules/ /exports/usr/libexec/ /exports/usr/local/bin/ /exports/usr/local/share/ /exports/usr/sbin/ /exports/usr/share/ /exports/usr/share/applications/ /exports/usr/share/apport/package-hooks/ /exports/usr/share/bug/ /exports/usr/share/dbus-1/services/ /exports/usr/share/doc-base/ /exports/usr/share/doc/ /exports/usr/share/glib-2.0/schemas/ /exports/usr/share/icons/ /exports/usr/share/icons/hicolor/ /exports/usr/share/icons/hicolor/48x48/ /exports/usr/share/icons/hicolor/48x48/apps/ /exports/usr/share/icons/hicolor/scalable/ /exports/usr/share/info/ /exports/usr/share/lintian/overrides/ /exports/usr/share/man/man1/ /exports/usr/share/man/man5/ /exports/usr/share/man/man7/ /exports/usr/share/menu/ /exports/usr/share/pkgconfig/ \
  ; mv /etc/dconf /etc/fonts /etc/gtk-3.0 /etc/vulkan /exports/etc/ \
  ; mv /etc/default/google-chrome-beta /exports/etc/default/ \
  ; mv /etc/X11/xkb /exports/etc/X11/ \
  ; mv /etc/X11/Xsession.d/20dbus_xdg-runtime /exports/etc/X11/Xsession.d/ \
  ; mv /opt/firefox /opt/google /exports/opt/ \
  ; mv /usr/bin/google-chrome /usr/bin/google-chrome-beta /exports/usr/bin/ \
  ; mv /usr/lib/systemd/user/dbus.service /usr/lib/systemd/user/dbus.socket /usr/lib/systemd/user/dconf.service /usr/lib/systemd/user/sockets.target.wants /exports/usr/lib/systemd/user/ \
  ; mv /usr/lib/x86_64-linux-gnu/avahi /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0 /usr/lib/x86_64-linux-gnu/gtk-3.0 /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libasound.so.2.0.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0.25209.1 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0.0.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0.0.1 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3.2.9 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3.5.4 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2.11800.0 /usr/lib/x86_64-linux-gnu/libcairo.so.2 /usr/lib/x86_64-linux-gnu/libcairo.so.2.11800.0 /usr/lib/x86_64-linux-gnu/libcolord.so.2 /usr/lib/x86_64-linux-gnu/libcolord.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcups.so.2 /usr/lib/x86_64-linux-gnu/libdatrie.so.1 /usr/lib/x86_64-linux-gnu/libdatrie.so.1.4.0 /usr/lib/x86_64-linux-gnu/libdbus-glib-1.so.* /usr/lib/x86_64-linux-gnu/libdconf.so.1 /usr/lib/x86_64-linux-gnu/libdconf.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdeflate.so.0 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0.0.0 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.1 /usr/lib/x86_64-linux-gnu/libfreebl3.chk /usr/lib/x86_64-linux-gnu/libfreebl3.so /usr/lib/x86_64-linux-gnu/libfreeblpriv3.chk /usr/lib/x86_64-linux-gnu/libfreeblpriv3.so /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.20.1 /usr/lib/x86_64-linux-gnu/libfribidi.so.0 /usr/lib/x86_64-linux-gnu/libfribidi.so.0.4.0 /usr/lib/x86_64-linux-gnu/libgbm.so.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0.4200.10 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0.2409.32 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgtk-3-0t64 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0.2409.32 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.60830.0 /usr/lib/x86_64-linux-gnu/libjbig.so.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2.0.14 /usr/lib/x86_64-linux-gnu/libLerc.so.4 /usr/lib/x86_64-linux-gnu/libnspr4.so /usr/lib/x86_64-linux-gnu/libnss3.so /usr/lib/x86_64-linux-gnu/libnssckbi.so /usr/lib/x86_64-linux-gnu/libnssdbm3.chk /usr/lib/x86_64-linux-gnu/libnssdbm3.so /usr/lib/x86_64-linux-gnu/libnssutil3.so /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0.5200.1 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0.5200.1 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0.5200.1 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0.42.2 /usr/lib/x86_64-linux-gnu/libplc4.so /usr/lib/x86_64-linux-gnu/libplds4.so /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.43.0 /usr/lib/x86_64-linux-gnu/libsharpyuv.so.0 /usr/lib/x86_64-linux-gnu/libsharpyuv.so.0.0.1 /usr/lib/x86_64-linux-gnu/libsmime3.so /usr/lib/x86_64-linux-gnu/libsoftokn3.chk /usr/lib/x86_64-linux-gnu/libsoftokn3.so /usr/lib/x86_64-linux-gnu/libssl3.so /usr/lib/x86_64-linux-gnu/libthai.so.0 /usr/lib/x86_64-linux-gnu/libthai.so.0.3.1 /usr/lib/x86_64-linux-gnu/libtiff.so.6 /usr/lib/x86_64-linux-gnu/libtiff.so.6.0.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1.3.275 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.22.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0.22.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.22.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0.22.0 /usr/lib/x86_64-linux-gnu/libwebp.so.7 /usr/lib/x86_64-linux-gnu/libwebp.so.7.1.8 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXcursor.so.1 /usr/lib/x86_64-linux-gnu/libXcursor.so.1.0.2 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libXi.so.6 /usr/lib/x86_64-linux-gnu/libXi.so.6.1.0 /usr/lib/x86_64-linux-gnu/libXinerama.so.1 /usr/lib/x86_64-linux-gnu/libXinerama.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrandr.so.2 /usr/lib/x86_64-linux-gnu/libXrandr.so.2.2.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/lib/x86_64-linux-gnu/gio/modules/giomodule.cache /usr/lib/x86_64-linux-gnu/gio/modules/libdconfsettings.so /exports/usr/lib/x86_64-linux-gnu/gio/modules/ \
  ; mv /usr/libexec/dconf-service /exports/usr/libexec/ \
  ; mv /usr/local/bin/firefox /exports/usr/local/bin/ \
  ; mv /usr/local/share/fonts /exports/usr/local/share/ \
  ; mv /usr/sbin/update-icon-caches /exports/usr/sbin/ \
  ; mv /usr/share/alsa /usr/share/appdata /usr/share/fontconfig /usr/share/fonts /usr/share/gettext /usr/share/gnome-control-center /usr/share/gtk-3.0 /usr/share/libdrm /usr/share/libthai /usr/share/mime /usr/share/themes /usr/share/X11 /exports/usr/share/ \
  ; mv /usr/share/applications/firefox.desktop /usr/share/applications/google-chrome-beta.desktop /exports/usr/share/applications/ \
  ; mv /usr/share/apport/package-hooks/source_fontconfig.py /exports/usr/share/apport/package-hooks/ \
  ; mv /usr/share/bug/fonts-liberation /usr/share/bug/libgbm1 /usr/share/bug/libgtk-3-0t64 /usr/share/bug/xdg-utils /exports/usr/share/bug/ \
  ; mv /usr/share/dbus-1/services/ca.desrt.dconf.service /exports/usr/share/dbus-1/services/ \
  ; mv /usr/share/doc-base/fontconfig.fontconfig-user /usr/share/doc-base/libpng16-16t64.libpng16 /usr/share/doc-base/shared-mime-info.shared-mime-info /exports/usr/share/doc-base/ \
  ; mv /usr/share/doc/adwaita-icon-theme /usr/share/doc/at-spi2-common /usr/share/doc/dbus-user-session /usr/share/doc/dconf-gsettings-backend /usr/share/doc/dconf-service /usr/share/doc/fontconfig-config /usr/share/doc/fontconfig /usr/share/doc/fonts-liberation /usr/share/doc/google-chrome-beta /usr/share/doc/gtk-update-icon-cache /usr/share/doc/hicolor-icon-theme /usr/share/doc/humanity-icon-theme /usr/share/doc/libasound2-data /usr/share/doc/libasound2t64 /usr/share/doc/libatk-bridge2.0-0t64 /usr/share/doc/libatk1.0-0t64 /usr/share/doc/libatspi2.0-0t64 /usr/share/doc/libavahi-client3 /usr/share/doc/libavahi-common-data /usr/share/doc/libavahi-common3 /usr/share/doc/libcairo-gobject2 /usr/share/doc/libcairo2 /usr/share/doc/libcolord2 /usr/share/doc/libcups2t64 /usr/share/doc/libdatrie1 /usr/share/doc/libdconf1 /usr/share/doc/libdeflate0 /usr/share/doc/libdrm-common /usr/share/doc/libdrm2 /usr/share/doc/libepoxy0 /usr/share/doc/libfontconfig1 /usr/share/doc/libfreetype6 /usr/share/doc/libfribidi0 /usr/share/doc/libgbm1 /usr/share/doc/libgdk-pixbuf-2.0-0 /usr/share/doc/libgdk-pixbuf2.0-common /usr/share/doc/libgraphite2-3 /usr/share/doc/libgtk-3-0t64 /usr/share/doc/libgtk-3-common /usr/share/doc/libharfbuzz0b /usr/share/doc/libjbig0 /usr/share/doc/libjpeg-turbo8 /usr/share/doc/libjpeg8 /usr/share/doc/liblcms2-2 /usr/share/doc/liblerc4 /usr/share/doc/libnspr4 /usr/share/doc/libnss3 /usr/share/doc/libpango-1.0-0 /usr/share/doc/libpangocairo-1.0-0 /usr/share/doc/libpangoft2-1.0-0 /usr/share/doc/libpixman-1-0 /usr/share/doc/libpng16-16t64 /usr/share/doc/libsharpyuv0 /usr/share/doc/libthai-data /usr/share/doc/libthai0 /usr/share/doc/libtiff6 /usr/share/doc/libvulkan1 /usr/share/doc/libwayland-client0 /usr/share/doc/libwayland-cursor0 /usr/share/doc/libwayland-egl1 /usr/share/doc/libwayland-server0 /usr/share/doc/libwebp7 /usr/share/doc/libx11-6 /usr/share/doc/libx11-data /usr/share/doc/libxau6 /usr/share/doc/libxcb-randr0 /usr/share/doc/libxcb-render0 /usr/share/doc/libxcb-shm0 /usr/share/doc/libxcb1 /usr/share/doc/libxcomposite1 /usr/share/doc/libxcursor1 /usr/share/doc/libxdamage1 /usr/share/doc/libxdmcp6 /usr/share/doc/libxext6 /usr/share/doc/libxfixes3 /usr/share/doc/libxi6 /usr/share/doc/libxinerama1 /usr/share/doc/libxkbcommon0 /usr/share/doc/libxrandr2 /usr/share/doc/libxrender1 /usr/share/doc/shared-mime-info /usr/share/doc/ubuntu-mono /usr/share/doc/xdg-utils /usr/share/doc/xkb-data /exports/usr/share/doc/ \
  ; mv /usr/share/glib-2.0/schemas/gschemas.compiled /usr/share/glib-2.0/schemas/org.gtk.Settings.ColorChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.Debug.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.EmojiChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.FileChooser.gschema.xml /exports/usr/share/glib-2.0/schemas/ \
  ; mv /usr/share/icons/Adwaita /usr/share/icons/default /usr/share/icons/Humanity-Dark /usr/share/icons/Humanity /usr/share/icons/LoginIcons /usr/share/icons/ubuntu-mono-dark /usr/share/icons/ubuntu-mono-light /exports/usr/share/icons/ \
  ; mv /usr/share/icons/hicolor/128x128 /usr/share/icons/hicolor/16x16 /usr/share/icons/hicolor/192x192 /usr/share/icons/hicolor/22x22 /usr/share/icons/hicolor/24x24 /usr/share/icons/hicolor/256x256 /usr/share/icons/hicolor/32x32 /usr/share/icons/hicolor/36x36 /usr/share/icons/hicolor/512x512 /usr/share/icons/hicolor/64x64 /usr/share/icons/hicolor/72x72 /usr/share/icons/hicolor/96x96 /usr/share/icons/hicolor/icon-theme.cache /usr/share/icons/hicolor/index.theme /usr/share/icons/hicolor/symbolic /exports/usr/share/icons/hicolor/ \
  ; mv /usr/share/icons/hicolor/48x48/actions /usr/share/icons/hicolor/48x48/animations /usr/share/icons/hicolor/48x48/categories /usr/share/icons/hicolor/48x48/devices /usr/share/icons/hicolor/48x48/emblems /usr/share/icons/hicolor/48x48/emotes /usr/share/icons/hicolor/48x48/filesystems /usr/share/icons/hicolor/48x48/intl /usr/share/icons/hicolor/48x48/mimetypes /usr/share/icons/hicolor/48x48/places /usr/share/icons/hicolor/48x48/status /usr/share/icons/hicolor/48x48/stock /exports/usr/share/icons/hicolor/48x48/ \
  ; mv /usr/share/icons/hicolor/48x48/apps/google-chrome-beta.png /exports/usr/share/icons/hicolor/48x48/apps/ \
  ; mv /usr/share/icons/hicolor/scalable/actions /usr/share/icons/hicolor/scalable/animations /usr/share/icons/hicolor/scalable/categories /usr/share/icons/hicolor/scalable/devices /usr/share/icons/hicolor/scalable/emblems /usr/share/icons/hicolor/scalable/emotes /usr/share/icons/hicolor/scalable/filesystems /usr/share/icons/hicolor/scalable/intl /usr/share/icons/hicolor/scalable/mimetypes /usr/share/icons/hicolor/scalable/places /usr/share/icons/hicolor/scalable/status /usr/share/icons/hicolor/scalable/stock /exports/usr/share/icons/hicolor/scalable/ \
  ; mv /usr/share/info/wget.info.gz /exports/usr/share/info/ \
  ; mv /usr/share/lintian/overrides/adwaita-icon-theme /usr/share/lintian/overrides/dbus-user-session /usr/share/lintian/overrides/hicolor-icon-theme /usr/share/lintian/overrides/libasound2t64 /usr/share/lintian/overrides/libatk-bridge2.0-0t64 /usr/share/lintian/overrides/libatk1.0-0t64 /usr/share/lintian/overrides/libatspi2.0-0t64 /usr/share/lintian/overrides/libcairo-gobject2 /usr/share/lintian/overrides/libcups2t64 /usr/share/lintian/overrides/libgbm1 /usr/share/lintian/overrides/libgtk-3-0t64 /usr/share/lintian/overrides/libjpeg-turbo8 /usr/share/lintian/overrides/libnspr4 /usr/share/lintian/overrides/libnss3 /usr/share/lintian/overrides/libpixman-1-0 /usr/share/lintian/overrides/libpng16-16t64 /usr/share/lintian/overrides/libx11-6 /exports/usr/share/lintian/overrides/ \
  ; mv /usr/share/man/man1/dconf-service.1.gz /usr/share/man/man1/fc-cache.1.gz /usr/share/man/man1/fc-cat.1.gz /usr/share/man/man1/fc-conflist.1.gz /usr/share/man/man1/fc-list.1.gz /usr/share/man/man1/fc-match.1.gz /usr/share/man/man1/fc-pattern.1.gz /usr/share/man/man1/fc-query.1.gz /usr/share/man/man1/fc-scan.1.gz /usr/share/man/man1/fc-validate.1.gz /usr/share/man/man1/google-chrome-beta.1.gz /usr/share/man/man1/gtk-update-icon-cache.1.gz /usr/share/man/man1/open.1.gz /usr/share/man/man1/update-mime-database.1.gz /usr/share/man/man1/xdg-desktop-icon.1.gz /usr/share/man/man1/xdg-desktop-menu.1.gz /usr/share/man/man1/xdg-email.1.gz /usr/share/man/man1/xdg-icon-resource.1.gz /usr/share/man/man1/xdg-mime.1.gz /usr/share/man/man1/xdg-open.1.gz /usr/share/man/man1/xdg-screensaver.1.gz /usr/share/man/man1/xdg-settings.1.gz /exports/usr/share/man/man1/ \
  ; mv /usr/share/man/man5/Compose.5.gz /usr/share/man/man5/fonts-conf.5.gz /usr/share/man/man5/XCompose.5.gz /exports/usr/share/man/man5/ \
  ; mv /usr/share/man/man7/xkeyboard-config.7.gz /exports/usr/share/man/man7/ \
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
  ; apteryx xclip='0.13-3'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/bin/xclip /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu/libICE.so.* /usr/lib/x86_64-linux-gnu/libSM.so.* /usr/lib/x86_64-linux-gnu/libX11.so.* /usr/lib/x86_64-linux-gnu/libXau.so.* /usr/lib/x86_64-linux-gnu/libxcb.so.* /usr/lib/x86_64-linux-gnu/libXdmcp.so.* /usr/lib/x86_64-linux-gnu/libXext.so.* /usr/lib/x86_64-linux-gnu/libXmu.so.* /usr/lib/x86_64-linux-gnu/libXt.so.* /exports/usr/lib/x86_64-linux-gnu/

# REDSHIFT
FROM base AS redshift
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx redshift='1.12-4.2ubuntu4'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/ \
  ; mv /usr/bin/redshift /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu /exports/usr/lib/

# QPDFVIEW
FROM base AS qpdfview
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx qpdfview='0.5.0+ds-4build4'
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
  ; mkdir -p /exports/etc/ /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/local/share/ /exports/usr/share/applications/ /exports/usr/share/apport/package-hooks/ /exports/usr/share/bash-completion/completions/ /exports/usr/share/dbus-1/interfaces/ /exports/usr/share/dbus-1/services/ /exports/usr/share/doc-base/ /exports/usr/share/ /exports/usr/share/man/man1/ /exports/usr/share/metainfo/ \
  ; mv /etc/vulkan /exports/etc/ \
  ; mv /usr/bin/flameshot /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu/dri /usr/lib/x86_64-linux-gnu/libdouble-conversion.so.3 /usr/lib/x86_64-linux-gnu/libdouble-conversion.so.3.1 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_intel.so.1 /usr/lib/x86_64-linux-gnu/libdrm_intel.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2.0.0 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1.0.1 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libEGL_mesa.so.0 /usr/lib/x86_64-linux-gnu/libEGL_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libEGL.so.1 /usr/lib/x86_64-linux-gnu/libEGL.so.1.1.0 /usr/lib/x86_64-linux-gnu/libevdev.so.2 /usr/lib/x86_64-linux-gnu/libevdev.so.2.3.0 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.1 /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.20.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libGL.so.1 /usr/lib/x86_64-linux-gnu/libGL.so.1.7.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX_indirect.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgudev-1.0.so.0 /usr/lib/x86_64-linux-gnu/libgudev-1.0.so.0.3.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.60830.0 /usr/lib/x86_64-linux-gnu/libICE.so.6 /usr/lib/x86_64-linux-gnu/libICE.so.6.3.0 /usr/lib/x86_64-linux-gnu/libinput.so.10 /usr/lib/x86_64-linux-gnu/libinput.so.10.13.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/libLLVM-17.so /usr/lib/x86_64-linux-gnu/libLLVM-17.so.1 /usr/lib/x86_64-linux-gnu/libmd4c.so.0 /usr/lib/x86_64-linux-gnu/libmd4c.so.0.4.8 /usr/lib/x86_64-linux-gnu/libmtdev.so.1 /usr/lib/x86_64-linux-gnu/libmtdev.so.1.0.0 /usr/lib/x86_64-linux-gnu/libpciaccess.so.0 /usr/lib/x86_64-linux-gnu/libpciaccess.so.0.11.1 /usr/lib/x86_64-linux-gnu/libpcre2-16.so.0 /usr/lib/x86_64-linux-gnu/libpcre2-16.so.0.11.2 /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.43.0 /usr/lib/x86_64-linux-gnu/libQt5Core.so.5 /usr/lib/x86_64-linux-gnu/libQt5Core.so.5.15 /usr/lib/x86_64-linux-gnu/libQt5Core.so.5.15.13 /usr/lib/x86_64-linux-gnu/libQt5DBus.so.5 /usr/lib/x86_64-linux-gnu/libQt5DBus.so.5.15 /usr/lib/x86_64-linux-gnu/libQt5DBus.so.5.15.13 /usr/lib/x86_64-linux-gnu/libQt5EglFSDeviceIntegration.so.5 /usr/lib/x86_64-linux-gnu/libQt5EglFSDeviceIntegration.so.5.15 /usr/lib/x86_64-linux-gnu/libQt5EglFSDeviceIntegration.so.5.15.13 /usr/lib/x86_64-linux-gnu/libQt5EglFsKmsSupport.so.5 /usr/lib/x86_64-linux-gnu/libQt5EglFsKmsSupport.so.5.15 /usr/lib/x86_64-linux-gnu/libQt5EglFsKmsSupport.so.5.15.13 /usr/lib/x86_64-linux-gnu/libQt5Gui.so.5 /usr/lib/x86_64-linux-gnu/libQt5Gui.so.5.15 /usr/lib/x86_64-linux-gnu/libQt5Gui.so.5.15.13 /usr/lib/x86_64-linux-gnu/libQt5Network.so.5 /usr/lib/x86_64-linux-gnu/libQt5Network.so.5.15 /usr/lib/x86_64-linux-gnu/libQt5Network.so.5.15.13 /usr/lib/x86_64-linux-gnu/libQt5Svg.so.5 /usr/lib/x86_64-linux-gnu/libQt5Svg.so.5.15 /usr/lib/x86_64-linux-gnu/libQt5Svg.so.5.15.13 /usr/lib/x86_64-linux-gnu/libQt5Widgets.so.5 /usr/lib/x86_64-linux-gnu/libQt5Widgets.so.5.15 /usr/lib/x86_64-linux-gnu/libQt5Widgets.so.5.15.13 /usr/lib/x86_64-linux-gnu/libQt5XcbQpa.so.5 /usr/lib/x86_64-linux-gnu/libQt5XcbQpa.so.5.15 /usr/lib/x86_64-linux-gnu/libQt5XcbQpa.so.5.15.13 /usr/lib/x86_64-linux-gnu/libsensors.so.5 /usr/lib/x86_64-linux-gnu/libsensors.so.5.0.0 /usr/lib/x86_64-linux-gnu/libSM.so.6 /usr/lib/x86_64-linux-gnu/libSM.so.6.0.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1.3.275 /usr/lib/x86_64-linux-gnu/libwacom.so.9 /usr/lib/x86_64-linux-gnu/libwacom.so.9.0.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.22.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0.22.0 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1.0.0 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-icccm.so.4 /usr/lib/x86_64-linux-gnu/libxcb-icccm.so.4.0.0 /usr/lib/x86_64-linux-gnu/libxcb-image.so.0 /usr/lib/x86_64-linux-gnu/libxcb-image.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so.1 /usr/lib/x86_64-linux-gnu/libxcb-keysyms.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-render-util.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render-util.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shape.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-util.so.1 /usr/lib/x86_64-linux-gnu/libxcb-util.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xinerama.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xinput.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xinput.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-xkb.so.1 /usr/lib/x86_64-linux-gnu/libxcb-xkb.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libxkbcommon-x11.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon-x11.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1.0.0 /usr/lib/x86_64-linux-gnu/qt-default /usr/lib/x86_64-linux-gnu/qt5 /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/local/share/fonts /exports/usr/local/share/ \
  ; mv /usr/share/applications/org.flameshot.Flameshot.desktop /exports/usr/share/applications/ \
  ; mv /usr/share/apport/package-hooks/source_fontconfig.py /usr/share/apport/package-hooks/source_mtdev.py /exports/usr/share/apport/package-hooks/ \
  ; mv /usr/share/bash-completion/completions/flameshot /exports/usr/share/bash-completion/completions/ \
  ; mv /usr/share/dbus-1/interfaces/org.flameshot.Flameshot.xml /exports/usr/share/dbus-1/interfaces/ \
  ; mv /usr/share/dbus-1/services/org.flameshot.Flameshot.service /exports/usr/share/dbus-1/services/ \
  ; mv /usr/share/doc-base/libpng16-16t64.libpng16 /exports/usr/share/doc-base/ \
  ; mv /usr/share/flameshot /usr/share/fontconfig /usr/share/gettext /exports/usr/share/ \
  ; mv /usr/share/man/man1/flameshot.1.gz /exports/usr/share/man/man1/ \
  ; mv /usr/share/metainfo/org.flameshot.Flameshot.metainfo.xml /exports/usr/share/metainfo/

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
  ; apteryx audacity='3.4.2+dfsg-1build4'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/lib/ /exports/usr/lib/mime/packages/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/lib/x86_64-linux-gnu/gio/modules/ /exports/usr/libexec/ /exports/usr/local/share/ /exports/usr/sbin/ /exports/usr/share/ /exports/usr/share/applications/ /exports/usr/share/apport/package-hooks/ /exports/usr/share/dbus-1/services/ /exports/usr/share/doc-base/ /exports/usr/share/glib-2.0/schemas/ /exports/usr/share/man/man1/ /exports/usr/share/metainfo/ /exports/usr/share/pixmaps/ \
  ; mv /usr/bin/audacity /exports/usr/bin/ \
  ; mv /usr/lib/audacity /exports/usr/lib/ \
  ; mv /usr/lib/mime/packages/audacity /exports/usr/lib/mime/packages/ \
  ; mv /usr/lib/x86_64-linux-gnu/avahi /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0 /usr/lib/x86_64-linux-gnu/gtk-3.0 /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libasound.so.2.0.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0.25209.1 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0.0.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0 /usr/lib/x86_64-linux-gnu/libatspi.so.0.0.1 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3 /usr/lib/x86_64-linux-gnu/libavahi-client.so.3.2.9 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3 /usr/lib/x86_64-linux-gnu/libavahi-common.so.3.5.4 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2 /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2.11800.0 /usr/lib/x86_64-linux-gnu/libcairo.so.2 /usr/lib/x86_64-linux-gnu/libcairo.so.2.11800.0 /usr/lib/x86_64-linux-gnu/libcolord.so.2 /usr/lib/x86_64-linux-gnu/libcolord.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2 /usr/lib/x86_64-linux-gnu/libcolordprivate.so.2.0.5 /usr/lib/x86_64-linux-gnu/libcups.so.2 /usr/lib/x86_64-linux-gnu/libdatrie.so.1 /usr/lib/x86_64-linux-gnu/libdatrie.so.1.4.0 /usr/lib/x86_64-linux-gnu/libdconf.so.1 /usr/lib/x86_64-linux-gnu/libdconf.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdeflate.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0 /usr/lib/x86_64-linux-gnu/libepoxy.so.0.0.0 /usr/lib/x86_64-linux-gnu/libFLAC.so.12 /usr/lib/x86_64-linux-gnu/libFLAC.so.12.1.0 /usr/lib/x86_64-linux-gnu/libFLAC++.so.10 /usr/lib/x86_64-linux-gnu/libFLAC++.so.10.0.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1.12.1 /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6.20.1 /usr/lib/x86_64-linux-gnu/libfribidi.so.0 /usr/lib/x86_64-linux-gnu/libfribidi.so.0.4.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0.4200.10 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 /usr/lib/x86_64-linux-gnu/libgdk-3.so.0.2409.32 /usr/lib/x86_64-linux-gnu/libgomp.so.1 /usr/lib/x86_64-linux-gnu/libgomp.so.1.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.2.0.0 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 /usr/lib/x86_64-linux-gnu/libgraphite2.so.3.2.1 /usr/lib/x86_64-linux-gnu/libgtk-3-0t64 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 /usr/lib/x86_64-linux-gnu/libgtk-3.so.0.2409.32 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0.60830.0 /usr/lib/x86_64-linux-gnu/libICE.so.6 /usr/lib/x86_64-linux-gnu/libICE.so.6.3.0 /usr/lib/x86_64-linux-gnu/libid3tag.so.0 /usr/lib/x86_64-linux-gnu/libid3tag.so.0.3.0 /usr/lib/x86_64-linux-gnu/libjack.so.0 /usr/lib/x86_64-linux-gnu/libjack.so.0.1.0 /usr/lib/x86_64-linux-gnu/libjacknet.so.0 /usr/lib/x86_64-linux-gnu/libjacknet.so.0.1.0 /usr/lib/x86_64-linux-gnu/libjackserver.so.0 /usr/lib/x86_64-linux-gnu/libjackserver.so.0.1.0 /usr/lib/x86_64-linux-gnu/libjbig.so.0 /usr/lib/x86_64-linux-gnu/libjpeg.so.8 /usr/lib/x86_64-linux-gnu/libjpeg.so.8.2.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2.0.14 /usr/lib/x86_64-linux-gnu/libLerc.so.4 /usr/lib/x86_64-linux-gnu/liblilv-0.so.0 /usr/lib/x86_64-linux-gnu/liblilv-0.so.0.24.22 /usr/lib/x86_64-linux-gnu/libmp3lame.so.0 /usr/lib/x86_64-linux-gnu/libmp3lame.so.0.0.0 /usr/lib/x86_64-linux-gnu/libmpg123.so.0 /usr/lib/x86_64-linux-gnu/libmpg123.so.0.48.2 /usr/lib/x86_64-linux-gnu/libnotify.so.4 /usr/lib/x86_64-linux-gnu/libnotify.so.4.0.0 /usr/lib/x86_64-linux-gnu/libogg.so.0 /usr/lib/x86_64-linux-gnu/libogg.so.0.8.5 /usr/lib/x86_64-linux-gnu/libopus.so.0 /usr/lib/x86_64-linux-gnu/libopus.so.0.9.0 /usr/lib/x86_64-linux-gnu/libopusfile.so.0 /usr/lib/x86_64-linux-gnu/libopusfile.so.0.4.5 /usr/lib/x86_64-linux-gnu/libopusurl.so.0 /usr/lib/x86_64-linux-gnu/libopusurl.so.0.4.5 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0.5200.1 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0.5200.1 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0.5200.1 /usr/lib/x86_64-linux-gnu/libpcre2-32.so.0 /usr/lib/x86_64-linux-gnu/libpcre2-32.so.0.11.2 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 /usr/lib/x86_64-linux-gnu/libpixman-1.so.0.42.2 /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16.43.0 /usr/lib/x86_64-linux-gnu/libportaudio.so.2 /usr/lib/x86_64-linux-gnu/libportaudio.so.2.0.0 /usr/lib/x86_64-linux-gnu/libportmidi.so.0 /usr/lib/x86_64-linux-gnu/libportmidi.so.0.0.0 /usr/lib/x86_64-linux-gnu/libportSMF.so.0 /usr/lib/x86_64-linux-gnu/libportSMF.so.0.0.0 /usr/lib/x86_64-linux-gnu/libporttime.so.0 /usr/lib/x86_64-linux-gnu/libporttime.so.0.0.0 /usr/lib/x86_64-linux-gnu/libsamplerate.so.0 /usr/lib/x86_64-linux-gnu/libsamplerate.so.0.2.2 /usr/lib/x86_64-linux-gnu/libsbsms.so.10 /usr/lib/x86_64-linux-gnu/libsbsms.so.10.0.0 /usr/lib/x86_64-linux-gnu/libserd-0.so.0 /usr/lib/x86_64-linux-gnu/libserd-0.so.0.32.2 /usr/lib/x86_64-linux-gnu/libsharpyuv.so.0 /usr/lib/x86_64-linux-gnu/libsharpyuv.so.0.0.1 /usr/lib/x86_64-linux-gnu/libSM.so.6 /usr/lib/x86_64-linux-gnu/libSM.so.6.0.1 /usr/lib/x86_64-linux-gnu/libsndfile.so.1 /usr/lib/x86_64-linux-gnu/libsndfile.so.1.0.37 /usr/lib/x86_64-linux-gnu/libsord-0.so.0 /usr/lib/x86_64-linux-gnu/libsord-0.so.0.16.16 /usr/lib/x86_64-linux-gnu/libSoundTouch.so.1 /usr/lib/x86_64-linux-gnu/libSoundTouch.so.1.0.0 /usr/lib/x86_64-linux-gnu/libSoundTouchDll.so.1 /usr/lib/x86_64-linux-gnu/libSoundTouchDll.so.1.0.0 /usr/lib/x86_64-linux-gnu/libsoxr.so.0 /usr/lib/x86_64-linux-gnu/libsoxr.so.0.1.2 /usr/lib/x86_64-linux-gnu/libsratom-0.so.0 /usr/lib/x86_64-linux-gnu/libsratom-0.so.0.6.16 /usr/lib/x86_64-linux-gnu/libsuil-0.so.0 /usr/lib/x86_64-linux-gnu/libsuil-0.so.0.10.20 /usr/lib/x86_64-linux-gnu/libthai.so.0 /usr/lib/x86_64-linux-gnu/libthai.so.0.3.1 /usr/lib/x86_64-linux-gnu/libtiff.so.6 /usr/lib/x86_64-linux-gnu/libtiff.so.6.0.1 /usr/lib/x86_64-linux-gnu/libtwolame.so.0 /usr/lib/x86_64-linux-gnu/libtwolame.so.0.0.0 /usr/lib/x86_64-linux-gnu/libvamp-hostsdk.so.3 /usr/lib/x86_64-linux-gnu/libvamp-hostsdk.so.3.10.0 /usr/lib/x86_64-linux-gnu/libvorbis.so.0 /usr/lib/x86_64-linux-gnu/libvorbis.so.0.4.9 /usr/lib/x86_64-linux-gnu/libvorbisenc.so.2 /usr/lib/x86_64-linux-gnu/libvorbisenc.so.2.0.12 /usr/lib/x86_64-linux-gnu/libvorbisfile.so.3 /usr/lib/x86_64-linux-gnu/libvorbisfile.so.3.3.8 /usr/lib/x86_64-linux-gnu/libwavpack.so.1 /usr/lib/x86_64-linux-gnu/libwavpack.so.1.2.5 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.22.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0 /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0.22.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.22.0 /usr/lib/x86_64-linux-gnu/libwebp.so.7 /usr/lib/x86_64-linux-gnu/libwebp.so.7.1.8 /usr/lib/x86_64-linux-gnu/libwx_baseu_net-3.2.so.0 /usr/lib/x86_64-linux-gnu/libwx_baseu_net-3.2.so.0.2.2 /usr/lib/x86_64-linux-gnu/libwx_baseu_xml-3.2.so.0 /usr/lib/x86_64-linux-gnu/libwx_baseu_xml-3.2.so.0.2.2 /usr/lib/x86_64-linux-gnu/libwx_baseu-3.2.so.0 /usr/lib/x86_64-linux-gnu/libwx_baseu-3.2.so.0.2.2 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_adv-3.2.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_adv-3.2.so.0.2.2 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_aui-3.2.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_aui-3.2.so.0.2.2 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_core-3.2.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_core-3.2.so.0.2.2 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_html-3.2.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_html-3.2.so.0.2.2 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_propgrid-3.2.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_propgrid-3.2.so.0.2.2 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_qa-3.2.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_qa-3.2.so.0.2.2 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_ribbon-3.2.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_ribbon-3.2.so.0.2.2 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_richtext-3.2.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_richtext-3.2.so.0.2.2 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_stc-3.2.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_stc-3.2.so.0.2.2 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_xrc-3.2.so.0 /usr/lib/x86_64-linux-gnu/libwx_gtk3u_xrc-3.2.so.0.2.2 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 /usr/lib/x86_64-linux-gnu/libxcb-render.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1 /usr/lib/x86_64-linux-gnu/libXcomposite.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXcursor.so.1 /usr/lib/x86_64-linux-gnu/libXcursor.so.1.0.2 /usr/lib/x86_64-linux-gnu/libXdamage.so.1 /usr/lib/x86_64-linux-gnu/libXdamage.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libXi.so.6 /usr/lib/x86_64-linux-gnu/libXi.so.6.1.0 /usr/lib/x86_64-linux-gnu/libXinerama.so.1 /usr/lib/x86_64-linux-gnu/libXinerama.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libXrandr.so.2 /usr/lib/x86_64-linux-gnu/libXrandr.so.2.2.0 /usr/lib/x86_64-linux-gnu/libXrender.so.1 /usr/lib/x86_64-linux-gnu/libXrender.so.1.3.0 /usr/lib/x86_64-linux-gnu/libXtst.so.6 /usr/lib/x86_64-linux-gnu/libXtst.so.6.1.0 /usr/lib/x86_64-linux-gnu/libzix-0.so.0 /usr/lib/x86_64-linux-gnu/libzix-0.so.0.4.2 /usr/lib/x86_64-linux-gnu/suil-0 /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/lib/x86_64-linux-gnu/gio/modules/giomodule.cache /usr/lib/x86_64-linux-gnu/gio/modules/libdconfsettings.so /exports/usr/lib/x86_64-linux-gnu/gio/modules/ \
  ; mv /usr/libexec/dconf-service /exports/usr/libexec/ \
  ; mv /usr/local/share/fonts /exports/usr/local/share/ \
  ; mv /usr/sbin/update-icon-caches /exports/usr/sbin/ \
  ; mv /usr/share/alsa /usr/share/audacity /usr/share/fontconfig /usr/share/gettext /usr/share/gtk-3.0 /usr/share/libthai /usr/share/themes /exports/usr/share/ \
  ; mv /usr/share/applications/audacity.desktop /exports/usr/share/applications/ \
  ; mv /usr/share/apport/package-hooks/source_audacity.py /usr/share/apport/package-hooks/source_fontconfig.py /exports/usr/share/apport/package-hooks/ \
  ; mv /usr/share/dbus-1/services/ca.desrt.dconf.service /exports/usr/share/dbus-1/services/ \
  ; mv /usr/share/doc-base/libpng16-16t64.libpng16 /exports/usr/share/doc-base/ \
  ; mv /usr/share/glib-2.0/schemas/gschemas.compiled /usr/share/glib-2.0/schemas/org.gtk.Settings.ColorChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.Debug.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.EmojiChooser.gschema.xml /usr/share/glib-2.0/schemas/org.gtk.Settings.FileChooser.gschema.xml /exports/usr/share/glib-2.0/schemas/ \
  ; mv /usr/share/man/man1/audacity.1.gz /usr/share/man/man1/dconf-service.1.gz /usr/share/man/man1/gtk-update-icon-cache.1.gz /exports/usr/share/man/man1/ \
  ; mv /usr/share/metainfo/audacity.appdata.xml /exports/usr/share/metainfo/ \
  ; mv /usr/share/pixmaps/audacity16.xpm /usr/share/pixmaps/audacity32.xpm /usr/share/pixmaps/gnome-mime-application-x-audacity-project.xpm /exports/usr/share/pixmaps/

# ALACRITTY
FROM base AS alacritty
COPY --from=clone /exports/ /
COPY --from=rust /exports/ /
ENV \
  PATH=/root/.cargo/bin:$PATH
RUN set -e \
  ; packages="cmake g++ pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3" \
  ; apt-get -q update \
  ; apt-get install -y --no-install-recommends --auto-remove $packages \
  ; clone --https --tag='v0.14.0' https://github.com/alacritty/alacritty \
  ; cd /root/src/github.com/alacritty/alacritty \
  ; cargo build --release --no-default-features --features=x11 \
  ; mv target/release/alacritty /usr/local/bin/alacritty \
  ; rm -r /root/src/ \
  ; apt-get remove --purge -y $packages \
  ; apt-get -q clean
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/local/bin/ \
  ; mv /usr/bin/x86_64-linux-gnu-addr2line /usr/bin/x86_64-linux-gnu-ar /usr/bin/x86_64-linux-gnu-as /usr/bin/x86_64-linux-gnu-c++filt /usr/bin/x86_64-linux-gnu-cpp /usr/bin/x86_64-linux-gnu-cpp-13 /usr/bin/x86_64-linux-gnu-dwp /usr/bin/x86_64-linux-gnu-elfedit /usr/bin/x86_64-linux-gnu-g++ /usr/bin/x86_64-linux-gnu-g++-13 /usr/bin/x86_64-linux-gnu-gcc /usr/bin/x86_64-linux-gnu-gcc-13 /usr/bin/x86_64-linux-gnu-gcc-ar /usr/bin/x86_64-linux-gnu-gcc-ar-13 /usr/bin/x86_64-linux-gnu-gcc-nm /usr/bin/x86_64-linux-gnu-gcc-nm-13 /usr/bin/x86_64-linux-gnu-gcc-ranlib /usr/bin/x86_64-linux-gnu-gcc-ranlib-13 /usr/bin/x86_64-linux-gnu-gcov /usr/bin/x86_64-linux-gnu-gcov-13 /usr/bin/x86_64-linux-gnu-gcov-dump /usr/bin/x86_64-linux-gnu-gcov-dump-13 /usr/bin/x86_64-linux-gnu-gcov-tool /usr/bin/x86_64-linux-gnu-gcov-tool-13 /usr/bin/x86_64-linux-gnu-gold /usr/bin/x86_64-linux-gnu-gp-archive /usr/bin/x86_64-linux-gnu-gp-collect-app /usr/bin/x86_64-linux-gnu-gp-display-html /usr/bin/x86_64-linux-gnu-gp-display-src /usr/bin/x86_64-linux-gnu-gp-display-text /usr/bin/x86_64-linux-gnu-gprof /usr/bin/x86_64-linux-gnu-gprofng /usr/bin/x86_64-linux-gnu-ld /usr/bin/x86_64-linux-gnu-ld.bfd /usr/bin/x86_64-linux-gnu-ld.gold /usr/bin/x86_64-linux-gnu-lto-dump /usr/bin/x86_64-linux-gnu-lto-dump-13 /usr/bin/x86_64-linux-gnu-nm /usr/bin/x86_64-linux-gnu-objcopy /usr/bin/x86_64-linux-gnu-objdump /usr/bin/x86_64-linux-gnu-pkg-config /usr/bin/x86_64-linux-gnu-pkgconf /usr/bin/x86_64-linux-gnu-ranlib /usr/bin/x86_64-linux-gnu-readelf /usr/bin/x86_64-linux-gnu-size /usr/bin/x86_64-linux-gnu-strings /usr/bin/x86_64-linux-gnu-strip /exports/usr/bin/ \
  ; mv /usr/local/bin/alacritty /exports/usr/local/bin/

# URLVIEW
FROM base AS urlview
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx urlview='1c-1'
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
  ; apteryx xinput='1.6.4-1build1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ \
  ; mv /usr/bin/xinput /exports/usr/bin/

# TREE
FROM base AS tree
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx tree='2.1.1-2ubuntu3'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man1/ \
  ; mv /usr/bin/tree /exports/usr/bin/ \
  ; mv /usr/share/doc/tree /exports/usr/share/doc/ \
  ; mv /usr/share/man/man1/tree.1.gz /exports/usr/share/man/man1/

# SUDO
FROM base AS sudo
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx sudo='1.9.15p5-3ubuntu5'
RUN set -e \
  ; mkdir -p /exports/etc/pam.d/ /exports/etc/ /exports/run/ /exports/usr/bin/ /exports/usr/include/ /exports/usr/lib/systemd/system/ /exports/usr/lib/tmpfiles.d/ /exports/usr/libexec/ /exports/usr/sbin/ /exports/usr/share/apport/package-hooks/ \
  ; mv /etc/pam.d/sudo /etc/pam.d/sudo-i /exports/etc/pam.d/ \
  ; mv /etc/sudo_logsrvd.conf /etc/sudo.conf /etc/sudoers /etc/sudoers.d /exports/etc/ \
  ; mv /run/sudo /exports/run/ \
  ; mv /usr/bin/cvtsudoers /usr/bin/sudo /usr/bin/sudoedit /usr/bin/sudoreplay /exports/usr/bin/ \
  ; mv /usr/include/sudo_plugin.h /exports/usr/include/ \
  ; mv /usr/lib/systemd/system/sudo.service /exports/usr/lib/systemd/system/ \
  ; mv /usr/lib/tmpfiles.d/sudo.conf /exports/usr/lib/tmpfiles.d/ \
  ; mv /usr/libexec/sudo /exports/usr/libexec/ \
  ; mv /usr/sbin/sudo_logsrvd /usr/sbin/sudo_sendlog /usr/sbin/visudo /exports/usr/sbin/ \
  ; mv /usr/share/apport/package-hooks/source_sudo.py /exports/usr/share/apport/package-hooks/

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
  ; apteryx rsync='3.2.7-1ubuntu1'
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
  ; npm install -g 'npm-check-updates@17.1.11'
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/ \
  ; mv /usr/local/bin/ncu /exports/usr/local/bin/ \
  ; mv /usr/local/lib/node_modules/npm-check-updates /exports/usr/local/lib/node_modules/

# MOREUTILS
FROM base AS moreutils
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx moreutils='0.69-1'
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
  ; apteryx mediainfo='24.01.1-1build2'
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

# LIBGLIB
FROM base AS libglib
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx libglib2.0-bin='2.80.0-6ubuntu3.2'
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
  ; uv tool install httpie=='3.2.4' \
  ; ln -s /usr/local/uv/bin/http /usr/local/bin/http
RUN set -e \
  ; mkdir -p /exports/usr/local/ /exports/usr/local/bin/ \
  ; mv /usr/local/uv /exports/usr/local/ \
  ; mv /usr/local/bin/http /exports/usr/local/bin/

# HTOP
FROM base AS htop
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx htop='3.3.0-4build1'
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
  ; wget -O /tmp/gh.tgz 'https://github.com/cli/cli/releases/download/v2.63.2/gh_2.63.2_linux_amd64.tar.gz' \
  ; tar xzvf /tmp/gh.tgz \
  ; rm /tmp/gh.tgz \
  ; mv 'gh_2.63.2_linux_amd64/bin/gh' /usr/local/bin/gh \
  ; rm -r 'gh_2.63.2_linux_amd64'
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/gh /exports/usr/local/bin/

# FILE
FROM base AS file
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx file='1:5.45-3build1'
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
  ; wget -O /usr/local/lib/docker/cli-plugins/docker-compose 'https://github.com/docker/compose/releases/download/v2.32.1/docker-compose-linux-x86_64' \
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
  ; apteryx docker-ce-cli='5:27.4.1*'
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
  ; apteryx bsdmainutils='12.1.8'
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
  ; wget -O /tmp/autotag.tgz "https://github.com/pantheon-systems/autotag/releases/download/v1.3.37/autotag_linux_amd64.tar.gz" \
  ; tar xzvf /tmp/autotag.tgz autotag \
  ; mv autotag /usr/local/bin/autotag \
  ; rm /tmp/autotag.tgz
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/autotag /exports/usr/local/bin/

# ALSA-UTILS
FROM base AS alsa-utils
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx alsa-utils='1.2.9-1ubuntu5'
RUN set -e \
  ; mkdir -p /exports/etc/ /exports/etc/init.d/ /exports/etc/rc0.d/ /exports/etc/rc1.d/ /exports/etc/rc6.d/ /exports/etc/rcS.d/ /exports/usr/bin/ /exports/usr/lib/modprobe.d/ /exports/usr/lib/systemd/system/ /exports/usr/lib/udev/rules.d/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/sbin/ /exports/usr/share/ /exports/usr/share/bash-completion/completions/ /exports/usr/share/doc/ /exports/usr/share/doc/libkmod2/ /exports/usr/share/lintian/overrides/ /exports/var/cache/ldconfig/ /exports/var/lib/ \
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
  ; mv /usr/lib/x86_64-linux-gnu/alsa-topology /usr/lib/x86_64-linux-gnu/libasound.so.2 /usr/lib/x86_64-linux-gnu/libasound.so.2.0.0 /usr/lib/x86_64-linux-gnu/libatopology.so.2 /usr/lib/x86_64-linux-gnu/libatopology.so.2.0.0 /usr/lib/x86_64-linux-gnu/libfftw3f_omp.so.3 /usr/lib/x86_64-linux-gnu/libfftw3f_omp.so.3.6.10 /usr/lib/x86_64-linux-gnu/libfftw3f_threads.so.3 /usr/lib/x86_64-linux-gnu/libfftw3f_threads.so.3.6.10 /usr/lib/x86_64-linux-gnu/libfftw3f.so.3 /usr/lib/x86_64-linux-gnu/libfftw3f.so.3.6.10 /usr/lib/x86_64-linux-gnu/libgomp.so.1 /usr/lib/x86_64-linux-gnu/libgomp.so.1.0.0 /usr/lib/x86_64-linux-gnu/libsamplerate.so.0 /usr/lib/x86_64-linux-gnu/libsamplerate.so.0.2.2 /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/sbin/alsa-info /usr/sbin/alsabat-test /usr/sbin/alsactl /usr/sbin/depmod /usr/sbin/insmod /usr/sbin/lsmod /usr/sbin/modinfo /usr/sbin/modprobe /usr/sbin/rmmod /exports/usr/sbin/ \
  ; mv /usr/share/alsa /usr/share/initramfs-tools /usr/share/sounds /exports/usr/share/ \
  ; mv /usr/share/bash-completion/completions/kmod /exports/usr/share/bash-completion/completions/ \
  ; mv /usr/share/doc/alsa-utils /usr/share/doc/kmod /usr/share/doc/libasound2-data /usr/share/doc/libasound2t64 /usr/share/doc/libatopology2t64 /usr/share/doc/libfftw3-single3 /usr/share/doc/libgomp1 /usr/share/doc/libsamplerate0 /exports/usr/share/doc/ \
  ; mv /usr/share/doc/libkmod2/README.md /usr/share/doc/libkmod2/TODO /exports/usr/share/doc/libkmod2/ \
  ; mv /usr/share/lintian/overrides/libasound2t64 /usr/share/lintian/overrides/libatopology2t64 /exports/usr/share/lintian/overrides/ \
  ; mv /var/cache/ldconfig/aux-cache /exports/var/cache/ldconfig/ \
  ; mv /var/lib/alsa /exports/var/lib/

# ACPI
FROM base AS acpi
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx acpi='1.7-1.3build1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ \
  ; mv /usr/bin/acpi /exports/usr/bin/

# X11-UTILS
FROM base AS x11-utils
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx x11-utils='7.7+6build2' x11-xkb-utils x11-xserver-utils xkb-data
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
  ; apteryx mesa-utils='9.0.0-2' mesa-utils-extra
RUN set -e \
  ; mkdir -p /exports/etc/ /exports/etc/X11/ /exports/usr/bin/ /exports/usr/lib/x86_64-linux-gnu/ /exports/usr/share/ /exports/usr/share/pkgconfig/ \
  ; mv /etc/vulkan /exports/etc/ \
  ; mv /etc/X11/xkb /exports/etc/X11/ \
  ; mv /usr/bin/eglgears_wayland /usr/bin/eglgears_wayland.x86_64-linux-gnu /usr/bin/eglgears_x11 /usr/bin/eglgears_x11.x86_64-linux-gnu /usr/bin/eglinfo /usr/bin/eglinfo.x86_64-linux-gnu /usr/bin/egltri_wayland /usr/bin/egltri_wayland.x86_64-linux-gnu /usr/bin/egltri_x11 /usr/bin/egltri_x11.x86_64-linux-gnu /usr/bin/es2_info /usr/bin/es2_info.x86_64-linux-gnu /usr/bin/es2gears_wayland /usr/bin/es2gears_wayland.x86_64-linux-gnu /usr/bin/es2gears_x11 /usr/bin/es2gears_x11.x86_64-linux-gnu /usr/bin/es2tri /usr/bin/es2tri.x86_64-linux-gnu /usr/bin/glxdemo /usr/bin/glxdemo.x86_64-linux-gnu /usr/bin/glxgears /usr/bin/glxgears.x86_64-linux-gnu /usr/bin/glxheads /usr/bin/glxheads.x86_64-linux-gnu /usr/bin/glxinfo /usr/bin/glxinfo.x86_64-linux-gnu /usr/bin/peglgears /usr/bin/peglgears.x86_64-linux-gnu /usr/bin/vkgears /usr/bin/vkgears.x86_64-linux-gnu /usr/bin/xeglgears /usr/bin/xeglgears.x86_64-linux-gnu /usr/bin/xeglthreads /usr/bin/xeglthreads.x86_64-linux-gnu /exports/usr/bin/ \
  ; mv /usr/lib/x86_64-linux-gnu/dri /usr/lib/x86_64-linux-gnu/libdecor-0.so.0 /usr/lib/x86_64-linux-gnu/libdecor-0.so.0.200.2 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1 /usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_intel.so.1 /usr/lib/x86_64-linux-gnu/libdrm_intel.so.1.0.0 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2 /usr/lib/x86_64-linux-gnu/libdrm_nouveau.so.2.0.0 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1 /usr/lib/x86_64-linux-gnu/libdrm_radeon.so.1.0.1 /usr/lib/x86_64-linux-gnu/libdrm.so.2 /usr/lib/x86_64-linux-gnu/libdrm.so.2.4.0 /usr/lib/x86_64-linux-gnu/libEGL_mesa.so.0 /usr/lib/x86_64-linux-gnu/libEGL_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libEGL.so.1 /usr/lib/x86_64-linux-gnu/libEGL.so.1.1.0 /usr/lib/x86_64-linux-gnu/libgbm.so.1 /usr/lib/x86_64-linux-gnu/libgbm.so.1.0.0 /usr/lib/x86_64-linux-gnu/libGL.so.1 /usr/lib/x86_64-linux-gnu/libGL.so.1.7.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0 /usr/lib/x86_64-linux-gnu/libglapi.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0 /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLESv2.so.2 /usr/lib/x86_64-linux-gnu/libGLESv2.so.2.1.0 /usr/lib/x86_64-linux-gnu/libGLX_indirect.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0 /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0.0.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0 /usr/lib/x86_64-linux-gnu/libGLX.so.0.0.0 /usr/lib/x86_64-linux-gnu/libLLVM-17.so /usr/lib/x86_64-linux-gnu/libLLVM-17.so.1 /usr/lib/x86_64-linux-gnu/libpciaccess.so.0 /usr/lib/x86_64-linux-gnu/libpciaccess.so.0.11.1 /usr/lib/x86_64-linux-gnu/libsensors.so.5 /usr/lib/x86_64-linux-gnu/libsensors.so.5.0.0 /usr/lib/x86_64-linux-gnu/libvulkan.so.1 /usr/lib/x86_64-linux-gnu/libvulkan.so.1.3.275 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 /usr/lib/x86_64-linux-gnu/libwayland-client.so.0.22.0 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1.22.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0 /usr/lib/x86_64-linux-gnu/libwayland-server.so.0.22.0 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1 /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1.0.0 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri2.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0 /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0 /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0 /usr/lib/x86_64-linux-gnu/libxcb-present.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0 /usr/lib/x86_64-linux-gnu/libxcb-randr.so.0.1.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1 /usr/lib/x86_64-linux-gnu/libxcb-sync.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0 /usr/lib/x86_64-linux-gnu/libxcb-xfixes.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxcb-xkb.so.1 /usr/lib/x86_64-linux-gnu/libxcb-xkb.so.1.0.0 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6.0.0 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6.4.0 /usr/lib/x86_64-linux-gnu/libXfixes.so.3 /usr/lib/x86_64-linux-gnu/libXfixes.so.3.1.0 /usr/lib/x86_64-linux-gnu/libxkbcommon-x11.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon-x11.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0.0.0 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1 /usr/lib/x86_64-linux-gnu/libxshmfence.so.1.0.0 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1 /usr/lib/x86_64-linux-gnu/libXxf86vm.so.1.0.0 /exports/usr/lib/x86_64-linux-gnu/ \
  ; mv /usr/share/drirc.d /usr/share/glvnd /usr/share/libdrm /usr/share/mesa-demos /usr/share/X11 /exports/usr/share/ \
  ; mv /usr/share/pkgconfig/xkeyboard-config.pc /exports/usr/share/pkgconfig/

# LIBXV1
FROM base AS libxv1
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx libxv1='2:1.0.11-1.1build1'
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
COPY --from=bandwhich /exports/ /
COPY --from=caddy /exports/ /
COPY --from=llm /exports/ /
COPY --from=strip-tags /exports/ /
COPY --from=ttok /exports/ /
COPY --from=sqlite-utils /exports/ /
COPY --from=heroku /exports/ /
COPY --from=brave /exports/ /
COPY --from=rofi /exports/ /
COPY --from=exa /exports/ /
COPY --from=zoxide /exports/ /
COPY --from=bun /exports/ /
COPY --from=rip /exports/ /
COPY --from=gosee /exports/ /
COPY --from=fonts /exports/ /
COPY --from=yq /exports/ /
COPY --from=xcolor /exports/ /
COPY --from=jo /exports/ /
COPY --from=sleek /exports/ /
COPY --from=oha /exports/ /
COPY --from=lazygit /exports/ /
COPY --from=gifski /exports/ /
COPY --from=ast-grep /exports/ /
COPY --from=jujutsu /exports/ /
COPY --from=hey /exports/ /
COPY --from=ffmpeg /exports/ /
COPY --from=yt-dlp /exports/ /
COPY --from=curlie /exports/ /
COPY --from=cloudflared /exports/ /
COPY --from=files-to-prompt /exports/ /
COPY --from=miller /exports/ /
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


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

# GIT
FROM base AS git
COPY --from=apteryx /exports/ /
RUN set -e \
  ; add-apt-repository ppa:git-core/ppa \
  ; apteryx git='1:2.49.0-2~ppa1~ubuntu24.04.1'
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
  ; wget -O /tmp/go.tgz "https://dl.google.com/go/go1.24.3.linux-amd64.tar.gz" \
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
  ; clone --https --tag='v1.110.2' https://github.com/stayradiated/dotfiles \
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
  ; wget "https://raw.githubusercontent.com/tj/n/v10.2.0/bin/n" -O /usr/local/bin/n \
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

# UV
FROM base AS uv
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/uv.tgz 'https://github.com/astral-sh/uv/releases/download/0.7.8/uv-x86_64-unknown-linux-gnu.tar.gz' \
  ; tar -xzvf /tmp/uv.tgz -C /tmp \
  ; rm /tmp/uv.tgz \
  ; mv /tmp/uv-x86_64-unknown-linux-gnu/uv /tmp/uv-x86_64-unknown-linux-gnu/uvx /usr/local/bin/ \
  ; rmdir /tmp/uv-x86_64-unknown-linux-gnu \
  ; mkdir -p /usr/local/uv/tools /usr/local/uv/bin /usr/local/uv/python
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/ \
  ; mv /usr/local/bin/uv /usr/local/bin/uvx /exports/usr/local/bin/ \
  ; mv /usr/local/uv /exports/usr/local/

# NODE
FROM base AS node
COPY --from=n /exports/ /
RUN set -e \
  ; n lts \
  ; n v24.1.0 \
  ; npm install -g npm
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/include/ /exports/usr/local/lib/ /exports/usr/local/ \
  ; mv /usr/local/bin/n /usr/local/bin/node /usr/local/bin/npm /usr/local/bin/npx /exports/usr/local/bin/ \
  ; mv /usr/local/include/node /exports/usr/local/include/ \
  ; mv /usr/local/lib/node_modules /exports/usr/local/lib/ \
  ; mv /usr/local/n /exports/usr/local/

# FZF
FROM base AS fzf
COPY --from=clone /exports/ /
RUN set -e \
  ; clone --https --tag='v0.62.0' https://github.com/junegunn/fzf \
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
  ; wget -O /tmp/nvim.appimage 'https://github.com/neovim/neovim/releases/download/v0.11.1/nvim-linux-x86_64.appimage' \
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

# RUST
FROM base AS rust
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O rust.sh 'https://sh.rustup.rs' \
  ; sh rust.sh -y --default-toolchain '1.87.0' \
  ; rm rust.sh
RUN set -e \
  ; mkdir -p /exports/root/ \
  ; mv /root/.cargo /root/.rustup /exports/root/

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

# UNZIP
FROM base AS unzip
COPY --from=apteryx /exports/ /
RUN set -e \
  ; apteryx unzip='6.0-28ubuntu4.1'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/share/man/man1/ \
  ; mv /usr/bin/unzip /exports/usr/bin/ \
  ; mv /usr/share/man/man1/unzip.1.gz /exports/usr/share/man/man1/

# ZOXIDE
FROM base AS zoxide
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/zoxide.tar.gz "https://github.com/ajeetdsouza/zoxide/releases/download/v0.9.8/zoxide-0.9.8-x86_64-unknown-linux-musl.tar.gz" \
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

# SAFE-RM
FROM base AS safe-rm
COPY --from=clone /exports/ /
RUN set -e \
  ; clone --https --tag='1.0.7' https://github.com/kaelzhang/shell-safe-rm \
  ; cd /root/src/github.com/kaelzhang/shell-safe-rm \
  ; cp ./bin/rm.sh /usr/local/bin/safe-rm \
  ; rm -rf /root/src/
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/safe-rm /exports/usr/local/bin/

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

# PRETTYPING
FROM base AS prettyping
COPY --from=wget /exports/ /
COPY --from=ping /exports/ /
RUN set -e \
  ; wget -O /usr/local/bin/prettyping 'https://raw.githubusercontent.com/denilsonsa/prettyping/v1.1.0/prettyping' \
  ; chmod +x /usr/local/bin/prettyping
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/local/bin/ /exports/usr/share/doc/ /exports/usr/share/man/man8/ \
  ; mv /usr/bin/ping /usr/bin/ping4 /usr/bin/ping6 /exports/usr/bin/ \
  ; mv /usr/local/bin/prettyping /exports/usr/local/bin/ \
  ; mv /usr/share/doc/iputils-ping /exports/usr/share/doc/ \
  ; mv /usr/share/man/man8/ping.8.gz /usr/share/man/man8/ping4.8.gz /usr/share/man/man8/ping6.8.gz /exports/usr/share/man/man8/

# PNPM
FROM base AS pnpm
COPY --from=node /exports/ /
RUN set -e \
  ; npm install -g 'pnpm@10.11.0'
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/ \
  ; mv /usr/local/bin/pnpm /usr/local/bin/pnpx /exports/usr/local/bin/ \
  ; mv /usr/local/lib/node_modules/pnpm /exports/usr/local/lib/node_modules/

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
  ; uv tool install pgcli=='4.3.0' \
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
  ; npm install -g 'npm-check-updates@18.0.1'
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
  ; uv tool install llm=='0.26' \
  ; ln -s /usr/local/uv/bin/llm /usr/local/bin/llm \
  ; llm install llm-anthropic
RUN set -e \
  ; mkdir -p /exports/usr/local/ /exports/usr/local/bin/ \
  ; mv /usr/local/uv /exports/usr/local/ \
  ; mv /usr/local/bin/llm /exports/usr/local/bin/

# LAZYJJ
FROM base AS lazyjj
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/lazyjj.tgz 'https://github.com/Cretezy/lazyjj/releases/download/v0.5.0/lazyjj-v0.5.0-x86_64-unknown-linux-musl.tar.gz' \
  ; mkdir -p /tmp/lazyjj \
  ; tar xzvf /tmp/lazyjj.tgz -C /tmp/lazyjj \
  ; mv /tmp/lazyjj/lazyjj /usr/local/bin \
  ; rm -r /tmp/lazyjj /tmp/lazyjj.tgz
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/lazyjj /exports/usr/local/bin/

# LAZYGIT
FROM base AS lazygit
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/lazygit.tgz 'https://github.com/jesseduffield/lazygit/releases/download/v0.51.1/lazygit_0.51.1_Linux_x86_64.tar.gz' \
  ; mkdir -p /tmp/lazygit \
  ; tar xzvf /tmp/lazygit.tgz -C /tmp/lazygit \
  ; mv /tmp/lazygit/lazygit /usr/local/bin \
  ; rm -r /tmp/lazygit /tmp/lazygit.tgz
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/lazygit /exports/usr/local/bin/

# LAZYCOMMIT
FROM base AS lazycommit
COPY --from=wget /exports/ /
RUN set -e \
  ; wget --no-hsts -O /tmp/lazycommit.tgz 'https://github.com/stayradiated/lazycommit/releases/download/v1.0.3/lazycommit_1.0.3_linux_amd64.tar.gz' \
  ; mkdir -p /tmp/lazycommit \
  ; tar xzvf /tmp/lazycommit.tgz -C /tmp/lazycommit \
  ; mv /tmp/lazycommit/lazycommit /usr/local/bin \
  ; rm -r /tmp/lazycommit /tmp/lazycommit.tgz
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/lazycommit /exports/usr/local/bin/

# JUJUTSU
FROM base AS jujutsu
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O /tmp/jj.tgz 'https://github.com/martinvonz/jj/releases/download/v0.29.0/jj-v0.29.0-x86_64-unknown-linux-musl.tar.gz' \
  ; tar xzvf /tmp/jj.tgz \
  ; rm /tmp/jj.tgz \
  ; mv 'jj' /usr/local/bin/jj
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/jj /exports/usr/local/bin/

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
  ; wget -O /tmp/gh.tgz 'https://github.com/cli/cli/releases/download/v2.73.0/gh_2.73.0_linux_amd64.tar.gz' \
  ; tar xzvf /tmp/gh.tgz \
  ; rm /tmp/gh.tgz \
  ; mv 'gh_2.73.0_linux_amd64/bin/gh' /usr/local/bin/gh \
  ; rm -r 'gh_2.73.0_linux_amd64'
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/gh /exports/usr/local/bin/

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
  ; uv tool install files-to-prompt=='0.6' \
  ; ln -s /usr/local/uv/bin/files-to-prompt /usr/local/bin/files-to-prompt
RUN set -e \
  ; mkdir -p /exports/usr/local/ /exports/usr/local/bin/ \
  ; mv /usr/local/uv /exports/usr/local/ \
  ; mv /usr/local/bin/files-to-prompt /exports/usr/local/bin/

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
  ; apteryx docker-ce-cli='5:28.2.1*'
RUN set -e \
  ; mkdir -p /exports/usr/bin/ /exports/usr/share/zsh/vendor-completions/ \
  ; mv /usr/bin/docker /exports/usr/bin/ \
  ; mv /usr/share/zsh/vendor-completions/_docker /exports/usr/share/zsh/vendor-completions/

# CLAUDE-CODE
FROM base AS claude-code
COPY --from=node /exports/ /
RUN set -e \
  ; npm install -g '@anthropic-ai/claude-code@1.0.3'
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ /exports/usr/local/lib/node_modules/@anthropic-ai/ \
  ; mv /usr/local/bin/claude /exports/usr/local/bin/ \
  ; mv /usr/local/lib/node_modules/@anthropic-ai/claude-code /exports/usr/local/lib/node_modules/@anthropic-ai/

# BAT
FROM base AS bat
COPY --from=wget /exports/ /
RUN set -e \
  ; wget -O bat.tgz 'https://github.com/sharkdp/bat/releases/download/v0.25.0/bat-v0.25.0-x86_64-unknown-linux-gnu.tar.gz' \
  ; tar -xzvf bat.tgz \
  ; rm bat.tgz \
  ; mv 'bat-v0.25.0-x86_64-unknown-linux-gnu/bat' /usr/local/bin/bat \
  ; rm -rf 'bat-v0.25.0-x86_64-unknown-linux-gnu'
RUN set -e \
  ; mkdir -p /exports/usr/local/bin/ \
  ; mv /usr/local/bin/bat /exports/usr/local/bin/

# MY-BENJI
FROM shell-admin AS my-benji
COPY --from=bat /exports/ /
COPY --from=build-essential /exports/ /
COPY --from=claude-code /exports/ /
COPY --from=clone /exports/ /
COPY --from=docker /exports/ /
COPY --from=exa /exports/ /
COPY --from=fd /exports/ /
COPY --from=file /exports/ /
COPY --from=files-to-prompt /exports/ /
COPY --from=fzf /exports/ /
COPY --from=gh /exports/ /
COPY --from=htop /exports/ /
COPY --from=httpie /exports/ /
COPY --from=jq /exports/ /
COPY --from=jujutsu /exports/ /
COPY --from=lazycommit /exports/ /
COPY --from=lazygit /exports/ /
COPY --from=lazyjj /exports/ /
COPY --from=llm /exports/ /
COPY --from=make /exports/ /
COPY --from=moreutils /exports/ /
COPY --from=ncu /exports/ /
COPY --from=node /exports/ /
COPY --from=pgcli /exports/ /
COPY --from=pnpm /exports/ /
COPY --from=prettyping /exports/ /
COPY --from=rip /exports/ /
COPY --from=ripgrep /exports/ /
COPY --from=safe-rm /exports/ /
COPY --from=sd /exports/ /
COPY --from=shell-git --chown=admin /home/admin/exports/ /
COPY --from=shell-git /exports/ /
COPY --from=shell-npm --chown=admin /home/admin/exports/ /
COPY --from=shell-npm /exports/ /
COPY --from=shell-ranger --chown=admin /home/admin/exports/ /
COPY --from=shell-ranger /exports/ /
COPY --from=shell-ssh --chown=admin /home/admin/exports/ /
COPY --from=shell-tmux --chown=admin /home/admin/exports/ /
COPY --from=shell-tmux /exports/ /
COPY --from=shell-vim --chown=admin /home/admin/exports/ /
COPY --from=shell-vim /exports/ /
COPY --from=shell-zsh --chown=admin /home/admin/exports/ /
COPY --from=shell-zsh /exports/ /
COPY --from=shoebox /exports/ /
COPY --from=sudo /exports/ /
COPY --from=tree /exports/ /
COPY --from=ttok /exports/ /
COPY --from=unzip /exports/ /
COPY --from=wget /exports/ /
COPY --from=zoxide /exports/ /
ENV \
  PATH=${PATH}:/home/admin/.cache/npm/bin
RUN set -e \
  ; chmod 0600 /home/admin/.ssh/* \
  ; chmod +x /home/admin/.ssh/sockets

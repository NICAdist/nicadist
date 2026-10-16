# A special version of GCC toolchain for building of leacy version of GCC compiler suite,
# namely GCC v6.2.0. For any other recent GCC version, please refer to GCC-ToolChain
# located inside gcc-toolchain.sh
# This build also disables libsanitizer in gcc
package: GCC6
version: v6.2.0
tag: v6.2.0-alice1
source: https://github.com/alisw/gcc-toolchain
prepend_path:
  "LD_LIBRARY_PATH": "$GCC_TOOLCHAIN_ROOT/lib64"
  "PATH": "$GCC_TOOLCHAIN_ROOT/libexec/bin"
build_requires:
  - autotools
  - make
  - yacc-like
prefer_system: .*
env:
  CCACHE_CONFIGPATH: "$GCC_TOOLCHAIN_ROOT/etc/ccache.conf"
---
unset CXXFLAGS
unset CFLAGS

echo "Building GCC because no compatible version was found on the system. To skip this step, install GCC 6.2.0"

USE_GOLD=
case $ARCHITECTURE in
  *x86-64)
    MARCH='x86_64-unknown-linux-gnu'
  ;;
  *)
    MARCH=
  ;;
esac

rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR/" ./

# patch in order to build old GCC version (v6.2) with new compiler
sed -i 's@struct ucontext@ucontext_t@g' $BUILDDIR/gcc/libgcc/config/i386/linux-unwind.h
sed -i 's@#include "gdb_wait.h"@// #include"gdb_wait.h"@g' $BUILDDIR/gdb/gdb/nat/linux-ptrace.c
sed -i 's@#include "gdb_ptrace.h"@// #include"gdb_ptrace.h"@g' $BUILDDIR/gdb/gdb/nat/linux-ptrace.c
sed -i 's@#include "nat/gdb_ptrace.h"@#include "nat/gdb_ptrace.h"\n#include "gdb_wait.h"@g' $BUILDDIR/gdb/gdb/nat/linux-ptrace.h
sed -i 's@#include <signal.h>@// #include <signal.h >@g' $BUILDDIR/gdb/gdb/nat/amd64-linux-siginfo.c
sed -i 's@#include "common-defs.h"@#include "common-defs.h"\n#include <signal.h>@g' $BUILDDIR/gdb/gdb/nat/amd64-linux-siginfo.c

# Disabled lib izer as whole, no more need for patching
# sed -i 's@#include <linux/cyclades.h>@// #include <linux/ cyclades.h>@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc
# sed -i 's@#include <sys/ustat.h>@// #include <sys/ ustat.h>@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc
# sed -i 's@  unsigned struct_ustat_sz = sizeof(struct ustat);@//  unsigned struct_ustat _sz = sizeof(struct ustat);@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc
# sed -i 's@  unsigned struct_cyclades_monitor_sz = sizeof(struct cyclades_monitor);@//  unsigned struct_cyclades_monitor_sz = sizeof(struct cyclades_monitor) ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc
# sed -i 's@  unsigned IOCTL_CYGETDEFTHRESH = CYGETDEFTHRESH;@  //   unsigned IOCTL_CYGETDEFTHRESH = CYGETDEFTHRESH ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc
# sed -i 's@  unsigned IOCTL_CYGETDEFTIMEOUT = CYGETDEFTIMEOUT;@  //   unsigned IOCTL_CYGETDEFTIMEOUT = CYGETDEFTIMEOUT ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc
# sed -i 's@  unsigned IOCTL_CYGETMON = CYGETMON;@  //   unsigned IOCTL_CYGETMON = CYGETMON ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc
# sed -i 's@  unsigned IOCTL_CYGETTHRESH = CYGETTHRESH;@  //   unsigned IOCTL_CYGETTHRESH = CYGETTHRESH ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc
# sed -i 's@  unsigned IOCTL_CYGETTIMEOUT = CYGETTIMEOUT;@  //   unsigned IOCTL_CYGETTIMEOUT = CYGETTIMEOUT ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc
# sed -i 's@  unsigned IOCTL_CYSETDEFTHRESH = CYSETDEFTHRESH;@  //   unsigned IOCTL_CYSETDEFTHRESH = CYSETDEFTHRESH ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc
# sed -i 's@  unsigned IOCTL_CYSETDEFTIMEOUT = CYSETDEFTIMEOUT;@  //   unsigned IOCTL_CYSETDEFTIMEOUT = CYSETDEFTIMEOUT ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc
# sed -i 's@  unsigned IOCTL_CYSETTHRESH = CYSETTHRESH;@  //   unsigned IOCTL_CYSETTHRESH = CYSETTHRESH ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc
# sed -i 's@  unsigned IOCTL_CYSETTIMEOUT = CYSETTIMEOUT;@  //   unsigned IOCTL_CYSETTIMEOUT = CYSETTIMEOUT ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.cc
# sed -i 's@  _(CYGETDEFTHRESH, WRITE, sizeof(int));@  // _(CYGETDEFTHRESH, WRITE, sizeof(int));@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_common_interceptors_ioctl.inc
# sed -i 's@  _(CYGETDEFTIMEOUT, WRITE, sizeof(int));@  // _(CYGETDEFTIMEOUT, WRITE, sizeof(int));@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_common_interceptors_ioctl.inc
# sed -i 's@  _(CYGETMON, WRITE, struct_cyclades_monitor_sz);@  // _(CYGETMON, WRITE, struct_cyclades_monitor_sz);@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_common_interceptors_ioctl.inc
# sed -i 's@  _(CYGETTHRESH, WRITE, sizeof(int));@  // _(CYGETTHRESH, WRITE, sizeof(int));@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_common_interceptors_ioctl.inc
# sed -i 's@  _(CYGETTIMEOUT, WRITE, sizeof(int));@  // _(CYGETTIMEOUT, WRITE, sizeof(int));@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_common_interceptors_ioctl.inc
# sed -i 's@  _(CYSETDEFTHRESH, NONE, 0);@  // _(CYSETDEFTHRESH, NONE, 0);@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_common_interceptors_ioctl.inc
# sed -i 's@  _(CYSETDEFTIMEOUT, NONE, 0);@  // _(CYSETDEFTIMEOUT, NONE, 0);@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_common_interceptors_ioctl.inc
# sed -i 's@  _(CYSETTHRESH, NONE, 0);@  // _(CYSETTHRESH, NONE, 0);@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_common_interceptors_ioctl.inc
# sed -i 's@  _(CYSETTIMEOUT, NONE, 0);@  // _(CYSETTIMEOUT, NONE, 0);@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_common_interceptors_ioctl.inc
# sed -i 's@  extern unsigned struct_cyclades_monitor_sz;@  //  extern unsigned struct_cyclades_monitor_sz ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.h
# sed -i 's@  extern unsigned IOCTL_CYGETDEFTHRESH;@  //   extern unsigned IOCTL_CYGETDEFTHRESH ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.h
# sed -i 's@  extern unsigned IOCTL_CYGETDEFTIMEOUT;@  //   extern unsigned IOCTL_CYGETDEFTIMEOUT ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.h
# sed -i 's@  extern unsigned IOCTL_CYGETMON;@  //   extern unsigned IOCTL_CYGETMON ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.h
# sed -i 's@  extern unsigned IOCTL_CYGETTHRESH;@  //   extern unsigned IOCTL_CYGETTHRESH ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.h
# sed -i 's@  extern unsigned IOCTL_CYGETTIMEOUT;@  //   extern unsigned IOCTL_CYGETTIMEOUT ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.h
# sed -i 's@  extern unsigned IOCTL_CYSETDEFTHRESH;@  //   extern unsigned IOCTL_CYSETDEFTHRESH ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.h
# sed -i 's@  extern unsigned IOCTL_CYSETDEFTIMEOUT;@  //   extern unsigned IOCTL_CYSETDEFTIMEOUT ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.h
# sed -i 's@  extern unsigned IOCTL_CYSETTHRESH;@  //   extern unsigned IOCTL_CYSETTHRESH ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.h
# sed -i 's@  extern unsigned IOCTL_CYSETTIMEOUT;@  //   extern unsigned IOCTL_CYSETTIMEOUT ;@g' $BUILDDIR/gcc/libsanitizer/sanitizer_common/sanitizer_platform_limits_posix.h

if [ -e autoconf-archive ]; then
  (cd autoconf-archive && autoreconf -ivf )
  mkdir build-autoconf-archive
  pushd build-autoconf-archive
    ../autoconf-archive/configure --prefix="$INSTALLROOT"
    make install
  popd
  export ACLOCAL_PATH=$INSTALLROOT/share/aclocal
fi

# Binutils
mkdir build-binutils
pushd build-binutils
  ../binutils/configure --prefix="$INSTALLROOT"                \
                        ${MARCH:+--build=$MARCH --host=$MARCH} \
                        ${USE_GOLD:+--enable-gold=yes}         \
                        --enable-ld=default                    \
                        --enable-lto                           \
                        --enable-plugins                       \
                        --enable-threads                       \
                        --enable-gprofng=no                    \
                        --disable-nls
  make ${JOBS:+-j$JOBS} MAKEINFO=":"
  make install MAKEINFO=":"
  hash -r
popd

# Test program
cat > test.c << EoF
#include <string.h>
#include <stdio.h>
int main(void) { printf("The answer is 42.\n"); }
EoF

# We will need to rebuild them with the final GCC
rsync -a gcc/mpfr/ mpfr
rsync -a gcc/gmp/ gmp
rsync -a gcc/isl/ isl
rsync -a gcc/mpc/ mpc

pushd gcc
  [ -d mpfr ] && (cd mpfr && autoreconf -ivf)
  [ -d mpc ] && (cd mpc && autoreconf -ivf)
  [ -d gmp ] && (cd gmp && autoreconf -ivf)
  [ -d isl ] && (cd isl && autoreconf -ivf)
  [ -d cloog ] && (cd cloog && autoreconf -ivf)
popd

[ -d mpfr ] && (cd mpfr && autoreconf -ivf)
[ -d mpc ] && (cd mpc && autoreconf -ivf)
[ -d gmp ] && (cd gmp && autoreconf -ivf)
[ -d isl ] && (cd isl && autoreconf -ivf)
[ -d cloog ] && (cd cloog && autoreconf -ivf)

mkdir build-gcc
pushd build-gcc
  # added --disable-libsanitizer since patching it, seems too complicated
  ../gcc/configure --prefix="$INSTALLROOT"                          \
                   ${MARCH:+--build=$MARCH --host=$MARCH}           \
                   --enable-languages="c,c++,fortran${EXTRA_LANGS}" \
                   --disable-multilib                               \
                   --disable-libsanitizer                           \
                   ${USE_GOLD:+--enable-gold=yes}                   \
                   --enable-ld=default                              \
                   --enable-lto                                     \
                   --disable-nls
  make ${JOBS+-j $JOBS} bootstrap-lean MAKEINFO=":"
  make install MAKEINFO=":"
  hash -r

  # GCC creates c++, but not cc
  ln -nfs gcc "$INSTALLROOT/bin/cc"
  rm -rf "$INSTALLROOT/lib/pkg-config"

  # Provide a custom specs file if needed
  #SPEC="$(dirname $(gcc -print-libgcc-file-name))/specs"
  #gcc -dumpspecs > $SPEC
  #perl -pe '++$x and next if /^\*link:/; $x-- and s/^(.*)$/\1 -rpath-link \/lib64:\/lib/ if $x' $SPEC > $SPEC.0
  #mv $SPEC.0 $SPEC

  rm -f "$INSTALLROOT"/lib/*.la \
        "$INSTALLROOT"/lib64/*.la
popd

# From now on, use own linker and GCC
export PATH="$INSTALLROOT/bin:$PATH"
export LD_LIBRARY_PATH="$INSTALLROOT/lib64:$INSTALLROOT/lib:$LD_LIBRARY_PATH"
hash -r

# Test own linker and own GCC
type ld
type g++
g++ test.c
./a.out
rm -f a.out

# Build a very basic CMake, to compile ccache and nothing else
# in case we manage, we build ccache
if [ -e ccache ]; then
  mkdir -p build-cmake
  pushd build-cmake
  cat > build-flags.cmake << EoF
# Disable Java capabilities; we don't need it and on OS X might miss the
# required /System/Library/Frameworks/JavaVM.framework/Headers/jni.h.
SET(JNI_H FALSE CACHE BOOL "" FORCE)
SET(Java_JAVA_EXECUTABLE FALSE CACHE BOOL "" FORCE)
SET(Java_JAVAC_EXECUTABLE FALSE CACHE BOOL "" FORCE)

# SL6 with GCC 4.6.1 and LTO requires -ltinfo with -lcurses for link to succeed,
# but cmake is not smart enough to find it. We do not really need ccmake anyway,
# so just disable it.
SET(BUILD_CursesDialog FALSE CACHE BOOL "" FORCE)
EoF
    $SOURCEDIR/cmake/bootstrap --prefix=$BUILDDIR/bootstrap-cmake \
                               --no-debugger                      \
                               --no-qt-gui                        \
                               --init=build-flags.cmake           \
                               ${JOBS:+--parallel=$JOBS}
    make ${JOBS+-j $JOBS}
    make install/strip
  popd

  # We build ccache using our own compiler, so that we do not have issue
  # with libstdc++ compatibility.
  mkdir build-ccache
  pushd build-ccache
    $BUILDDIR/bootstrap-cmake/bin/cmake -S ../ccache \
        -DENABLE_DOCUMENTATION=OFF                   \
        -DENABLE_TESTING=OFF                         \
        -DSTATIC_LINK=ON                             \
        -DCMAKE_INSTALL_PREFIX="$INSTALLROOT/libexec/ccache"
    make ${JOBS:+-j $JOBS} install
    ln -sf ccache $INSTALLROOT/libexec/ccache/bin/gcc
    ln -sf ccache $INSTALLROOT/libexec/ccache/bin/g++
    ln -sf ccache $INSTALLROOT/libexec/ccache/bin/cc
    ln -sf ccache $INSTALLROOT/libexec/ccache/bin/c++
    export PATH=$INSTALLROOT/libexec/ccache/bin:$PATH
    # Notice how we configure CCACHE to work, but then 
    # disable so that users need to export CCACHE_DISABLE=false
    # to actually have it working.
    mkdir -p $INSTALLROOT/libexec/ccache/etc
    cat > $INSTALLROOT/libexec/ccache/etc/ccache.conf << EoF
cache_dir=$WORK_DIR/TMP/ccache/$ARCHITECTURE
disable=true
EoF
  popd
fi

# We rebuild mpfr, gmp, isl to be used with gdb. We do so because
# we want to make sure they were actually built with the GCC we
# use, not with the bootstrap xgcc.
[ -d mpfr ] && (cd mpfr && autoreconf -ivf)
[ -d gmp ] && (cd gmp && autoreconf -ivf)
[ -d isl ] && (cd isl && autoreconf -ivf)
[ -d mpc ] && (cd mpc && autoreconf -ivf)
mkdir -p build-gmp
mkdir -p build-mpfr
mkdir -p build-isl
mkdir -p build-mpc

pushd build-gmp
  ../gmp/configure --prefix="$INSTALLROOT/libexec/extra"  \
                   --disable-shared                       \
                   --enable-static
  make ${JOBS:+-j$JOBS} MAKEINFO=":"
  make install MAKEINFO=":"
popd

pushd build-mpfr
  ../mpfr/configure --prefix="$INSTALLROOT/libexec/extra"  \
                   --disable-shared                        \
                   --with-gmp="$INSTALLROOT/libexec/extra" \
                   --enable-static
  make ${JOBS:+-j$JOBS} MAKEINFO=":"
  make install MAKEINFO=":"
popd

pushd build-isl
  ../isl/configure --prefix="$INSTALLROOT/libexec/extra"          \
                   --with-gmp-prefix="$INSTALLROOT/libexec/extra" \
                   --disable-shared                               \
                   --enable-static
  make ${JOBS:+-j$JOBS} MAKEINFO=":"
  make install MAKEINFO=":"
popd

pushd build-mpc
  ../mpc/configure --prefix="$INSTALLROOT/libexec/extra"    \
                   --disable-shared                         \
                   --with-gmp="$INSTALLROOT/libexec/extra"  \
                   --with-mpft="$INSTALLROOT/libexec/extra" \
                   --enable-static
  make ${JOBS:+-j$JOBS} MAKEINFO=":"
  make install MAKEINFO=":"
popd

# GDB
mkdir build-gdb
pushd build-gdb
  ../gdb/configure --prefix="$INSTALLROOT"                \
                   ${MARCH:+--build=$MARCH --host=$MARCH} \
                   --with-gmp=$INSTALLROOT/libexec/extra  \
                   --with-mpfr=$INSTALLROOT/libexec/extra \
                   --with-isl=$INSTALLROOT/libexec/extra  \
                   --with-mpc=$INSTALLROOT/libexec/extra  \
                   --without-guile                        \
                   --without-python                       \
                   --disable-multilib
  make ${JOBS:+-j$JOBS} MAKEINFO=":"
  make install MAKEINFO=":"
  hash -r
  rm -f "$INSTALLROOT"/lib/*.la
popd

# We remove the sim folder because it's not used and actually
# conflicts with FairRoot when installing in a single installation
# path.
rm -fr "$INSTALLROOT"/include/sim
# If fixincludes is not desired, see:
# http://ewontfix.com/12/
# https://sources.gentoo.org/cgi-bin/viewvc.cgi/gentoo-x86/eclass/toolchain.eclass?view=markup&sortby=log#l1524

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib --lib64 > $MODULEFILE

nicadist-postbuild-hook

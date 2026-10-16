package: GCC-ToolChain
version: "%(tag_basename)s"
tag: "v16.2.0"
source: https://git.jinr.ru/mpd/nicadist/GCC-ToolChain.git
prepend_path:
  "LD_LIBRARY_PATH": "$GCC_TOOLCHAIN_ROOT/lib64"
build_requires:
 - autotools
 - make
 - yacc-like
prefer_system: .*
prefer_system_check: |
  set -e
  which gfortran || { echo "gfortran missing"; exit 1; }
  case $REQUESTED_VERSION in
    v16*) MIN_GCC_VERSION=160200 ;;
    v14*) MIN_GCC_VERSION=140200 ;;
    v13*) MIN_GCC_VERSION=130200 ;;
    v12*) MIN_GCC_VERSION=120200 ;;
    v11*) MIN_GCC_VERSION=110200 ;;
  esac
  which gcc
  test -f "$(dirname "$(which gcc)")/c++"
  gcc -xc++ - -c -o /dev/null << EoF
  #define GCCVER ((__GNUC__ * 10000)+(__GNUC_MINOR__ * 100)+(__GNUC_PATCHLEVEL__))
  #if (GCCVER < $MIN_GCC_VERSION)
  #error "System's GCC cannot be used: we need at least GCC $REQUESTED_VERSION. We'll compile our own version."
  #endif
  EoF
---
# Fix syntax highlight
cat << EoF
EoF
unset CXXFLAGS
unset CFLAGS

echo "Building GCC because no compatible version was found on the system. To skip this step, install compatible GCC. Make sure you have gfortran installed too."

case $ARCHITECTURE in
  *x86-64)
    MARCH='x86_64-unknown-linux-gnu'
  ;;
  *)
    MARCH=
  ;;
esac

pushd $SOURCEDIR
  ./missing-timestamps.sh --apply
popd

rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR"/binutils*/ ./binutils
rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR"/gcc*/ ./gcc
rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR"/gdb*/ ./gdb
rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR"/gmp*/ ./gcc/gmp
rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR"/isl*/ ./gcc/isl
rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR"/mpc*/ ./gcc/mpc
rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR"/mpfr*/ ./gcc/mpfr
rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR"/gmp*/ ./gdb/gmp
rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR"/mpfr*/ ./gdb/mpfr

# Binutils
mkdir binutils/build
pushd binutils/build
  echo 'Building binutils'
  ../configure --prefix="$INSTALLROOT"                \
               ${MARCH:+--build=$MARCH --host=$MARCH} \
               --enable-ld=default                    \
               --enable-lto                           \
               --enable-plugins                       \
               --enable-threads                       \
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

pushd gcc
  [ -d gmp ] && (cd gmp && autoreconf -ivf && autoupdate)
  [ -d isl ] && (cd isl && autoreconf -ivf && autoupdate)
  [ -d mpc ] && (cd mpc && autoreconf -ivf && autoupdate)
  [ -d mpfr ] && (cd mpfr && autoreconf -ivf && autoupdate)
popd

mkdir gcc/build
pushd gcc/build
  echo 'Building gcc'
  ../configure --prefix="$INSTALLROOT"                \
               ${MARCH:+--build=$MARCH --host=$MARCH} \
               --enable-languages="c,c++,fortran"     \
               --disable-multilib                     \
               --enable-ld=default                    \
               --enable-lto                           \
               --disable-nls
  make ${JOBS+-j $JOBS} bootstrap-lean MAKEINFO=":"
  make install MAKEINFO=":"
  hash -r

  # GCC creates c++, but not cc
  ln -nfs gcc "$INSTALLROOT/bin/cc"
  rm -rf "$INSTALLROOT/lib/pkg-config"

  rm -f "$INSTALLROOT"/lib/*.la \
        "$INSTALLROOT"/lib64/*.la
popd

# From now on, use own linker and GCC
export PATH="$INSTALLROOT/bin:$PATH"
export LD_LIBRARY_PATH="$INSTALLROOT/lib64:$INSTALLROOT/lib:$LD_LIBRARY_PATH"
hash -r

# Test own linker and own GCC
which ld
which g++
g++ test.c
./a.out
rm -f a.out

pushd gdb
  [ -d gmp ] && (cd gmp && autoreconf -ivf && autoupdate)
  [ -d mpfr ] && (cd mpfr && autoreconf -ivf && autoupdate)
popd

# GDB
mkdir gdb/build
pushd gdb/build
  echo 'Building gdb'
  ../configure --prefix="$INSTALLROOT"                \
               ${MARCH:+--build=$MARCH --host=$MARCH} \
               --without-python                       \
               --disable-multilib
  make ${JOBS:+-j$JOBS} MAKEINFO=":"
  make install MAKEINFO=":"
  hash -r
  rm -f $INSTALLROOT/lib/*.la
popd

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib --lib64 > $MODULEFILE

nicadist-postbuild-hook

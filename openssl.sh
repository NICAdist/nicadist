package: OpenSSL
version: v4.0.2
tag: openssl-4.0.2
source: https://github.com/openssl/openssl.git
requires:
  - zlib
build_requires:
  - pigz
---
#!/bin/bash -e
rsync -a --delete --exclude="**/.git" $SOURCEDIR/ .
case ${PKG_VERSION} in
  v1.1*)
    OPTS=""
    OPENSSLDIRPREFIX="" ;;
  v3.1*)
    OPTS=""
    OPENSSLDIRPREFIX="" ;;
  v4.0*)
    OPTS=""
    OPENSSLDIRPREFIX="" ;;
  *)
    OPENSSLDIRPREFIX="etc/ssl"
  ;;
esac

# Time::Piece is required by OpenSSL since v3.2
# sudo dnf install perl-Time-Piece

./config --prefix="$INSTALLROOT"                       \
         --openssldir="$INSTALLROOT/$OPENSSLDIRPREFIX" \
         --libdir=lib                                  \
         zlib                                          \
         no-idea                                       \
         no-mdc2                                       \
         no-rc5                                        \
         no-asm                                        \
         ${OPTS}                                       \
         shared                                        \
         -fno-strict-aliasing                          \
         -L"$INSTALLROOT/lib"                          \
         -Wa,--noexecstack

make depend
make ${JOBS:+-j$JOBS}
make install_sw # no not install man pages

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
setenv OpenSSL_DIR \$PKG_ROOT/lib/cmake/OpenSSL
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
EoF

nicadist-postbuild-hook

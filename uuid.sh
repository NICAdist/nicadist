package: UUID
version: v2.42.4
tag: v2.42.4
source: https://github.com/util-linux/util-linux.git
build_requires:
  - autotools
---
#!/bin/bash -e
rsync -av --delete --exclude '**/.git' "$SOURCEDIR/" .
if [[ $AUTOTOOLS_ROOT == "" ]]  && which brew >/dev/null; then
  PATH=$PATH:$(brew --prefix gettext)/bin
fi

case $ARCHITECTURE in
  osx_*) disable_shared=yes ;;
  *) disable_shared= ;;
esac

./autogen.sh

./configure ${disable_shared:+--disable-shared} \
            --libdir="$INSTALLROOT/lib"         \
            --prefix="$INSTALLROOT"             \
            --disable-all-programs              \
            --disable-gtk-doc                   \
            --disable-silent-rules              \
            --disable-tls                       \
            --disable-rpath                     \
            --enable-ncurses                    \
            --enable-libuuid

make ${JOBS:+-j$JOBS} libuuid.la libuuid/uuid.pc install-uuidincHEADERS

mkdir -p "$INSTALLROOT/lib" "$INSTALLROOT/share/pkgconfig"
cp -a libuuid/uuid.pc "$INSTALLROOT/share/pkgconfig"
cp -a .libs/libuuid.a* "$INSTALLROOT/lib"
if [ -z "$disable_shared" ]; then
  cp -a .libs/libuuid.so* "$INSTALLROOT/lib"
fi
# rm -rf "$INSTALLROOT/man"

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/share/pkgconfig
EoF

nicadist-postbuild-hook

package: libtirpc
version: v1.3.7
tag: v1.3.7
source: https://git.jinr.ru/mpd/nicadist/libtirpc.git
build_requires:
  - autotools
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./
./bootstrap
./configure --prefix="$INSTALLROOT" \
            --disable-gssapi        \
            --enable-shared=no

make ${JOBS:+-j$JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
prepend-path MANPATH \$PKG_ROOT/share/man
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
EoF

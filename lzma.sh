package: lzma
version: v5.8.4
tag: v5.8.4
source: https://github.com/tukaani-project/xz.git
build_requires:
  - autotools
  - rsync
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./
./autogen.sh --no-doxygen \
             --no-po4a

./configure CFLAGS="$CFLAGS -fPIC -Ofast" \
            --prefix="$INSTALLROOT"       \
            --disable-shared              \
            --enable-static               \
            --disable-nls                 \
            --disable-rpath               \
            --disable-dependency-tracking \
            --disable-doc

make ${JOBS:+-j$JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

# Add additional paths to the modulefile
cat >> "$MODULEFILE" << EoF
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path MANPATH \$PKG_ROOT/share/man
EoF

nicadist-postbuild-hook

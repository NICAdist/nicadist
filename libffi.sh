package: libffi
version: v3.8.0
tag: v3.8.0
source: https://github.com/libffi/libffi.git
build_requires:
  - autotools
---
#!/bin/bash -ex
rsync -a $SOURCEDIR/ .
autoreconf -ivf .

./configure --prefix="$INSTALLROOT"      \
            --disable-docs               \
            --disable-multi-os-directory \
            --libdir="$INSTALLROOT/lib"

make ${JOBS:+-j $JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

# Add additional paths to the modulefile
cat >> "$MODULEFILE" << EoF
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path MANPATH \$PKG_ROOT/share/man
EoF

nicadist-postbuild-hook

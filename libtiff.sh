package: libtiff
version: v4.7.2
tag: v4.7.2
source: https://gitlab.com/libtiff/libtiff.git
build_requires:
  - autotools
---
#!/bin/bash -ex
rsync -a --exclude '**/.git' $SOURCEDIR/ .
autoreconf -ivf .

./configure --prefix=$INSTALLROOT \
            --disable-docs

make ${JOBS:+-j $JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

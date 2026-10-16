package: sqlite
version: v3.53.4
tag: version-3.53.4
source: https://github.com/sqlite/sqlite.git
build_requires:
  - autotools
---
#!/bin/bash -e
rsync -av $SOURCEDIR/ ./

./configure --disable-tcl         \
            --disable-readline    \
            --prefix=$INSTALLROOT

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

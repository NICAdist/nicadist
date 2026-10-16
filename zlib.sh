package: zlib
version: v1.3.2
tag: v1.3.2
source: https://github.com/madler/zlib.git
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

./configure --prefix=$INSTALLROOT

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

nicadist-postbuild-hook

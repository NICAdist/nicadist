package: libICU
version: v78.3
tag: release-78.3
source: https://github.com/unicode-org/icu.git
build_requires:
  - autotools
---
#!/bin/bash -ex
rsync -a $SOURCEDIR/icu4c/* .
rm -f LICENSE
cp $SOURCEDIR/LICENSE ./
cd source/
autoreconf -ivf .

./configure --prefix="${INSTALLROOT}"

make ${JOBS:+-j $JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
prepend-path PATH \$PKG_ROOT/sbin
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path MANPATH \$PKG_ROOT/share/man
EoF

nicadist-postbuild-hook

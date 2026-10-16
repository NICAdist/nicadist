package: liblzf
version: v3.8
tag: fb25820c3c0aeafd127956ae6c115063b47e459a
source: https://github.com/nemequ/liblzf.git
build_requires:
  - autotools
---
#!/bin/bash -e
rsync -a $SOURCEDIR/ .
autoreconf -ivf .

./configure --prefix="$INSTALLROOT"

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

mkdir -p "$INSTALLROOT/lib/pkgconfig"
cat > "$INSTALLROOT/lib/pkgconfig/liblzf.pc" << EoF
prefix=$INSTALLROOT
exec_prefix=\${prefix}
libdir=$INSTALLROOT/lib
toolexeclibdir=\${libdir}
includedir=\${prefix}/include

Name: lzf
Description: lzf data compression library
Version: 3.8.0
Libs: -L\${toolexeclibdir} -llzf
Cflags: -I\${includedir}
EoF

nicadist-postbuild-hook

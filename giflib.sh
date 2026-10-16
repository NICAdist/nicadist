package: giflib
version: v6.1.3
tag: 6.1.3
source: https://git.jinr.ru/mpd/nicadist/giflib.git
build_requires:
  - autotools
---
#!/bin/bash -ex
rsync -a --exclude '**/.git' $SOURCEDIR/ .

PREFIX=$INSTALLROOT make ${JOBS:+-j $JOBS}
PREFIX=$INSTALLROOT make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv giflib_ROOT \$PKG_ROOT
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

mkdir -p "$INSTALLROOT/lib/pkgconfig"
# Manualy creted .pc file so that PKGCONFIG can be used to find it
cat > "$INSTALLROOT/lib/pkgconfig/libgif.pc" << EoF
prefix=$INSTALLROOT
exec_prefix=\${prefix}
libdir=$INSTALLROOT/lib
toolexeclibdir=\${libdir}
includedir=\${prefix}/include

Name: libgif
Description: gif library
Version: 5.2.2
Libs: -L\${toolexeclibdir} -lgif
Cflags: -I\${includedir}
EoF

nicadist-postbuild-hook

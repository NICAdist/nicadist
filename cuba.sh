package: Cuba
version: v4.2.2
tag: "Cuba-4.2.2"
source: https://git.jinr.ru/mpd/nicadist/Cuba.git
build_requires:
  - autotools
---
#!/bin/bash
rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ ./

autoreconf -ivf

./configure --prefix="$INSTALLROOT"

make # parallel build fails due to interlibrary dependencies problem
make install

# remove bin directory since it is empty
rm -rf $INSTALLROOT/bin

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv Cuba_ROOT \$PKG_ROOT
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

# Manualy create .pc file so that PKGCONFIG can be used to find it
mkdir -p "$INSTALLROOT/lib/pkgconfig"
cat > "$INSTALLROOT/lib/pkgconfig/libcuba.pc" << EoF
prefix=$INSTALLROOT
exec_prefix=\${prefix}
libdir=$INSTALLROOT/lib
toolexeclibdir=\${libdir}
includedir=\${prefix}/include

Name: Cuba
Description: Cuba - a library for multidimensional numerical integration
Version: 4.2.2
Libs: -L\${toolexeclibdir} -lcuba
Cflags: -I\${includedir}
EoF

nicadist-postbuild-hook

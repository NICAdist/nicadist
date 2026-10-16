package: HepPDT
version: v3.04.01
tag: v3.04.01
source: https://git.jinr.ru/mpd/nicadist/HepPDT.git 
build_requires:
  - autotools
---
#!/bin/bash -e
rsync -a --exclude='**/.git' --delete --delete-excluded \
      $SOURCEDIR/ ./
autoreconf -ivf

./configure --prefix=$INSTALLROOT

make ${JOBS:+-j$JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv HepPDT_ROOT \$PKG_ROOT
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

# Manualy create .pc file so that PKGCONFIG can be used to find it
mkdir -p "$INSTALLROOT/lib/pkgconfig"
cat > "$INSTALLROOT/lib/pkgconfig/libHepPDT.pc" << EoF
prefix=$INSTALLROOT
exec_prefix=\${prefix}
libdir=$INSTALLROOT/lib
toolexeclibdir=\${libdir}
includedir=\${prefix}/include

Name: HepPDT
Description: HepPDT library
Version: 3.4.1
Libs: -L\${toolexeclibdir} -lHepPDT
Cflags: -I\${includedir}
EoF

cat > "$INSTALLROOT/lib/pkgconfig/libHepPID.pc" << EoF
prefix=$INSTALLROOT
exec_prefix=\${prefix}
libdir=$INSTALLROOT/lib
toolexeclibdir=\${libdir}
includedir=\${prefix}/include

Name: HepPID
Description: HepPID library
Version: 3.4.1
Libs: -L\${toolexeclibdir} -lHepPID
Cflags: -I\${includedir}
EoF

nicadist-postbuild-hook

package: FastJet
# Note that this version is only for FastJet. Bellow you will find
# hard-coded version of FastJet contrib 
# https://fastjet.fr/
version: v3.5.1
tag: v3.5.1
source: https://git.jinr.ru/mpd/nicadist/fastjet.git
requires:
  - GCC-ToolChain
build_requires:
  - autotools
  - Boost
  - CGAL
---
#!/bin/bash -e
export CXXFLAGS="$CXXFLAG -fkeep-inline-functions"

rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ ./

autoreconf -ivf

./configure --prefix=$INSTALLROOT      \
            --enable-allplugins        \
            --enable-allcxxplugins     \
            --enable-shared            \
             CXXFLAGS="$CXXFLAGS"      \
            --enable-cgal=${CGAL_ROOT}

make ${JOBS:+-j$JOBS}
make install

cd "$SOURCEDIR"/fjcontrib-*

./configure  --fastjet-config=$INSTALLROOT/bin/fastjet-config \
             CXXFLAGS="$CXXFLAGS"                             \
             CFLAGS="$CFLAGS"

make ${JOBS:+-j$JOBS}
make install
make fragile-shared ${JOBS:+-j$JOBS}
make fragile-shared-install

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
cat > "$INSTALLROOT/lib/pkgconfig/libfastjet.pc" << EoF
prefix=$INSTALLROOT
exec_prefix=\${prefix}
libdir=$INSTALLROOT/lib
toolexeclibdir=\${libdir}
includedir=\${prefix}/include

Name: FastJet
Description: FastJet library
Version: 3.5.1
Libs: -L\${toolexeclibdir} -lfastjet
Cflags: -I\${includedir}
EoF

nicadist-postbuild-hook

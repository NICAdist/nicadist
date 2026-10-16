package: JAM2
version: v2.0097
tag: "jam2.0097"
source: https://github.com/ynara305/jam2.0.git
requires:
  - Pythia8JAM2
build_requires:
  - autotools
---
#!/bin/bash
rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ ./

autoreconf -ivf

# hack with STD is needed since Pythia 8.2.44 does not support c++17 or newer
CXXFLAGS='-fPIC -O2 -std=c++14' CXXSTD='14'    \
         ./configure --prefix="$INSTALLROOT"   \
                     Pythia8=$PYTHIA8JAM2_ROOT

make -j$JOBS
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv JAM2_ROOT \$PKG_ROOT
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

# Manualy create .pc file so that PKGCONFIG can be used to find it
mkdir -p "$INSTALLROOT/lib/pkgconfig"
cat > "$INSTALLROOT/lib/pkgconfig/libjam2.pc" << EoF
prefix=$INSTALLROOT
exec_prefix=\${prefix}
libdir=$INSTALLROOT/lib
toolexeclibdir=\${libdir}
includedir=\${prefix}/include

Name: jam2
Description: jam2 library
Version: 2.0097
Libs: -L\${toolexeclibdir} -ljam2
Cflags: -I\${includedir}
EoF

nicadist-postbuild-hook

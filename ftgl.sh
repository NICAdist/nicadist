package: FTGL
version: v2.4.0
tag: v2.4.0
source: https://github.com/frankheckenbach/ftgl.git
requires:
  - FreeType
build_requires:
  - autotools
---
#!/bin/bash -ex
rsync -a $SOURCEDIR/ .
autoreconf -ivf .

# Fix to enable c++20 build
sed -i 's@\&outline.tags\[startIndex\];@reinterpret_cast<char*>(\&outline.tags[startIndex]);@g' src/FTVectoriser.cpp

FT2_CFLAGS="-I$FREETYPE_ROOT/include/freetype2" \
FT2_LIBS="$FREETYPE_ROOT/lib/libfreetype.so" \
./configure --prefix="$INSTALLROOT"      \
            --libdir="$INSTALLROOT/lib"

make ${JOBS:+-j $JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

# Add additional paths to the modulefile
cat >> "$MODULEFILE" << EoF
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

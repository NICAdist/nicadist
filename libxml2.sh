package: libxml2
version: v2.15.4
tag: v2.15.4
source: https://github.com/GNOME/libxml2.git
build_requires:
  - autotools
  - zlib
prefer_system_check: |
  xml2-config --version;
  if [ $? -ne 0 ]; then printf "libxml2 not found.\n * On RHEL-compatible systems you probably need: libxml2 libxml2-devel\n * On Ubuntu-compatible systems you probably need: libxml2 libxml2-dev"; exit 1; fi
---
#!/bin/bash -e
rsync -a $SOURCEDIR/ ./

autoreconf -i
./configure --disable-static           \
            --prefix=$INSTALLROOT      \
            --with-zlib="${ZLIB_ROOT}" \
            --without-python

make ${JOBS+-j $JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

# Add additional paths to the modulefile
cat >> "$MODULEFILE" << EoF
setenv libxml2_DIR \$PKG_ROOT/lib/cmake/libxml2
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include/libxml2
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

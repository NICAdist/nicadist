package: PostgreSQL
version: v18.99.4
tag: REL_19_BETA4
source: https://git.postgresql.org/git/postgresql.git
# https://www.postgresql.org/ftp/source/
requires:
  - libICU
---
#!/bin/bash -e
rsync -a --exclude '**/.git' --delete $SOURCEDIR/ $BUILDDIR

export PKG_CONFIG_PATH=$LIBICU_ROOT/lib/pkgconfig:$PKG_CONFIG_PATH

./configure --without-readline        \
            --prefix="${INSTALLROOT}"

make ${JOBS+-j$JOBS}
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

nicadist-postbuild-hook

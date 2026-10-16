package: Lmod
version: v9.4.3
tag: 9.4.3
source: https://github.com/TACC/Lmod.git
requires:
  - autotools
  - Lua
  - termcap
---
#!/bin/bash -e
rsync -a --exclude '**/.git' --delete $SOURCEDIR/ $BUILDDIR

autoreconf -ivf .

./configure --prefix=$INSTALLROOT                             \
            ${LUA_ROOT:+--with-lua_include=$LUA_ROOT/include} \
            ${LUA_ROOT:+--with-lua=$LUA_ROOT/bin/lua}         \
            ${LUA_ROOT:+--with-luac=$LUA_ROOT/bin/luac}

make ${JOBS:+-j $JOBS}

make pre-install

rm -rf $INSTALLROOT/share # remove man

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --root > $MODULEFILE

LMODVER="$(basename $(find $INSTALLROOT/lmod -type d -name '*.*.*'))"

cat >> "$MODULEFILE" << EoF
setenv LMOD_CMD \$PKG_ROOT/lmod/$LMODVER/libexec/lmod
prepend-path LD_LIBRARY_PATH \$PKG_ROOT/lmod/$LMODVER/lib
prepend-path MANPATH \$PKG_ROOT/lmod/$LMODVER/share/man
EoF

nicadist-postbuild-hook

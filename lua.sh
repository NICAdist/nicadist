package: Lua
# v5.4.8 is the maximum which works with luarocks
version: v5.4.8
env:
  LUA_PATH: "$LUA_ROOT/share/lua/5.4/?.lua;;"
  LUA_CPATH: "$LUA_ROOT/lib/lua/5.4/?.so;;"
---
#!/bin/bash -e
# Lua
wget https://www.lua.org/ftp/lua-5.4.8.tar.gz
tar -xf lua-5.4.8.tar.gz
cd lua-5.4.8

make INSTALL_TOP=$INSTALLROOT ${JOBS:+-j$JOBS}
make INSTALL_TOP=$INSTALLROOT install
cd ..

# LuaRocks
wget https://luarocks.github.io/luarocks/releases/luarocks-3.13.0.tar.gz
tar -xf luarocks-3.13.0.tar.gz
cd luarocks-3.13.0
./configure --prefix=$INSTALLROOT                   \
            --with-lua-bin=$INSTALLROOT/bin         \
            --with-lua-include=$INSTALLROOT/include \
            --with-lua-lib=$INSTALLROOT/lib
make ${JOBS:+-j$JOBS}
make install
cd ..

# Install luaposix
cd $INSTALLROOT/bin
./luarocks install luaposix
cp $INSTALLROOT/share/lua/5.4/posix/init.lua $INSTALLROOT/share/lua/5.4/posix.lua

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

LUAVER="$(basename $(find $INSTALLROOT/lib/lua -type d -name '*.*'))"

cat >> "$MODULEFILE" << EoF
setenv LUA_ROOT \$PKG_ROOT/
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
setenv LUA_PATH "\$PKG_ROOT/share/lua/$LUAVER/?.lua;;"
setenv LUA_CPATH "\$PKG_ROOT/lib/lua/$LUAVER/?.so;;"
prepend-path MANPATH \$PKG_ROOT/man
EoF

nicadist-postbuild-hook

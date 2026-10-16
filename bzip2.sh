package: bzip2
version: v1.0.8
tag: bzip2-1.0.8
source: https://github.com/alisw/bzip2.git
prefer_system_check: |
  printf "#include <bzlib.h>\n" | c++ -xc++ - -c -o /dev/null
prepend_path:
  "PKG_CONFIG_PATH": $BZIP2_ROOT/lib/pkgconfig
---
#!/bin/bash -e
# Notice how this will build just the archive library.
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./
make ${JOBS:+-j $JOBS} CFLAGS="-O2 -fPIC -D_FILE_OFFSET_BITS=64" PREFIX=$INSTALLROOT install
make -f Makefile-libbz2_so ${JOBS:+-j $JOBS} CFLAGS="-O2 -fPIC -D_FILE_OFFSET_BITS=64" PREFIX=$INSTALLROOT

cp bzip2-shared $INSTALLROOT/bin/
cp libbz2.so.* $INSTALLROOT/lib/

cd $INSTALLROOT/bin
rm -f bzegrep bzfgrep bzless bzcmp
ln -ns bzdiff bzcmp 
ln -ns bzgrep bzegrep
ln -ns bzgrep bzfgrep
ln -ns bzmore bzless 

cd $INSTALLROOT/lib
ln -ns libbz2.so.*.*.* libbz2.so

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

# Add additional paths to the modulefile
cat >> "$MODULEFILE" << EoF
setenv bzip2_ROOT \$PKG_ROOT
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path MANPATH \$PKG_ROOT/share/man
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
EoF

mkdir -p "$INSTALLROOT/lib/pkgconfig"
cat > "$INSTALLROOT/lib/pkgconfig/libbz2.pc" << EoF
prefix=$INSTALLROOT
exec_prefix=\${prefix}
libdir=$INSTALLROOT/lib
toolexeclibdir=\${libdir}
includedir=\${prefix}/include

Name: bzip2
Description: bzip2 data compression library
Version: 1.0.8
Libs: -L\${toolexeclibdir} -lbz2
Cflags: -I\${includedir}
EoF

nicadist-postbuild-hook

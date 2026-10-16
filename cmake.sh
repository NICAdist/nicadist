package: CMake
version: v4.4.3
tag: v4.4.3
source: https://github.com/Kitware/CMake.git
requires:
  - OpenSSL
build_requires:
  - make
prefer_system: .*
prefer_system_check: |
  verge() { [[  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]]; }
  type cmake && verge 3.23.1 `cmake --version | sed -e 's/.* //' | cut -d. -f1,2,3`
---
#!/bin/bash -e
cat > build-flags.cmake <<- EoF
# Disable Java capabilities; we don't need it and on OS X might miss the
# required /System/Library/Frameworks/JavaVM.framework/Headers/jni.h.
SET(JNI_H FALSE CACHE BOOL "" FORCE)
SET(Java_JAVA_EXECUTABLE FALSE CACHE BOOL "" FORCE)
SET(Java_JAVAC_EXECUTABLE FALSE CACHE BOOL "" FORCE)

SET(CMAKE_USE_OPENSSL "TRUE")
EoF

$SOURCEDIR/bootstrap --prefix=$INSTALLROOT     \
                     --init=build-flags.cmake  \
                     ${JOBS:+--parallel=$JOBS}

make ${JOBS+-j $JOBS}
make install/strip

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin > $MODULEFILE

cat >> "$MODULEFILE" << EoF
prepend-path ACLOCAL_PATH \$PKG_ROOT/share/aclocal
prepend-path XDG_DATA_DIRS \$PKG_ROOT/share/
EoF

nicadist-postbuild-hook

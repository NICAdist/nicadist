package: libpng
version: v1.6.58
tag: v1.6.58
source: https://github.com/glennrp/libpng.git
requires:
  - zlib
build_requires:
  - autotools
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja

cmake "$SOURCEDIR"                                               \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                      \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}  \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                 \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                    \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                               \
      -G Ninja                                                   \
      -DCMAKE_INSTALL_LIBDIR=lib                                 \
      -DBUILD_SHARED_LIBS=YES                                    \
      -DCMAKE_SKIP_RPATH=YES                                     \
      -DSKIP_INSTALL_FILES=1                                     \
      ${ZLIB_ROOT:+-DZLIB_ROOT:PATH=$ZLIB_ROOT}

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

# Add additional paths to the modulefile
cat >> "$MODULEFILE" << EoF
setenv PNG_DIR \$PKG_ROOT/lib/cmake/PNG
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

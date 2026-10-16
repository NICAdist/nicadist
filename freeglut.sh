package: freeglut
version: v3.8.0
tag: v3.8.0
source: https://github.com/freeglut/freeglut.git
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja

rsync -a --exclude '**/.git' $SOURCEDIR/ .

# make missing XInput2.h warning instead of error, we don't need to build it
sed -i 's@MESSAGE(FATAL_ERROR@MESSAGE(@g' CMakeLists.txt
# remove include of unavailable header
sed -i 's@\#include <X11\/extensions\/XInput.h>@\/\/ \#include <X11\/extensions\/XInput.h>@g' src/x11/fg_internal_x11.h

cmake "$BUILDDIR"                                               \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                  \
      -DCMAKE_INSTALL_LIBDIR=lib                                \
      -DFREEGLUT_BUILD_DEMOS=OFF

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv FreeGLUT_DIR \$PKG_ROOT/lib/cmake/FreeGLUT
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path MANPATH \$PKG_ROOT/share/man
EoF

nicadist-postbuild-hook

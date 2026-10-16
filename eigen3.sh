package: Eigen3
version: v5.0.1
tag: "5.0.1"
source: https://gitlab.com/libeigen/eigen.git
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

cmake "$SOURCEDIR"                                               \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                      \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}  \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                 \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                    \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                               \
      -G Ninja

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include/eigen3
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
setenv Eigen3_DIR \$PKG_ROOT/share/eigen3/cmake
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/share/pkgconfig
EoF

nicadist-postbuild-hook

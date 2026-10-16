# pybind11 — Seamless interoperability between C++ and Python
package: pybind11
version: v3.1.0
tag: v3.1.0
source: https://github.com/pybind/pybind11.git
requires:
  - Python
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

cmake "$SOURCEDIR"                                              \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                  \
      -DPYBIND11_TEST=FALSE

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --root > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv Package_DIR \$PKG_ROOT/share/cmake/pybind11
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/share/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

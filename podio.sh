package: podio
version: v1.8.0
tag: v01-08
source: https://github.com/AIDASoft/podio.git
requires:
  - Catch2
  - fmt
  - GCC-ToolChain
  - lz4
  - Python
  - Python-modules
  - ROOT
  - TBB
  - xxHash
  - zlib
  - zstd
build_requires:
  - clang-format
  - CMake
  - ninja
  - nlohmann_json
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
      -DCMAKE_INSTALL_LIBDIR=lib                                \
      -DCMAKE_POLICY_DEFAULT_CMP0144=NEW

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

PYVER="$(basename $(find $INSTALLROOT/lib -type d -name 'python*'))"

cat >> "$MODULEFILE" << EoF
setenv podio_DIR \$PKG_ROOT/lib/cmake/podio
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path PYTHONPATH \$PKG_ROOT/lib/$PYVER/site-packages
EoF

nicadist-postbuild-hook

package: VMC
version: v2.2
tag: "v2-2"
source: https://github.com/vmc-project/vmc.git
requires:
  - bzip2
  - FreeType
  - libpng
  - lz4
  - ROOT
  - TBB
  - xxHash
  - zlib
  - zstd
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
      -DCMAKE_INSTALL_LIBDIR=lib

cmake --build . -- ${JOBS+-j $JOBS} install

# Create modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

VMCVER="$(basename $(find $INSTALLROOT/lib -type d -name 'VMC*'))"

cat >> "$MODULEFILE" << EoF
setenv VMC_DIR \$PKG_ROOT/lib/$VMCVER
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include/vmc
EoF

nicadist-postbuild-hook

package: VGM
version: v5.4
tag: v5-4
source: https://github.com/vmc-project/vgm.git
requires:
  - bzip2
  - FreeType
  - Geant4
  - lz4
  - libpng
  - ROOT
  - TBB
  - xerces-c
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

cmake "$SOURCEDIR"                                                          \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                                 \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}             \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                            \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                               \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                                          \
      -G Ninja                                                              \
      -DCMAKE_INSTALL_LIBDIR=lib                                            \
      -DCMAKE_POLICY_DEFAULT_CMP0144=NEW                                    \
      ${XERCES_C_ROOT:+-DXercesC_INCLUDE_DIR=$XERCES_C_ROOT/include}        \
      ${XERCES_C_ROOT:+-DXercesC_LIBRARY=$XERCES_C_ROOT/lib/libxerces-c.so} \

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

VGMVER="$(basename $(find $INSTALLROOT/lib -type d -name 'VGM-*'))"

cat >> "$MODULEFILE" << EoF
setenv VGM_DIR \$PKG_ROOT/lib/$VGMVER
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

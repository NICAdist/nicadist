package: LCIO
version: v2.23.3
tag: v02-23-03
source: https://github.com/iLCSoft/LCIO.git
requires:
  - bzip2
  - Catch2
  - CLHEP
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
      -DCMAKE_INSTALL_LIBDIR=lib                                \
      -DCMAKE_POLICY_DEFAULT_CMP0074=NEW                        \
      -DCMAKE_POLICY_DEFAULT_CMP0144=NEW                        \
      -DCMAKE_POLICY_DEFAULT_CMP0153=OLD                        \
      -DBUILD_ROOTDICT=ON                                       \
      -DROOT_DIR=$ROOTSYS

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv LCIO_DIR \$PKG_ROOT/lib/cmake/LCIO
setenv SIO_DIR \$PKG_ROOT/lib/cmake/SIO
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path PYTHONPATH \$PKG_ROOT/python
EoF

nicadist-postbuild-hook

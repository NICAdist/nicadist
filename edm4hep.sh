package: EDM4hep
version: v01.01.01
tag: v01-01-01
source: https://github.com/key4hep/EDM4hep.git
requires:
  - HepMC3
  - HepPDT
  - lz4
  - podio
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
#!/bin/bash
#export HEPPDT_ROOT_DIR=$HEPPDT_ROOT

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
setenv EDM4HEP_DIR \$PKG_ROOT/lib/cmake/EDM4HEP
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path PYTHONPATH \$PKG_ROOT/lib/$PYVER/site-packages
EoF

nicadist-postbuild-hook

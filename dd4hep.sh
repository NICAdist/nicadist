package: DD4hep
version: v1.38.0
tag: v01-38
source: https://github.com/AIDASoft/DD4hep.git
requires:
  - bzip2
  - EDM4hep
  - FreeType
  - GCC-ToolChain
  - Geant4
  - LCIO
  - libpng
  - lz4
  - podio
  - Python
  - Python-modules
  - ROOT
  - TBB
  - xerces-c
  - xxHash
  - zlib
  - zstd
build_requires:
  - Boost
  - CMake
  - ninja
  - nlohmann_json
---
#!/bin/bash
##  # fix c++20 standard related bug
#sed -i 's@std::vector<PlacedVolume> placements {  };@std::vector<PlacedVolume> placements;@g' $SOURCEDIR/DDCore/include/DD4hep/Volumes.h

#      -DCMAKE_POLICY_DEFAULT_CMP0074=NEW                                    \

cmake "$SOURCEDIR"                                                          \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                                 \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}             \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                            \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                               \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                                          \
      -G Ninja                                                              \
      -DCMAKE_POLICY_DEFAULT_CMP0144=NEW                                    \
      -DDD4HEP_USE_GEANT4=ON                                                \
      -DDD4HEP_USE_LCIO=ON                                                  \
      -DDD4HEP_USE_EDM4HEP=ON                                               \
      -DBUILD_DOCS=OFF                                                      \
      ${XERCES_C_ROOT:+-DXercesC_INCLUDE_DIR=$XERCES_C_ROOT/include}        \
      ${XERCES_C_ROOT:+-DXercesC_LIBRARY=$XERCES_C_ROOT/lib/libxerces-c.so} \
      ${PYTHON_ROOT:+-DPython_ROOT_DIR=$PYTHON_ROOT}                        \
      ${LCIO_ROOT:+-DLCIO_DIR=$LCIO_ROOT}                                   \
      -DROOT_DIR=$ROOTSYS                                                   \
      ${PYTHON_MODULES_ROOT:+-DCMAKE_PREFIX_PATH=$PYTHON_MODULES_ROOT/share/python-modules/bin}

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

PYVER="$(basename $(find $INSTALLROOT/lib -type d -name 'python*'))"

cat >> "$MODULEFILE" << EoF
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
setenv DD4hep_DIR \$PKG_ROOT/cmake
prepend-path PYTHONPATH \$PKG_ROOT/lib/$PYVER/site-packages
EoF

nicadist-postbuild-hook

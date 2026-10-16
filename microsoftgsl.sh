package: MicrosoftGSL
version: v4.2.2
tag: v4.2.2 # v5.x.x does not work with latest ONNXRuntime (1.30)
source: https://github.com/Microsoft/GSL.git
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e

# recipe for the C++ guidelines support library (Microsoft implementation)
cmake "$SOURCEDIR"                                              \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                  \
      -DGSL_TEST=OFF

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --root > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv Microsoft_GSL_DIR \$PKG_ROOT/share/cmake/Microsoft.GSL
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

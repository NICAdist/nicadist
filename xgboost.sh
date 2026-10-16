package: XGBoost
version: v3.4.1
tag: v3.4.1
source: https://git.jinr.ru/mpd/nicadist/XGBoost.git
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e

# Forced Release build type since executable is 12x smaller than
# when running RelWithDebugInfo
cmake "$SOURCEDIR"                                              \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      -DCMAKE_BUILD_TYPE="Release"                              \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                  \
      -DCMAKE_INSTALL_LIBDIR=lib                                \

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv dmlc_DIR \$PKG_ROOT/lib/cmake/dmlc
setenv xgboost_DIR \$PKG_ROOT/lib/cmake/xgboost
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

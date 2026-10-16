package: ONNX
version: v1.22.0
tag: v1.22.0
source: https://github.com/onnx/onnx.git
requires:
  - abseil-cpp
  - GCC-ToolChain
  - protobuf
  - pybind11
build_requires:
  - CMake
  - ninja
  - Python
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
      -DCMAKE_POLICY_DEFAULT_CMP0144=NEW                        \
      -DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON                     \
      -DONNX_BUILD_PYTHON=TRUE                                  \
      -DONNX_DISABLE_STATIC_REGISTRATION=ON

cmake --build . -- ${IGNORE_ERRORS:+-k} ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv ONNX_DIR \$PKG_ROOT/lib/cmake/ONNX
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

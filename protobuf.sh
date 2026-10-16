package: protobuf
version: v36.1
tag: v36.1
source: https://github.com/protocolbuffers/protobuf.git
requires:
  - abseil-cpp
  - GCC-ToolChain
  - zlib
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja

cmake "$SOURCEDIR"                                              \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                  \
      -DCMAKE_INSTALL_LIBDIR=lib                                \
      -DCMAKE_POLICY_DEFAULT_CMP0144=NEW                        \
      -Dprotobuf_BUILD_TESTS=NO                                 \
      -Dprotobuf_MODULE_COMPATIBLE=YES                          \
      -Dprotobuf_BUILD_SHARED_LIBS=OFF                          \
      ${ZLIB_ROOT:+-DZLIB_ROOT=$ZLIB_ROOT} 

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

# Add additional paths to the modulefile
cat >> "$MODULEFILE" << EoF
setenv protobuf_DIR \$PKG_ROOT/lib/cmake/protobuf
setenv utf8_range_DIR \$PKG_ROOT/lib/cmake/utf8_range
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

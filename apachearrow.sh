package: ApacheArrow
version: v25.0.1
tag: apache-arrow-25.0.1
source: https://github.com/apache/arrow.git
requires:
  - Boost
  - OpenSSL
  - protobuf
  - xsimd
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja

cmake "$SOURCEDIR/cpp"                                          \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                  \
      -DCMAKE_INSTALL_LIBDIR=lib                                \
      -DARROW_BOOST_USE_SHARED=ON                               \
      -DARROW_BUILD_EXAMPLES=OFF                                \
      -DARROW_BUILD_TESTS=OFF                                   \
      -DARROW_GENERATE_COVERAGE=OFF                             \
      -DARROW_PARQUET=ON                                        \
      -DARROW_PROTOBUF_USE_SHARED=ON                            \
      -DBUILD_SHARED_LIBS=TRUE                                  \
      -DPARQUET_BUILD_EXECUTABLES=ON

cmake --build . -- ${JOBS+-j $JOBS} install

# Create modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

# Add additional paths to the modulefile
cat >> "$MODULEFILE" << EoF
setenv Arrow_DIR \$PKG_ROOT/lib/cmake/Arrow
setenv Parquet_DIR \$PKG_ROOT/lib/cmake/Parquet
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

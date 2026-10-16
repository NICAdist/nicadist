# Package containing HDF5 library, plugins, and HighFive c++ bindings
# It build HDF5 v2.2.0, HFD5_plugins V2.2.0, and HighFive v3.3.0
package: HDF5-Tools
version: v2.2.0
tag: 2.2.0
source: https://github.com/HDFGroup/hdf5.git
requires:
  - bzip2
  - C-Blosc
  - C-Blosc2
  - libjpeg-turbo
  - liblzf
  - lz4
  - zlib
build_requires:
  - autotools
  - CMake
  - ninja
license: BSD-3-Clause
prefer_system_check: |
  printf "#include <hdf5.h>\n" | cc -xc - -I$(brew --prefix hdf5)/include -c -o /dev/null
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

BUILD_VERSION="2.2.0" # same as GIT_TAG. GIT_TAG is not set during dev (incremental) builds
PATCH=$ALIBUILD_CONFIG_DIR/patches/HDF5-Tools/hdf5_v$BUILD_VERSION.patch

# If I have patch available, then apply it
if [ -f "$PATCH" ]; then
  cd "$SOURCEDIR"
  patch -p1 < $PATCH
  cd $BUILDDIR
fi

cmake "$SOURCEDIR"                                              \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                  \
      -DCMAKE_INSTALL_LIBDIR=lib                                \
      -DBUILD_TESTING=OFF                                       \
      -DHDF5_BUILD_CPP_LIB=ON

cmake --build . -- ${JOBS+-j $JOBS} install

# Clone and build HDF5 plugins
git clone -b "2.2.0" --depth 1 --single-branch https://github.com/HDFGroup/hdf5_plugins.git
cd hdf5_plugins
autoreconf -ivf
./configure --prefix="$INSTALLROOT"                                                        \
            --with-hdf5-plugin-path="$INSTALLROOT/lib/plugin"                              \
            CPPFLAGS="-I$INSTALLROOT/include -I$LZ4_ROOT/include -I$LIBJPEG_TURBO_ROOT/include -I$BZIP2_ROOT/include -I$LIBLZF_ROOT/include " \
            LDFLAGS="-L$INSTALLROOT/lib -L$LZ4_ROOT/lib -L$LIBJPEG_TURBO_ROOT/lib -L$BZIP2_ROOT/lib -L$LIBLZF_ROOT/lib"
make ${JOBS:+-j$JOBS}
make install
# C-Blosc plugin
cd BLOSC
autoreconf -ivf
./configure --prefix="$INSTALLROOT"                                   \
            --with-hdf5-plugin-dir="$INSTALLROOT/lib/plugin"          \
            CPPFLAGS="-I$INSTALLROOT/include -I$C_BLOSC_ROOT/include" \
            LDFLAGS="-L$INSTALLROOT/lib -L$C_BLOSC_ROOT/lib"
make ${JOBS:+-j$JOBS}
make install
# C-Blosc2 plugin
cd ../BLOSC2
autoreconf -ivf
./configure --prefix="$INSTALLROOT"                                    \
            --with-hdf5-plugin-dir="$INSTALLROOT/lib/plugin"           \
            CPPFLAGS="-I$INSTALLROOT/include -I$C_BLOSC2_ROOT/include" \
            LDFLAGS="-L$INSTALLROOT/lib -L$C_BLOSC2_ROOT/lib"
make ${JOBS:+-j$JOBS}
make install
cd ../..
# Clone HighFive header-only c++ library
git clone -b "v3.3.0" --depth 1 --single-branch https://github.com/highfive-devs/highfive.git
mkdir highfive/build
cd highfive/build

cmake "$BUILDDIR/highfive"                                      \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                  \
      -DHDF5_ROOT="$INSTALLROOT"                                \
      -DHIGHFIVE_UNIT_TESTS=NO                                  \
      -DHIGHFIVE_EXAMPLES=NO                                    \
      -DHIGHFIVE_BUILD_DOCS=NO

cmake --build . -- ${JOBS+-j $JOBS} install

# Make search for HDF5 silent.
sed -i 's@find_dependency(HDF5)@find_dependency(HDF5 QUIET)@g' $INSTALLROOT/lib/cmake/HighFive/HighFiveConfig.cmake

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv HighFive_DIR \$PKG_ROOT/lib/cmake/HighFive
setenv hdf5_DIR \$PKG_ROOT/lib/cmake/hdf5
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path LD_LIBRARY_PATH \$PKG_ROOT/lib/plugin
EoF

nicadist-postbuild-hook

package: FFTW
version: v3.3.11
tag: v3.3.11
source: https://git.jinr.ru/mpd/nicadist/FFTW.git
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja

mkdir shared
pushd shared
  echo 'Building shared FFTW library'
  cmake "$SOURCEDIR"                                              \
        -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
        ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
        ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
        ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
        -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
        -G Ninja                                                  \
        -DCMAKE_INSTALL_LIBDIR=lib                                \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5                        \
        -DBUILD_SHARED_LIBS=ON
  cmake --build . -- ${JOBS+-j $JOBS} install
popd

mkdir static
pushd static
  echo 'Building static FFTW library'
  cmake "$SOURCEDIR"                                              \
        -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
        ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
        ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
        ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
        -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
        -G Ninja                                                  \
        -DCMAKE_INSTALL_LIBDIR=lib                                \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5                        \
        -DBUILD_SHARED_LIBS=OFF
  cmake --build . -- ${JOBS+-j $JOBS} install
popd

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv fftw3_DIR \$PKG_ROOT/lib/cmake/fftw3
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

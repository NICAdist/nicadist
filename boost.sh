package: Boost
version: v1.92.0
tag: v1.92.0
source: https://git.jinr.ru/mpd/nicadist/boost.git
# v1.75.0 is not compatible with Python 3.11
# v1.85.0 contains bug breaking ACTS (https://github.com/boostorg/container/issues/273)
requires:
  - bzip2
  - libpng
  - Python-modules
  - zlib
build_requires:
  - CMake
  - ninja
  - lzma
  - OpenSSL
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
      -DBOOST_ENABLE_PYTHON=ON                                  \
      -DBUILD_SHARED_LIBS=ON                                    \
      -DBUILD_TESTING=OFF

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

BOOSTVER="$(basename $(find $INSTALLROOT/lib/cmake -type d -name 'Boost*'))"

cat >> "$MODULEFILE" << EoF
setenv Boost_DIR \$PKG_ROOT/lib/cmake/$BOOSTVER
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

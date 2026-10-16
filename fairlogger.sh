package: FairLogger
version: v2.3.2
tag: v2.3.2
source: https://github.com/FairRootGroup/FairLogger.git
requires:
  - fmt
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

cmake "$SOURCEDIR"                                               \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                      \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}  \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                 \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                    \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                               \
      -G Ninja                                                   \
      -DCMAKE_INSTALL_LIBDIR=lib                                 \
      ${CXX_COMPILER:+-DCMAKE_CXX_COMPILER=$CXX_COMPILER}        \
      -DPROJECT_GIT_VERSION=$(echo $PKGVERSION | sed -e 's/v//') \
      -DBUILD_TESTING=OFF                                        \
      -DDISABLE_COLOR=OFF                                        \
      -DUSE_EXTERNAL_FMT=ON

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

FLOGGERVER="$(basename $(find $INSTALLROOT/lib/cmake -type d -name 'FairLogger*'))"

cat >> "$MODULEFILE" << EoF
setenv FairLogger_DIR \$PKG_ROOT/lib/cmake/$FLOGGERVER
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

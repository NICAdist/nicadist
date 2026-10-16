package: NICA_scheduler
version: v24.06.0
tag: 24.06.0
source: https://git.jinr.ru/nica_modules/mpd_scheduler.git
requires:
  - libxml2
  - ROOT
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

sed -i 's@cmake_minimum_required(VERSION 3.9.0)@cmake_minimum_required(VERSION 3.28)@g' $SOURCEDIR/CMakeLists.txt
sed -i 's@#include <ctime>@#include <ctime>\n#include <cstdint>@g' $SOURCEDIR/src/function_set.h

unset SIMPATH
export NICA_SCHEDULER_ROOT=$INSTALLROOT

cmake "$SOURCEDIR"                                                  \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                         \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}     \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                    \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                       \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                      \
      ${LIBXML2_ROOT:+-DPC_LIBXML_INCLUDEDIR=$LIBXML2_ROOT/include} \
      ${LIBXML2_ROOT:+-DPC_LIBXML_LIBDIR=$LIBXML2_ROOT/lib}         \
      ${ROOT_ROOT:+-DROOTSYS=$ROOT_ROOT}

cmake --build . -- ${JOBS+-j $JOBS} install

# hack to keep install directory clean
rm -f $INSTALLROOT/nica-scheduler
rm -f $INSTALLROOT/merge_result.C
rm -f $INSTALLROOT/union.sh

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin > $MODULEFILE

nicadist-postbuild-hook

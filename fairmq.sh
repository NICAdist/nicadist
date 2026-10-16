package: FairMQ
version: v1.11.0
tag: v1.11.0
source: https://github.com/FairRootGroup/FairMQ.git
requires:
  - Boost
  - FairLogger
  - fmt
  - GCC-ToolChain
  - ZeroMQ
build_requires:
  - CMake
  - FairCMakeModules
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

cmake "$SOURCEDIR"                                                             \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                                    \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}                \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                               \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                                  \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                                             \
      -G Ninja                                                                 \
      -DCMAKE_INSTALL_LIBDIR=lib                                               \
      ${CXX_COMPILER:+-DCMAKE_CXX_COMPILER=$CXX_COMPILER}                      \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                                  \
      ${FAIRLOGGER_ROOT:+-DFairLogger_ROOT=$FAIRLOGGER_ROOT}                   \
      ${ZEROMQ_ROOT:+-DZeroMQ_ROOT=$ZEROMQ_ROOT}                               \
      ${FAIRCMAKEMODULES_ROOT:+-DFairCMakeModules_ROOT=$FAIRCMAKEMODULES_ROOT} \
      -DDISABLE_COLOR=OFF                                                      \
      -DBUILD_EXAMPLES=OFF

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

FMQVER="$(basename $(find $INSTALLROOT/lib/cmake -type d -name 'FairMQ-*'))"

cat >> "$MODULEFILE" << EoF
setenv FairMQ_DIR \$PKG_ROOT/lib/cmake/$FMQVER
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include/fairmq
EoF

nicadist-postbuild-hook

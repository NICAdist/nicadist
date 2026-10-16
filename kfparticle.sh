# for TARGET_ARCHITECTURE see vc.sh
package: KFParticle
version: v2020.06.10
tag: 3e9c2681bff1eb6594362ba98bcff2dcb090ac36
source: https://github.com/FlowNICA/KFParticle.git
requires:
  - ROOT
  - Vc
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

rsync -a --exclude '**/.git*' $SOURCEDIR/ $BUILDDIR/KFPARTICLE_SOURCE

# bump minimal required version according to Vc
sed -i 's@cmake_minimum_required(VERSION 2.8.8 FATAL_ERROR)@cmake_minimum_required(VERSION 3.28)@g' $BUILDDIR/KFPARTICLE_SOURCE/CMakeLists.txt
# don't force c++11, we use c++20
sed -i 's@  set (CMAKE_CXX_STANDARD 11)@@g' $BUILDDIR/KFPARTICLE_SOURCE/CMakeLists.txt

cmake "$BUILDDIR/KFPARTICLE_SOURCE"                             \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                  \
      ${VC_ROOT:+-DVc_INCLUDE_DIR=$VC_ROOT/include}             \
      ${VC_ROOT:+-DVc_LIBRARIES=$VC_ROOT/lib/libVc.a}           \
      -DFIXTARGET=FALSE

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv KFParticle_DIR \$PKG_ROOT/lib/cmake/KFParticle
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

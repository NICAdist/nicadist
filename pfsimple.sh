# for TARGET_ARCHITECTURE see vc.sh
package: PFSimple
version: v2024.03.28
tag: cd5b219172d911442144e3a5bc45797d4c014289
source: https://github.com/FlowNICA/PFSimple.git
requires:
  - KFParticle
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

BUILD_VERSION="cd5b21" # same as GIT_TAG. GIT_TAG is not set during dev (incremental) builds
PATCH=$ALIBUILD_CONFIG_DIR/patches/PFSimple/PFSimple_$BUILD_VERSION.patch

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
      -DCMAKE_POLICY_DEFAULT_CMP0074=NEW                        \
      -DCMAKE_POLICY_DEFAULT_CMP0144=NEW                        \
      ${VC_ROOT:+-DVc_INCLUDE_DIR=$VC_ROOT/include}             \
      ${VC_ROOT:+-DVc_LIBRARIES=$VC_ROOT/lib/libVc.a}           \
      -DTARGET_ARCHITECTURE="ivy-bridge"                        \
      -DPFSimple_BUNDLED_AT=OFF                                 \
      -DPFSimple_BUILD_TESTS=OFF

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv KFParticleSimple_DIR \$PKG_ROOT/lib/cmake/KFParticleSimple
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

# Warning: Don't forget to set BUILD_VERSION below twice!
package: FairRoot
version: v18.6.11
tag: v18.6.11
source: https://github.com/FairRootGroup/FairRoot.git
requires:
  - Boost
  - bzip2
  - clang-format
  - DDS
  - FairLogger
  - FairMQ
  - FlatBuffers
  - fmt
  - FreeType
  - GCC-ToolChain
  - Geant4
  - Geant4_VMC
  - GSL
  - libpng
  - lz4
  - protobuf
  - pythia
  - ROOT
  - TBB
  - VGM
  - VMC
  - xerces-c # needed for Geant4
  - xxHash
  - yaml-cpp
  - ZeroMQ
  - zlib
  - zstd
build_requires:
  - CMake
  - ninja
incremental_recipe: |
  rsync -a --exclude '**/.git' $SOURCEDIR/ $BUILDDIR/FAIR_ROOT_SOURCES
  BUILD_VERSION="v18.6.11" # same as GIT_TAG. GIT_TAG is not set during dev (incremental) builds
  PATCH=$ALIBUILD_CONFIG_DIR/patches/FairRoot/fairroot_$BUILD_VERSION.patch
  if [ -f "$PATCH" ]; then
    echo "Patch $PATCH exists."
  fi
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

BUILD_VERSION="v18.6.11" # same as GIT_TAG. GIT_TAG is not set during dev (incremental) builds
PATCH=$ALIBUILD_CONFIG_DIR/patches/FairRoot/fairroot_$BUILD_VERSION.patch

# Making sure people do not have SIMPATH set when they build fairroot.
# Unfortunately SIMPATH seems to be hardcoded in a bunch of places in
# fairroot, so this really should be cleaned up in FairRoot itself for
# maximum safety.
unset SIMPATH

rsync -a --exclude '**/.git' --delete $SOURCEDIR/ $BUILDDIR/FAIR_ROOT_SOURCES

# If I have patch available, then apply it
if [ -f "$PATCH" ]; then
  cd "$BUILDDIR/FAIR_ROOT_SOURCES"
  patch -p1 < $PATCH
  cd $BUILDDIR
fi

cmake "$BUILDDIR/FAIR_ROOT_SOURCES"                                                         \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                                                 \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}                             \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                                            \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                                               \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                                                          \
      -G Ninja                                                                              \
      -DCMAKE_INSTALL_LIBDIR=lib                                                            \
      ${ROOTSYS:+-DROOTSYS=$ROOTSYS}                                                        \
      -DBUILD_MBS=OFF                                                                       \
      -DBUILD_EXAMPLES=OFF                                                                  \
      -DBUILD_UNITTESTS=OFF                                                                 \
      -DBUILD_DOXYGEN=OFF                                                                   \
      ${Geant4_ROOT:+-DGeant4_DIR=$Geant4_ROOT}                                             \
      ${DDS_ROOT:+-DDDS_ROOT=$DDS_ROOT}                                                     \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                                               \
      ${GSL_ROOT:+-DGSL_DIR=$GSL_ROOT}                                                      \
      ${GSL_ROOT:+-DGSL_ROOT=$GSL_ROOT}                                                     \
      ${YAML_CPP_ROOT:+-DYAML-CPP_ROOT=$YAML_CPP_ROOT}                                      \
      ${YAML_CPP_ROOT:+-DYAML_CPP_INCLUDE_DIR=$YAML_CPP_ROOT/include}                       \
      ${FLATBUFFERS_ROOT:+-DFLATBUFFERS_ROOT=$FLATBUFFERS_ROOT}                             \
      ${CLANG_FORMAT_ROOT:+-DGIT_CLANG_FORMAT_BIN=$CLANG_FORMAT_ROOT/bin/git-clang-format}  \
      ${CLANG_FORMAT_ROOT:+-DCLANG_FORMAT_BIN=$CLANG_FORMAT_ROOT/bin/clang-format}          \
      ${CLANG_FORMAT_ROOT:+-DClangFormat_ROOT=$CLANG_FORMAT_ROOT}                           \
      ${XERCES_C_ROOT:+-DXercesC_INCLUDE_DIR=$XERCES_C_ROOT/include}                        \
      ${XERCES_C_ROOT:+-DXercesC_LIBRARY=$XERCES_C_ROOT/lib/libxerces-c.so}                 \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cmake --build . -- ${JOBS+-j $JOBS} install

# Work around hardcoded paths in PCM
for DIR in source sink field event sim steer; do
  ln -nfs ../include $INSTALLROOT/include/$DIR
done

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv FAIRROOT_ROOT_DIR \$PKG_ROOT
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
setenv VMCWORKDIR \$PKG_ROOT/share/fairbase/examples"
setenv GEOMPATH \$PKG_ROOT/share/fairbase/examples/common/geometry"
setenv CONFIG_DIR \$PKG_ROOT/share/fairbase/examples/common/gconfig"
EoF

nicadist-postbuild-hook

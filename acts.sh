# Make sure, that version in tag and BUILD_VERSION in the beginning of the recipe are the same!
# This recipe is tested only on version of ACTS from given list. Patches for other versions
# of ACTS need to be added in order for it to work according to expectations.
# New version patches
# v48.0.1
package: ACTS
version: v48.0.1
tag: v48.0.1
source: https://github.com/acts-project/acts.git
requires:
  - Boost
  - Eigen3
  - GCC-ToolChain
  - Geant4
  - HepMC3
  - LCIO
  - lz4
  - ONNXRuntime
  - pythia
  - Python
  - Python-modules
  - ROOT
  - TBB
  - xerces-c
  - xxHash
  - zlib
  - zstd
build_requires:
  - CMake
  - ninja
  - nlohmann_json
incremental_recipe: |
  rsync -a --exclude '**/.git' $SOURCEDIR/ $BUILDDIR/ACTS_SOURCES
  REFERENCE_VERSION="48.0.0"
  BUILD_VERSION="v48.0.1" # same as GIT_TAG. GIT_TAG is not set during dev (incremental) builds
  ACTUAL_VERSION=$(echo "$BUILD_VERSION" | sed 's/^v//')
  if [ "$(printf '%s\n%s' "$ACTUAL_VERSION" "$REFERENCE_VERSION" | sort -V | head -n1)" = "$ACTUAL_VERSION" ] && [ "$ACTUAL_VERSION" != "$REFERENCE_VERSION" ]; then
    # old approach to patches
    PATCH_URL=https://git.jinr.ru/nica/nicadist/-/raw/master/patches/acts/$BUILD_VERSION/downloadPatches
    set +e # enable errors. If disabled, following command will exit script if given file does not exist
    $(wget -q --spider --tries 1 $PATCH_URL)
    HAS_PATCH=$?
    set -e
    if [[ $HAS_PATCH -eq 0 ]]; then # patch is available
      mkdir -p $BUILDDIR/ACTS_SOURCES/nicaPatches && cd $BUILDDIR/ACTS_SOURCES/nicaPatches/
      pushd $BUILDDIR/ACTS_SOURCES/nicaPatches
        wget -N $PATCH_URL
        . downloadPatches
        . applyPatches
      popd
    fi
  else
    PATCH=$ALIBUILD_CONFIG_DIR/patches/ACTS/ACTS_$BUILD_VERSION.patch
    if [ -f "$PATCH" ]; then
      cd "$BUILDDIR/ACTS_SOURCES"
      patch -p1 < $PATCH
      cd $BUILDDIR
    fi
  fi
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

rsync -a --exclude '**/.git' --delete $SOURCEDIR/ $BUILDDIR/ACTS_SOURCES
REFERENCE_VERSION="48.0.0"
BUILD_VERSION="v48.0.1" # same as GIT_TAG. GIT_TAG is not set during dev (incremental) builds
ACTUAL_VERSION=$(echo "$BUILD_VERSION" | sed 's/^v//')

if [ "$(printf '%s\n%s' "$ACTUAL_VERSION" "$REFERENCE_VERSION" | sort -V | head -n1)" = "$ACTUAL_VERSION" ] && [ "$ACTUAL_VERSION" != "$REFERENCE_VERSION" ]; then
  # old approach to patches
  PATCH_URL=https://git.jinr.ru/nica/nicadist/-/raw/master/patches/acts/$BUILD_VERSION/downloadPatches
  set +e # enable errors. If disabled, following command will exit script if given file does not exist
  $(wget -q --spider --tries 1 $PATCH_URL)
  HAS_PATCH=$?
  set -e
  if [[ $HAS_PATCH -eq 0 ]]; then # patch is available
    mkdir -p $BUILDDIR/ACTS_SOURCES/nicaPatches && cd $BUILDDIR/ACTS_SOURCES/nicaPatches/
    pushd $BUILDDIR/ACTS_SOURCES/nicaPatches
      wget -N $PATCH_URL
      . downloadPatches
      . applyPatches
    popd
  fi
else
  # new approach since v48.0.0 - real patch files
  PATCH=$ALIBUILD_CONFIG_DIR/patches/acts/ACTS_$BUILD_VERSION.patch
  if [ -f "$PATCH" ]; then
    cd "$BUILDDIR/ACTS_SOURCES"
    patch -p1 < $PATCH
    cd $BUILDDIR
  fi
fi

# Add path to uv so that ACTS can find it
export PATH=$PYTHON_MODULES_ROOT/share/python-modules/bin:$PATH

cmake "$BUILDDIR/ACTS_SOURCES"                                              \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                                 \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}             \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                            \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                               \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                                          \
      -G Ninja                                                              \
      -DCMAKE_INSTALL_LIBDIR=lib                                            \
      -DCMAKE_POLICY_DEFAULT_CMP0144=NEW                                    \
      -DACTS_USE_SYSTEM_NLOHMANN_JSON=ON                                    \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                               \
      ${XERCES_C_ROOT:+-DXercesC_INCLUDE_DIR=$XERCES_C_ROOT/include}        \
      ${XERCES_C_ROOT:+-DXercesC_LIBRARY=$XERCES_C_ROOT/lib/libxerces-c.so} \
      -DACTS_BUILD_EXAMPLES=ON                                              \
      -DACTS_BUILD_FATRAS=ON                                                \
      -DACTS_BUILD_PLUGIN_DD4HEP=OFF                                        \
      -DACTS_BUILD_PLUGIN_EDM4HEP=OFF                                       \
      -DACTS_BUILD_PLUGIN_FPEMON=ON                                         \
      -DACTS_BUILD_PLUGIN_GEANT4=ON                                         \
      -DACTS_BUILD_PLUGIN_JSON=ON                                           \
      -DACTS_BUILD_PLUGIN_ONNX=ON                                           \
      -DACTS_BUILD_PLUGIN_ROOT=ON

# If build crashes without obvious reason, remove ${JOBS+-j$JOBS} and run single-thread build
cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > "$MODULEFILE"

cat >> "$MODULEFILE" << EoF
setenv Acts_DIR \$PKG_ROOT/lib/cmake/Acts
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

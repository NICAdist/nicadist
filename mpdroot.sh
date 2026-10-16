package: mpdroot
version: "%(commit_hash)s"
tag: "future_main"
source: https://git.jinr.ru/nica/mpdroot.git
requires:
  - Boost
  - bzip2
  - FairLogger
  - FairRoot
  - FFTW
  - fmt
  - FreeType
  - GCC-ToolChain
  - libpng
  - libxml2
  - lz4
  - PostgreSQL
  - pythia
  - ROOT
  - RooUnfold
  - TBB
  - VMC
  - xxHash
  - zlib
  - zstd
build_requires:
  - CMake
  - GSL
  - ninja
  - nlohmann_json
  - ZeroMQ
##env:
##  VMCWORKDIR: "$MPDROOT/macros"
##  GEOMPATH:   "$MPDROOT/geometry"
##  CONFIG_DIR: "$MPDROOT/gconfig"
---
#!/bin/bash -e
export CLICOLOR_FORCE=1
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja

# Making sure people do not have SIMPATH set when they build fairroot.
# Unfortunately SIMPATH seems to be hardcoded in a bunch of places in
# fairroot, so this really should be cleaned up in FairRoot itself for
# maximum safety.
unset SIMPATH

#
# To build use:
#  aliBuild --no-system --remote-store ~/fair/sw::rw build --debug --defaults global -j10 MPDRoot 2>&1 | tee output.txt
#
# Enter the module environment:
#  alienv enter MPDRoot/latest-30-fix-cmakelists-txt-to-accept-paths-as-parameters-mpd
#
# To use with MPD, for now one has to set paths to source directory:
#  export CONFIG_DIR=/var/home/busa/fair/MPDRoot/gconfig
#  export GEOMPATH=/var/home/busa/fair/MPDRoot/geometry
#  export VMCWORKDIR=/home/busa/fair/MPDRoot    <- this is still hard-coded inside inside MPDRoot, needs to be removed first
#
export MPDROOT=$INSTALLROOT

if [ ! "X$BOOST_ROOT" = X ]; then
  BOOSTVER="$(basename $(find $BOOST_ROOT/lib/cmake -type d -name 'Boost*'))"
fi

if [ ! "X$FAIRLOGGER_ROOT" = X ]; then
  FLOGGERVER="$(basename $(find $FAIRLOGGER_ROOT/lib/cmake -type d -name 'FairLogger*'))"
fi

if [ ! "X$GSL_ROOT" = X ]; then
  export PKG_CONFIG_PATH=$GSL_ROOT/lib/pkgconfig:$PKG_CONFIG_PATH
fi

if [ ! "X$ROOUNFOLD_ROOT" = X ]; then
  export PKG_CONFIG_PATH=$ROOUNFOLD_ROOT/lib/pkgconfig:$PKG_CONFIG_PATH
fi

cmake "$SOURCEDIR"                                                                             \
      -DCMAKE_INSTALL_PREFIX="$MPDROOT"                                                        \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}                                \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                                               \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                                                  \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                                                             \
      -G Ninja                                                                                 \
      -DCMAKE_POLICY_DEFAULT_CMP0144=NEW                                                       \
      ${BOOST_ROOT:+-DBoost_DIR=$BOOST_ROOT/lib/cmake/$BOOSTVER}                               \
      ${FAIRLOGGER_ROOT:+-DFairLogger_DIR=$FAIRLOGGER_ROOT/lib/cmake/$FLOGGERVER}              \
      ${FAIRROOT_ROOT:+-DFAIRROOT_ROOT_DIR=$FAIRROOT_ROOT}                                     \
      ${FFTW_ROOT:+-Dfftw3_DIR=$FFTW_ROOT/lib/cmake/fftw3}                                     \
      ${FMT_ROOT:+-Dfmt_DIR=$FMT_ROOT/lib/cmake/fmt}                                           \
      ${LIBXML2_ROOT:+-Dlibxml2_DIR=$LIBXML2_ROOT/lib/cmake/libxml2}                           \
      ${NLOHMANN_JSON_ROOT:+-Dnlohmann_json_DIR=$NLOHMANN_JSON_ROOT/share/cmake/nlohmann_json} \
      ${VMC_ROOT:+-DVMC_ROOT=$VMC_ROOT}                                                        \
      ${ZEROMQ_ROOT:+-DZeroMQ_DIR=$ZEROMQ_ROOTlib/cmake/ZeroMQ}                                \
      -Wno-unused-cli

cmake --build . --target install ${JOBS+-j $JOBS}

# Work around hardcoded paths in old root files
mkdir $INSTALLROOT/include/deprecated
for DIR in clustering emcClustering emcKI hitmaker; do
# bbc bmd clustering config emc emcKI hitmaker etof eventdisplay external nicafemto \
# analysis qa v0s nicagenerators readers writers fairtools ffd gconfig generators   \
# genFactory unigen_format geobase kalman lhetrack macro mpd mcord mcstack mpdbase  \
# mpddata mpddst mcDst MpdMiniEvent mpdfield mpdpid parbase passive physics femto   \
# MpdFemtoMaker MpdFemtoMakerUser format combined minidst minidstV0 nica_helpers    \
# tasks photons shield_pack hadgen inc THadgen sts tof tpc zdc
  ln -nfs ../../include $INSTALLROOT/include/deprecated/$DIR
done

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib --path > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv MpdRoot_DIR \$PKG_ROOT/lib/cmake/MpdRoot
setenv MPDROOT \$PKG_ROOT
setenv GEOMPATH \$PKG_ROOT/geometry
setenv CONFIG_DIR \$PKG_ROOT/gconfig
setenv MPDROOT_MACROS \$PKG_ROOT/macros
setenv VMCWORKDIR \$PKG_ROOT
prepend-path ROOT_INCLUDE_PATH \$PKG_PATH/GSL/$GSL_VERSION-$GSL_REVISION/include
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include/deprecated
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/macros/common
EoF

nicadist-postbuild-hook

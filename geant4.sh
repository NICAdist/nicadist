# When changing version of GEANT4, make sure you change first versions of datasets
# mentioned in G4_datasets.sh. We maintain separate packages for datasets to save
# (share) storage across different builds of GEANT4.
package: Geant4
version: v11.5.0.beta
tag: "v11.5.0.beta"
source: https://gitlab.cern.ch/geant4/geant4.git
requires:
  - CLHEP
  - FreeType
  - GCC-ToolChain
  - xerces-c
build_requires:
  - CMake
  - ninja
env:
  G4INSTALL : $Geant4_ROOT
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

# We download and install datasets to 'external' directory in order to share them
# between different builds
function download_and_install_dataset() {
  # $1 - path to install directory
  # $2 - package version
  # $3 - download name
  # $4 - unpacked name
  # First check if root directory exists, if not, create it
  START_DIRECTORY=$(pwd) # save starting directory to return to  start state
  echo "I'm starting in $START_DIRECTORY"
  if [ -d "$1" ]; then
    cd $1
  else
    mkdir -p $1
    cd $1
  fi
  local TEST_DIRECTORY="$4$2"
  if [ ! -d "$TEST_DIRECTORY" ]; then # Directory (and dataset) is missing. Download and unpack.
    curl -kLo data.tar.gz "https://cern.ch/geant4-data/datasets/$3.$2.tar.gz"
    tar -xf data.tar.gz
    rm -rf data.tar.gz
  fi
  cd $START_DIRECTORY
}

# For list of datasets with versions see cmake/Modules/G4DatasetDefinitions.cmake
ABLA_VER="3.3"                ABLA_BASE="G4ABLA"                           ABLA_PATH="G4ABLA"
CHANNELING_VER="2.0"          CHANNELING_BASE="G4CHANNELING"               CHANNELING_PATH="G4CHANNELING"
ENSDFSTATE_VER="3.0"          ENSDFSTATE_BASE="G4ENSDFSTATE"               ENSDFSTATE_PATH="G4ENSDFSTATE"
EMLOW_VER="9.0"               EMLOW_BASE="G4EMLOW"                         EMLOW_PATH="G4EMLOW"
INCL_VER="1.3"                INCL_BASE="G4INCL"                           INCL_PATH="G4INCL"
NDL_VER="4.7.1"               NDL_BASE="G4NDL"                             NDL_PATH="G4NDL"
NUDEXLIB_VER="1.0"            NUDEXLIB_BASE="G4NUDEXLIB"                   NUDEXLIB_PATH="G4NUDEXLIB"
PARTICLEXS_VER="4.2"          PARTICLEXS_BASE="G4PARTICLEXS"               PARTICLEXS_PATH="G4PARTICLEXS"
PHOTONEVAPORATION_VER="6.1.2" PHOTONEVAPORATION_BASE="G4PhotonEvaporation" PHOTONEVAPORATION_PATH="PhotonEvaporation"
PII_VER="1.3"                 PII_BASE="G4PII"                             PII_PATH="G4PII"
RADIOACTIVEDECAY_VER="6.1.2"  RADIOACTIVEDECAY_BASE="G4RadioactiveDecay"   RADIOACTIVEDECAY_PATH="RadioactiveDecay"
REALSURFACE_VER="2.2"         REALSURFACE_BASE="G4RealSurface"             REALSURFACE_PATH="RealSurface"
SAIDDATA_VER="2.0"            SAIDDATA_BASE="G4SAIDDATA"                   SAIDDATA_PATH="G4SAIDDATA"
TENDL_VER="1.4"               TENDL_BASE="G4TENDL"                         TENDL_PATH="G4TENDL"
URRPT_VER="1.1"               URRPT_BASE="G4URRPT"                         URRPT_PATH="G4URRPT"

GEANT4_DATADIR=$WORK_DIR/shared/Geant4/data
download_and_install_dataset $GEANT4_DATADIR $ABLA_VER $ABLA_BASE $ABLA_PATH
download_and_install_dataset $GEANT4_DATADIR $CHANNELING_VER $CHANNELING_BASE $CHANNELING_PATH
download_and_install_dataset $GEANT4_DATADIR $ENSDFSTATE_VER $ENSDFSTATE_BASE $ENSDFSTATE_PATH
download_and_install_dataset $GEANT4_DATADIR $EMLOW_VER $EMLOW_BASE $EMLOW_PATH
download_and_install_dataset $GEANT4_DATADIR $INCL_VER $INCL_BASE $INCL_PATH
download_and_install_dataset $GEANT4_DATADIR $NDL_VER $NDL_BASE $NDL_PATH
download_and_install_dataset $GEANT4_DATADIR $NUDEXLIB_VER $NUDEXLIB_BASE $NUDEXLIB_PATH
download_and_install_dataset $GEANT4_DATADIR $PARTICLEXS_VER $PARTICLEXS_BASE $PARTICLEXS_PATH
download_and_install_dataset $GEANT4_DATADIR $PHOTONEVAPORATION_VER $PHOTONEVAPORATION_BASE $PHOTONEVAPORATION_PATH
download_and_install_dataset $GEANT4_DATADIR $PII_VER $PII_BASE $PII_PATH
download_and_install_dataset $GEANT4_DATADIR $RADIOACTIVEDECAY_VER $RADIOACTIVEDECAY_BASE $RADIOACTIVEDECAY_PATH
download_and_install_dataset $GEANT4_DATADIR $REALSURFACE_VER $REALSURFACE_BASE $REALSURFACE_PATH
download_and_install_dataset $GEANT4_DATADIR $SAIDDATA_VER $SAIDDATA_BASE $SAIDDATA_PATH
download_and_install_dataset $GEANT4_DATADIR $TENDL_VER $TENDL_BASE $TENDL_PATH
download_and_install_dataset $GEANT4_DATADIR $URRPT_VER $URRPT_BASE $URRPT_PATH
# If this variable is not defined default it to OFF
: ${GEANT4_BUILD_MULTITHREADED:=OFF}

# Data sets directory:
# if not set (default), data sets will be installed in CMAKE_INSTALL_DATAROOTDIR
: ${GEANT4_DATADIR:=""}

cmake "$SOURCEDIR"                                                  \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                         \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}     \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                    \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                       \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                                  \
      -G Ninja                                                      \
      -DCMAKE_INSTALL_LIBDIR=lib                                    \
      ${CLHEP_ROOT:+-DCLHEP_ROOT_DIR="$CLHEP_ROOT"}                 \
      -DGEANT4_BUILD_TLS_MODEL="global-dynamic"                     \
      -DGEANT4_ENABLE_TESTING=OFF                                   \
      -DBUILD_SHARED_LIBS=ON                                        \
      -DGEANT4_INSTALL_EXAMPLES=OFF                                 \
      -DGEANT4_BUILD_MULTITHREADED="$GEANT4_BUILD_MULTITHREADED"    \
      -DGEANT4_USE_FREETYPE=ON                                      \
      -DGEANT4_USE_G3TOG4=ON                                        \
      -DGEANT4_USE_GDML=ON                                          \
      -DGEANT4_INSTALL_DATA=OFF                                     \
      -DGEANT4_USE_SYSTEM_EXPAT=OFF                                 \
      ${GEANT4_DATADIR:+-DGEANT4_INSTALL_DATADIR="$GEANT4_DATADIR"} \
      ${XERCES_C_ROOT:+-DXERCESC_ROOT_DIR=$XERCES_C_ROOT}           \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cmake --build . -- ${JOBS+-j $JOBS} install

# fix of relative paths since there are relative to INSTALLROOT instead of the real location of GEANT4
sed -i 's@/../../../../../../../../@/../../../../../../@g' $INSTALLROOT/share/Geant4/geant4make/geant4make.csh
sed -i 's@/../../../../../../../../@/../../../../../../@g' $INSTALLROOT/share/Geant4/geant4make/geant4make.sh
# hack enabling joining flags in other applications using GEANT4
sed -i 's@-std=c++20"@-std=c++20 "@g' $INSTALLROOT/lib/cmake/Geant4/Geant4Config.cmake

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include/Geant4
setenv Geant4_DIR \$PKG_ROOT/lib/cmake/Geant4
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
setenv Geant4_ROOT \$PKG_ROOT
setenv G4ABLADATA \$PKG_ROOT/../../../shared/Geant4/data/G4ABLA$ABLA_VER
setenv G4CHANNELINGDATA \$PKG_ROOT/../../../shared/Geant4/data/G4CHANNELING$CHANNELING_VER
setenv G4ENSDFSTATEDATA \$PKG_ROOT/../../../shared/Geant4/data/G4ENSDFSTATE$ENSDFSTATE_VER
setenv G4INCLDATA \$PKG_ROOT/../../../shared/Geant4/data/G4INCL$INCL_VER
setenv G4LEDATA \$PKG_ROOT/../../../shared/Geant4/data/G4EMLOW$EMLOW_VER
setenv G4LEVELGAMMADATA \$PKG_ROOT/../../../shared/Geant4/data/PhotonEvaporation$PHOTONEVAPORATION_VER
setenv G4NEUTRONHPDATA \$PKG_ROOT/../../../shared/Geant4/data/G4NDL$NDL_VER
setenv G4NUDEXLIBDATA \$PKG_ROOT/../../../shared/Geant4/data/G4NUDEXLIB$NUDEXLIB_VER
setenv G4PARTICLEHPDATA \$PKG_ROOT/../../../shared/Geant4/data/G4TENDL$TENDL_VER
setenv G4PARTICLEXSDATA \$PKG_ROOT/../../../shared/Geant4/data/G4PARTICLEXS$PARTICLEXS_VER
setenv G4PIIDATA \$PKG_ROOT/../../../shared/Geant4/data/G4PII$PII_VER
setenv G4RADIOACTIVEDATA \$PKG_ROOT/../../../shared/Geant4/data/RadioactiveDecay$RADIOACTIVEDECAY_VER
setenv G4REALSURFACEDATA \$PKG_ROOT/../../../shared/Geant4/data/RealSurface$REALSURFACE_VER
setenv G4SAIDXSDATA \$PKG_ROOT/../../../shared/Geant4/data/G4SAIDDATA$SAIDDATA_VER
setenv G4URRPTDATA \$PKG_ROOT/../../../shared/Geant4/data/G4URRPT$URRPT_VER
EoF

nicadist-postbuild-hook

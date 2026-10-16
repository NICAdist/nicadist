package: Geant4_VMC
version: v6.8.0
tag: "v6-8"
source: https://github.com/vmc-project/geant4_vmc.git
requires:
  - bzip2
  - FreeType
  - Geant4
  - libpng
  - lz4
  - ROOT
  - TBB
  - VGM
  - VMC
  - xerces-c
  - xxHash
  - zlib
  - zstd
build_requires:
  - CMake
  - ninja
prepend_path:
  ROOT_INCLUDE_PATH: "$GEANT4_VMC_ROOT/include/g4root:$GEANT4_VMC_ROOT/include/geant4vmc:$GEANT4_VMC_ROOT/include"
env:
  G4VMCINSTALL: "$GEANT4_VMC_ROOT"
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

cmake "$SOURCEDIR"                                                          \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                                 \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}             \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                            \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                               \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                                          \
      -G Ninja                                                              \
      -DCMAKE_INSTALL_LIBDIR=lib                                            \
      -DGeant4VMC_USE_VGM=ON                                                \
      ${XERCES_C_ROOT:+-DXercesC_INCLUDE_DIR=$XERCES_C_ROOT/include}        \
      ${XERCES_C_ROOT:+-DXercesC_LIBRARY=$XERCES_C_ROOT/lib/libxerces-c.so} \

cmake --build . -- ${JOBS+-j $JOBS} install

G4VMC_SHARE=$(cd "$INSTALLROOT/share"; echo Geant4VMC-* | cut -d' ' -f1)
ln -nfs "$G4VMC_SHARE/examples" "$INSTALLROOT/share/examples"

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

G4RVER="$(basename $(find $INSTALLROOT/lib -type d -name 'G4Root-*'))"
G4VMCVER="$(basename $(find $INSTALLROOT/lib -type d -name 'Geant4VMC-*'))"

cat >> "$MODULEFILE" << EoF
setenv G4Root_DIR \$PKG_ROOT/lib/$G4RVER
setenv Geant4VMC_DIR \$PKG_ROOT/lib/$G4VMCVER
setenv G4VMCINSTALL \$PKG_ROOT
setenv GEANT4VMC_MACRO_DIR \$PKG_ROOT/share/examples/macro
setenv USE_VGM 1
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include/geant4vmc
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include/g4root
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

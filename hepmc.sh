package: HepMC
version: v2.6.11
tag: HEPMC_02_06_11
source: https://gitlab.cern.ch/hepmc/HepMC.git
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

cmake "$SOURCEDIR"                                              \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                  \
      -Dmomentum=GEV                                            \
      -Dlength=MM                                               \
      -Dbuild_docs=OFF                                          \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

mkdir -p "$INSTALLROOT/lib/pkgconfig"
cat > "$INSTALLROOT/lib/pkgconfig/libHepMC.pc" << EoF
prefix=$INSTALLROOT
exec_prefix=\${prefix}
libdir=$INSTALLROOT/lib
toolexeclibdir=\${libdir}
includedir=\${prefix}/include

Name: HepMC
Description: HepMC - a C++ Event Record for Monte Carlo Generators
Version: 2.6.11
Libs: -L\${toolexeclibdir} -lHepMC
Cflags: -I\${includedir}
EoF

nicadist-postbuild-hook

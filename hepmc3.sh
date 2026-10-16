package: HepMC3
version: v3.3.1
tag: "3.3.1"
source: https://gitlab.cern.ch/hepmc/HepMC3.git
requires:
  - lz4
  - Python
  - ROOT
  - TBB
  - xxHash
  - zlib
  - zstd
build_requires:
  - CMake
  - ninja
  - nlohmann_json
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

PYVER="$(python3 -c 'import sysconfig; print(sysconfig.get_python_version().replace(".", ""))')"
PYVER_DOT="$(python3 -c 'import sysconfig; print(sysconfig.get_python_version())')"
PYTHON_PATH="-DHEPMC3_Python_SITEARCH$PYVER=$INSTALLROOT/lib/python$PYVER_DOT/site-packages"

cmake "$SOURCEDIR"                                              \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                  \
      -DCMAKE_INSTALL_LIBDIR=lib                                \
      -DCMAKE_POLICY_DEFAULT_CMP0074=NEW                        \
      -DHEPMC3_ENABLE_TEST=OFF                                  \
      -DHEPMC3_INSTALL_INTERFACES=ON                            \
      -DHEPMC3_BUILD_STATIC_LIBS=OFF                            \
      -DHEPMC3_BUILD_DOCS=OFF                                   \
      -DHEPMC3_ENABLE_PYTHON=ON                                 \
      $PYTHON_PATH

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv HepMC3_DIR \$PKG_ROOT/share/HepMC3/cmake
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path PYTHONPATH \$PKG_ROOT/lib/python$PYVER_DOT/site-packages
EoF

nicadist-postbuild-hook

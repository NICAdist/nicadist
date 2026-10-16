package: PyTorch-CPUInfo
version: v2026.07.30
tag: 66ee79c038d70dad9f08705b2c9b3e58f6d8f512
source: https://github.com/pytorch/cpuinfo.git
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

cmake "$SOURCEDIR"                                               \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                      \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}  \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                 \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                    \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                               \
      -G Ninja                                                   \
      -DCMAKE_INSTALL_LIBDIR=lib                                 \
      -DCPUINFO_BUILD_UNIT_TESTS=OFF                             \
      -DCPUINFO_BUILD_MOCK_TESTS=OFF                             \
      -DCPUINFO_BUILD_BENCHMARKS=OFF

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv cpuinfo_DIR \$PKG_ROOT/share/cpuinfo
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

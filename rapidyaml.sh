package: RapidYAML
version: v0.16.0
tag: v0.16.0
source: https://github.com/biojppm/rapidyaml.git
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

rsync -a $SOURCEDIR/ $BUILDDIR

# update directory ext which is submodule
git submodule update --init --recursive

cmake "$BUILDDIR"                                                \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                      \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}  \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                 \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                    \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                   \
      -DCMAKE_INSTALL_LIBDIR=lib

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv ryml_DIR \$PKG_ROOT/lib/cmake/ryml
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

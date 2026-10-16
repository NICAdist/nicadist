package: Cppcheck
version: v2.22.0
tag: "2.22.0"
source: https://github.com/cppcheck-opensource/cppcheck.git
requires:
  - Boost
  - Clang
  - GCC-ToolChain
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
      -DCMAKE_INSTALL_LIBDIR=lib                                \
      -DCMAKE_POLICY_DEFAULT_CMP0144=NEW                        \
      -DBUILD_TESTING=OFF                                       \
      -DUSE_MATCHCOMPILER=ON                                    \
      -DHAVE_RULES=ON                                           \
      -DBUILD_GUI=OFF                                           \
      ${BOOST_ROOT:+-DBoost_INCLUDE_DIR=$BOOST_ROOT/include}

cmake --build . -- ${JOBS+-j $JOBS} install

cp -r $INSTALLROOT/share/Cppcheck/cfg $INSTALLROOT/bin/

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv Cppcheck_ROOT \$PKG_ROOT
EoF

nicadist-postbuild-hook

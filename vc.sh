# Since this is a legacy library, we build only for ivy-bridge since it is
# the "oldest" architecture available on our servers
package: Vc
version: v1.4.5
tag: 1.4.5
source: https://github.com/VcDevel/Vc.git
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

sed -i 's@cmake_minimum_required(VERSION 3.5)@cmake_minimum_required(VERSION 3.28)@g' $SOURCEDIR/CMakeLists.txt

cmake "$SOURCEDIR"                                              \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                  \
      -DCMAKE_POLICY_DEFAULT_CMP0153=OLD                        \
      -DTARGET_ARCHITECTURE="ivy-bridge"                        \
      -DBUILD_TESTING=OFF

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv Vc_DIR \$PKG_ROOT/lib/cmake/Vc
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

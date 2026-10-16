package: xerces-c
version: v3.3.0
tag: v3.3.0
source: https://github.com/apache/xerces-c.git
requires:
  - libICU
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

sed -i '/set(CMAKE_CXX_STANDARD 14)/d' $SOURCEDIR/CMakeLists.txt
sed -i 's/^enable_testing()/#enable_testing()/' $SOURCEDIR/CMakeLists.txt
sed -i 's/^add_subdirectory(tests)/#add_subdirectory(tests)/' $SOURCEDIR/CMakeLists.txt
sed -i 's/^add_subdirectory(samples)/#add_subdirectory(samples)/' $SOURCEDIR/CMakeLists.txt

cmake "$SOURCEDIR"                                              \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                  \
      -DCMAKE_INSTALL_LIBDIR=lib                                \
      ${LIBICU_ROOT:+-DCMAKE_PREFIX_PATH=$LIBICU_ROOT}          \
      -DBUILD_SHARED_LIBS=ON                                    \
      -Dnetwork=OFF

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv XercesC_DIR \$PKG_ROOT/lib/cmake/XercesC
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

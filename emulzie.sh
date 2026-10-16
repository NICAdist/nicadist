package: emulzie
version: v1.0.0
tag: "v1.0.0"
source: https://gitlab.com/ndmspc/lab/emulzie.git
requires:
  - bzip2
  - FreeType
  - "GCC-ToolChain:(?!osx)"
  - libpng
  - lz4
  - ROOT
  - TBB
  - xxHash
  - zlib
  - zstd
build_requires:
  - CMake
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

sed -i 's@project(upjs-emulzie CXX)@@g' $SOURCEDIR/CMakeLists.txt
sed -i 's@cmake_minimum_required(VERSION 3.0 FATAL_ERROR)@cmake_minimum_required(VERSION 3.0 FATAL_ERROR)\nproject(upjs-emulzie CXX)@g' $SOURCEDIR/CMakeLists.txt
sed -i 's@add_compile_options("-std=c++17")@#add_compile_options("-std=c++17")@g' $SOURCEDIR/CMakeLists.txt

cmake "$SOURCEDIR"                                              \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                  \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5                        \
      -DCMAKE_POLICY_DEFAULT_CMP0074=NEW                        \
      -DCMAKE_POLICY_DEFAULT_CMP0188=OLD

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

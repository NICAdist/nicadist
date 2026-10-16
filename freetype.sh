package: FreeType
version: v2.14.3
tag: VER-2-14-3
source: https://github.com/freetype/freetype.git
requires:
  - bzip2
  - libpng
build_requires:
  - autotools
  - CMake
  - ninja
  - pigz
---
#!/bin/bash -e
export CLICOLOR_FORCE=1
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja

sed -i 's@find_package(BZip2 REQUIRED)@find_package(BZip2 REQUIRED)\n    set_target_properties(BZip2::BZip2 PROPERTIES IMPORTED_LOCATION_RELWITHDEBINFO "${BZIP2_LIBRARIES}")@g' $SOURCEDIR/CMakeLists.txt
sed -i 's@pkg_check_modules(PC_BZIP2 bzip2)@if (NOT ${BZIP2_FOUND})\n    pkg_check_modules(PC_BZIP2 bzip2)\n  endif()@g' $SOURCEDIR/CMakeLists.txt

cmake "$SOURCEDIR"                                                 \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                        \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}    \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                   \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                      \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                                 \
      -G Ninja                                                     \
      -DCMAKE_INSTALL_LIBDIR=lib                                   \
      ${LIBPNG_ROOT:+-DPNG_ROOT=$LIBPNG_ROOT}                      \
      ${BZIP2_ROOT:+-DBZIP2_INCLUDE_DIR="$BZIP2_ROOT/include"}     \
      ${BZIP2_ROOT:+-DBZIP2_LIBRARIES="$BZIP2_ROOT/lib/libbz2.so"} \
      -DFT_DISABLE_HARFBUZZ=TRUE                                   \
      -DFT_REQUIRE_BZIP2=TRUE                                      \
      -DBUILD_SHARED_LIBS=TRUE                                     \

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv freetype_DIR \$PKG_ROOT/lib/cmake/freetype
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

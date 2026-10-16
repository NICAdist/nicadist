package: RooUnfold
version: v3.1.0
tag: 3.1.0
source: https://gitlab.cern.ch/RooUnfold/RooUnfold.git
requires:
  - ROOT
build_requires:
  - CMake
  - ninja
---
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

# Target name has changed
sed -i 's@RooFitJSONInterface@RooFitHS3@g' $SOURCEDIR/CMakeLists.txt
sed -i 's@include(cmake/doxygen.cmake)@# include(cmake/doxygen.cmake)@g' $SOURCEDIR/CMakeLists.txt

cmake "$SOURCEDIR"                                              \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja

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

# Manualy create .pc file so that PKGCONFIG can be used to find it
mkdir -p "$INSTALLROOT/lib/pkgconfig"
cat > "$INSTALLROOT/lib/pkgconfig/libRooUnfold.pc" << EoF
prefix=$INSTALLROOT
exec_prefix=\${prefix}
libdir=$INSTALLROOT/lib
toolexeclibdir=\${libdir}
includedir=\${prefix}/include

Name: libRooUnfold
Description: RooUnfold library
Version: 3.1.0
Libs: -L\${toolexeclibdir} -lRooUnfold
Cflags: -I\${includedir}
EoF

nicadist-postbuild-hook

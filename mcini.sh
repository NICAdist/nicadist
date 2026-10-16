package: mcini
version: v2026.09.01
tag: fcdccc60e5e20ac662fbd6d5a8be9eaddb9c2013
source: https://github.com/FlowNICA/mcini.git
requires:
  - ROOT
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

rsync -a --exclude '**/.git' $SOURCEDIR/ $BUILDDIR/MCINI_SOURCES

# patch sources
# Remove obsolete ClassImp
sed -i '/^ClassImp(/d' $BUILDDIR/MCINI_SOURCES/src/EventInitialState.cxx
sed -i '/^ClassImp(/d' $BUILDDIR/MCINI_SOURCES/src/Nucleon.cxx
sed -i '/^ClassImp(/d' $BUILDDIR/MCINI_SOURCES/src/UEvent.cxx
sed -i '/^ClassImp(/d' $BUILDDIR/MCINI_SOURCES/src/UParticle.cxx
sed -i '/^ClassImp(/d' $BUILDDIR/MCINI_SOURCES/src/URun.cxx
# remove path from include files
sed -i 's@include/@@g' $BUILDDIR/MCINI_SOURCES/CMakeLists.txt
sed -i 's@target_link_libraries(McIniData@target_include_directories(McIniData PRIVATE "include")\ntarget_link_libraries(McIniData@g' $BUILDDIR/MCINI_SOURCES/CMakeLists.txt
sed -i 's@MCIni-LinkDef.h@include/MCIni-LinkDef.h@g' $BUILDDIR/MCINI_SOURCES/CMakeLists.txt

# include headers, not paths
sed -i 's@../include/@@g' $BUILDDIR/MCINI_SOURCES/macro/convertSmashParticles.C
sed -i 's@../include/@@g' $BUILDDIR/MCINI_SOURCES/macro/convertUrQMD.C

cmake "$BUILDDIR/MCINI_SOURCES"                                 \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                  \
      -DCMAKE_POLICY_DEFAULT_CMP0074=NEW                        \
      -DBUILD_SHARED_LIBS=ON

cmake --build . -- ${JOBS+-j $JOBS}

# "Install" everything
mkdir -p $INSTALLROOT/bin $INSTALLROOT/include $INSTALLROOT/lib $INSTALLROOT/macro/jam
cp JAMReader $INSTALLROOT/bin/
cp libMcIniData_rdict.pcm libMcIniData.rootmap libMcIniData.so $INSTALLROOT/lib/
cp -r $BUILDDIR/MCINI_SOURCES/include/* $INSTALLROOT/include/
cp -r $BUILDDIR/MCINI_SOURCES/macro/*.C $INSTALLROOT/macro/
cp -r $BUILDDIR/MCINI_SOURCES/macro/jam/* $INSTALLROOT/macro/jam/
rm -f $INSTALLROOT/include/MCIni-LinkDef.h

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

mkdir -p "$INSTALLROOT/lib/pkgconfig"
cat > "$INSTALLROOT/lib/pkgconfig/McIniData.pc" << EoF
prefix=$INSTALLROOT
exec_prefix=\${prefix}
libdir=$INSTALLROOT/lib
toolexeclibdir=\${libdir}
includedir=\${prefix}/include

Name: McIniData
Description: McIniData library
Version: 2026.09.01
Libs: -L\${toolexeclibdir} -lMcIniData
Cflags: -I\${includedir}
EoF

cat >> "$MODULEFILE" << EoF
setenv McIni_ROOT \$PKG_ROOT
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

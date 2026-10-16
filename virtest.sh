package: VirTest
version: v2020.09.17
tag: 95a85e23517e045845bdf324a93a57e13c34efe7
source: https://github.com/mattkretz/virtest.git
build_requires:
  - CMake
---
#!/bin/bash -e
# We're not using ninja as it is not supported by VirTest

cmake "$SOURCEDIR"                                              \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                  \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5

# build one by one since otherwise tests may run sooner than they are built
make checks
make checks-14
make empty
make empty-14
make plotdist

make run_checks
make run_checks-14
make run_empty
make run_empty-14
make run_plotdist

make install
# fix since code is on /vir deeper than should be
mv ${INSTALLROOT}/include/vir/vir/* ${INSTALLROOT}/include/vir
rmdir ${INSTALLROOT}/include/vir/vir

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --root > $MODULEFILE

cat >> "$MODULEFILE" << EoF
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

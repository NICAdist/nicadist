package: pythia
version: v8.3.17
tag: pythia8317
source: https://gitlab.com/Pythia8/releases.git
requires:
  - HepMC
  - LHAPDF
  - Python
  - Python-modules
env:
  PYTHIA8: "$PYTHIA_ROOT"
---
#!/bin/bash -e
rsync -a $SOURCEDIR/ ./

PYVER="$(basename $(find $PYTHON_ROOT/include -type d -name 'python*'))"

# Hack to build pythia with c++20 support
sed -i 's@-std=c++11@-std=c++20@g' ./configure

./configure --prefix="$INSTALLROOT"                                             \
            ${HEPMC_ROOT:+--with-hepmc2="$HEPMC_ROOT"}                          \
            ${LHAPDF_ROOT:+--with-lhapdf6="$LHAPDF_ROOT"}                       \
            ${PYTHON_ROOT:+--with-python="$PYTHON_ROOT"}                        \
            ${PYTHON_ROOT:+--with-python-include="$PYTHON_ROOT/include/$PYVER"}

make ${JOBS+-j $JOBS}
make install

chmod a+x $INSTALLROOT/bin/pythia8-config

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
setenv PYTHIA8DATA \$PKG_ROOT/share/Pythia8/xmldoc
setenv PYTHIA8 \$PKG_ROOT
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

mkdir -p "$INSTALLROOT/lib/pkgconfig"
cat > "$INSTALLROOT/lib/pkgconfig/libpythia8.pc" << EoF
prefix=$INSTALLROOT
exec_prefix=\${prefix}
libdir=$INSTALLROOT/lib
toolexeclibdir=\${libdir}
includedir=\${prefix}/include

Name: pythia8
Description: pythia8 library
Version: 8.3.17
Libs: -L\${toolexeclibdir} -lpythia8
Cflags: -I\${includedir}
EoF

nicadist-postbuild-hook

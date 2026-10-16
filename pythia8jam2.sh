package: Pythia8JAM2
version: v8.2.44
tag: v8.2.44
source: https://git.jinr.ru/mpd/nicadist/Pythia8JAM2.git
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

# Hack to build pythia with c++20 support
sed -i 's@-std=c++11@-std=c++20@g' ./configure

if [ -n "$PYTHON_ROOT" ]; then
  PYVER="$(basename $(find $PYTHON_ROOT/include -type d -name 'python*'))"
fi

./configure --prefix=$INSTALLROOT \
            ${HEPMC_ROOT:+--with-hepmc2="$HEPMC_ROOT"}                              \
            ${LHAPDF_ROOT:+--with-lhapdf6="$LHAPDF_ROOT"}                           \
            ${PYTHON_ROOT:+--with-python="$PYTHON_ROOT"}                            \
            ${PYTHON_ROOT:+--with-python-bin="$PYTHON_ROOT/bin/"}                   \
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
setenv PYTHIA8_ROOT \$PKG_ROOT
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

# Manualy create .pc file so that PKGCONFIG can be used to find it
mkdir -p "$INSTALLROOT/lib/pkgconfig"
cat > "$INSTALLROOT/lib/pkgconfig/libpythia8.pc" << EoF
prefix=$INSTALLROOT
exec_prefix=\${prefix}
libdir=$INSTALLROOT/lib
toolexeclibdir=\${libdir}
includedir=\${prefix}/include

Name: pythia8
Description: pythia8 library
Version: 8.2.44
Libs: -L\${toolexeclibdir} -lpythia8
Cflags: -I\${includedir}
EoF

nicadist-postbuild-hook

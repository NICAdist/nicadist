# Note, that we don't install datasets. They were not (yet) requested by users.
package: LHAPDF
version: v6.5.6
tag: lhapdf-6.5.6
source: https://gitlab.com/hepcedar/lhapdf.git
requires:
  - Python
build_requires:
  - autotools
  - Python-modules
---
#!/bin/bash -ex
EXTRA_LD_FLAGS="-Wl,--no-as-needed"

rsync -a --exclude '**/.git' $SOURCEDIR/ ./

export LIBRARY_PATH="$LD_LIBRARY_PATH"

export PYTHON=$PYTHONHOME/bin/python
export PATH=$PYTHON_MODULES_ROOT/share/python-modules/bin:$PATH

autoreconf -ivf
./configure --prefix=$INSTALLROOT

make ${JOBS+-j$JOBS} all
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

PYVER="$(basename $(find $INSTALLROOT/lib -type d -name 'python*'))"

cat >> "$MODULEFILE" << EoF
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path PYTHONPATH \$PKG_ROOT/lib/$PYVER/site-packages
prepend-path LHAPDF_DATA_PATH \$PKG_ROOT/share/LHAPDF
EoF

nicadist-postbuild-hook

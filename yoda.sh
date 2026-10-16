package: YODA
version: v2.1.4
tag: "yoda-2.1.4"
source: https://gitlab.com/hepcedar/yoda.git
requires:
  - HDF5-Tools
  - Python
  - Python-modules
build_requires:
  - autotools
  - Boost
  - ROOT
---
#!/bin/bash -e
rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ ./

autoreconf -ivf

./configure --disable-silent-rules                  \
            --prefix="$INSTALLROOT"                 \
            --with-hdf5="$HDF5_TOOLS_ROOT"/bin/h5cc \
            --with-highfive="$HDF5_TOOLS_ROOT"      \
            PYTHON=$PYTHON_ROOT/bin/python          \
            CYTHON="$PYTHON_MODULES_ROOT/share/python-modules/bin/cython"

make ${JOBS+-j $JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

PYVER="$(basename $(find $INSTALLROOT/lib -type d -name 'python*'))"

cat >> "$MODULEFILE" << EoF
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path PYTHONPATH \$PKG_ROOT/lib/$PYVER/site-packages
EoF

nicadist-postbuild-hook

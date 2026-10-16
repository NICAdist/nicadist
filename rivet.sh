package: RIVET
version: v4.1.4
tag: "rivet-4.1.4"
source: https://gitlab.com/hepcedar/rivet.git
requires:
  - FastJet
  - GCC-ToolChain
  - HDF5-Tools
  - HepMC3
  - Python
  - Python-modules
  - YODA
build_requires:
  - autotools
---
#!/bin/bash -e
export CC="$GCC_TOOLCHAIN_ROOT"/bin/gcc
export CXX="$GCC_TOOLCHAIN_ROOT"/bin/g++
export CXXFLAGS="-fPIC -O2 -std=c++17" # force older c++ standard since fjcontrib is not ready for c++20 yet

rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ ./

autoreconf -ivf

./configure  --prefix="$INSTALLROOT"                                       \
             --disable-doxygen                                             \
             --with-yoda="$YODA_ROOT"                                      \
             --with-hepmc3="$HEPMC3_ROOT"                                  \
             --with-fastjet="$FASTJET_ROOT"                                \
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

package: mxpfit
version: vCPC
tag: cpc
source: https://github.com/hydeik/mxpfit.git
requires:
  - Eigen3
  - FFTW
---
#!/bin/bash -e

# header only package, just copy headers. Documentation, tests, and examples are not built.
mkdir ${INSTALLROOT}/include ${INSTALLROOT}/include/fftw3 ${INSTALLROOT}/include/mxpfit
cp -r $SOURCEDIR/include/fftw3/*.hpp ${INSTALLROOT}/include/fftw3/
cp -r $SOURCEDIR/include/mxpfit/*.hpp ${INSTALLROOT}/include/mxpfit/

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --root > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv MXPFit_ROOT \$PKG_ROOT
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

package: vHLLE
version: v2025.11.20
tag: ae2ba98609ff1203e6ab6e9d201db0e708322717
source: https://github.com/yukarpenko/vhlle_params.git
requires:
  - bzip2
  - FreeType
  - GCC-ToolChain
  - libpng
  - lz4
  - ROOT
  - TBB
  - xxHash
  - zlib
  - zstd
---
#!/bin/bash
mkdir -p $INSTALLROOT/data/params
cp -r $SOURCEDIR/ic $SOURCEDIR/eos $INSTALLROOT/data/
cp -r $SOURCEDIR/params/* $INSTALLROOT/data/params/

# manually build hlle_visc
git clone  --depth 1 --branch "stable_ebe" https://git.jinr.ru/mpd/nicadist/vHLLE.git

cd vHLLE/

# Fix of new approach to TF1, TF2 since ROOT v6.40
sed -i 's@, "IC", "WoodSaxon"@@g' src/icGlauber.cpp
sed -i 's@, "IC", "Thickness"@@g' src/icGlauber.cpp

make ${JOBS+-j $JOBS}

mkdir -p $INSTALLROOT/bin/params

mv hlle_visc $INSTALLROOT/bin/
mv params/* $INSTALLROOT/bin/params/

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv vHLLE_PARAMS  \$PKG_ROOT/data
setenv vHLLE_ROOT  \$PKG_ROOT
EoF

nicadist-postbuild-hook

package: ninja
version: v1.13.2
tag: v1.13.2
source: https://github.com/ninja-build/ninja.git
---
python3 $SOURCEDIR/configure.py --bootstrap

mkdir -p $INSTALLROOT/bin
cp ./ninja $INSTALLROOT/bin

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin > $MODULEFILE

nicadist-postbuild-hook

package: pigz
version: v2.8
tag: v2.8
source: https://github.com/madler/pigz.git
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

make ${JOBS:+-j$JOBS}

mkdir -p $INSTALLROOT/bin
cp pigz $INSTALLROOT/bin/
cp unpigz $INSTALLROOT/bin/

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv pigz_ROOT \$PKG_ROOT
EoF

nicadist-postbuild-hook

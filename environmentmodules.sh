package: EnvironmentModules
version: v5.6.2
tag: "v5.6.2"
source: https://github.com/cea-hpc/modules.git
build_requires:
  - make
---
#!/bin/bash -e
rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ ./

./configure --prefix=$INSTALLROOT --disable-doc-install

make ${JOBS+-j $JOBS}
make install

# ModuleFile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

nicadist-postbuild-hook

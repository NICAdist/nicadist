# Version 3.24 at the github is actually 3.0.24
package: SafeInt
version: v3.0.28a
tag: 3.0.28a
source: https://github.com/dcleblanc/SafeInt
prefer_system: .*
prefer_system_check: |
  printf "#include <SafeInt.hpp>\n" | cc -xc++ - -I"$(brew --prefix safeint)/include" -c -o /dev/null
---
#!/bin/bash -e
mkdir -p $INSTALLROOT/include
cp -r  $SOURCEDIR/SafeInt.hpp $SOURCEDIR/safe_math.h $SOURCEDIR/safe_math_impl.h $INSTALLROOT/include

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --root > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv SafeInt_ROOT \$PKG_ROOT
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

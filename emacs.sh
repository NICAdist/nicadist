package: Emacs
# when changing version, don't forget to change version in setenv at the end of file!
version: v31.1
tag: "emacs-31.1"
source: https://github.com/emacs-mirror/emacs.git
requires:
  - libjpeg-turbo 
  - libpng
  - libtiff
  - zlib
build_requires:
  - autotools
---
#!/bin/bash -e
rsync -a --exclude '**/.git' --delete $SOURCEDIR/ $BUILDDIR
autoreconf -f -v -i

if [ -n "$LIBTIFF_ROOT" ]; then
  export CFLAGS="-I${LIBTIFF_ROOT}/include $CFLAGS"
  export LDFLAGS="-L${LIBTIFF_ROOT}/lib $LDFLAGS"
fi

if [ -n "$LIBJPEG_TURBO_ROOT" ]; then
  export CFLAGS="-I${LIBJPEG_TURBO_ROOT}/include $CFLAGS"
  export LDFLAGS="-L${LIBJPEG_TURBO_ROOT}/lib $LDFLAGS"
fi

if [ -n "$LIBPNG_ROOT" ]; then
  export CFLAGS="-I${LIBPNG_ROOT}/include $CFLAGS"
  export LDFLAGS="-L${LIBPNG_ROOT}/lib $LDFLAGS"
fi

./configure --prefix="$INSTALLROOT"                                \
            --with-x-toolkit=no                                    \
            --with-gif=ifavailable                                 \
            --with-gnutls=ifavailable

make ${JOBS:+-j$JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

EMACSVER="$(basename $(find $INSTALLROOT/share/emacs -type d -name '??.?'))"

# EMACSDATA     - arch-independent data dir+charset
# EMACSLOADPATH - lisp
# EMACSPATH     - arch-dependent data dir
cat >> "$MODULEFILE" << EoF
setenv EMACSDATA \$PKG_ROOT/share/emacs/$EMACSVER/etc
prepend-path EMACSLOADPATH \$PKG_ROOT/share/emacs/$EMACSVER/lisp
setenv EMACSPATH \$PKG_ROOT
prepend-path MANPATH \$PKG_ROOT/share/man
EoF

nicadist-postbuild-hook

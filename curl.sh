package: curl
version: v8.23.0
tag: curl-8_23_0
source: https://github.com/curl/curl.git
requires:
  - OpenSSL
---
#!/bin/bash -e
${OPENSSL_ROOT:+env LDFLAGS=-Wl,-R$OPENSSL_ROOT/lib}

rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .

autoreconf -ivf
./configure --prefix=$INSTALLROOT                     \
            --disable-ldap                            \
            ${OPENSSL_ROOT:+--with-ssl=$OPENSSL_ROOT} \
            --disable-static                          \
            --without-libpsl
make ${JOBS:+-j$JOBS}
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path ACLOCAL_PATH \$PKG_ROOT/share/aclocal
prepend-path MANPATH \$PKG_ROOT/share/man
EoF

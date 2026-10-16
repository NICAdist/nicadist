# If changing release version, change accordingly as well:
# lhapdf.sh
# pythia.sh
package: Python
version: v3.15.0rc2
tag: v3.15.0rc2
source: https://github.com/python/cpython.git
requires:
  - FreeType
  - libffi
  - libpng
  - lzma
  - sqlite
build_requires:
  - bzip2
env:
  SSL_CERT_FILE: "$(export PATH=$PYTHON_ROOT/bin:$PATH; export LD_LIBRARY_PATH=$PYTHON_ROOT/lib:$LD_LIBRARY_PATH; python -c \"import certifi; print(certifi.where())\")"
  PYTHONHOME: "$PYTHON_ROOT"
  PYTHONPATH: "$PYTHON_ROOT/lib/python/site-packages"
prefer_system_check:
  python3 -c 'import sys; import sqlite3; sys.exit(1 if sys.version_info < (3, 5) else 0)' && python3 -m pip --help > /dev/null && printf '#include "pyconfig.h"' | cc -c $(python3-config --includes) -xc -o /dev/null -; if [ $? -ne 0 ]; then printf "Python, the Python development packages, and pip must be installed on your system.\nUsually those packages are called python, python-devel (or python-dev) and python-pip.\n"; exit 1; fi
---
rsync -av --exclude '**/.git' $SOURCEDIR/ $BUILDDIR/

# According to cmsdist, this is required to pick up our own version
export LIBFFI_ROOT

# The only way to pass externals to Python
LDFLAGS=
CPPFLAGS=
for ext in $ZLIB_ROOT $FREETYPE_ROOT $LIBPNG_ROOT $SQLITE_ROOT $LIBFFI_ROOT; do
  LDFLAGS="$(find $ext -type d \( -name lib -o -name lib64 \) -exec echo -L\{\} \;) $LDFLAGS"
  CPPFLAGS="$(find $ext -type d -name include -exec echo -I\{\} \;) $CPPFLAGS"
done
export LDFLAGS=$(echo $LDFLAGS)
export CPPFLAGS=$(echo $CPPFLAGS)

# Set own OpenSSL if appropriate
if [[ $OPENSSL_ROOT ]]; then
  export CPATH="$OPENSSL_ROOT/include:$OPENSSL_ROOT/include/openssl:$CPATH"
  export CPPFLAGS="-I$OPENSSL_ROOT/include -I$OPENSSL_ROOT/include/openssl $CPPFLAGS"
  export CFLAGS="-I$OPENSSL_ROOT/include -I$OPENSSL_ROOT/include/openssl"
fi

if [[ $BZIP2_ROOT ]]; then
  export CPATH="$BZIP2_ROOT/include:$CPATH"
  export CPPFLAGS="-I$BZIP2_ROOT/include $CPPFLAGS"
  export CFLAGS="-I$BZIP2_ROOT/include $CFLAGS"
  export LDFLAGS="-L$BZIP2_ROOT/lib $LDFLAGS"
fi

if [[ $LZMA_ROOT ]]; then
  export CPATH="$LZMA_ROOT/include:$CPATH"
  export CPPFLAGS="-I$LZMA_ROOT/include $CPPFLAGS"
  export CFLAGS="-I$LZMA_ROOT/include $CFLAGS"
  export LDFLAGS="-L$LZMA_ROOT/lib $LDFLAGS"
fi

./configure --prefix="$INSTALLROOT"                       \
            ${OPENSSL_ROOT:+--with-openssl=$OPENSSL_ROOT} \
            ${OPENSSL_ROOT:+--with-openssl-rpath=no}      \
            --enable-shared                               \
            --with-ensurepip=install
#            --enable-optimizations                        \

# make ${JOBS:+-j $JOBS}
make ${JOBS:+-j $JOBS}
make altinstall

# Patch long shebangs (by default max is 128 chars on Linux) and add pip(3)/python(3) symlinks
pushd "$INSTALLROOT/bin"
  sed -i.deleteme -e "1 s|^#!${INSTALLROOT}/bin/\(.*\)$|#!/usr/bin/env \1|" * || true
  rm -f *.deleteme
  PYTHON_BIN=$(for X in python*; do echo "$X"; done | grep -E '^python[0-9]+\.[0-9]+$' | head -n1)
  PIP_BIN=$(for X in pip*; do echo "$X"; done | grep -E '^pip[0-9]+\.[0-9]+$' | head -n1)
  PYTHON_CONFIG_BIN=$(for X in python*-config; do echo "$X"; done | grep -E '^python[0-9]+\.[0-9]+m?-config$' | head -n1)
  [[ -x python ]] || ln -nfs "$PYTHON_BIN" python
  [[ -x python3 ]] || ln -nfs "$PYTHON_BIN" python3
  [[ -x pip ]] || ln -nfs "$PIP_BIN" pip
  [[ -x pip3 ]] || ln -nfs "$PIP_BIN" pip3
  [[ -x python-config ]] || ln -nfs "$PYTHON_CONFIG_BIN" python-config
  [[ -x python3-config ]] || ln -nfs "$PYTHON_CONFIG_BIN" python3-config
popd

# Make sure we have the latest pip
env PATH="$INSTALLROOT/bin:$PATH"                       \
    LD_LIBRARY_PATH="$INSTALLROOT/lib:$LD_LIBRARY_PATH" \
    PYTHONHOME="$INSTALLROOT"                           \
    python3 -m pip install --upgrade pip

# Install Python SSL certificates right away
env PATH="$INSTALLROOT/bin:$PATH" \
    LD_LIBRARY_PATH="$INSTALLROOT/lib:$LD_LIBRARY_PATH" \
    PYTHONHOME="$INSTALLROOT" \
    python3 -m pip install 'certifi==2026.7.22'

# Uniform Python library path
pushd "$INSTALLROOT/lib"
  ln -nfs python* python
popd

# Remove useless stuff
rm -rvf "$INSTALLROOT"/share "$INSTALLROOT"/lib/python*/test
find "$INSTALLROOT"/lib/python* \
     -mindepth 2 -maxdepth 2 -type d -and \( -name test -or -name tests \) \
     -exec rm -rvf '{}' \;

cp "$INSTALLROOT/lib/pkgconfig/python-3.15.pc" "$INSTALLROOT/lib/pkgconfig/python.pc"
cp "$INSTALLROOT/lib/pkgconfig/python-3.15-embed.pc" "$INSTALLROOT/lib/pkgconfig/python-embed.pc"

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv PYTHONHOME \$PKG_ROOT
prepend-path PYTHONPATH \$PKG_ROOT/lib/python/site-packages
if { [module-info mode load] } {
  setenv SSL_CERT_FILE  [exec env LD_LIBRARY_PATH=\$PKG_ROOT/lib \$PKG_ROOT/bin/python3 -c "import certifi; print(certifi.where())"]
}
if { [module-info mode remove] } {
  unsetenv SSL_CERT_FILE
}
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
EoF

nicadist-postbuild-hook

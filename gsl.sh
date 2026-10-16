package: GSL
version: v2.8
tag: "release-2-8"
source: https://git.jinr.ru/mpd/nicadist/GSL.git
# https://savannah.gnu.org/projects/gsl
build_requires:
  - autotools
prefer_system: .*
prefer_system_check: |
  printf "#include \"gsl/gsl_version.h\"\n#define GSL_V GSL_MAJOR_VERSION * 100 + GSL_MINOR_VERSION\n# if (GSL_V < 116)\n#error \"Cannot use system's gsl. Notice we only support versions from 1.16 (included)\"\n#endif\nint main(){}" | c++  -I$(brew --prefix gsl)/include -xc++ - -o /dev/null
---
#!/bin/bash -e
rsync -a --exclude '**/.git' --delete $SOURCEDIR/ $BUILDDIR

# Prevent building documentation
perl -p -i -e "s/doc//" Makefile.am
perl -p -i -e "s|doc/Makefile||" configure.ac

autoreconf -f -v -i
./configure --prefix="$INSTALLROOT"  \
            --enable-maintainer-mode

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
EoF

nicadist-postbuild-hook

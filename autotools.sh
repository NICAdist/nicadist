package: autotools
version: v2.0.0
tag: v2.0.0
source: https://git.jinr.ru/mpd/nicadist/autotools.git
prefer_system: .*
prefer_system_check: |
  export PATH=$PATH:$(brew --prefix gettext || true)/bin:$(brew --prefix texinfo || true)/bin;
  which aclocal && \
  which autoconf && \
  which autoconf-archive && \
  which automake && \
  which autopoint && \
  which awk && \
  which libtool &&
  which m4 && \
  which makeinfo && \
  which pkg-config && \
  which pkgconf && \
  which readline && \
  which sed && \
  which texinfo;
  if [ $? -ne 0 ]; then printf "One or more autotools packages are missing on your system.\n * On a RHEL-compatible system you probably need: aclocal, autoconf, autoconf-archive, automake, autopoint, (g)awk, libtool, m4, makeinfo, pkg-config, pkgconf, readline, sed, and texinfo."; exit 1; fi
prepend_path:
  PKG_CONFIG_PATH: $(pkg-config --debug 2>&1 | grep 'Scanning directory' | sed -e "s/.*'\(.*\)'/\1/" | xargs echo | sed -e 's/ /:/g')
build_requires:
 - termcap
 - make
---
#!/bin/bash -e
unset CXXFLAGS
unset CFLAGS

echo "Building autotools. To avoid this install aclocal, autoconf, autoconf-archive, automake, autopoint, (g)awk, libtool, m4, makeinfo, pkg-config, pkgconf, readline, sed, and texinfo."

# Restore original timestamps to avoid reconf (Git does not preserve them)
pushd $SOURCEDIR
  ./missing-timestamps.sh --apply
popd

rsync -a --delete --exclude '**/.git' $SOURCEDIR/ .

# Use our auto* tools as soon as we build them
export PATH=$INSTALLROOT/bin:$PATH
export LD_LIBRARY_PATH=$INSTALLROOT/lib:$LD_LIBRARY_PATH

# help2man
pushd help2man*
  echo 'Building help2man'
  ./configure --prefix $INSTALLROOT
  make ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# m4
pushd m4*
  echo 'Building m4'
  rm -f doc/m4.texi.bak
  ./configure --prefix $INSTALLROOT         \
              --disable-dependency-tracking
  make ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# autoconf
pushd autoconf-?.??
  echo 'Building autoconf'
  ./configure --prefix $INSTALLROOT
  make MAKEINFO=true ${JOBS+-j $JOBS}
  make MAKEINFO=true install
  hash -r
popd

# automake
pushd automake*
  echo 'Building automake'
  ./configure --prefix $INSTALLROOT
  make MAKEINFO=true ${JOBS+-j $JOBS}
  make MAKEINFO=true install
  hash -r
popd

# gawk
pushd gawk-*
  echo 'Building gawk'
  ./configure --prefix $INSTALLROOT
  make ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# sed
pushd sed-*
  echo 'Building sed'
  ./configure --prefix $INSTALLROOT
  make ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# autoconf-archive
pushd autoconf-archive*
  echo 'Building autoconf-archive'
  ./configure --prefix $INSTALLROOT
  make MAKEINFO=true ${JOBS+-j $JOBS}
  make MAKEINFO=true install
  hash -r
popd

# libtool
pushd libtool*
  echo 'Building libtool'
  ./configure --prefix $INSTALLROOT         \
              --disable-dependency-tracking \
              --enable-ltdl-install
  make ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# gettext
pushd gettext*
  echo 'Building gettext'
  ./configure --prefix $INSTALLROOT         \
              --disable-acl                 \
              --disable-dependency-tracking \
              --disable-java                \
              --disable-native-java         \
              --disable-nls                 \
              --disable-openmp              \
              --disable-rpath               \
              --disable-silent-rules        \
              --enable-curses               \
              --enable-relocatable          \
              --without-bzip2               \
	            --without-emacs               \
              --without-selinux             \
              --without-xz
  make ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# pkgconf -- replaced original (but obsolete) pkg-config
pushd pkgconf-*
  OLD_LDFLAGS="$LDFLAGS"
  [[ ${ARCHITECTURE:0:3} == osx ]] && export LDFLAGS="$LDFLAGS -framework CoreFoundation -framework Carbon"
  ./configure --prefix=$INSTALLROOT
  export LDFLAGS="$OLD_LDFLAGS"
  make ${JOBS+-j $JOBS}
  make install
  cd $INSTALLROOT/bin
  ln -nfs pkgconf pkg-config
  cd -
  hash -r
popd

# gengetopt
pushd gengetopt*
  echo 'Building gengetopt'
  ./configure --prefix $INSTALLROOT
  make ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# readline
pushd readline*
  echo 'Building readline'
  ./configure --prefix $INSTALLROOT \
              --with-curses
  make SHLIB_LIBS="-ltinfo" ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# texinfo
pushd texinfo*
  echo 'Building texinfo'
  ./configure --prefix $INSTALLROOT
  make ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# Fix perl location, required on /usr/bin/perl
grep -l -R -e '^#!.*perl' $INSTALLROOT | \
  xargs -r -n1 sed -ideleteme -e 's;^#!.*perl;#!/usr/bin/perl;'
find $INSTALLROOT -name '*deleteme' -delete
grep -l -R -e 'exec [^ ]*/perl' $INSTALLROOT | \
  xargs -r -n1 sed -ideleteme -e 's;exec [^ ]*/perl;exec /usr/bin/perl;g'
find $INSTALLROOT -name '*deleteme' -delete

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

nicadist-postbuild-hook

package: PCRE2
version: v10.48
tag: pcre2-10.48
source: https://github.com/PCRE2Project/pcre2.git
requires:
  - bzip2
build_requires:
  - autotools
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

# copy including .git since we need to download submodules
rsync -a --delete --delete-excluded $SOURCEDIR/ ./

git submodule update --init

cmake "$SOURCEDIR"                                              \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                  \
      -DCMAKE_INSTALL_LIBDIR=lib                                \
      ${BZIP2_ROOT:+-DBZip2_ROOT=$BZIP2_ROOT}                   \
      -DBUILD_SHARED_LIBS=ON                                    \
      -DPCRE2_BUILD_PCRE2_8=ON                                  \
      -DPCRE2_BUILD_PCRE2_16=ON                                 \
      -DPCRE2_BUILD_PCRE2_32=ON                                 \
      -DPCRE2_BUILD_TESTS=OFF                                   \
      -DPCRE2_STATIC_PIC=ON                                     \
      -DPCRE2_SUPPORT_JIT=ON

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv pcre2_DIR \$PKG_ROOT/lib/cmake/pcre2
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path MANPATH \$PKG_ROOT/share/man
EoF

nicadist-postbuild-hook

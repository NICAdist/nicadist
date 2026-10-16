package: mfddev
version: "%(commit_hash)s"
tag: "main"
requires:
  - Boost
  - Catch2
  - CMake
  - Clang
  - Cppcheck
  - GCC-ToolChain
  - HDF5-Tools
  - yaml-cpp
---
# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --path > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv CFLAGS "$CFLAGS"
setenv CXXFLAGS "$CXXFLAGS"
setenv CXXSTD "$CXXSTD"
EoF

nicadist-postbuild-hook

package: mpddev
version: "%(commit_hash)s"
tag: "dev"
requires:
  - Boost
  - bzip2
  - clang-format
  - CMake
  - FairLogger
  - FairRoot
  - FFTW
  - fmt
  - FreeType
  - GCC-ToolChain
  - GSL
  - libpng
  - libxml2
  - lz4
  - nlohmann_json
  - PostgreSQL
  - pythia
  - ROOT
  - RooUnfold
  - TBB
  - VMC
  - xerces-c
  - xxHash
  - ZeroMQ
  - zlib
  - zstd
---
# Making sure people do not have SIMPATH set when they build fairroot.
# Unfortunately SIMPATH seems to be hardcoded in a bunch of places in
# fairroot, so this really should be cleaned up in FairRoot itself for
# maximum safety.
unset SIMPATH

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

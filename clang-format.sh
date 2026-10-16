package: clang-format
version: v23.1.2
tag: "llvmorg-23.1.2"
source: https://github.com/llvm/llvm-project.git
requires:
  - libxml2
  - zlib
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

cmake "$SOURCEDIR/llvm"                     \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
      -DCMAKE_BUILD_TYPE=MinSizeRel         \
      -DCMAKE_COLOR_DIAGNOSTICS=ON          \
      -G Ninja                              \
      -DLLVM_ENABLE_PROJECTS=clang          \
      -DLLVM_TARGET_ARCH=x86_64

cmake --build . -- ${JOBS+-j $JOBS} install-clang-format

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin > $MODULEFILE

nicadist-postbuild-hook

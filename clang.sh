# Clang built together with clang-format, clang-tidy, and
# IWYU (Include-What-You-Use)
package: Clang
version: v23.1.2
tag: "llvmorg-23.1.2"
source: https://github.com/llvm/llvm-project.git
requires:
  - Boost
  - GCC-ToolChain
  - zlib
build_requires:
  - CMake
  - ninja
  - Python
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

# Unsetting default compiler flags in order to make sure that no debug
# information is compiled into the objects which make the build artifacts very
# big.
unset CXXFLAGS
unset CFLAGS
unset LDFLAGS

# Check-out Include What You Use. It will be built as a part of LLVM suite
git clone -b "clang_23" --depth 1 --single-branch https://github.com/include-what-you-use/include-what-you-use.git iwyu

DEFAULT_SYSROOT= 
LLVM_TARGETS_TO_BUILD=X86

cmake $SOURCEDIR/llvm                                                         \
  -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                                       \
  -DCMAKE_BUILD_TYPE=Release                                                  \
  -DCMAKE_COLOR_DIAGNOSTICS=ON                                                \
  -G Ninja                                                                    \
  -DCMAKE_POLICY_DEFAULT_CMP0144=NEW                                          \
  ${GCC_TOOLCHAIN_ROOT:+-DCMAKE_C_COMPILER="$GCC_TOOLCHAIN_ROOT/bin/gcc"}     \
  ${GCC_TOOLCHAIN_ROOT:+-DCMAKE_CXX_COMPILER="$GCC_TOOLCHAIN_ROOT/bin/g++"}   \
  -DCMAKE_COLOR_DIAGNOSTICS=ON                                                \
  -DLLVM_TARGETS_TO_BUILD="${LLVM_TARGETS_TO_BUILD:?}"                        \
  -DLLVM_LIBC_FULL_BUILD=ON                                                   \
  -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra"                            \
  -DLLVM_ENABLE_RUNTIMES="libunwind;libcxxabi;libcxx;compiler-rt;openmp"      \
  -DLLVM_EXTERNAL_PROJECTS=iwyu                                               \
  -DLLVM_EXTERNAL_IWYU_SOURCE_DIR=$BUILDDIR/iwyu                              \
  -DLLVM_TARGET_ARCH=x86_64                                                   \
  -DLLVM_BUILD_LLVM_DYLIB=ON                                                  \
  -DLLVM_ENABLE_RTTI=ON                                                       \
  -DBUILD_SHARED_LIBS=OFF                                                     \
  -DCOMPILER_RT_BUILD_BUILTINS=TRUE                                           \
  -DLIBCXXABI_USE_LLVM_UNWINDER=OFF

cmake --build . -- ${JOBS+-j $JOBS} install

# Allow clang to find our own GCC. Notice the cat does not expand variables because
# we want to resolve the environment when we run, not when we build this, to avoid
# relocation issues in case GCC and clang are not built at the same time.
if [ ! "X$GCC_TOOLCHAIN_ROOT" = X ]; then
  cat > "$INSTALLROOT/bin/$($INSTALLROOT/bin/clang --print-target-triple)-clang++.cfg" << EoF
--gcc-toolchain=$GCC_TOOLCHAIN_ROOT
EoF
  cat > "$INSTALLROOT/bin/$($INSTALLROOT/bin/clang --print-target-triple)-clang.cfg" << EoF
--gcc-toolchain=$GCC_TOOLCHAIN_ROOT
EoF
  cat > "$INSTALLROOT/bin/$($INSTALLROOT/bin/clang --print-target-triple)-clang-cpp.cfg" << EoF
--gcc-toolchain=$GCC_TOOLCHAIN_ROOT
EoF

# Check if build actually works
cat > test.cc << EoF
#include <iostream>
EoF
"$INSTALLROOT/bin/clang++" -v -c test.cc
fi

CLANG_MAJOR_VERSION=$(echo "$PKG_VERSION" | cut -c 2- | cut -d'.' -f1)
CLEAN_GCC_VERSION="${GCC_TOOLCHAIN_VERSION#v}"
LINUXTRIPLET="$(basename $(find $GCC_TOOLCHAIN_ROOT/include/c++/$CLEAN_GCC_VERSION/ -type d -name '*-*-*'))"

# make soft link to run-clang-tidy
cd $INSTALLROOT/bin
ln -nfs run-clang-tidy run-clang-tidy-$CLANG_MAJOR_VERSION
cd $BUILDDIR

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv Clang_DIR \$PKG_ROOT/lib/cmake/clang
setenv LLVM_DIR \$PKG_ROOT/lib/cmake/llvm
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include/$LINUXTRIPLET
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/lib/clang/$CLANG_MAJOR_VERSION/include
prepend-path LD_LIBRARY_PATH \$PKG_ROOT/lib/$LINUXTRIPLET
prepend-path LD_LIBRARY_PATH \$PKG_ROOT/lib/clang/$CLANG_MAJOR_VERSION/lib/$LINUXTRIPLET
prepend-path PATH \$PKG_ROOT/libexec
prepend-path PATH \$PKG_ROOT/lib/clang/$CLANG_MAJOR_VERSION/bin
prepend-path MANPATH \$PKG_ROOT/share/man
EoF

nicadist-postbuild-hook

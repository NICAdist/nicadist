package: ndmspc
version: v1.4.0.rc46
tag: v1.4.0-rc46
source: https://gitlab.com/ndmspc/ndmspc.git
requires:
  - nlohmann_json
  - OpenSSL
  - ROOT
  - ZeroMQ
build_requires:
  - CMake
  - ninja
incremental_recipe: |
  [[ $ALIBUILD_NDMSPC_TESTS ]] && CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
  cmake --build . -- ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/sh -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

if [[ $ALIBUILD_NDMSPC_TESTS ]]; then
  # Impose extra errors.
  CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
fi

# When O2 is built against Gandiva (from Arrow), then we need to use
# -DLLVM_ROOT=$CLANG_ROOT, since O2's CMake calls into Gandiva's
# -CMake, which requires it.
cmake "$SOURCEDIR"                                                      \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                             \
      ${CMAKE_BUILD_TYPE:+"-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE"}       \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                        \
      ${CXXSTD:+"-DCMAKE_CXX_STANDARD=$CXXSTD"}                         \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                                      \
      -G Ninja                                                          \
      -DCMAKE_POLICY_DEFAULT_CMP0144=NEW                                \
      -DWITH_HTTP:bool=ON                                               \
      -DWITH_UI:bool=ON                                                 \
      -DWITH_AI:bool=OFF                                                \
      ${NLOHMANN_JSON_ROOT:+"-DNLOHMANN_JSON_ROOT=$NLOHMANN_JSON_ROOT"} \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cmake --build . -- ${JOBS+-j $JOBS} install

# export compile_commands.json in (taken from o2.sh)
DEVEL_SOURCES="$(readlink $SOURCEDIR || echo $SOURCEDIR)"
if [ "$DEVEL_SOURCES" != "$SOURCEDIR" ]; then
  perl -p -i -e "s|$SOURCEDIR|$DEVEL_SOURCES|" compile_commands.json
  ln -sf $BUILDDIR/compile_commands.json $DEVEL_SOURCES/compile_commands.json
fi

# Modulefile
mkdir -p etc/modulefiles
MODULEFILE="etc/modulefiles/$PKGNAME"
alibuild-generate-module --bin --lib > "$MODULEFILE"
cat >> "$MODULEFILE" << EoF
# Our environment
setenv NDMSPC_RELEASE \$version
setenv NDMSPC_BASEDIR \$::env(BASEDIR)/$PKGNAME
setenv NDMSPC_DIR \$::env(NDMSPC_BASEDIR)/\$::env(NDMSPC_RELEASE)
setenv NDMSPC_MACRO_DIR \$::env(NDMSPC_DIR)/macros
setenv NDMSPC_TUTORIAL_DIR \$::env(NDMSPC_DIR)/tutorial
prepend-path ROOT_DYN_PATH \$PKG_ROOT/lib
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include/ndmspc
EoF

mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles

nicadist-postbuild-hook

exit(432)
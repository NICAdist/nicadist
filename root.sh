package: ROOT
version: v6.40.04
tag: "v6-40-04" # don't forget to set BUILD_VERSION below
source: https://github.com/root-project/root.git
requires:
  - abseil-cpp
  - bzip2
  - FFTW
  - FTGL
  - FreeType
  - GCC-ToolChain
  - giflib
  - gl2ps
  - glew
  - GSL
  - libjpeg-turbo
  - libpng
  - libtiff
  - libxml2
  - lz4
  - lzma
  - nlohmann_json
  - OpenSSL
  - PCRE2
  - protobuf
  - Python
  - Python-modules
  - pythia
  - TBB
  - Xdevel
  - XRootD
  - xxHash
  - zlib
  - zstd
build_requires:
  - CMake
  - ninja
  - opengl
env:
  ROOTSYS: "$ROOT_ROOT"
prepend_path:
  PYTHONPATH: "$ROOTSYS/lib"
  ROOT_DYN_PATH: "$ROOT_ROOT/lib"
incremental_recipe: |
  rsync -a --exclude '**/.git' $SOURCEDIR/ $BUILDDIR/ROOT_SOURCES
  if [ -d "$BUILDDIR/ROOT_SOURCES/nicaPatches" ]; then # apply patches if they are available
    cd ROOT_SOURCES/nicaPatches && . applyPatches && cd ../..
  fi
  # Limit parallel builds to prevent OOM
  cmake --build . --target install ${JOBS+-j $JOBS}
  rm -vf "$INSTALLROOT/etc/plugins/TGrid/P010_TAlien.C"         \
         "$INSTALLROOT/etc/plugins/TSystem/P030_TAlienSystem.C" \
         "$INSTALLROOT/etc/plugins/TFile/P070_TAlienFile.C"
  # Add support for ROOT_PLUGIN_PATH envvar for specifying additional plugin search paths
  grep -v '^Unix.*.Root.PluginPath' "$INSTALLROOT/etc/system.rootrc" > system.rootrc.0
  cat >> system.rootrc.0 << EoF
  # Specify additional plugin search paths via the environment variable ROOT_PLUGIN_PATH.
  # Plugins in \$ROOT_PLUGIN_PATH have priority.
  Unix.*.Root.PluginPath: \$(ROOT_PLUGIN_PATH):\$(ROOTSYS)/etc/plugins:
  Unix.*.Root.DynamicPath: .:\$(ROOT_DYN_PATH):
  EoF
  mv system.rootrc.0 "$INSTALLROOT/etc/system.rootrc"

  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e
# Fix syntax highlight
cat << EoF
EoF

export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

rsync -a --exclude '**/.git*' $SOURCEDIR/ $BUILDDIR/ROOT_SOURCES

BUILD_VERSION="v6-40-04" # same as GIT_TAG. GIT_TAG is not set during dev (incremental) builds
PATCH_URL=https://git.jinr.ru/nica/nicadist/-/raw/master/patches/ROOT/$BUILD_VERSION/downloadPatches
set +e # enable errors. If disabled, following command will exit script if given file does not exist
$(wget -q --spider --tries 1 $PATCH_URL)
HAS_PATCH=$?
set -e
if [[ $HAS_PATCH -eq 0 ]]; then # patch is available
  mkdir -p ROOT_SOURCES/nicaPatches && cd ROOT_SOURCES/nicaPatches/
  wget -N $PATCH_URL
  . downloadPatches
  . applyPatches
  cd ../..
fi

unset ROOTSYS
COMPILER_CC=cc
COMPILER_CXX=c++
COMPILER_LD=c++

# ROOT 6+: enable Python
ROOT_PYTHON_FLAGS="-Dpyroot=ON"
ROOT_HAS_PYTHON=1
which python3
python_exec=$(python3 -c 'import sysconfig; print(sysconfig.get_config_var("exec_prefix"))')/bin/python3
if [ "$python_exec" = "$(which python3)" ]; then
  # By default, if there's nothing funny going on, let ROOT pick the Python in
  # the PATH, which is the one built by us (unless disabled, in which case it
  # is the system one). This is substituted into ROOT's Python scripts'
  # shebang lines, so we cannot use an absolute path because the path to our
  # Python will differ between build time and runtime, e.g. on the Grid.
  PYTHON_EXECUTABLE=
else
  # If Python's exec_prefix doesn't point to the same place as $PATH, then we
  # have a shim script in between. This is used by things like pyenv and asdf.
  # This doesn't happen when building things to be published, only in local
  # usage, so hardcoding an absolute path into the shebangs is fine.
  PYTHON_EXECUTABLE=$python_exec
fi

if [ -n "$XROOTD_ROOT" ]; then
  ROOT_XROOTD_FLAGS="-Dxrootd=ON -DXROOTD_ROOT_DIR=$XROOTD_ROOT"
else
  # If we didn't build XRootD (e.g. if it was disabled by a default), explicitly
  # disable support for it -- otherwise, ROOT will download and compile against
  # its own XRootD version.
  ROOT_XROOTD_FLAGS='-Dxrootd=OFF'
fi

unset DYLD_LIBRARY_PATH

# Standard ROOT build
cmake "$BUILDDIR/ROOT_SOURCES"                                                          \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                                             \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}                         \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                                        \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                                           \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                                                      \
      -G Ninja                                                                          \
      -DCMAKE_POLICY_DEFAULT_CMP0074=NEW                                                \
      -DCMAKE_POLICY_DEFAULT_CMP0144=NEW                                                \
      -Dfreetype=ON                                                                     \
      -Dbuiltin_freetype=OFF                                                            \
      -Dpcre=ON                                                                         \
      -Dbuiltin_pcre=OFF                                                                \
      -Dsqlite=OFF                                                                      \
      $ROOT_XROOTD_FLAGS                                                                \
      $ROOT_PYTHON_FLAGS                                                                \
      ${ENABLE_COCOA:+-Dcocoa=ON}                                                       \
      -DCMAKE_CXX_COMPILER=$COMPILER_CXX                                                \
      -DCMAKE_C_COMPILER=$COMPILER_CC                                                   \
      -Dfortran=OFF                                                                     \
      -DCMAKE_LINKER=$COMPILER_LD                                                       \
      ${FFTW_ROOT:+-DFFTW_ROOT=$FFTW_ROOT}                                              \
      ${FFTW_ROOT:+-DFFTW_ROOT=$FFTW_ROOT}                                              \
      ${BZIP2_ROOT:+-DBZIP2_INCLUDE_DIR=$BZIP2_ROOT/include}                            \
      ${BZIP2_ROOT:+-DBZIP2_LIBRARIES=$BZIP2_ROOT/lib/libbz2.so}                        \
      ${GCC_TOOLCHAIN_REVISION:+-DCMAKE_EXE_LINKER_FLAGS="-L$GCC_TOOLCHAIN_ROOT/lib64"} \
      ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT}                                 \
      ${LIBBSD_ROOT:+-DLIBBSDROOT=$LIBBSD_ROOT}                                         \
      ${LIBXML2_ROOT:+-DLIBXML2_ROOT=$LIBXML2_ROOT}                                     \
      ${LIBXML2_ROOT:+-DPC_LIBXML_INCLUDEDIR=$LIBXML2_ROOT/include}                     \
      ${LIBXML2_ROOT:+-DPC_LIBXML_LIBDIR=$LIBXML2_ROOT/lib}                             \
      ${GIFLIB_ROOT:+-DGIF_INCLUDE_DIR=$GIFLIB_ROOT/include}                            \
      ${GIFLIB_ROOT:+-DGIF_LIBRARY=$GIFLIB_ROOT/lib/libgif.so}                          \
      ${GLEW_ROOT:+-DGLEW_INCLUDE_DIRS=$GLEW_ROOT/include}                              \
      ${GLEW_ROOT:+-DGLEW_LIBRARIES=$GLEW_ROOT/lib/libGLEW.so}                          \
      ${GL2PS_ROOT:+-Dgl2ps_INCLUDE_DIR=$GL2PS_ROOT/include}                            \
      ${GL2PS_ROOT:+-Dgl2ps_LIBRARY=$GL2PS_ROOT/lib/libgl2ps.so}                        \
      ${GSL_ROOT:+-DGSL_DIR=$GSL_ROOT}                                                  \
      ${LIBJPEG_TURBO_ROOT:+-DJPEG_INCLUDE_DIR=$LIBJPEG_TURBO_ROOT/include}             \
      ${LIBJPEG_TURBO_ROOT:+-DJPEG_LIBRARY=$LIBJPEG_TURBO_ROOT/lib/libjpeg.so}          \
      ${LIBPNG_ROOT:+-DPNG_ROOT=$LIBPNG_ROOT}                                           \
      ${LIBPNG_ROOT:+-DPNG_INCLUDE_DIRS=$LIBPNG_ROOT/include}                           \
      ${LIBPNG_ROOT:+-DPNG_LIBRARY=$LIBPNG_ROOT/lib/libpng.so}                          \
      ${LIBTIFF_ROOT:+-DTIFF_INCLUDE_DIR=$LIBTIFF_ROOT/include}                         \
      ${LIBTIFF_ROOT:+-DTIFF_LIBRARY=$LIBTIFF_ROOT/lib/libtiff.so}                      \
      ${ZLIB_ROOT:+-DZLIB_ROOT=${ZLIB_ROOT}}                                            \
      ${XXHASH_ROOT:+-DxxHash_LIBRARY=$XXHASH_ROOT/lib/libxxhash.so}                    \
      ${XXHASH_ROOT:+-DxxHash_INCLUDE_DIR=$XXHASH_ROOT/include}                         \
      ${XROOTD_ROOT:+-DXROOTD_DIR=$XROOTD_ROOT}                                         \
      ${PYTHIA8_ROOT:+-DPYTHIA8=$PYTHIA8_ROOT}                                          \
      -Dbuiltin_davix=OFF                                                               \
      -Dbuiltin_fftw3=OFF                                                               \
      -Dbuiltin_vdt=ON                                                                  \
      -Ddavix=OFF                                                                       \
      -Dfftw3=ON                                                                        \
      -Dfitsio=OFF                                                                      \
      -Dgfal=OFF                                                                        \
      -Dgviz=OFF                                                                        \
      -Dhttp=ON                                                                         \
      -Dmathmore=ON                                                                     \
      -Dpythia8=ON                                                                      \
      -Droofit=ON                                                                       \
      -Droot7=ON                                                                        \
      -Dshadowpw=OFF                                                                    \
      -Dsoversion=ON                                                                    \
      -Dtmva-sofie=ON                                                                   \
      -Dvdt=ON                                                                          \
      ${ROOT_HAS_PYTHON:+-DPYTHON_PREFER_VERSION=3}                                     \
      ${PYTHON_EXECUTABLE:+-DPYTHON_EXECUTABLE="${PYTHON_EXECUTABLE}"}                  \
      -DCMAKE_PREFIX_PATH="$FREETYPE_ROOT;$GSL_ROOT;$PYTHON_ROOT;$PYTHON_MODULES_ROOT;$LIBPNG_ROOT;$LZMA_ROOT;$PROTOBUF_ROOT"

cmake --build . --target install ${JOBS+-j $JOBS}

# add special command to run JupyROOT without installing additional package
## root --notebook  <- this does not work when using multiple toolboxes on single computer
cat >> "$INSTALLROOT/bin/mpdJupyROOT" << EoF
#!/bin/bash
if [ -n "\$1" ]; then
  IFS=: read -r IP PORT <<< \$1
  root --notebook --ip=\$IP --port=\$PORT
else
  root --notebook
fi
EoF

chmod +x "$INSTALLROOT/bin/mpdJupyROOT"

# Add support for ROOT_PLUGIN_PATH envvar for specifying additional plugin search paths
grep -v '^Unix.*.Root.PluginPath' $INSTALLROOT/etc/system.rootrc > system.rootrc.0
cat >> system.rootrc.0 << EoF

# Specify additional plugin search paths via the environment variable ROOT_PLUGIN_PATH.
# Plugins in \$ROOT_PLUGIN_PATH have priority.
Unix.*.Root.PluginPath: \$(ROOT_PLUGIN_PATH):\$(ROOTSYS)/etc/plugins: 
Unix.*.Root.DynamicPath: .:\$(ROOT_DYN_PATH):
EoF
mv system.rootrc.0 $INSTALLROOT/etc/system.rootrc

# Make some CMake files used by other projects relocatable
sed -i.deleteme -e "s!$BUILDDIR!$INSTALLROOT!g" $(find "$INSTALLROOT" -name '*.cmake') || true

# Make sure all the tools use the correct python
for binfile in "$INSTALLROOT"/bin/*; do
  [ -f "$binfile" ] || continue
  if grep -q "^'''exec' .*python.*" "$binfile"; then
    # This file uses a hack to get around shebang size limits. As we're
    # replacing the shebang with the system python, the limit doesn't apply and
    # we can just use a normal shebang.
    sed -i.bak '1d; 2d; 3d; 4s,^,#!/usr/bin/env python3\n,' "$binfile"
  else
    sed -i.bak '1s,^#!.*python.*,#!/usr/bin/env python3,' "$binfile"
  fi
done

rm -fv "$INSTALLROOT"/bin/*.bak

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv ROOT_DIR \$PKG_ROOT/cmake
prepend-path MANPATH \$PKG_ROOT/man
setenv ROOTSYS \$PKG_ROOT
prepend-path PYTHONPATH \$PKG_ROOT/lib
prepend-path ROOT_DYN_PATH \$PKG_ROOT/lib
EoF

nicadist-postbuild-hook

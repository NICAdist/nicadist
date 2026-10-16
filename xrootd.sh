package: XRootD
version: v6.1.1
tag: v6.1.1
source: https://github.com/xrootd/xrootd.git
requires:
  - libxml2
  - Python-modules
build_requires:
  - CMake
  - ninja
  - UUID
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

XROOTD_PYTHON=""
[[ -e ${SOURCEDIR}/bindings ]] && XROOTD_PYTHON=True;
PYTHON_EXECUTABLE=$(/usr/bin/env python3 -c 'import sys; print(sys.executable)')
PYTHON_VER=$( ${PYTHON_EXECUTABLE} -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' )

rsync -a --exclude='**/.git' --exclude='**/.ci' --exclude='**/.github' --delete --delete-excluded \
      $SOURCEDIR/ ${BUILDDIR}

mkdir build
pushd build

cmake "$BUILDDIR"                                                               \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}                 \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                                              \
      -G Ninja                                                                  \
      -DCMAKE_INSTALL_LIBDIR=lib                                                \
      -DXRootD_VERSION_STRING=6.1.1                                             \
      ${CMAKE_FRAMEWORK_PATH:+-DCMAKE_FRAMEWORK_PATH=$CMAKE_FRAMEWORK_PATH}     \
      -DXRDCL_ONLY=ON                                                           \
      ${UUID_ROOT:+-DUUID_LIBRARY=$UUID_ROOT/lib/libuuid.so}                    \
      ${UUID_ROOT:+-DUUID_INCLUDE_DIRS=$UUID_ROOT/include}                      \
      ${UUID_ROOT:+-DUUID_INCLUDE_DIR=$UUID_ROOT/include}                       \
      ${LIBXML2_ROOT:+-DPC_LIBXML_INCLUDEDIR=$LIBXML2_ROOT/include}             \
      ${LIBXML2_ROOT:+-DPC_LIBXML_LIBDIR=$LIBXML2_ROOT/lib}                     \
      ${CURL_ROOT:+-DPC_CURL_INCLUDE_DIRS=$CURL_ROOT/include}                   \
      ${CURL_ROOT:+-DPC_CURL_LIBRARY_DIRS=$CURL_ROOT/lib}                       \
      -DENABLE_FUSE=OFF                                                         \
      -DENABLE_KRB5=OFF                                                         \
      -DENABLE_READLINE=OFF                                                     \
      -DENABLE_VOMS=OFF                                                         \
      ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT}                         \
      ${ZLIB_ROOT:+-DZLIB_ROOT=$ZLIB_ROOT}                                      \
      ${XROOTD_PYTHON:+-DENABLE_PYTHON=ON}                                      \
      ${XROOTD_PYTHON:+-DPIP_OPTIONS='--force-reinstall --ignore-installed -v'} \
      -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-Wno-error"

cmake --build . -- ${JOBS+-j $JOBS} install

popd

if [[ x"$XROOTD_PYTHON" == x"True" ]]; then
    pushd ${INSTALLROOT}

    # there are cases where python bindings are installed as relative to INSTALLROOT
    if [[ -d local/lib64 ]]; then
        [[ -d local/lib64/python${PYTHON_VER} ]] && mv -f local/lib64/python${PYTHON_VER} lib/
    fi
    if [[ -d local/lib ]]; then
        [[ -d local/lib/python${PYTHON_VER} ]] && mv -f local/lib/python${PYTHON_VER} lib/
    fi

    pushd lib
    if [ -d ../lib64/python${PYTHON_VER} ]; then
      ln -s ../lib64/python${PYTHON_VER} python
    elif [[ -d python${PYTHON_VER} ]]; then
      ln -s python${PYTHON_VER} python
    fi
    [[ ! -e python ]] && echo "NO PYTHON SYMLINK CREATED in: $(pwd -P)"
    popd  # get back from lib

    popd  # get back from INSTALLROOT

    # Print found XRootD python bindings
    # just run the the command as this is under "bash -e"
    echo -ne ">>>>>>   Found XRootD python bindings: "
    LD_LIBRARY_PATH="$INSTALLROOT/lib${LD_LIBRARY_PATH:+:}$LD_LIBRARY_PATH" PYTHONPATH="$INSTALLROOT/lib/python/site-packages${PYTHONPATH:+:}$PYTHONPATH" ${PYTHON_EXECUTABLE} -c 'from XRootD import client as xrd_client;print(f"{xrd_client.__version__}\n{xrd_client.__file__}");'
    echo
fi  # end of PYTHON part

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > "$MODULEFILE"

PYVER="$(basename $(find $INSTALLROOT/lib -type d -name 'python*'))"

cat >> "$MODULEFILE" << EoF
setenv XRootD_DIR \$PKG_ROOT/lib/cmake/XRootD
prepend-path PYTHONPATH \$PKG_ROOT/lib/$PYVER/site-packages
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path MANPATH \$PKG_ROOT/share/man
EoF

nicadist-postbuild-hook

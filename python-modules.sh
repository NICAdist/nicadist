package: Python-modules
version: "v2026.09"
requires:
  - OpenBLAS
  - Python
build_requires:
  - FreeType
  - libpng
  - Python-modules-list
prepend_path:
  PYTHONPATH: $PYTHON_MODULES_ROOT/share/python-modules/lib/python/site-packages 
---
# A spurios PYTHONPATH can affect later commands
unset PYTHONPATH
# If we are in a virtualenv, assume that what you want to do is to copy
# the same installation in your alibuild one.
if [ ! "X$VIRTUAL_ENV" = X ]; then
  # Once more to get the deactivate
  . $VIRTUAL_ENV/bin/activate
  pip freeze > system-requirements.txt
  deactivate
fi

# Special lists for different platforms
PIP39_REQUIREMENTS=$(eval echo \${PIP39_REQUIREMENTS_${ARCHITECTURE/-/_}:-$PIP39_REQUIREMENTS})
PIP310_REQUIREMENTS=$(eval echo \${PIP310_REQUIREMENTS_${ARCHITECTURE/-/_}:-$PIP310_REQUIREMENTS})
PIP311_REQUIREMENTS=$(eval echo \${PIP311_REQUIREMENTS_${ARCHITECTURE/-/_}:-$PIP311_REQUIREMENTS})
PIP312_REQUIREMENTS=$(eval echo \${PIP312_REQUIREMENTS_${ARCHITECTURE/-/_}:-$PIP312_REQUIREMENTS})
PIP315_REQUIREMENTS=$(eval echo \${PIP315_REQUIREMENTS_${ARCHITECTURE/-/_}:-$PIP315_REQUIREMENTS})

# PIP_REQUIREMENTS, PIP36_REQUIREMENTS, PIP38_REQUIREMENTS come from python-modules-list.sh
case $ARCHITECTURE in
  *)
  echo $PIP_REQUIREMENTS | tr \  \\n > requirements.txt
  if python3 -c 'import sys; exit(0 if 1000*sys.version_info.major + sys.version_info.minor >= 3015 else 1)'; then
    echo $PIP315_REQUIREMENTS | tr \  \\n >> requirements.txt
  elif python3 -c 'import sys; exit(0 if 1000*sys.version_info.major + sys.version_info.minor >= 3012 else 1)'; then
    echo $PIP312_REQUIREMENTS | tr \  \\n >> requirements.txt
  elif python3 -c 'import sys; exit(0 if 1000*sys.version_info.major + sys.version_info.minor >= 3011 else 1)'; then
    echo $PIP311_REQUIREMENTS | tr \  \\n >> requirements.txt
  elif python3 -c 'import sys; exit(0 if 1000*sys.version_info.major + sys.version_info.minor >= 3010 else 1)'; then
    echo $PIP310_REQUIREMENTS | tr \  \\n >> requirements.txt
  elif python3 -c 'import sys; exit(0 if 1000*sys.version_info.major + sys.version_info.minor >= 3009 else 1)'; then
    echo $PIP39_REQUIREMENTS | tr \  \\n >> requirements.txt
  elif python3 -c 'import sys; exit(0 if 1000*sys.version_info.major + sys.version_info.minor >= 3008 else 1)'; then
    echo $PIP38_REQUIREMENTS | tr \  \\n >> requirements.txt
  elif python3 -c 'import sys; exit(0 if 1000*sys.version_info.major + sys.version_info.minor >= 3006 else 1)'; then
    echo $PIP36_REQUIREMENTS | tr \  \\n >> requirements.txt
  fi
  ;;
esac
# We use a different INSTALLROOT, so that we can build updatable RPMS which
# do not conflict with the underlying Python installation.
PYTHON_MODULES_INSTALLROOT=$INSTALLROOT/share/python-modules
mkdir -p $PYTHON_MODULES_INSTALLROOT

# Create the virtualenv
python3 -m venv $PYTHON_MODULES_INSTALLROOT
. $PYTHON_MODULES_INSTALLROOT/bin/activate

# Upgrade pip
python3 -m pip install -IU pip
python3 -m pip install --upgrade pip
# Install setuptools upfront, since this seems to create issues now...
python3 -m pip install -IU "setuptools<=60.8.2"
python3 -m pip install -IU wheel
python3 -m pip install --upgrade setuptools

# FIXME: required because of the newly introduced dependency on scikit-garden requires
# a numpy to be installed separately
# See also:
#   https://github.com/scikit-garden/scikit-garden/issues/23
# This makes numpy crash since it allows for 2 incompatible versions on single installation
# python3 -m pip install -IU numpy 
# --config-settings=cmake.args="-Duse-pythran=false" is a fix to make scipy 1.17.1 build with Python 3.15
python3 -m pip install -IU -r requirements.txt

# Major.minor version of Python
export PYVER="$(python3 -c 'import sysconfig; print(sysconfig.get_python_version())')"
# Find the proper Python lib library and export it
pushd "$PYTHON_MODULES_INSTALLROOT"
  # let's remove any pre-existent symlinks to have a clean slate
  [ -h lib64 ] && unlink lib64
  [ -h lib ]   && unlink lib
  if [[ -d lib64 ]]; then
    ln -nfs lib64 lib  # creates lib pointing to lib64
  elif [[ -d lib ]]; then
       ln -nfs lib lib64 # creates lib64 pointing to lib
  fi
  pushd lib
    ln -nfs python$PYVER python
  popd
  pushd bin
    # Fix shebangs: remove hardcoded Python path
    find . -type f -exec sed -i.deleteme -e "s|${PYTHON_MODULES_INSTALLROOT}|/usr|;s|python3|env python3|" '{}' \;
    find . -name "*.deleteme" -delete
  popd
popd

# Remove useless stuff
rm -rvf "$PYTHON_MODULES_INSTALLROOT"/lib/python*/test
find "$PYTHON_MODULES_INSTALLROOT"/lib/python* \
     -mindepth 2 -maxdepth 2 -type d -and \( -name test -or -name tests \) \
     -exec rm -rvf '{}' \;

# Install uv
curl -kLo uv-x86_64-unknown-linux-musl.tar.gz "https://releases.astral.sh/github/uv/releases/download/0.12.21/uv-x86_64-unknown-linux-musl.tar.gz"
tar -xf uv-x86_64-unknown-linux-musl.tar.gz
mv uv-x86_64-unknown-linux-musl/* $INSTALLROOT/share/python-modules/bin

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --root > $MODULEFILE

cat >> "$MODULEFILE" << EoF
prepend-path PATH \$PKG_ROOT/share/python-modules/bin
prepend-path LD_LIBRARY_PATH \$PKG_ROOT/share/python-modules/lib
prepend-path PYTHONPATH \$PKG_ROOT/share/python-modules/lib/python/site-packages
setenv JUPYTERLAB_DIR \$PKG_ROOT/share/python-modules/share/jupyter/lab
EoF

nicadist-postbuild-hook

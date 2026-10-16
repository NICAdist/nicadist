package: pycudwt
version: v1.0.2
tag: "v1.0.2"
source: https://github.com/pierrepaleo/pypwt.git
requires:
  - CUDA
  - GCC-ToolChain
  - Python
build_requires:
  - autotools
  - Python-modules
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

# Manualy set paths since aliBuild does not use real Modulefiles
export PATH=$WORK_DIR/shared/CUDA/$CUDA_VERSION/bin:$PATH
export LD_LIBRARY_PATH=$WORK_DIR/shared/CUDA/$CUDA_VERSION/lib:$WORK_DIR/shared/CUDA/$CUDA_VERSION/lib64:$LD_LIBRARY_PATH

case "$CUDA_VERSION" in
  "v12.9")
    sed -i "s@\"-arch=sm_30\"@-arch=compute_70 -code=sm_70 -Wno-deprecated-gpu-targets -allow-unsupported-compiler@g" pdwt/Makefile
    ;;
  "v13.4")
    sed -i "s@\"-arch=sm_30\"@-arch=compute_80 -code=sm_80 -Wno-deprecated-gpu-targets -allow-unsupported-compiler@g" pdwt/Makefile
    ;;
  *)
    echo "Error: Unsupported version of CUDA ($CUDA_VERSION). Change version in recipe or fix recipe of pycudwt." >&2
    exit 1
    ;;
esac

sed -i "s@\$(NVCC) --ptxas-options@\$(NVCC) \$(CFLAGS) --ptxas-options@g" pdwt/Makefile

pushd pdwt
  make libpdwt.so
  make libpdwtd.so
  # install
  mkdir -p $INSTALLROOT/lib
  mkdir -p $INSTALLROOT/include
  cp libpdwt.so $INSTALLROOT/lib/
  cp libpdwtd.so $INSTALLROOT/lib/
  cp src/*.h $INSTALLROOT/include/
popd

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv pycudwt_ROOT=\$PKG_ROOT
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

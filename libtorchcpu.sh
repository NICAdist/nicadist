# changing tag (and version) don't forget to change number in the zip in curl command
package: libTorchCPU
version: "v2.14.1"
tag: "2.14.1"
---
#!/bin/bash -e
# current versions see for https://pytorch.org/get-started/locally/
curl -fSsLo LibTorch.zip "https://download.pytorch.org/libtorch/cpu/libtorch-shared-with-deps-2.14.1%2Bcpu.zip"
unzip -o LibTorch.zip -d "$BUILDDIR"
mv "$BUILDDIR/libtorch"/* "$INSTALLROOT/"

# Disable kineto search since we don't provide it and search produces unnecessary warning
sed -i 's@  append_torchlib_if_found(kineto)@#  append_torchlib_if_found(kineto)@g' $INSTALLROOT/share/cmake/Torch/TorchConfig.cmake

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv ATen_DIR \$PKG_ROOT/share/cmake/ATen
setenv Caffe2_DIR \$PKG_ROOT/share/cmake/Caffe2
setenv Tensorpipe_DIR \$PKG_ROOT/share/cmake/Tensorpipe
setenv Torch_DIR \$PKG_ROOT/share/cmake/Torch
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook

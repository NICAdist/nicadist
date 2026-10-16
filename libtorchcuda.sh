# Changing tag (and version) don't forget to change number in the zip
# in curl command and set appropriate CUDA version in file name 
package: libTorchCUDA
version: "v2.14.1-cuda-12.6"
tag: "2.14.1"
---
#!/bin/bash -e
# current versions see for https://pytorch.org/get-started/locally/
# CUDA 12.x - V100
curl -fSsLo LibTorch.zip "https://download.pytorch.org/libtorch/cu126/libtorch-shared-with-deps-2.14.1%2Bcu126.zip"
# CUDA 13.x - A100, H100
# curl -fSsLo LibTorch.zip "https://download.pytorch.org/libtorch/cu132/libtorch-shared-with-deps-2.14.1%2Bcu132.zip"
                          
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

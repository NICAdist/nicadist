# Virtual package, that creates modulefile for CUDA. For this module to work, one has to
# install CUDA first and place it into $ALIBUILD_WORK_DIR/shared/CUDA/vXX.X directory
# and take care of all necessary drivers. Module file is written by hand since package
# is located in non-standard place
# 
# CUDA version | GCC-ToolChain | Supported GPU | Driver version | Where download for 64 bit linux
#   v11.4.4    |    v11.5.0    |   K40, K80    |  >= 470.82.01  | https://developer.download.nvidia.com/compute/cuda/11.4.4/local_installers/cuda_11.4.4_470.82.01_linux.run
#   v12.9      |    v14.4.0    |   V100        |  >= 575.51.03  | https://developer.download.nvidia.com/compute/cuda/12.9.0/local_installers/cuda_12.9.0_575.51.03_linux.run
#   v13.4      |    v16.2.0    |   A100, H100  |  >= 615.71.09  | https://developer.download.nvidia.com/compute/cuda/13.4.2/local_installers/cuda_13.4.2_linux.run
#
# To install CUDA, download one of the versions above and
# 1. Load module with respective version of GCC (11.5.0, 14.4.0, 16.2.0)
# 2. Run ./cuda_*_linux.run
# 3. Accept (license agreement)
# 4. Turn off installation of Driver, Samples, Demo suite, Documentation (leave Toolkit)
# 5. Enter Options menu
# 5a. Toolkit options -> Change toolkit install path -> Set to
#     /path/to/nica/sw/.../shared/CUDA/vXX.X
# 5b. Toolkit options -> Disable Creation of symbolic link, Desktop menu shortcuts, Installation of documents
# 5c. Library install path, same as in 5a
#     /path/to/nica/sw/.../shared/CUDA/vXX.X
# 6. Run installer
package: CUDA
version: v13.4
build_requires:
  - GCC-ToolChain
---
#!/bin/bash -e
if ! [[ "$PKGVERSION" =~ (11\.4\.4|12\.9|13\.4) ]]; then
  echo "Cuda version $PKGVERSION is not supported. Use supported version (11.4.4, 12.9, 13.4) or modify recipe first." >&2
  exit 1
fi

CURRENT_GCC_MAJOR=$(g++ -dumpversion | cut -d. -f1)
CURRENT_GCC=$(g++ -dumpversion)
if [[ "$PKGVERSION" == *"11.4.4"* ]] && [ "$CURRENT_GCC_MAJOR" -ne 11 ]; then
  echo "Error: CUDA 11.4.4 demands maximum GCC 11.5. Found GCC $CURRENT_GCC" >&2
  exit 1
fi

if [[ "$PKGVERSION" == *"12.9"* ]] && [ "$CURRENT_GCC_MAJOR" -gt 14 ]; then
    echo "Error: CUDA 12.9 demands maximum GCC 14. Found GCC $CURRENT_GCC" >&2
    exit 1
fi

if [[ "$PKGVERSION" == *"13.4"* ]] && [ "$CURRENT_GCC_MAJOR" -lt 16 ]; then
    echo "Error: CUDA 13.4 demands at least GCC 16. Found GCC $CURRENT_GCC" >&2
    exit 1
fi

if [ ! -d "$WORK_DIR/shared/CUDA/$PKGVERSION" ]; then
  echo "Error: CUDA not found at $WORK_DIR/shared/CUDA/$PKGVERSION Install CUDA first and then try again." >&2
  exit 1
fi

# ModuleFile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

cat >> "$MODULEFILE" << EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "NICA Modulefile for CUDA $PKGVERSION"
}
set version $PKGVERSION
module-whatis "NICA Modulefile for CUDA $PKGVERSION"
# Dependencies
if ![ is-loaded "GCC-ToolChain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION" ] { module load GCC-ToolChain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION }
# Determine path to programs relative to MODULES directory (MODULES/../architecture/programs)
# and set PKG_ROOT and/or PKG_PATH
set cuda_base [file normalize [file dirname \$ModulesCurrentModulefile]/../../../shared/[file tail [file dirname \$ModulesCurrentModulefile]]/$PKGVERSION]
setenv CUDA_ROOT \$cuda_base
prepend-path PATH \$cuda_base/bin
prepend-path LD_LIBRARY_PATH \$cuda_base/lib
prepend-path LD_LIBRARY_PATH \$cuda_base/lib64
prepend-path ROOT_INCLUDE_PATH \$cuda_base/include
EoF

nicadist-postbuild-hook

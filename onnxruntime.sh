package: ONNXRuntime
version: v1.30.0
# version v1.23.2 does not build with onnx v1.17 (or newer)
tag: v1.30.0
source: https://github.com/microsoft/onnxruntime
requires:
  - Boost
  - Eigen3
  - FlatBuffers
  - MicrosoftGSL
  - ONNX
  - RE2
build_requires:
  - date
  - SafeInt
  - PyTorch-CPUInfo
  - CMake
  - ninja
  - nlohmann_json
  - Python
prepend_path:
  ROOT_INCLUDE_PATH: "$ONNXRUNTIME_ROOT/include/onnxruntime"
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

mkdir -p $INSTALLROOT

# Check ROCm MIOPEN build conditions
ORT_ROCM_BUILD="0"

# Check CUDA CUDNN build conditions
ORT_CUDA_BUILD="0"

# Optional GPU features
### MIGraphX
ORT_MIGRAPHX_BUILD="0"

### TensorRT
ORT_TENSORRT_BUILD="0"

mkdir -p $INSTALLROOT/etc
cat > $INSTALLROOT/etc/ort-init.sh << EoF
export ORT_ROCM_BUILD=$ORT_ROCM_BUILD
export ORT_CUDA_BUILD=$ORT_CUDA_BUILD
export ORT_MIGRAPHX_BUILD=$ORT_MIGRAPHX_BUILD
export ORT_TENSORRT_BUILD=$ORT_TENSORRT_BUILD
EoF

python3 $SOURCEDIR/onnxruntime/core/flatbuffers/schema/compile_schema.py --flatc $(which flatc)
python3 $SOURCEDIR/onnxruntime/lora/adapter_format/compile_schema.py --flatc $(which flatc)

# help to find includes of ONNX
sed -i 's@onnxruntime_fetchcontent_makeavailable(onnx)@onnxruntime_fetchcontent_makeavailable(onnx)\ninclude_directories(${ONNX_ROOT}/include)@g' $SOURCEDIR/cmake/external/onnxruntime_external_deps.cmake

# --debug-find - debug option on find commands in CMake
cmake "$SOURCEDIR/cmake"                                                                                    \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                                                                 \
      -DCMAKE_BUILD_TYPE=Release                                                                            \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                                                               \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                                                                          \
      -G Ninja                                                                                              \
      -DCMAKE_INSTALL_LIBDIR=lib                                                                            \
      -DCMAKE_BUILD_TYPE=Release                                                                            \
      -DPython_EXECUTABLE="$(python3 -c 'import sys; print(sys.executable)')"                               \
      -DFETCHCONTENT_FULLY_DISCONNECTED=ON                                                                  \
      -DFETCHCONTENT_QUIET=OFF                                                                              \
      -DFETCHCONTENT_TRY_FIND_PACKAGE_MODE=ALWAYS                                                           \
      -DCMAKE_SHARED_LINKER_FLAGS='-Wl,-undefined,dynamic_lookup'                                           \
      -DCMAKE_EXE_LINKER_FLAGS='-Wl,-undefined,dynamic_lookup'                                              \
      -Dsafeint_SOURCE_DIR=${SAFEINT_ROOT}/include                                                          \
      ${ONNX_ROOT:+-DONNX_ROOT=$ONNX_ROOT}                                                                  \
      -Donnxruntime_BUILD_UNIT_TESTS=OFF                                                                    \
      -Donnxruntime_USE_PREINSTALLED_EIGEN=OFF                                                              \
      -Donnxruntime_BUILD_BENCHMARKS=OFF                                                                    \
      -Donnxruntime_BUILD_CSHARP=OFF                                                                        \
      -Donnxruntime_ENABLE_DLPACK=OFF                                                                       \
      -Donnxruntime_ENABLE_MICROSOFT_INTERNAL=OFF                                                           \
      -Donnxruntime_USE_TENSORRT=OFF                                                                        \
      -Donnxruntime_CROSS_COMPILING=OFF                                                                     \
      -Donnxruntime_DISABLE_CONTRIB_OPS=OFF                                                                 \
      -Donnxruntime_BUILD_SHARED_LIB=ON                                                                     \
      -Donnxruntime_USE_VCPKG=ON                                                                            \
      -Donnxruntime_ENABLE_TRAINING=OFF                                                                     \
      -Donnxruntime_USE_FULL_PROTOBUF=ON                                                                    \
      -Donnxruntime_ENABLE_PYTHON=OFF                                                                       \
      -Donnxruntime_MINIMAL_BUILD=OFF                                                                       \
      ${PROTOBUF_ROOT:+-DONNX_CUSTOM_PROTOC_EXECUTABLE=$PROTOBUF_ROOT/bin/protoc}                           \
      -Donnxruntime_USE_MIGRAPHX=${ORT_MIGRAPHX_BUILD}                                                      \
      -Donnxruntime_DISABLE_RTTI=OFF                                                                        \
      -DMSVC=OFF                                                                                            \
      -Donnxruntime_USE_CUDA=OFF                                                                            \
      -Donnxruntime_USE_CUDA_NHWC_OPS=OFF                                                                   \
      -DCMAKE_CXX_FLAGS="${CXXFLAGS} -Wno-error=unused-but-set-variable -Wno-error=deprecated -Wno-error=maybe-uninitialized -Wno-error=deprecated-enum-enum-conversion -Wno-error -Wno-error=missing-requires -w" \
      -DCMAKE_C_FLAGS="$CFLAGS -Wno-error=unused-but-set-variable -Wno-error=deprecated -Wno-error=maybe-uninitialized -Wno-error=deprecated-enum-enum-conversion -Wno-error -Wno-error=missing-requires -w"

cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
setenv onnxruntime_DIR \$PKG_ROOT/lib/cmake/onnxruntime
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include/onnxruntime
EoF

nicadist-postbuild-hook

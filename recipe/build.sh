#!/bin/bash
set -ex

# Workaround missing leading whitespace for mcpu stripping in bazel-toolchain
export CFLAGS=" ${CXXFLAGS}"
export CXXFLAGS=" ${CXXFLAGS}"

source gen-bazel-toolchain

if [[ "${target_platform}" == linux-* ]]; then
  $RECIPE_DIR/add_py_toolchain.sh
  EXTRA_BAZEL_ARGS="--extra_toolchains=//py_toolchain:py_toolchain"
fi

cd python

export PROTOC=$PREFIX/bin/protoc
if [[ "$build_platform" != "$target_platform" ]]; then
    export PROTOC=$BUILD_PREFIX/bin/protoc
fi

export PYTHON_BIN_PATH=$PREFIX/bin/python

# Prevent build_env python from being picked up. 
# $BUILD_PREFIX/bin is listed first in PATH, and bazel finds that python first.
export PATH="$PREFIX/bin:${PATH}"

bazel build \
    --platforms=//bazel_toolchain:target_platform \
    --host_platform=//bazel_toolchain:build_platform \
    --extra_toolchains=//bazel_toolchain:cc_cf_toolchain \
    --extra_toolchains=//bazel_toolchain:cc_cf_host_toolchain \
    --crosstool_top=//bazel_toolchain:toolchain \
    ${EXTRA_BAZEL_ARGS:-} \
    --cpu=${TARGET_CPU} \
    --local_cpu_resources=${CPU_COUNT} \
    --spawn_strategy=standalone \
    //python/dist:binary_wheel

$PYTHON -m pip install --no-deps --no-build-isolation ../bazel-bin/python/dist/protobuf-${PKG_VERSION}-*.whl

# Remove chance of trying to install multiple variants. 
rm ../bazel-bin/python/dist/protobuf-${PKG_VERSION}-*.whl
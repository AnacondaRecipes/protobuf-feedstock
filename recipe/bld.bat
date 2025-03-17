@echo on
setlocal enabledelayedexpansion

md py_toolchain

set "PYTHON_CYGPATH=%PYTHON:\=/%"
set "PY_VER_NO_DOT=%PY_VER:.=%"

sed -i "s/ SYSTEM_PYTHON_VERSION/ %PY_VER_NO_DOT%/g" python\dist\dist.bzl
if %ERRORLEVEL% neq 0 exit 1

sed -i "s;PYTHON_EXE;%PYTHON_CYGPATH%;g" %SRC_DIR%\python\dist\system_python.bzl
if %ERRORLEVEL% neq 0 exit 1

cd python

set PROTOC=%LIBRARY_BIN%\protoc

@rem Shorten path in CI
@rem See https://github.com/bazelbuild/bazel/issues/18683 and https://github.com/protocolbuffers/protobuf/issues/12947
if defined CONDA_BLD_PATH (
  set "OUTPUT_BASE=--output_base=%CONDA_BLD_PATH%bazel"
) else (
  set OUTPUT_BASE=
)
set BAZEL_LLVM=%BUILD_PREFIX:\=/%/Library/
set CLANG_COMPILER_PATH=%Bazel_LLVM%/bin/clang.exe
set BAZEL_VS="%VSINSTALLDIR%"
set BAZEL_VC="%VSINSTALLDIR%/VC"

:: _ALLOW_COMPILER_AND_STL_VERSION_MISMATCH can be removed when we have clang>=11.0
bazel %OUTPUT_BASE% build ^
    --linkopt "/LIBPATH:%PREFIX%\libs" ^
    --action_env PYTHON_BIN_PATH=%PYTHON% ^
    --cxxopt=/std:c++17 ^
    --host_cxxopt=/std:c++17 ^
    --compiler=clang-cl ^
    --verbose_failures ^
    --copt=-D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH ^
    --host_copt=-D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH ^
    //python/dist:binary_wheel ^
    --define=use_fast_cpp_protos=true
if %ERRORLEVEL% neq 0 exit 1

%PYTHON% -m pip install --no-deps --no-build-isolation ..\bazel-bin\python\dist\protobuf-%PKG_VERSION%-cp%PY_VER_NO_DOT%-abi3-win_amd64.whl
if %ERRORLEVEL% neq 0 exit 1

bazel clean --expunge
if %ERRORLEVEL% neq 0 exit 1

bazel shutdown
if %ERRORLEVEL% neq 0 exit 1

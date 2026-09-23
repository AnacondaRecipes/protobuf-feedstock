@echo on
setlocal enabledelayedexpansion

@rem Create python3.exe symlink for rules_python compatibility
@rem On Windows, only python.exe exists, but rules_python looks for python3
@rem see https://github.com/conda-forge/python-feedstock/pull/640
copy "%PREFIX%\python.exe" "%PREFIX%\python3.exe"
if %ERRORLEVEL% neq 0 exit 1

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
set CLANG_COMPILER_PATH=%BAZEL_LLVM%/bin/clang.exe
set BAZEL_VS="%VSINSTALLDIR%"
set BAZEL_VC="%VSINSTALLDIR%/VC"

@rem The upstream .bazelrc hardcodes the x64_windows-clang-cl platform, which is
@rem wrong when building natively for win-arm64. Select the Bazel platform and
@rem toolchain that match the build architecture.  clang does not define
@rem __SEH__ for aarch64-windows, so define it for upb's encode.c to omit the
@rem in-function .p2align that crashes the AArch64 SEH backend
@rem (see https://github.com/llvm/llvm-project/issues/47432).
set "BAZEL_ARM64_FLAGS=--platforms=//build_defs:win-arm64 --host_platform=//build_defs:arm64_windows-clang-cl --extra_execution_platforms=//build_defs:arm64_windows-clang-cl --extra_toolchains=@local_config_cc//:cc-toolchain-arm64_windows-clang-cl --per_file_copt=.*upb/wire/encode\.c@-D__SEH__ --host_per_file_copt=.*upb/wire/encode\.c@-D__SEH__"
set "BAZEL_ARCH_FLAGS="
if /I "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "BAZEL_ARCH_FLAGS=%BAZEL_ARM64_FLAGS%"
if /I "%target_platform%"=="win-arm64" set "BAZEL_ARCH_FLAGS=%BAZEL_ARM64_FLAGS%"

for %%f in ("dist\BUILD.bazel" "dist\dist.bzl") do (
  sed -i "/@system_python\/\/:version\.bzl/d" "%%~f"
  if %ERRORLEVEL% neq 0 exit 1
  sed -i "s|SYSTEM_PYTHON_VERSION|\"%PY_VER_NO_DOT%\"|g" "%%~f"
  if %ERRORLEVEL% neq 0 exit 1
)

:: protobuf misuses `SUPPORTED_PYTHON_VERSIONS[-1]` to mean "default python", see
:: https://github.com/protocolbuffers/protobuf/issues/22313
sed -i "s|SUPPORTED_PYTHON_VERSIONS\[-1\]|\"%PY_VER%\"|g" "..\MODULE.bazel"
if %ERRORLEVEL% neq 0 exit 1

bazel %OUTPUT_BASE% build ^
    --linkopt "/LIBPATH:%PREFIX%\libs" ^
    --action_env PYTHON_BIN_PATH=%PYTHON% ^
    --compiler=clang-cl ^
    --cxxopt=/std:c++17 ^
    --host_cxxopt=/std:c++17 ^
    --verbose_failures %BAZEL_ARCH_FLAGS% ^
    //python/dist:binary_wheel
if %ERRORLEVEL% neq 0 exit 1

@rem The wheel platform tag depends on the target architecture (win_amd64 vs
@rem win_arm64), so locate the built wheel instead of hardcoding its name.
for %%w in ("..\bazel-bin\python\dist\protobuf-*.whl") do set "PROTOBUF_WHEEL=%%~fw"
if not defined PROTOBUF_WHEEL (
  echo Could not find the built protobuf wheel & exit 1
)

%PYTHON% -m pip install --no-deps --no-build-isolation "!PROTOBUF_WHEEL!"
if %ERRORLEVEL% neq 0 exit 1

bazel clean --expunge
if %ERRORLEVEL% neq 0 exit 1

bazel shutdown
if %ERRORLEVEL% neq 0 exit 1

@rem remove extraneous python3 again (see above)
del /s /q %PREFIX%\python3.exe

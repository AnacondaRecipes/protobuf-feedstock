:: Install the Python portions too.
cd %SRC_DIR%
if errorlevel 1 exit 1
cd python
if errorlevel 1 exit 1

"%PYTHON%" -m pip install . -vv --install-option="--cpp_implementation" --no-deps --no-build-isolation
if errorlevel 1 exit 1

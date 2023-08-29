:: Install the Python portions too.
cd %SRC_DIR%
if errorlevel 1 exit 1
cd python
if errorlevel 1 exit 1

"%PYTHON%" -m pip install --config-settings="--build-option=--cpp_implementation" --use-pep517 --no-deps --no-build-isolation -vv .
if errorlevel 1 exit 1

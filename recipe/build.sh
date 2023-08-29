#!/bin/bash

# Install python package now
cd python

${PYTHON} -m pip install . -vv --install-option="--cpp_implementation" --no-deps --no-build-isolation

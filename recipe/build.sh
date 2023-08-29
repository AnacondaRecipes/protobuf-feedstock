#!/bin/bash

# Install python package now
cd python

${PYTHON} -m pip install --config-settings="--build-option=--cpp_implementation" --no-deps --no-build-isolation -vv .
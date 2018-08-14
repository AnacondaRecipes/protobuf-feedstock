#!/bin/bash

# Install python package now
cd python

if [[ ${PY_VER} == 3.7 ]]; then
  # https://github.com/google/protobuf/issues/4086
  export CFLAGS="${CFLAGS} -fpermissive"
fi

${PYTHON} setup.py install --cpp_implementation --single-version-externally-managed --record record.txt

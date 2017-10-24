#!/bin/bash

set -ex

./autogen.sh
./configure --prefix="${PREFIX}" \
            --build=${HOST}      \
            --host=${HOST}       \
            --with-pic           \
            --enable-shared      \
            CC_FOR_BUILD=${CC}   \
            CXX_FOR_BUILD=${CXX} \
            --enable-static
make -j ${CPU_COUNT}
make check -j ${CPU_COUNT}
make install
(cd python && python setup.py install --cpp_implementation --single-version-externally-managed --record record.txt && cd ..)

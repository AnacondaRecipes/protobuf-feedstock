#!/bin/bash

cd python
$PYTHON setup.py install --cpp_implementation --old-and-unmanageable

rm $SP_DIR/*-nspkg.pth

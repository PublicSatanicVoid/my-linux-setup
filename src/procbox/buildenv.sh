#!/bin/sh

~/etc/setup/tools/newconda.sh seccomp
./seccomp/bin/conda install -y 'conda-forge::seccomp'


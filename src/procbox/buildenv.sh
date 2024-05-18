#!/bin/sh

~/etc/setup/tools/newconda.sh ptrace
./ptrace/bin/conda install -y 'conda-forge::seccomp'


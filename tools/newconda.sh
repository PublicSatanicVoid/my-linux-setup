#!/bin/bash

ENV_NAME="${1:-conda}"

INSTALLER_BASENAME="Miniconda3-latest-Linux-x86_64.sh"

wget --no-check-certificate "https://repo.anaconda.com/miniconda/$INSTALLER_BASENAME"
chmod +x "$INSTALLER_BASENAME"
./"$INSTALLER_BASENAME" -b -p "$ENV_NAME"

cd "$ENV_NAME"
./bin/conda update --all -y
./bin/conda install -y gcc_linux-64 gxx_linux-64
cd -

rm "$INSTALLER_BASENAME"


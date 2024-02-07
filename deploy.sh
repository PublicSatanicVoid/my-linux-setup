#!/bin/bash


REPO_ROOT="$(dirname "$(readlink -f "$0")")"

PYTHON3_EXE="python3"

"$PYTHON3_EXE" -m venv venv
./venv/bin/pip install --upgrade pip
./venv/bin/pip install pynvim 'python-lsp-server[all]' ruff-lsp ruff

# TODO download and install neovim

# Configure neovim
mkdir -p "$HOME/.config/nvim"
ln -s "$REPO_ROOT/config/nvim/init.lua" "$HOME/.config/nvim/init.lua"

# TODO download and install zellij

# Configure zellij
mkdir -p "$HOME/.config/zellij"
ln -s "$REPO_ROOT/config/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"


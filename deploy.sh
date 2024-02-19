#!/bin/bash


REPO_ROOT="$(dirname "$(readlink -f "$0")")"

PYTHON3_EXE="python3"

mkdir "$HOME/venvs"
pushd "$HOME/venvs"
"$PYTHON3_EXE" -m venv neovim_venv
./venv/bin/pip install --upgrade pip
./venv/bin/pip install neovim pynvim 'python-lsp-server[all]' ruff-lsp ruff
popd
echo "!! Add the following to your zshrc:"
echo "      export NEOVIM_VENV="$HOME/venvs/neovim_venv""

mkdir ~/.config

# TODO install npm


# TODO download and install neovim

# Configure neovim
#mkdir -p "$HOME/.config/nvim"
#ln -s "$REPO_ROOT/config/nvim/init.lua" "$HOME/.config/nvim/init.lua"
ln -s "$REPO_ROOT/config/nvim" "$HOME/.config/nvim"


# :TSUpdate
# :MasonInstall rust-analyzer
# :MasonInstall clangd
# :MasonInstall ruff-lsp
# :MasonInstall bash-language-server

# TODO download and install zellij

# Configure zellij
mkdir -p "$HOME/.config/zellij"
#ln -s "$REPO_ROOT/config/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"
ln -s "$REPO_ROOT/config/zellij" "$HOME/.config/zellij"


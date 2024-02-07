#!/bin/bash


REPO_ROOT="$(dirname "$(readlink -f "$0")")"


# TODO download and install neovim

# Configure neovim
mkdir -p "$HOME/.config/nvim"
ln -s "$REPO_ROOT/config/nvim/init.lua" "$HOME/.config/nvim/init.lua"

# TODO download and install zellij

# Configure zellij
mkdir -p "$HOME/.config/zellij"
ln -s "$REPO_ROOT/config/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"


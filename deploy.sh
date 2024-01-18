#!/bin/bash


REPO_ROOT="$(dirname "$(readlink -f "$0")")"


mkdir -p "$HOME/.config/nvim"
ln -s "$REPO_ROOT/config/nvim/init.vim" "$HOME/.config/nvim/init.vim"

mkdir -p "$HOME/.config/zellij"
ln -s "$REPO_ROOT/config/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"


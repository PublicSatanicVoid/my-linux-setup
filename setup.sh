#!/bin/bash

REPO_DIR="$(dirname "$(readlink -f "$0")")"
CONFIG_DIR="$HOME/.config"

#TODO

#https://github.com/neovim/neovim/releases/download/v0.9.5/nvim-linux64.tar.gz

#sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
#       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

mkdir -p "$CONFIG_DIR/nvim"
ln -s "$REPO_DIR/init.vim" "$CONFIG_DIR/nvim/init.vim"


# :PlugInstall
# :TransparentEnable


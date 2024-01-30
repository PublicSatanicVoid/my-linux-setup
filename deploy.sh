#!/bin/bash


REPO_ROOT="$(dirname "$(readlink -f "$0")")"

# Install vim-plug plugin manager
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# TODO download and install neovim

# Configure neovim
mkdir -p "$HOME/.config/nvim"
ln -s "$REPO_ROOT/config/nvim/init.vim" "$HOME/.config/nvim/init.vim"

# TODO download and install zellij

# Configure zellij
mkdir -p "$HOME/.config/zellij"
ln -s "$REPO_ROOT/config/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"


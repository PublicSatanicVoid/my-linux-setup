#!/bin/bash

# Prerequisites:
# - Python 3 installed and supports venvs
# - Login shell is zsh
# On Ubuntu:
# $ sudo apt update
# $ sudo apt dist-upgrade
# $ sudo apt autoremove
# $ sudo apt install zsh python3.12 python3.12-venv gcc-14 g++-14
# $ mkdir ~/bin
# $ ln -s /usr/bin/gcc-14 ~/bin/gcc
# $ ln -s /usr/bin/g++-14 ~/bin/g++
# $ chsh -s /bin/zsh

REPO_ROOT="$(dirname "$(readlink -f "$0")")"

ETC="$HOME/etc"
ETC_SETUP="$ETC/setup"

mkdir -p "$ETC_SETUP"
if [[ "$REPO_ROOT" != "$ETC_SETUP" ]]; then
    ln -s "$REPO_ROOT" "$ETC_SETUP"
fi

echo "-- Installing scripts..."
mkdir -p ~/bin
ln -s "$ETC_SETUP/tools/psall.sh" ~/bin/psall

echo "-- Installing zsh config..."
[ -f "$HOME/.zshrc" ] && mv "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%s)"
ln -s "$ETC_SETUP/config/zsh/zshrc" "$HOME/.zshrc"

echo "-- Installing gdb and gdb config..."
#mkdir "$HOME/conda"
#pushd "$HOME/conda"
#"$ETC_SETUP/tools/newconda.sh" gdb
#./gdb/bin/conda install -y python==3.11.5 gdb debugpy
#popd
ln -s "$ETC_SETUP/config/gdb/gdbinit" "$HOME/.gdbinit"


echo "-- Installing neovim python support..."
PYTHON3_EXE="python3"

mkdir "$HOME/venvs"
pushd "$HOME/venvs"
"$PYTHON3_EXE" -m venv neovim-venv
./neovim-venv/bin/pip install --upgrade pip
./neovim-venv/bin/pip install pynvim basedpyright ruff
popd
echo "!! Add the following to your zshrc:"
echo "      export NEOVIM_VENV="$HOME/venvs/neovim-venv""

mkdir -p ~/.config

# TODO install npm and cargo


# TODO download and install neovim

echo "-- Installing neovim config..."
# Configure neovim
#mkdir -p "$HOME/.config/nvim"
#ln -s "$REPO_ROOT/config/nvim/init.lua" "$HOME/.config/nvim/init.lua"
ln -s "$ETC_SETUP/config/nvim" "$HOME/.config/nvim"


# :TSUpdate

# TODO download and install rust
# $ curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
# $ rustup component add rust-analyzer-x86_64-unknown-linux-gnu

# TODO download and install zellij
# https://github.com/zellij-org/zellij/releases/download/v0.40.0/zellij-x86_64-unknown-linux-musl.tar.gz

echo "-- Installing zellij config..."
# Configure zellij
mkdir -p "$HOME/.config/zellij"
#ln -s "$REPO_ROOT/config/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"
ln -s "$ETC_SETUP/config/zellij" "$HOME/.config/zellij"

echo "-- Installing psql config..."
# Configure psqlrc
ln -s "$ETC_SETUP/config/psql/psqlrc" "$HOME/.psqlrc"

echo "-- Installing sqlite config..."
ln -s "$ETC_SETUP/config/sqlite/sqliterc" "$HOME/.sqliterc"

echo "-- Installing atop config..."
ln -s "$ETC_SETUP/config/atop/atoprc" "$HOME/.atoprc"

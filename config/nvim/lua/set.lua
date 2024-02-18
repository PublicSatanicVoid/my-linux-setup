local neovim_venv = os.getenv("NEOVIM_VENV") or os.getenv("HOME") .. "/venvs/neovim_venv"

vim.g.mapleader = " "

local opt = vim.opt

opt.compatible = false
opt.encoding = "utf-8"
opt.cursorline = false
opt.ignorecase = true
opt.hlsearch = false
opt.incsearch = true
opt.tabstop = 4
opt.softtabstop = 4
opt.expandtab = true
opt.shiftwidth = 4
opt.autoindent = true
opt.smartindent = true
opt.number = true
opt.relativenumber = true
opt.wildmode = "longest,list"
opt.colorcolumn = "88"
opt.textwidth = 88
opt.ttyfast = true
opt.swapfile = false
opt.backup = false
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
opt.undofile = true
opt.scrolloff = 10
opt.showmode = false  -- lualine does this now

-- Setup for plugins/features that use globals
vim.g.context_enabled = 1
vim.g.context_add_mappings = 1
vim.g.context_add_autocmds = 1
vim.g.context_max_height = 21
vim.g.context_max_per_indent = 11
vim.g.context_skip_regex = "^\\s*($|#|//|/\\*)"

vim.g.python3_host_prog = neovim_venv .. "/bin/python3"
vim.g.python_indent = {
    closed_paren_align_last_line = false,
    open_paren = "shiftwidth()",
    continue = "shiftwidth()"
}


local neovim_venv = os.getenv("NEOVIM_VENV") or os.getenv("HOME") .. "/venvs/neovim_venv"

local opt = vim.opt

-- Editor behavior
opt.ignorecase = true
opt.hlsearch = false
opt.incsearch = true
opt.scrolloff = 10
opt.showmode = false  -- lualine shows mode instead
vim.g.mapleader = " "

-- Indentation and formatting
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true
opt.colorcolumn = "88"
opt.textwidth = 88

-- Line numbers
opt.number = true
opt.relativenumber = true

-- File handling
opt.swapfile = false
opt.backup = false
opt.undodir = os.getenv("HOME") .. "/.vim/undo"
opt.undofile = true

-- Custom nvim patch to save undo files by the hash of the full path, rather
-- than the '%'-delimited full path
pcall(function() opt.undofilehash = true end)

-- Completion
opt.wildmode = "longest,list"

-- UI
opt.cmdheight = 0  -- hide command line until needed
opt.cursorline = false
opt.winborder = "rounded"
opt.synmaxcol = 20000  -- support syntax highlighting on longer lines

-- Global settings
vim.g.editorconfig = false
vim.g.clipboard = 'osc52'

-- Python provider
vim.g.python3_host_prog = neovim_venv .. "/bin/python3"
vim.g.python_indent = {
    closed_paren_align_last_line = false,
    open_paren = "shiftwidth()",
    continue = "shiftwidth()"
}

-- File type detection
vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
    pattern = {"*.cir", "*.cir.gz", "*.spf", "*.spf.gz", "*.sp", "*.sim"},
    command = "set filetype=spice"
})

vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
    pattern = {"*.cfg", "*.cfg.inc", "*.yml", "*.yaml"},
    command = "set filetype=yaml | set shiftwidth=4"
})

-- Highlighting override for color scheme (see highlights.scm in after/ directory)
vim.api.nvim_set_hl(0, "@custom.number.dimmed", { fg = "#A1A9AE" })
vim.api.nvim_set_hl(0, "@custom.parameter.dimmed", { fg = "#A1A9AE" })

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

-- Shorten an absolute path to a relative one if it falls under cwd.
local function shorten_path(path)
    local cwd = vim.fn.getcwd() .. "/"
    if vim.startswith(path, cwd) then
        local rel = path:sub(#cwd + 1)
        if rel ~= "" then return rel end
    end
    return path
end

-- After bufstop renders its window, rewrite absolute paths that fall under the
-- cwd as relative paths.  This is display-only: buffer names are not changed,
-- so :w, LSP, undo, etc. are completely unaffected.
function _G.bufstop_shorten_paths()
    local data = vim.g.BufstopData
    if not data or #data == 0 then return end

    local win = vim.fn.bufwinnr("--Bufstop--")
    if win == -1 then return end

    local bufnr = vim.fn.winbufnr(win)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local changed = false

    for i, entry in ipairs(data) do
        local short_path = shorten_path(entry.path)
        if short_path ~= entry.path and lines[i] then
            lines[i] = lines[i]:gsub(vim.pesc(entry.path), short_path, 1)
            changed = true
        end
    end

    if changed then
        vim.bo[bufnr].modifiable = true
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        vim.bo[bufnr].modifiable = false
    end
end

-- Highlighting override for color scheme (see highlights.scm in after/ directory)
vim.api.nvim_set_hl(0, "@custom.number.dimmed", { fg = "#A1A9AE" })
vim.api.nvim_set_hl(0, "@custom.parameter.dimmed", { fg = "#A1A9AE" })

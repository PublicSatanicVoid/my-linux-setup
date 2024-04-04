local neovim_venv = os.getenv("NEOVIM_VENV") or os.getenv("HOME") .. "/venvs/neovim_venv"

vim.g.mapleader = " "

function nmap(shortcut, command)
    vim.api.nvim_set_keymap('n', shortcut, command, { noremap = true, silent = false })
end

function imap(shortcut, command)
    vim.api.nvim_set_keymap('i', shortcut, command, { noremap = true, silent = false })
end

function tmap(shortcut, command)
    vim.api.nvim_set_keymap('t', shortcut, command, { noremap = true, silent = false  })
end

function vmap(shortcut, command)
    vim.api.nvim_set_keymap('v', shortcut, command, { noremap = true, silent = false  })
end

-- Scrolling half-page down/up keeps cursor centered vertically
nmap("<C-d>", "L<C-d>zz")
nmap("<C-u>", "H<C-u>zz")

-- File search / replace
nmap("<leader>sf", "<cmd>Telescope find_files<CR>")
nmap("<leader>sn", "<cmd>lua require('telescope.builtin').find_files({cwd=require('telescope.utils').buffer_dir()})<CR>")
nmap("<leader>sg", "<cmd>Telescope live_grep<CR>")
nmap("<leader>ss", "<cmd>Telescope lsp_document_symbols<CR>")
nmap("<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<CR>")
nmap("<leader>t", "<cmd>NvimTreeToggle<CR>")
nmap("<leader>S", "<cmd>lua require('spectre').toggle()<CR>")
nmap("<leader>sp", '<cmd>lua require("spectre").open_file_search({select_word = true})<CR>')

-- Search that doesn't require escaping regexes
nmap("/", ":%s%%%gn<Left><Left><Left><Left>")

-- Yank visual selection to system clipboard
vmap("<leader>y", "<Plug>OSCYankVisual")
nmap("<leader>y", "<Plug>OSCYankVisual")

-- Buffer switching
nmap("<leader>b", "<cmd>BufstopFast<CR>")
nmap("<leader>n", "<cmd>bprev<CR>")
nmap("<leader>p", "<cmd>bnext<CR>")
nmap("<leader><leader>", "<C-^>")

-- Open undo-tree panel
nmap("<leader>u", "<cmd>UndotreeToggle<CR>")

-- Esc gets out of terminal mode as well
tmap("<esc>", "<C-\\><C-N>")
tmap("<C-c>", "<C-\\><C-N>")

-- Make current file executable
nmap("<leader>x", "<cmd>!chmod +x %<CR>")

-- Ability to enter visual block mode when C-v is terminal paste
nmap("<C-b>", "<C-v>")

-- Search current word
nmap("<leader>sw", '<cmd>lua require("spectre").open_visual({select_word = true})<CR>')
vmap("<leader>sw", '<cmd>lua require("spectre").open_visual({select_word = true})<CR>')

-- Useful code snippets
nmap("<leader>ipdb", "a<CR>import ipdb<CR>ipdb.set_trace()<CR><C-c>")

-- Break the habit of using arrow keys instead of vim motions
nmap("<Up>", "<nop>")
nmap("<Down>", "<nop>")
nmap("<Left>", "<nop>")
nmap("<Right>", "<nop>")
vmap("<Up>", "<nop>")
vmap("<Down>", "<nop>")
vmap("<Left>", "<nop>")
vmap("<Right>", "<nop>")

-- Break the habit of using Esc instead of C-c
--imap("<Esc>", "<nop>")
--nmap("<Esc>", "<nop>")
--vmap("<Esc>", "<nop>")
--tmap("<Esc>", "<nop>")


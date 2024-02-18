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

nmap("<C-d>", "<C-d>zz")
nmap("<C-u>", "<C-u>zz")
nmap("<C-f>", "<cmd>Telescope find_files<CR>")
nmap("<C-i>", "<cmd>Telescope live_grep<CR>")
nmap("<C-l>", "<cmd>NvimTreeToggle<CR>")
nmap("/", ":%s###gn<Left><Left><Left><Left>")
vmap("<leader>y", "<Plug>OSCYankVisual")
nmap("<leader>y", "<Plug>OSCYankVisual")
nmap("<leader>b", "<cmd>BufstopFast<CR>")
nmap("<leader>n", "<cmd>bprev<CR>")
nmap("<leader>p", "<cmd>bnext<CR>")
nmap("<leader>u", "<cmd>UndotreeToggle<CR>")
tmap("<esc>", "<C-\\><C-N>")
nmap("<C-x>", "<cmd>!chmod +x %<CR>")
nmap("<C-b>", "<C-v>")

-- Break the habit of using arrow keys instead of vim motions
nmap("<Up>", "<nop>")
nmap("<Down>", "<nop>")
nmap("<Left>", "<nop>")
nmap("<Right>", "<nop>")
vmap("<Up>", "<nop>")
vmap("<Down>", "<nop>")
vmap("<Left>", "<nop>")
vmap("<Right>", "<nop>")


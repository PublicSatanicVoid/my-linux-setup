local neovim_venv = os.getenv("NEOVIM_VENV") or os.getenv("HOME") .. "/venvs/neovim_venv"

vim.g.mapleader = " "

-- Modern keymap helper with descriptions
local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { desc = desc })
end

-- Scrolling half-page down/up keeps cursor centered vertically
map("n", "<C-d>", "25jzz", "Scroll down and center")
map("n", "<C-u>", "25kzz", "Scroll up and center")

-- File search / replace
map("n", "<leader>sf", "<cmd>Telescope find_files<CR>", "Find files")
map("n", "<leader>sn", "<cmd>lua require('telescope.builtin').find_files({cwd=require('telescope.utils').buffer_dir()})<CR>", "Find files in current dir")
map("n", "<leader>sg", "<cmd>Telescope live_grep<CR>", "Live grep")
map("n", "<leader>ss", "<cmd>Telescope lsp_document_symbols<CR>", "Document symbols")
map("n", "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<CR>", "Search in buffer")
map("n", "<leader>t", "<cmd>NvimTreeToggle<CR>", "Toggle file tree")
map("n", "<leader>S", "<cmd>lua require('spectre').toggle()<CR>", "Toggle Spectre")
map("n", "<leader>sp", '<cmd>lua require("spectre").open_file_search({select_word = true})<CR>', "Search in file")

-- Search that doesn't require escaping regexes
map("n", "/", ":%s%%%gn<Left><Left><Left><Left>", "Search")

-- Yank visual selection to system clipboard
map("v", "<leader>y", '"+y', "Yank to system clipboard")

-- Buffer switching
map("n", "<leader>b", "<cmd>BufstopFast<CR>", "Buffer picker")
map("n", "<leader>n", "<cmd>bprev<CR>", "Previous buffer")
map("n", "<leader>p", "<cmd>bnext<CR>", "Next buffer")
map("n", "<leader><leader>", "<C-^>", "Toggle last buffer")

-- Open undo-tree panel
map("n", "<leader>u", "<cmd>UndotreeToggle<CR>", "Toggle undo tree")

-- Terminal mode escapes
map("t", "<esc>", "<C-\\><C-N>", "Exit terminal mode")
map("t", "<C-c>", "<C-\\><C-N>", "Exit terminal mode")

-- Make current file executable
map("n", "<leader>x", "<cmd>!chmod +x %<CR>", "Make file executable")

-- Ability to enter visual block mode when C-v is terminal paste
map("n", "<C-b>", "<C-v>", "Visual block mode")

-- Search current word
map("n", "<leader>sw", '<cmd>lua require("spectre").open_visual({select_word = true})<CR>', "Search word")
map("v", "<leader>sw", '<cmd>lua require("spectre").open_visual({select_word = true})<CR>', "Search selection")

-- Break the habit of using arrow keys instead of vim motions
local arrow_keys = {"<Up>", "<Down>", "<Left>", "<Right>"}
for _, key in ipairs(arrow_keys) do
    map("n", key, "<nop>", "Disabled arrow key")
    map("v", key, "<nop>", "Disabled arrow key")
end
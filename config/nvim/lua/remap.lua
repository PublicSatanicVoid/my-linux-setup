vim.g.mapleader = " "

local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { desc = desc })
end

-- Scrolling half-page down/up keeps cursor centered vertically
map("n", "<C-d>", "<C-d>zz", "Scroll down and center")
map("n", "<C-u>", "<C-u>zz", "Scroll up and center")

-- Search that doesn't require escaping regexes
map("n", "S", ":%s%%%gn<Left><Left><Left><Left>", "Search")

-- Yank visual selection to system clipboard
map({"v", "x"}, "<leader>y", '"+y', "Yank to system clipboard")

-- Buffer switching
map("n", "<leader>n", "<cmd>bprev<CR>", "Previous buffer")
map("n", "<leader>p", "<cmd>bnext<CR>", "Next buffer")
map("n", "<leader><leader>", "<C-^>", "Toggle last buffer")

-- Terminal mode escapes
map("t", "<esc>", "<C-\\><C-N>", "Exit terminal mode")
map("t", "<C-c>", "<C-\\><C-N>", "Exit terminal mode")

-- Make current file executable
map("n", "<leader>x", "<cmd>!chmod +x %<CR>", "Make file executable")

-- Break the habit of using arrow keys instead of vim motions
local arrow_keys = {"<Up>", "<Down>", "<Left>", "<Right>"}
for _, key in ipairs(arrow_keys) do
    map("n", key, "<nop>", "Disabled arrow key")
    map("v", key, "<nop>", "Disabled arrow key")
end

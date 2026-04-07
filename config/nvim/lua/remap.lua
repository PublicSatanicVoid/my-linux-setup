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


map(
    "n",
    "<leader>psr",
    function()
        require("custom.py-string-reflow").reflow_python_string_on_current_line()
    end,
    "Reflow single-line Python string"
)


map("n", "<leader>sf", "<cmd>Telescope find_files<CR>", "Find files")
map("n", "<leader>sn", "<cmd>lua require('telescope.builtin').find_files({cwd=require('telescope.utils').buffer_dir()})<CR>", "Find files in current dir")
map("n", "<leader>sg", "<cmd>Telescope live_grep<CR>", "Live grep")
map("n", "<leader>ss", "<cmd>Telescope lsp_document_symbols<CR>", "Document symbols")
map("n", "<leader>sc", "<cmd>lua require('custom.telescope').lsp_classes()<CR>", "Find classes in file")
map("n", "<leader>sm", "<cmd>lua require('custom.telescope').lsp_context_symbols()<CR>", "Find symbols in current class")
map("n", "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<CR>", "Search in buffer")

map("n", "<leader>b", function()
    vim.cmd("BufstopFast")
    _G.bufstop_shorten_paths()
end, "Buffer picker")

--vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
--vim.keymap.set("n", "<leader>d", function() harpoon:list():remove() end)
--vim.keymap.set("n", "<leader>h", function()
--    harpoon.ui:toggle_quick_menu(harpoon:list())
--end)


--map("n", "<leader>S", "<cmd>lua require('spectre').toggle()<CR>", "Toggle Spectre")
--map("n", "<leader>sp", "<cmd>lua require('spectre').open_file_search({select_word = true})<CR>", "Search in file")
--map({"n", "v"}, "<leader>sw", "<cmd>lua require('spectre').open_visual({select_word = true})<CR>", "Search word")

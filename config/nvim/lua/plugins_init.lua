--vim.api.nvim_create_autocmd('PackChanged', { callback = function(ev)
--    local name, kind = ev.data.spec.name, ev.data.kind
--    if name == 'blink.cmp' then
--        local obj = vim.system({'cargo', 'build', '--release'}, { cwd = ev.data.path }):wait()
--        print(vim.inspect(obj))
--    end
--end })

vim.pack.add({
    'https://github.com/nvim-lua/plenary.nvim',
    --'https://github.com/nvim-lualine/lualine.nvim',
    'https://github.com/PublicSatanicVoid/nightfox.nvim',
    'https://github.com/nvim-telescope/telescope.nvim',
    'https://github.com/mihaifm/bufstop',
    { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range("^1") },
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/nvim-treesitter/nvim-treesitter-context',
    'https://github.com/f-person/git-blame.nvim',
    --{ src = 'https://github.com/ThePrimeagen/harpoon', version = 'harpoon2' },
    'https://github.com/nvim-pack/nvim-spectre',
    'https://github.com/gukz/ftFT.nvim',
})

--require("lualine").setup({
--    options = {
--        icons_enabled = false,
--        theme = "auto",
--    },
--    sections = {
--        lualine_a = {"mode"},
--        lualine_b = {"branch", "diagnostics"},
--        lualine_c = {"filename"},
--        lualine_x = {"filetype"},
--        lualine_y = {"progress"},
--        lualine_z = {"location"}
--    }
--})
--
require("nightfox").setup({
    options = { transparent = true }
})
vim.cmd.colorscheme("terafox")

require("telescope").setup({
    -- Ivy theme: show telescope along the bottom rather than over the top
    -- of the existing buffers
    defaults = require("telescope.themes").get_ivy({
        border = {
            prompt = { 1, 1, 1, 1 },
            results = { 1, 1, 1, 1 },
            preview = { 0, 0, 0, 1 },
        },

        file_ignore_patterns = {
            ".git/.*",
            "*venv",
            "build",
            "__pycache__"
        }
    }),

    pickers = {
        current_buffer_fuzzy_find = {
            previewer = false,
            sorting_strategy = "ascending",
        }
    }
})

local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { desc = desc })
end
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


require("blink.cmp").setup({
    keymap = {
        preset = "none",
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
        ["<C-k>"] = { "show_signature", "hide_signature", "fallback" }
    },
    completion = {
        list = {
            -- Don't select first item automatically. This makes tabbing work
            -- correctly (first tab selects first item, etc)
            selection = {
                preselect = false,
                auto_insert = true
            }
        },
        documentation = {
            auto_show = true,
        }
    },
    sources = {
        default = { "lsp", "buffer" },

        providers = {
            -- https://cmp.saghen.dev/configuration/sources#show-buffer-completions-with-lsp
            -- > By default, the buffer source will only show when the LSP
            -- > source is disabled or returns no items. You may always show the
            -- > buffer source via:
            lsp = { fallbacks = {} },

            -- Deprioritize buffer completions, in favor of LSP completions
            buffer = { score_offset = -5 }
        }
    },
    cmdline = {
        enabled = false
    },
    appearance = {
        nerd_font_variant = "mono",
    },
    signature = {
        enabled = true,
        window = {
            show_documentation = true
        }
    }
})
local original = require("blink.cmp.completion.list").show
require("blink.cmp.completion.list").show = function(ctx, items_by_source)
    local seen = {}
    local function filter(item)
        if seen[item.label] then return false end
        seen[item.label] = true
        return true
    end

    for id in { "lsp", "buffer" } do
        items_by_source[id] = items_by_source[id] and vim.iter(items_by_source[id]):filter(filter):totable()
    end
    return original(ctx, items_by_source)
end


require("nvim-treesitter").setup()

langs = { "lua", "yaml", "vim", "bash", "python", "rust", "c", "javascript", "markdown", "rst" }

local spice_tree_sitter_src = "~/opt/tree-sitter-spice"
local have_spice = vim.fn.isdirectory(vim.fs.normalize(spice_tree_sitter_src))
if have_spice == 1 or have_spice == true then
    vim.api.nvim_create_autocmd("User", {
        pattern = "TSUpdate",
        callback = function()
            require("nvim-treesitter.parsers").spice = {
                install_info = {
                    path = spice_tree_sitter_src,
                    queries = "queries",
                }
            }
        end
    })

    table.insert(langs, "spice")
end

require("nvim-treesitter").install(langs, {summary = true})

vim.api.nvim_create_autocmd("FileType", {
    pattern = langs,
    callback = function()
        vim.treesitter.start()

        if vim.bo.filetype == "python" then
            -- equivalent to enabling additional_regex_syntax_highlighting
            -- in legacy nvim-treesitter
            -- without this, python indents are majorly screwed up
            vim.bo.syntax = "ON"
        end

        -- treesitter based indents are still supper buggy
        -- -- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})
--vim.g._ts_force_sync_parsing = true

require("treesitter-context").setup({
    enable = true,
    max_lines = 0,
    min_window_height = 0,
    line_numbers = true,
    multiline_threshold = 5,
    trim_scope = 'outer',
    mode = 'cursor',
    separator = '-',
    zindex = 20
})
vim.cmd("hi TreesitterContext guibg=none")
--
--
vim.api.nvim_create_user_command("BlameOn", "GitBlameEnable", {})
vim.api.nvim_create_user_command("BlameOff", "GitBlameDisable", {})
vim.api.nvim_create_user_command("Blame", "GitBlameToggle", {})
require("gitblame").setup({ enabled = false })
vim.g.gitblame_display_virtual_text = 1
vim.g.gitblame_date_format = "%r"
vim.g.gitblame_message_template = "    <author>, <date> • [<sha>] <summary>"

--local harpoon = require("harpoon")
--harpoon:setup()
--vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
--vim.keymap.set("n", "<leader>d", function() harpoon:list():remove() end)
--vim.keymap.set("n", "<leader>h", function()
--    harpoon.ui:toggle_quick_menu(harpoon:list())
--end)


map("n", "<leader>S", "<cmd>lua require('spectre').toggle()<CR>", "Toggle Spectre")
map("n", "<leader>sp", "<cmd>lua require('spectre').open_file_search({select_word = true})<CR>", "Search in file")
map({"n", "v"}, "<leader>sw", "<cmd>lua require('spectre').open_visual({select_word = true})<CR>", "Search word")

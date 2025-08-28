local neovim_venv = os.getenv("NEOVIM_VENV") or os.getenv("HOME") .. "/venvs/neovim_venv"

local T = {
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        opts = {
            options = {
                icons_enabled = false,
                theme = "auto",
            },
            sections = {
                lualine_a = {"mode"},
                lualine_b = {"branch", "diagnostics"},
                lualine_c = {"filename"},
                lualine_y = {"progress"},
                lualine_z = {"location"}
            },
        }
    },

    {
        "nvim-tree/nvim-web-devicons",
        lazy = true,
        opts = {}
    },

    {
        "PublicSatanicVoid/nightfox.nvim",
        lazy = false,  -- Load immediately for colors
        priority = 1000,  -- High priority for color scheme
        config = function()
            require("nightfox").setup({
                options = { transparent = true }
            })
            vim.cmd.colorscheme("terafox")
        end,
    },

    {"nvim-lua/plenary.nvim", lazy = true},

    {
        "nvim-telescope/telescope.nvim",
        event = "VeryLazy"
    },

    {"mihaifm/bufstop", event = "VeryLazy"},
    
    {
        "nvim-tree/nvim-tree.lua",
        cmd = "NvimTreeToggle",
        keys = {
            {"<leader>t", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file tree"}
        },
        config = function()
            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1
            require("nvim-tree").setup()
        end
    },

    -- Completion engine
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-nvim-lsp-signature-help",
        },
        config = function()
            local cmp = require("cmp")
            cmp.setup({
                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
                mapping = cmp.mapping.preset.insert({
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then cmp.select_next_item()
                        else fallback() end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then cmp.select_prev_item()
                        else fallback() end
                    end, { "i", "s" }),
                    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
                    ["<C-Space>"] = cmp.mapping.confirm({ select = true }),
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-e>"] = cmp.mapping.abort(),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "nvim_lsp_signature_help" },
                }, {
                    { name = "buffer" },
                })
            })
        end
    },

    {
        "nvim-treesitter/nvim-treesitter",
        event = "BufRead",
        build = ":TSUpdate",
        config = function()
            require('nvim-treesitter.configs').setup({
                ensure_installed = { "c", "lua", "vim", "bash", "python", "rust" },
                auto_install = true,
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
                indent = {
                    enable = true,
                    disable = { "python", "yaml" },
                }
            })

            vim.g._ts_force_sync_parsing = true
        end
    },

    {
        "nvim-treesitter/nvim-treesitter-context",
        event = "BufRead",
        opts = {
            enable = true,
            max_lines = 0,
            min_window_height = 0,
            line_numbers = true,
            multiline_threshold = 2,
            trim_scope = 'outer',
            mode = 'cursor',
            separator = '—',
            zindex = 20,
        },
        config = function(_, opts)
            require("treesitter-context").setup(opts)
            vim.cmd("hi TreesitterContext guibg=none")
        end
    },

    {
        "f-person/git-blame.nvim",
        cmd = {"BlameOn", "BlameOff", "Blame", "GitBlameToggle"},
        config = function()
            vim.api.nvim_create_user_command("BlameOn", "GitBlameEnable", {})
            vim.api.nvim_create_user_command("BlameOff", "GitBlameDisable", {})
            vim.api.nvim_create_user_command("Blame", "GitBlameToggle", {})
            require("gitblame").setup({ enabled = false })
            vim.g.gitblame_display_virtual_text = 1
            vim.g.gitblame_date_format = "%r"
            vim.g.gitblame_message_template = "    <author>, <date> • [<sha>] <summary>"
        end
    },
    
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        event = "VeryLazy",
        config = function()
            local harpoon = require("harpoon")
            harpoon:setup()
            vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
            vim.keymap.set("n", "<leader>d", function() harpoon:list():remove() end)
            vim.keymap.set("n", "<leader>h", function()
                harpoon.ui:toggle_quick_menu(harpoon:list())
            end)
        end
    },

    {
        "mbbill/undotree",
        cmd = "UndotreeToggle",
        keys = {
            {"<leader>u", "<cmd>UndotreeToggle<CR>", desc = "Toggle undo tree"}
        }
    },

    {
        "nvim-pack/nvim-spectre",
        cmd = {"Spectre"},
        keys = {
            {"<leader>S", "<cmd>lua require('spectre').toggle()<CR>", desc = "Toggle Spectre"},
            {"<leader>sp", "<cmd>lua require('spectre').open_file_search({select_word = true})<CR>", desc = "Search in file"},
            {"<leader>sw", "<cmd>lua require('spectre').open_visual({select_word = true})<CR>", desc = "Search word", mode = {"n", "v"}},
        }
    },

    {
        "tpope/vim-abolish",
        event = "VeryLazy"
    },

    {
        "unblevable/quick-scope",
        event = "VeryLazy"
    },

    -- Vim practice game
    -- {"ThePrimeagen/vim-be-good", event = "VeryLazy"},
}

return T

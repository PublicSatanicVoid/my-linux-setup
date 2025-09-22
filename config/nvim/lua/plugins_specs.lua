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
                lualine_x = {"filetype"},
                lualine_y = {"progress"},
                lualine_z = {"location"}
            }
        }
    },

    {
        "PublicSatanicVoid/nightfox.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("nightfox").setup({
                options = { transparent = true }
            })
            vim.cmd.colorscheme("terafox")
        end
    },

    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            -- Show telescope along the bottom rather than over the top of the existing
            -- buffers
            defaults = require("telescope.themes").get_ivy({
                border = {
                    prompt = { 1, 1, 1, 1 },
                    results = { 1, 1, 1, 1 },
                    preview = { 0, 0, 0, 1 },
                },

                file_ignore_patterns = {
                    ".git/.*",
                    "venv",
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
        },
        keys = {
            {"<leader>sf", "<cmd>Telescope find_files<CR>", desc = "Find files"},
            {"<leader>sn", "<cmd>lua require('telescope.builtin').find_files({cwd=require('telescope.utils').buffer_dir()})<CR>", desc = "Find files in current dir"},
            {"<leader>sg", "<cmd>Telescope live_grep<CR>", desc = "Live grep"},
            {"<leader>ss", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Document symbols"},
            {"<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search in buffer"}
        }
    },

    {
        "mihaifm/bufstop",
        event = "VeryLazy",
        keys = {
            {"<leader>b", "<cmd>BufstopFast<CR>", desc = "Buffer picker"}
        }
    },
    
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

    {
        "saghen/blink.cmp",
        event = { "InsertEnter", "VeryLazy" },
        version = "*",  -- Use a tagged release so we get the precompiled fuzzy finder
        opts = {
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
        }
    },

    {
        "nvim-treesitter/nvim-treesitter",
        event = { "BufReadPost", "BufNewFile" },
        build = ":TSUpdate",
        opts = {
            ensure_installed = { "c", "lua", "vim", "bash", "python", "rust" },
            auto_install = true,
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false
            },
            indent = {
                enable = true,
                disable = { "python", "yaml" }
            },
            move = {
                enable = true,
                goto_next_start = {
                  ["]m"] = "@function.outer",
                  ["]]"] = "@class.outer"
                },
                goto_next_end = {
                  ["]M"] = "@function.outer",
                  ["]["] = "@class.outer"
                },
                goto_previous_start = {
                  ["[m"] = "@function.outer",
                  ["[["] = "@class.outer"
                },
                goto_previous_end = {
                  ["[M"] = "@function.outer",
                  ["[]"] = "@class.outer"
                }
            }
        },
        config = function(_, opts)
            require("nvim-treesitter.configs").setup(opts)
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
            multiline_threshold = 5,
            trim_scope = 'outer',
            mode = 'cursor',
            separator = '-',
            zindex = 20
        },
        config = function(_, opts)
            require("treesitter-context").setup(opts)
            vim.cmd("hi TreesitterContext guibg=none")
        end
    },

    {
        "f-person/git-blame.nvim",
        cmd = {"BlameOn", "BlameOff", "Blame"},
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
        event = "VeryLazy",
        keys = {
            {"<leader>S", "<cmd>lua require('spectre').toggle()<CR>", desc = "Toggle Spectre"},
            {"<leader>sp", "<cmd>lua require('spectre').open_file_search({select_word = true})<CR>", desc = "Search in file"},
            {"<leader>sw", "<cmd>lua require('spectre').open_visual({select_word = true})<CR>", desc = "Search word", mode = {"n", "v"}}
        }
    },

    {
        "unblevable/quick-scope",
        event = "VeryLazy"
    },

    -- -- Case-matched search and replace
    -- {
    --     "tpope/vim-abolish",
    --     event = "VeryLazy"
    -- },

    -- -- Vim practice game
    -- {
    --     "ThePrimeagen/vim-be-good",
    --     event = "VeryLazy"
    -- }
}

return T
